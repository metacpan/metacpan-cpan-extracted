package AI::MicroStructure::KnowHow;
use strict;
use AI::MicroStructure ();    # do not export metaname and friends
#use AI::MicroStructure::RemoteKnowledge;
use List::Util qw( shuffle );
use Carp;

#our @ISA = qw( AI::MicroStructure::RemoteKnowledge );

sub init {
    my $class = caller(0);
    my $data  = AI::MicroStructure->load_data($class);
    no strict 'refs';

    my $sep = ${"$class\::Separator"} ||= '/';
    my $tail = qr/$sep?[^$sep]*$/;

    # compute all categories
    my @categories = ( [ $data->{names}, '' ] );
    while ( my ( $h, $k ) = @{ shift @categories or []} ) {
        if ( ref $h eq 'HASH' ) {
            push @categories,
                map { [ $h->{$_}, ( $k ? "$k$sep$_" : $_ ) ] } keys %$h;
        }
        else {    # leaf
            my @items = split /\s+/, $h;
            while ($k) {
                push @{ ${"$class\::KnowHow"}{$k} }, @items;
                $k =~ s!$tail!!;
            }
        }
    }

    ${"$class\::Default"} = $data->{default} || ':all';
    ${"$class\::Theme"} = ( split /::/, $class )[-1];

    *{"$class\::import"} = sub {
        my $callpkg = caller(0);
        my $theme   = ${"$class\::Theme"};
        my $meta    = $class->new;
        *{"$callpkg\::meta$theme"} = sub { $meta->name(@_) };
    };

    ${"$class\::meta"} = $class->new();
}

sub name {
    my ( $self, $count ) = @_;
    my $class = ref $self;

    if ( !$class ) {    # called as a class method!
        $class = $self;
        no strict 'refs';
        $self = ${"$class\::meta"};
    }
  no strict 'refs';

    if ( defined $count && $count !~ /A-Za-z/ && $count == 0 ) {
        return wantarray
            ? shuffle @{ $self->{base} }
            : scalar @{ $self->{base} };
    }

    $count ||= 1;
    my $Knowledge = $self->{cache};
    if ( @{ $self->{base} } ) {
        push @$Knowledge, shuffle @{ $self->{base} } while @$Knowledge < $count;
    }
    splice( @$Knowledge, 0, $count );
}

sub new {
    my $class = shift;

    no strict 'refs';
    my $self = bless { @_, cache => [] }, $class;

    # compute some defaults
    $self->{category} ||= ${"$class\::Default"};

    # fall back to last resort (FIXME should we carp()?)
    $self->{category} = ${"$class\::Default"}
        if $self->{category} ne ':all'
        && !exists ${"$class\::KnowHow"}{ $self->{category} };

    $self->_compute_base();
    return $self;
}

sub _compute_base {
    my ($self) = @_;
    my $class = ref $self;

    # compute the base Knowledge for this category
    no strict 'refs';
    my %seen;
    $self->{base} = [
        grep { !$seen{$_}++ }
            map { @{ ${"$class\::KnowHow"}{$_} } }
            $self->{category} eq ':all'
        ? ( keys %{"$class\::KnowHow"} )
        : ( $self->{category} )
    ];
    return;
}

sub category { $_[0]->{category} }

sub categories {
    my $class = shift;
    $class = ref $class if ref $class;

    no strict 'refs';
    return keys %{"$class\::KnowHow"};
}

sub has_category {
    my ($class, $category) = @_;
    $class = ref $class if ref $class;

    no strict 'refs';
    return exists ${"$class\::KnowHow"}{$category};
}

sub theme {
    my $class = ref $_[0] || $_[0];
    no strict 'refs';
    return ${"$class\::Theme"};
}

1;


package AI::MicroStructure::KnowHow;
use strict;
use warnings;
use Carp;

# method that extracts the items from the remote content and returns them
sub extract {
    my $class = ref $_[0] || $_[0];
    no strict 'refs';
    my $func  = ${"$class\::Remote"}{extract};

    # provide a very basic default
    my $meth = ref $func eq 'CODE'
        ? sub { my %seen; return grep { !$seen{$_}++ } $func->( $_[1] ); }
        : sub { return $_[1] };    # very basic default

    # put the method in the subclass symbol table (at runtime)
    *{"$class\::extract"} = $meth;

    # now run the function^Wmethod
    goto &$meth;
}

# methods related to the source URL
sub source {
    my $class = ref $_[0] || $_[0];
    no strict 'refs';

    return ${"$class\::Remote"}{source};
}

sub sources {
    my $class = ref $_[0] || $_[0];
    no strict 'refs';

    my $src = ${"$class\::Remote"}{source};
    if ( ref $src eq 'ARRAY' ) {
        return @$src;
    }
    elsif ( ref $src eq 'HASH' ) {
        return
            map { ref $_ ? @$_ : $_ } $_[1] ? $src->{ $_[1] } : values %$src;
    }
    return $src;
}

sub has_remoteKnowledge { return defined $_[0]->source(); }

# main method: return the Knowledge from the remote source
sub remote_Knowledge {
    my $class = ref $_[0] || $_[0];
    return unless $class->has_remoteKnowledge();

    # check that we can access the network
    eval {
        require LWP::UserAgent;
        die "version 5.802 required ($LWP::VERSION installed)\n"
            if $LWP::VERSION < 5.802;
    };
    if ($@) {
        carp "LWP::UserAgent not available: $@";
        return;
    }

    # fetch the content
    my @items;
    my @srcs = $class->sources($_[1]);
    my $ua   = LWP::UserAgent->new( env_proxy => 1 );
    foreach my $src (@srcs) {
        my $res  = $ua->request( HTTP::Request->new( GET => $src ) );
        if ( ! $res->is_success() ) {
            carp "Failed to get content at $src (" . $res->status_line();
            return;
        }

        # extract, cleanup and return the data
        # if decoding the content fails, we just deal with the raw content
        push @items =>
            $class->extract( $res->decoded_content() || $res->content() );

    }

    # return unique items
    my %seen;
    return grep { !$seen{$_}++ } @items;
}

#
# transformation subroutines
#
sub tr_nonword {
    my $str = shift;
    $str =~ tr/a-zA-Z0-9_/_/c;
    $str;
}

sub tr_accent {
    my $str = shift;
    $str =~ tr{ÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÑÒÓÔÕÖØÙÚÛÜÝàáâãäåçèéêëìíîïñòóôõöøùúûüýÿ}
              {AAAAAACEEEEIIIINOOOOOOUUUUYaaaaaaceeeeiiiinoooooouuuuyy};
    return $str;
}

my %utf2asc = (
    "\xc3\x89" => 'E',
    "\xc3\xa0" => 'a',
    "\xc3\xa1" => 'a',
    "\xc3\xa9" => 'e',
    "\xc3\xaf" => 'i',
    "\xc3\xad" => 'i',
    "\xc3\xb6" => 'o',
    "\xc3\xb8" => 'o',
    "\xc5\xa0" => 'S',
    "\x{0160}" => 'S',
    # for pokemons
    "\x{0101}"     => 'a',
    "\x{012b}"     => 'i',
    "\x{014d}"     => 'o',
    "\x{016b}"     => 'u',
    "\xe2\x99\x80" => 'female',
    "\xe2\x99\x82" => 'male',
    "\x{2640}"     => 'female',
    "\x{2642}"     => 'male',
);
my $utf_re = qr/(@{[join( '|', sort keys %utf2asc )]})/;

sub tr_utf8_basic {
    my $str = shift;
    $str =~ s/$utf_re/$utf2asc{$1}/go;
    return $str;
}

1;

package main;

use Data::Printer;
my $ps = AI::MicroStructure::KnowHow->new();
my @go = $ps->remote_Knowledge();
print  @go;
p $ps;
1;


__DATA__
package AI::MicroStructure::Knowledge;
use strict;
use AI::MicroStructure (); # do not export metaname and friends
#use AI::MicroStructure::RemoteKnowledge;
use List::Util qw( shuffle );
use Carp;

our @ISA = qw( AI::MicroStructure::RemoteKnowledge );

sub init {
    my ($self, $data) = @_;
    my $class = caller(0);

    $data ||= AI::MicroStructure->load_data($class);
    croak "The optional argument to init() must be a hash reference"
      if ref $data ne 'HASH';

    no strict 'refs';
    no warnings;
    ${"$class\::Theme"} = ( split /::/, $class )[-1];
    @{"$class\::Knowledge"} = split /\s+/, $data->{names};
    *{"$class\::import"} = sub {
        my $callpkg = caller(0);
        my $theme   = ${"$class\::Theme"};
        my $meta    = $class->new();
        *{"$callpkg\::meta$theme"} = sub { $meta->name(@_) };
      };
    ${"$class\::meta"} = $class->new();
}

sub name {
    my ( $self, $count ) = @_;
    my $class = ref $self;

    if( ! $class ) { # called as a class method!
        $class = $self;
        no strict 'refs';
        $self = ${"$class\::meta"};
    }
  no strict 'refs';

    if( defined $count && $count == 0 ) {
        return
          wantarray ? shuffle @{"$class\::Knowledge"} : scalar @{"$class\::Knowledge"};
    }

    $count ||= 1;
    my $Knowledge = $self->{cache};
    {
      no strict 'refs';
      if (@{"$class\::Knowledge"}) {
          push @$Knowledge, shuffle @{"$class\::Knowledge"} while @$Knowledge < $count;
      }
    }
    splice( @$Knowledge, 0, $count );
}

sub new {
    my $class = shift;

    bless { cache => [] }, $class;
}

sub theme {
    my $class = ref $_[0] || $_[0];
    no strict 'refs';
    return ${"$class\::Theme"};
}

1;


package AI::MicroStructure::pornstars;
use strict;
#use AI::MicroStructure::KnowHow;
our @ISA = qw( AI::MicroStructure::KnowHow );
__PACKAGE__->init();

our %Remote = (
    source => {
        female => 'http://en.wikipedia.org/wiki/Knowledge_of_female_porn_stars',
        male   => 'http://en.wikipedia.org/wiki/Knowledge_of_male_porn_stars'
    },
    extract => sub {
        return
            map { AI::MicroStructure::RemoteKnowledge::tr_accent($_) }
            map { AI::MicroStructure::RemoteKnowledge::tr_utf8_basic($_) }
            grep { ! /^Knowledge_|_Groups$/ }
            map { s/[-\s']/_/g; s/[."]//g; $_ }
            $_[0]
            =~ m{^<li>(?:<[^>]*>)?(.*?)(?:(?: ?[-,(<]| aka | see ).*)?</li>}mig
    },
    ,
);

1;
package main;

use Data::Printer;
my $ps = AI::MicroStructure::pornstars->new();
my @go = $ps->extract();
p  @go;
p $ps;
1;
__DATA__
# names female
Abigail_Clayton
Adara_Michaels
Addison_Rose
Adele_Stevens
Adriana_Sage
Adrienne_Bellaire
Africa_Sexxx
Ai_Iijima
Aimee_Sweet
Aja
Akira_Fubuki
Alana_Evans
Alaura_Eden
Alex_Dane
Alex_Jordan
Alex_Taylor
Alexa_May
Alexa_Rae
Alexa_Weix
Alexandra_Nice
Alexandra_Silk
Alexis_Amore
Alexis_DeVell
Alexis_Malone
Alexis_May
Alicia_Alighatti
Alicia_Monet
Alicia_Rhodes
Alicia_Rio
Alisha_Klass
Alison_Angel
Aliyah_Yi
Allie
Allie_Sin
Allison_Wyte
Ally_Mac_Tyana
Allysin_Chaynes
Amber_Lynn
Amber_Michaels
Amber_Rain
Amber_Rose
Anastasia_Blue
Anastasia_Christ
Andi_Pink
Andrea_Butjko
Andrea_True
Aneta_Smrhova
Angel_Dark
Angel_Kelly
Angel_Long
Angela_Baron
Angela_Devi
Angela_Haze
Angela_Tiger
Angelica_Bella
Angelica_Costello
Angelica_Sin
Angelina_Crow
Anika_Fox
Anita_Blond
Anita_Dark
Anja_Juliette_Laval
Anjali_Kara
Ann_Marie
Anna_Malle
Anna_Marek
Anna_Nova
Anna_Ohura
Anna_Ventura
Annabel_Chong
Anne_Howe
Annette_Haven
Annie_Cruz
Annie_Sprinkle
Annie_Swanson
April_Summers
Arcadia_Lake
Aria_Giovanni
Ariana_Jollee
Arsen_Wenger
Ashley_Blue
Ashley_Long
Ashlyn_Gere
Ashton_Moore
Asia_Carrera
Aspen_Stevens
Asuka_Sakamaki
Audrey_Hollander
Aurora_Snow
Austin_Kincaid
Austin_O_Riley
Autumn_Jade
Ava_Devine
Ava_Nova
Ava_Ramone
Ava_Vincent
Avena_Lee
Avy_Scott
Aya_Otosaki
Ayana_Angel
Azlea_Antistia
Azumi_Kawashima
Bambi_Blaze
Bambi_Woods
Bamboo
Barbara_Dare
Barbara_Summer
Barbie_Griffin
Belladonna
Betty_G
Beverley_Cocks
Beverly_Lynne
Bianca_Biaggi
Bianca_Pureheart
Bianca_Trump
Bibi_Fox
Bionca
Black_Diamond
Black_Widow
Blair_Segal
Blondie_Bee
Bobbi_Billard
Bobbi_Eden
Bodil_Joensen
Bonita_Saint
Boo_D_Licious
Brandi_Love
Brandi_Lyons
Brandi_Wine
Brandy_Alexandre
Brandy_Bosworth
Brandy_Starz
Brandy_Talore
Breanne
Briana_Banks
Brianna_Rai
Bridget_the_Midget_Powerz
Bridgette_Belle
Bridgette_Kerkove
Bridgette_Monet
Bridgette_Monroe
Brigitte_Lahaie
Britney_Rears
Brittany_Andrews
Brittany_Blue
Brittany_Stryker
Brittney_Skye
Brooke_Ashley
Brooke_Biggs
Brooke_Milano
Brooke_West
Buffy_Davis
Bunko_Kanazawa
Bunny_Bleu
Bunny_Luv
Cailey_Taylor
Calli_Cox
Cameron_Cain
Cameron_James
Candida_Royalle
Candie_Evans
Candy_Barr
Candy_Manson
Candy_Samples
Cara_Lott
Careena_Collins
Caressa_Savage
Carmella_Bing
Carmen_Hayes
Carmen_Luvana
Carol_Connors
Carol_Cummings
Caroline_Pierce
Casey_James
Cassandra_Wild
Catalina_Cruz
Celeste
Celia_Blanco
Champagne
Charlene_Aspen
Charlie_Angel
Charlie
Charlie_Style
Charlotte_Stokely
Charmaine_Sinclair
Charmane_Star
Chasey_Lain
Chaz
Chelsea_Charms
Cheri_Lai
Cherie
Cherokee
Cherry_Lee
Cherry_Poppens
Cherry_Potter
Cherry_Rain
Cherry_Rose
Chessie_Moore
Cheyenne_Silver
Chloe
Chloe_Dior
Chloe_Foxxx
Chloe_Jones
Chloe_Vevrier
Chocolate
Chris_Cassidy
Christi_Lake
Christie_Lee
Christina_Noir
Christine_Allure
Christine_Young
Christy_Canyon
Cicciolina
Ciera_Sage
Cindy_Crawford
Cindy_Miel
Clara_Morgane
Claudia_Ferrari
Claudia_Jamsson
Claudia_Rossi
Claudine_Beccarie
Colette_Choisez
Constance_Money
Corina_Taylor
Cris_Cassidy
Cris_Taliana
Crissy_Cums
Crissy_Moran
Cristina_Bella
Crystal_Breeze
Crystal_Craft
Crystal_Holland
Crystal_Klein
Crystal_Knight
Crystal_Ray
Crystal_Steal
Cynara_Fox
Cyndee_Summers
Cytherea
Daisy_Marie
Dana_Dylan
Dana_Lynn
Dana_Vespoli
Dani_Woodward
Daniella_Rush
Danni_Ashe
Daphne_Rosen
Darla_Crane
Dasha
Debi_Diamond
Deborah_Wells
Deidre_Holland
Demi_Marx
Denise_Masino
Desire_Vinci
Desiree_Cousteau
Desiree_West
Destiny_Deville
Destiny_Summers
Deven_Davis
Devin_DeRay
Devinn_Lane
Devon
Devon_Michaels
Diana_Devoe
Dina_Jewel
Dolly_Buster
Dominique_Simone
Donita_Dunes
Dora_Venter
Dorothy_Le_May
Draghixa
Dru_Berrymore
Dyanna_Lauren
Ebony_Ayes
Eden_Alaura
Elizabeth_Del_Mar
Elizabeth_Lawrence
Emma_Nixon
Emma_Starr
Erica_Bella
Erica_Boyer
Erica_Campbell
Estelle_Desanges
Eva_Angelina
Eva_Black
Eva_Henger
Eve_Angel
Eve_Laurence
Evelyn_Janaei
Fallon
Fallon_Sommers
Felecia
Felecia_Fox
Felicia_Tang
Felix_Vicious
Flame
Flick_Shagwell
Flower_Tucci
Fovea
Foxy_Lady
Friday
Fujiko_Kano
Gail_Lawrence
Gauge
Gen_Padova
Genevieve_Elise_Silva
Georgette_Neale
Georgina_Lempin
Georgina_Spelvin
Ghost_Angel
Gia_Jordan
Gia_Paloma
Gianna_Michaels
Gina_Carrera
Gina_Lynn
Gina_Ryder
Gina_Wild
Ginger_Lynn
Gloria_Guida
Gloria_Leonard
Greta_Milos
Gwen_Summers
Haley_Paige
Hannah_Harper
Haven
Heather_Harmon
Heather_Hunter
Helga_Sven
Hillary_Scott
Holly_Body
Holly_McCall
Holly_Page
Holly_Wellin
Honey_Wilder
Houston
Hyapatia_Lee
Ice_La_Fox
Inari_Vachs
India
Isabella_Camille
Isabella_Soprano
Isis_Nile
JR_Carrington
Jackie_Ashe
Jackie_Moore
Jacqueline_Lorians
Jada_Fire
Jade_East
Jade_Hsu
Jade_Marcela
Jaimee_Foxworth
Jamie_Brooks
Jamie_Summers
Jana_Cova
Jana_Miartusova
Jane_Darling
Janet_Jacme
Janette_Littledove
Janey_Robbins
Janine_Lindemulder
Jasmin_St_Claire
Jasmine_Byrne
Jasmine_Lynn
Jasmine_Tame
Jassie_James
Jaye_Starr
Jayna_Oso
Jazmin
Jeanna_Fine
Jelena_Jensen
Jenaveve_Jolie
Jenna_Haze
Jenna_Jameson
Jennifer_Andersson
Jennifer_Luv
Jennifer_Noxt
Jenteal
Jesse_Capelli
Jesse_Jane
Jessica_Darlin
Jessica_Dee
Jessica_Drake
Jessie_St_James
Jewel_De_Nyle
Jezebelle_Bond
Jill_Kelly
Joanna_Angel
Joanne_Jo_Guest
Jodie_Moore
Joelean
Johnni_Black
Jordan_Capri
Jordan_Haze
Jordan_Lee
Joselyn_Pink
Joy_Kiss
Judy_Star
Juli_Ashton
Julia_Ann
Julia_Bond
Julia_Channel
Julia_Parton
Julie_Meadows
Julie_Night
Julie_Silver
Julie_Strain
Juliet_Anderson
Justine_Joli
Kacey
Kaitlyn_Ashley
Kandi_Barbour
Karen_Dior
Karen_Lancaume
Karen_Summers
Karin_Schubert
Karina_Kay
Kascha_Papillon
Katalyn_Cica
Kate_Frost
Katerina_Konec
Kathy_Willets
Katie_Gold
Katie_Morgan
Katja_Kassin
Katja_Kean
Katja_Love
Katrina_Kraven
Katsumi
Kawashima_Azumi
Kay_Parker
Kayla_Marie
Kaylani_Lei
Kaylynn
Keiko_Nakazawa
Keisha
Kelle_Marie
Kelly_Erikson
Kelly_Kline
Kelly_Kroft
Kelly_Nichols
Kelly_O_Dell
Kelly_Trump
Kelly_Wells
Kelsey_Michaels
Keri_Sable
Kerry_Marie
Kianna_Dior
Kikki_Daire
Kiko_Wu
Kim_Angeli
Kim_Chambers
Kim_Eternity
Kimberly_Carson
Kinzie_Kenner
Kira_Kener
Kitten_Natividad
Kitty_Marie
Kitty_Yung
Kobe_Tai
Krista_Lane
Kristara_Barrington
Kristi_Myst
Krystal_de_Boor
Krystal_Steal
Krysti_Lynn
Kyla_Cole
Kylie_Ireland
Lacey_Duvalle
Lanny_Barbie
Lara_Roxx
Laura_Angel
Laura_Gemser
Laure_Sainclair
Lauren_Phoenix
Layla_Jade
Lea_De_Mae
Lea_Walker
Leanna_Foxxx
Leanna_Heart
Leanni_Lei
Leena
Lene_Hefner
Leslie_Bovee
Letha_Weapons
Lexie_Marie
Lexus_Locklear
Lillian_Tiger
Lily_Thai
Linda_Lovelace
Linda_Lust
Linda_Thoren
Linda_Wong
Linsey_Dawn_McKenzie
Lisa_Ann
Lisa_De_Leeuw
Lisa_K_Loring
Lisa_Sparxxx
Little_Oral_Annie
Liz_Harvey
Liz_Honey
Liz_Vicious
Liza_Harper
Logan_LaBrent
Lois_Ayres
Lolo_Ferrari
Loni_Sanders
Lorelei
Loretta_Loren
Lori_Alexia
Lou_Valmont
Lovette
Lucie_Stratilova
Lucy_Lee
Lucy_Thai
Luna_Lane
Lyla_Lei
Lynda_Leigh
Madison_Stone
Makayla_Coxxx
Mai_Lee
Mai_Lin
Maia_Ginger
Mandi_Wine
Mandy_Bright
Maria_Tortuga
Mariah_Kekkonen
Marilyn_Chambers
Marketa_Brymova
Mary_Anne
Mary_Carey
Mary_Millington
Marylin_Star
Maya_Gold
McKayla_Matthews
McKenzie_Lee
Megan_Jones
Megan_Leigh
Megan_Martinez
Melanie_Jagger
Melissa_Ashley
Melissa_Harrington
Melissa_Hill
Melissa_Lauren
Melissa_Milano
Melissa_Walker
Melody_Love
Melody_Max
Mercedesaka_Eva_Black
Mercedez
Mia_Smiles
Michaela_Schaffrath
Michele_Evette_Watley
Michelle_Barrett
Michelle_Monaghan
Michelle_Thorne
Michelle_Wild
Micka_French
Midori
Mika_Tan
Miko_Lee
Mimi_Miyagi
Mindy_Rae
Mindy_Vega
Minka
Miriam_Gonzalez
Miss_Arroyo
Missy
Missy_Monroe
Mistress_Yvette
Misty_Rain
Moana_Pozzi
Mocha
Molly_Rome
Monica_Cameron
Monica_Mayhem
Monica_Sweet
Monica_Sweetheart
Monique_Alexander
Monique_DeMoan
Mya_Mason
Mysti_May
Nadia_Nyce
Naomi
Natasha_Yi
Naughty_Allie
Naughty_Alysha
Nautica_Thorn
Nena_Cherry
Nichola_Holt
Nici_Sterling
Nicki_Hunter
Nicole_Lace
Nicole_Sheridan
Nikita_Denise
Nikki_Anderson
Nikki_Benz
Nikki_Carlisle
Nikki_Charm
Nikki_Dial
Nikki_Diamond
Nikki_Fairchild
Nikki_Fritz
Nikki_Hunter
Nikki_Knights
Nikki_Nova
Nikki_Park
Nikki_Rider
Nikki_Tyler
Nikky_Blond
Nina_DePonca
Nina_Hartley
Nina_Mercedez
Nyomi_Marcela
O
Obsession
Olinka_Ferova
Olivia_Del_Rio
Olivia_O_Lovely
Olivia_Saint
Ona_Zee
Ovidie
PJ_Sparxx
Paizley_Adams
Pandora_Peaks
Paris_Showers
Pason
Patti_Petite
Penelope_Black_Diamond
Penny_Flame
Penny_Porsche
Persia
Phyllisha_Anne
Phoenix_Ray
Pixie
Poppy_Morgan
Porsche_Lynn
Porsha_Blaze
Rachel_Aziani
Rachel_Rotten
Rachel_Ryan
Racquel_Darrian
Rakel_Liekki
Randi_Wright
Raven_Riley
Raylene
Rayveness
Rebecca_Cummings
Rebecca_Lord
Rebecca_Wild
Red_Heaven
Reika
Rene_Bond
Rene_Tiffany
Renee_LaRue
Renee_Pornero
Rikki_Anderson
Riley_Mason
Rita_Faltoyano
Rocki_Roads
Ronni_Tuscadero
Roxanne_Hall
Roxetta
Roxy_Jezel
Roxy_Rush
Sabina_Black
Sabrina_Johnson
Sabrine_Maui
Sakura_Sena
Samantha_Fox
Samantha_Sterlyng
Samantha_Strong
Sandee_Westgate
Sandra_Romain
Sandra_Shine
Sandy
Saphire_Rae
Sara_Jay
Sarah_Blue
Sarah_Louise_Young
Sarah_Twain
Sativa_Rose
Savanna_Samson
Savannah
Seka
Selen
Selena_Silver
Selena_Steele
Serena
Serenity
Shakina_Shergold
Shanna_McCullough
Sharka_Blue
Sharon_Kane
Sharon_Mitchell
Shauna_Grant
Shay_Sweet
Shayla_LaVeaux
Shyla_Foxxx
Shyla_Stylez
Sierra
Silvia_Saint
Simone
Simony_Diamond
Sindee_Coxx
Sinderella
Sky_Lopez
Sophia_Ferrari
Sophia_Rossi
Sophie_Deei
Sophie_Evans
Sophie_Moone
Spring_Thomas
Stacey_Donovan
Stacy_Burke
Stacy_Valentine
Stephanie_Bellars
Stephanie_Swift
Stormy
Summer_Cummings
Sunny_Leone
Sunny_Rain
Sunrise_Adams
Sunset_Thomas
Sunshine_Nee
Susan_Nero
Suzie_Carina
Sydney_Moon
T_J_Hart
Tabatha_Cash
Tabatha_Jordan
Tabitha_Stevens
Taija_Rae
Tammi_Ann
Tania_Russof
Tanya_Hansen
Tanya_James
Tawnee_Stone
Tawny_Roberts
Tawny_Pearl
Taylor_Hayes
Taylor_Hill
Taylor_Lyn
Taylor_Rain
Taylor_St_Clair
Taylor_Wane
Teagan_Presley
Teanna_Kai
Teena_Fine
Temptress
Tera_Heart
Tera_Patrick
Teresa_May
Teresa_Scott
Teri_Diver
Teri_Weigel
Terri_Summers
Texas_Presley
Tia_Bella
Tia_Tanaka
Tianna
Tianna_Lynn
Tiffany_Diamond
Tiffany_Holiday
Tiffany_Hopkins
Tiffany_May
Tiffany_Million
Tiffany_Mynx
Tiffany_Rayne
Tiffany_Rose
Tiffany_Teen
Tiffany_Towers
Tiffany_Walker
Timea_Vagvolgyi
Tina_Cheri
Tina_Fine
Tori_DeLuca
Tori_Welles
Tory_Lane
Tove_Jensen
Tracey_Adams
Traci_Lords
Tricia_Devereaux
Trinity_Loren
Trixie_Teen
Tyffany_Million
Tyla_Wynn
Tyler_Faith
Uschi_Digard
Valentina_Vaughn
Vanessa_Blue
Vanessa_Chase
Vanessa_Del_Rio
Vanessa_Lane
Vanessa_McKenzie
Velicity_Von
Velvet_Rose
Venus
Veronica_Carso
Veronica_Hart
Veronica_Moser
Veronika_Raquel
Veronika_Simon
Veronika_Zemanova
Vicky_Vette
Victoria_Givens
Victoria_Knight
Victoria_Paris
Victoria_Sweet
Victoria_Zdrok
Vida_Garman
Violet_Blue
Watase_Akira
Wendy_Jaymes
Wendy_Whoppers
Wifey
Yana_Cova
Yulia_Nova
Yvette_Wilde
Zara_Whites
Zdenka
Zsanett_Egerhazi
# names male
Adam_Wilde
Al_Borda
Alain_Deloin
Alberto_Rey
Alec_Metro
Ales_Hanak
Alex_Rox
Alex_Sanders
Alexander_Devoe
Alexandre_Frota
Andre_Chazel
Andrea_Nobili
Barrett_Blade
Barry_Wood
Ben_Dover
Ben_English
Ben_Hardy
Benjamin_Brat
Big_Herc
Biggz
Biff_Malibu
Billy_Banks
Billy_Dee
Billy_Glide
Bobby_Blake
Bobby_Vitale
Boz
Brad_Armstrong
Brandon_Iron
Brett_McCoy
Brett_Rockman
Brian_Pumper
Brian_Surewood
Brick_Majors
Brock
Bruno_Sx
Brutus_Black
Buck_Adams
Byron_Long
Cal_Jammer
Captain_Bob
Carlos_Krystal
Carmelo_Petix
Chance_Ryder
Cheyne_Collins
Chris_Cannon
Chris_Charming
Chris_Evans
Chris_small_package_Marshman
Christoph_Clark
Claudio_Meloni
Colt_Steele
Dale_DaBone
Daniel_Espinoza
Daniel_Kane
Daniel_Thuerrigl
Darren_James
Dave_Cummings
Dave_Hardman
David_Christopher
David_Cahse
David_Perry
David_Ruby
Deep_Threat
Devlin_Weed
Dez
Dick_Dashton
Dick_Delaware
Dick_Nasty
Dick_Rambone
Dillion_Day
Dino_Bravo
Dino_Toscani
Don_Fernando
Don_Hollywood
Donny_Long
Ed_Powers
Ed_Luistro
Eduardo_Yanez
Elone_Disere
Eric_Manchester
Eric_Masterson
Eric_Price
Erik_Everhard
Etienne_Jaumillot
Evan_Stone
Frankie_Jay
Falcon_X
Ficky_Martin
FM_Bradley
Francesco_Malcom
Franco_Roccaforte
Franco_Trentalance
Francois_Papillon
Frank_Gun
Frank_Major
Frank_Shaft
Frank_Towers
Frankie_Versace
Gene_Ross
George_Payne
George_Uhl
Gerard_Luig
Gigantua
Gilbert_Servien
Gino_Greco
Greg_Rome
Greg_Centauro
Guy_Bonnafoux
Guy_DaSilva
Guy_Masse
Hank_Rose
Harry_Reems
Henry_Pachard
Herschel_Savage
HPG
Ian_Daniels
Ian_Scott
Iron_Lee
Jack_Baker
Jack_Bravo
Jack_Hammer
Jack_Napier
Jack_Surf
Jack_Wrangler
Jacques_Insermini
Jake_Ryan
Jake_Steed
James_Bonn
James_Brossman
Jamie_Gillis
Jan_Olav_Norberg
Jason_Zupalo
Jasper_Wade
Jay_Ashley
Jay_Crew
Jean
Jean_Pierre_Armand
Jean_Louis
Jean_Roche
Jean_Yves_LeCastel
Jeff_Stryker
Jeremy_Tucker
Jerry_Butler
J_J_Michaels
Joachim_Kessef
Joel_Lawrence
Joey_Ray
Joey_Hafley
Joey_Silvera
John_Dough
John_Holmes
John_Leslie
Johnny_Nineteen
John_Slovak
John_Stagliano
John_Strong
John_West
Jonathan_Morgan
Jonathan_Stern
Jon_Dough
Johnny_Depth
Jolth_Walton
Jules_Jordan
Julian
Juliano_Ferraz
Julian_St_Jox
Justin_Berry
Justin_Slayer
Kato_Kalin
Ken_Ryker
Kid_Jamaica
Kurt_Lockwood
Kyle_Stone
Lee_Stone
Leslie_Taylor
Lex_Baldwin
Lexington_Steele
Luc_Wylder
Mr_18_inch
Mandingo
Manuel_Ferrara
Marc_Cummings
Marc_Stevens
Marc_Wallice
Marco_Duato
Mario_Rossi
Mark_Anthony
Mark_Ashley
Mark_Davis
Mark_Sloan
Mark_Wood
Marty_Romano
Matt_Drake
Max_Hardcore
Michael_J_Cox
Michael_Stefano
Mike_Feline
Mike_Foster
Mike_Horner
Mike_Ranger
Mike_South
Mickey_G
Miles_Malone
Mr_Lothar
Mr_Marcus
Mr_Pete
Nacho_Vidal
Nat_Turnher
Nick_East
Nick_Lang
Nick_Manning
Nikko_Knight
Matt_Bixel
Neeo
Pascal_Saint
Pat_Myne
Paul_Barresi
Paul_Cox
Paul_Thomas
Peter_Foster
Peter_Ho
Peter_North
Peter_Shaft
Philippe_Dean
Philippe_Soine
Pier_Evergreen
Pierre_Woodman
Preston_Parker
Randy_Spears
Randy_West
Ray_Victory
Remigio_Zampa
Ricardo_Bell
Richard_Langin
Rich_Handsome
Rick_Masters
Rick_Lee
Rob_Rotten
Robbie_James
Robert_Darcy
Robert_Rosenberg
Roberto_Malone
Rod_Danger
Rodney_Moore
Ronnie_Coxx
Rocco_Rizzoli
Rocco_Siffredi
Rod_Fontana
Ron_Jeremy
Ryan_Idol
Richard_Pacheco
Samson_Biceps
Sam_Strong
Sascha
Scott_Lyons
Scott_Styles
Sean_Michaels
Sebastian_Barrio
Sergio_Suarez
Shane_Diesel
Slim_Dawg
Silvio_EvangeKnowledgea
Simon_Rex
Skunk_Riley
Sledge_Hammer
Spyder_Jonez
Stephen_Wolfe
Steve_Holmes
Steve_Hooper
Steve_York
Steve_Powers
Steven_St_Croix
T_J_Cummings
TT_Boy
Tom_Byron
Tom_Cruiso
Tony_DeSergio
Tony_Everready
Tony_Martino
Tony_Michaels
Toni_Ribas
Tony_Tedeschi
Tony_Sexton
Trent_Tesoro
Trevor_Zen
Tyce_Bune
Tyler_Knight
Ty_Lattimore
Tom_Shepard
Valentino_Rey
Van_Damage
Van_Darkholme
Vince_Vouyer
Voodoo
Walter_Midolo
Wes_Bauer
Wesley_Pipes
Will_Ravage
Willi_Montana
Willy_Braque
Wilde_Oscar
Woody_Long
Yoshiya_Minami
Yves_Baillat
Yves_Callas
Zake_Thomas
Zensa_Raggi
Zare_Prejaki
