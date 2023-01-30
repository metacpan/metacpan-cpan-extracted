package DateTime::Calendar::Pataphysical;
$DateTime::Calendar::Pataphysical::VERSION = '0.07';
use strict;
use warnings;
use utf8;

use DateTime::Duration;
use DateTime::Locale;
use Params::Validate qw/validate SCALAR OBJECT/;

sub _floor {
    my $x  = shift;
    my $ix = int $x;
    if ($ix <= $x) {
        return $ix;
    } else {
        return $ix - 1;
    }
}

use overload ( 'fallback' => 1,
               '<=>' => '_compare_overload',
               'cmp' => '_compare_overload',
               '-' => '_subtract_overload',
               '+' => '_add_overload',
             );

{
    my $DefaultLocale;
    sub DefaultLocale {
        my $class = shift;

        if (@_) {
            my $lang = shift;

            DateTime::Locale->load($lang);

            $DefaultLocale = $lang;
        }

        return $DefaultLocale;
    }
}
__PACKAGE__->DefaultLocale('French');

sub new {
    my $class = shift;
    my %p = validate( @_,
                      { year  => {type => SCALAR},
                        month => {type => SCALAR, default => 1},
                        day   => {type => SCALAR, default => 1},
                        rd_secs   => { type => SCALAR, default => 0},
                        rd_nano   => { type => SCALAR, default => 0},
                        locale  => { type => SCALAR | OBJECT,
                                       default => $class->DefaultLocale },
                      } );

    my $self = bless \%p, $class;
    $self->{locale} = DateTime::Locale->load($p{locale})
        unless (ref $self->{locale});

    return $self;
}

sub clone {
    my $self = shift;

    return bless {%$self}, ref $self;
}

sub set
{
    my $self = shift;
    my %p = validate( @_,
                      { year     => { type => SCALAR, optional => 1 },
                        month    => { type => SCALAR, optional => 1 },
                        day      => { type => SCALAR, optional => 1 },
                        locale => { type => SCALAR | OBJECT, optional => 1 },
                      } );

    if (exists $p{locale} && ! ref $p{locale}) {
        $p{locale} = DateTime::Locale->load($p{locale})
    }

    $self->{$_} = $p{$_} for keys %p;
    return $self;
}

sub truncate {
    my $self = shift;
    my %p = validate( @_,
                      { to =>
                        { regex => qr/^(?:year|month|day)$/ },
                      },
                    );
    foreach my $f ( qw( day month year ) ) {
        last if $p{to} eq $f;
        $self->{$f} = 1;
    }
    return $self;
}

sub locale { $_[0]->{locale} }

sub is_leap_year {
    my $self = shift;
    my $year = $self->{year};
    $year++ if $year < 0;
    if ($year % 4 != 3 or ($year % 100 == 27 and $year % 400 != 127)) {
        return 0;
    } else {
        return 1;
    }
}

sub year    { $_[0]->{year} }

sub month   { $_[0]->{month} }
*mon = \&month;

sub month_0 { $_[0]->{month}-1 }
*mon_0 = \&month_0;

sub day_of_month { $_[0]->{day} }
*day  = \&day_of_month;
*mday = \&day_of_month;

sub day_of_month_0 { $_[0]->{day} - 1 }
*day_0  = \&day_of_month_0;
*mday_0 = \&day_of_month_0;

sub month_name {
    return (qw/Absolu Haha As Sable Décervelage Gueules Pédale Clinamen
               Palotin Merdre Gidouille Tatane Phalle/)[$_[0]->{month}-1];
}

sub day_of_week {
    my $self = shift;

    if ($self->{day} == 29) {
        return undef;
    } else {
        return 1 + ($self->{day}-1) % 7;
    }
}

sub day_of_week_0 {
    my $self = shift;

    if ($self->{day} == 29) {
        return undef;
    } else {
        return +($self->{day}-1) % 7;
    }
}

sub day_name {
    my $self = shift;

    if ($self->{day} == 29) {
        my $name = 'hunyadi';
        my $n = $self->{locale}->day_format_wide->[0];
        $name = ucfirst $name if $n eq ucfirst $n;
        return $name;
    } else {
        return $self->{locale}->day_format_wide->[($self->day_of_week_0 || 7)-1];
    }
}

sub week_number {
    my $self = shift;

    if ($self->{day} == 29) {
        return undef;
    } else {
        return 4*($self->{month} - 1) + int(($self->{day} - 1)/7) + 1;
    }
}

sub week_year { $_[0]->year }

sub week { $_[0]->week_year, $_[0]->week_number }

sub day_of_year {
    my $self = shift;

    return $self->{day} + ($self->{month}-1) * 29;
}

sub day_of_year_0 {
    my $self = shift;

    return $self->{day} + ($self->{month}-1) * 29 - 1;
}

sub ymd {
    my ($self, $sep) = @_;
    $sep = '-' unless defined $sep;

    return sprintf( "%0.3d%s%0.2d%s%0.2d",
                    $self->{year}, $sep,
                    $self->{month}, $sep,
                    $self->{day} );
}
*date = \&ymd;

sub mdy {
    my ($self, $sep) = @_;
    $sep = '-' unless defined $sep;

    return sprintf( "%0.2d%s%0.2d%s%0.3d",
                    $self->{month}, $sep,
                    $self->{day}, $sep,
                    $self->{year} );
}
sub dmy {
    my ($self, $sep) = @_;
    $sep = '-' unless defined $sep;

    return sprintf( "%0.2d%s%0.2d%s%0.3d",
                    $self->{day}, $sep,
                    $self->{month}, $sep,
                    $self->{year} );
}

sub datetime {
    my $self = shift;

    # EP = Ere Pataphysique
    return $self->ymd() . 'EP';
}

my %formats =
    ( 'A' => sub { $_[0]->day_name },
      'B' => sub { $_[0]->month_name },
      'C' => sub { int( $_[0]->year / 100 ) },
      'd' => sub { sprintf( '%02d', $_[0]->day_of_month ) },
      'D' => sub { $_[0]->strftime( '%m/%d/%y' ) },
      'e' => sub { sprintf( '%2d', $_[0]->day_of_month ) },
      'F' => sub { $_[0]->ymd('-') },
      'j' => sub { $_[0]->day_of_year },
      'm' => sub { sprintf( '%02d', $_[0]->month ) },
      'n' => sub { "\n" },
      't' => sub { "\t" },
      'u' => sub { $_[0]->day_of_week || 'H' },
      'U' => sub { my $w = $_[0]->week_number;
                   defined $w ? sprintf('%02d', $w) : '  ' },
      'w' => sub { my $dow = $_[0]->day_of_week;
                   defined $dow ? $dow-1 : 'H' },
      'y' => sub { sprintf( '%02d', substr( $_[0]->year, -2 ) ) },
      'Y' => sub { return $_[0]->year },
      '%' => sub { '%' },
      '*' => sub { $_[0]->feast },
    );
$formats{W} = $formats{V} = $formats{U};

sub strftime {
    my ($self, @r) = @_;

    foreach (@r) {
        s/%([%*A-Za-z])/ $formats{$1} ? $formats{$1}->($self) : $1 /ge;
        return $_ unless wantarray;
    }
    return @r;
}

sub last_day_of_month {
    my $class = shift;
    my %p = validate( @_,
                      { year   => { type => SCALAR },
                        month  => { type => SCALAR },
                        locale  => { type => SCALAR | OBJECT, optional => 1 },
                      }
                    );
    $p{day} = 29;
    return $class->new(%p);
}

sub is_imaginary {
    my $self = shift;

    return $self->{day} == 29 && $self->{month} != 11 &&
           ($self->{month} != 6 or !$self->is_leap_year);
}

sub utc_rd_values {
    my $self = shift;

    return if $self->is_imaginary;

    my ($year, $month, $day) = @{$self}{qw/year month day/};
    $year++ if $year < 0;

    my $cyear = $year;
    $cyear++ if $month > 6;
    $day++ if $month > 11;

    my $rd = 683984 +                   # 7 September 1873 = 28 Phalle '0'
             ($year-1) * 365 +          # normal years: 365 real days
             _floor( .25 * $cyear) -    # leap years
             _floor(($cyear+72)/100) +  # century years
             _floor(($cyear+272)/400 ) +
             + ($month - 1) * 28 + $day;
    return ($rd, $self->{rd_secs}, $self->{rd_nano});
}

sub utc_rd_as_seconds {
    my $self = shift;
    my ($rd_days, $rd_secs, $rd_nano) = $self->utc_rd_values;

    if (defined $rd_days) {
        return $rd_days*24*60*60 + $rd_secs + $rd_nano * 1e-9;
    } else {
        return undef;
    }
}

sub from_object {
    my $class = shift;
    my %p = validate( @_,
                      { object => { type => OBJECT,
                                    can => 'utc_rd_values',
                                  },
                        locale => { type => SCALAR | OBJECT,
                                      default => $class->DefaultLocale },
                      },
                       );

    $p{object} = $p{object}->clone->set_time_zone( 'floating' )
                                if $p{object}->can( 'set_time_zone' );

    my ( $rd_days, $rd_secs, $rd_nano ) = $p{object}->utc_rd_values;

    my ($y, $m, $d) = $class->_rd2ymd( $rd_days );

    return $class->new( year => $y, month => $m, day => $d,
                        rd_secs => $rd_secs||0, rd_nano => $rd_nano||0,
                        locale => $p{locale} );
}

sub _rd2ymd {
    my ($class, $rd) = @_;

    # Algorithm similar to the one on
    # http://home.capecod.net/~pbaum/date/injdalg2.htm
    # for the gregorian calendar

    # Number of days since 1 Pedale 127 (day after first extra leap day) =
    # 24-02-2000
    $rd -= 730173;

    my $a = _floor(($rd-0.25)/(100*365.2425));
    my $b = $rd - 0.25 + $a - _floor($a/4);
    my $y = _floor($b/365.25);
    my $d = $rd + $a - _floor($a/4) - _floor(365.25*$y);

    my $m;
    if ($d < 5*28 + 1) {        # Before 29 Gidouille
        $m = _floor(($d-1)/28);
        $d -= $m * 28;
    } elsif ($d == 5*28 + 1) {  # 29 Gidouille
        $m = 4;
        $d = 29;
    } elsif ($d < 366) {        # Before 29 Gueules
        $m = _floor(($d-2)/28);
        $d -= $m*28 + 1;
    } else {                    # 29 Gueules (leap day)
        $m = 12;
        $d = 29;
    }

    $y += 127;
    $m += 7;
    if ($m > 13) {
        $m -= 13;
        $y ++;
    }

    # There is no year 0
    if ($y <= 0) {
        $y--;
    }

    return $y, $m, $d;
}

sub from_epoch {
    my $class = shift;
    my %p = validate( @_,
                      { epoch => { type => SCALAR },
                        locale => { type => SCALAR | OBJECT,
                                      default => $class->DefaultLocale },
                      }
                    );

    my $rd = int($p{epoch}/(24*60*60) + 719163);

    my ($y, $m, $d) = $class->_rd2ymd( $rd );

    return $class->new( year => $y, month => $m, day => $d,
                        locale => $p{locale} );
}

sub now { shift->from_epoch( epoch => (scalar time), @_ ) }

sub _add_overload {
    my ($dt, $dur, $reversed) = @_;
    ($dur, $dt) = ($dt, $dur) if $reversed;

    my $new = $dt->clone;
    $new->add_duration($dur);
    return $new;
}

sub _subtract_overload
{
    my ( $date1, $date2, $reversed ) = @_;
    ($date1, $date2) = ($date2, $date1) if $reversed;

    if ( UNIVERSAL::isa($date2, 'DateTime::Duration') ) {
        my $new = $date1->clone;
        $new->add_duration( $date2->inverse );
        return $new;
    } else {
        return $date1->subtract_datetime($date2);
    }
}

sub add {return shift->add_duration(DateTime::Duration->new(@_)) }

sub subtract { return shift->subtract_duration(DateTime::Duration->new(@_)) }

sub subtract_duration { return $_[0]->add_duration( $_[1]->inverse ) }

sub add_duration {
    my ($self, $dur) = @_;

    my %deltas = $dur->deltas;

    $self->{year}++ if $self->{year} < 0;

    $self->{day} += $deltas{days} if $deltas{days};
    $self->{month} += $deltas{months} if $deltas{months};

    if ($self->{day} < 1 or $self->{day} > 29) {
        $self->{month} += _floor(($self->{day}-1)/29);
        $self->{day} %= 29;
    }
    if ($self->{month} < 1 or $self->{month} > 13) {
        $self->{year} += _floor(($self->{month}-1)/13);
        $self->{month} %= 13;
    }

    $self->{year}-- if $self->{year} <= 0;

    return $self;
}

sub subtract_datetime {
    my ($self, $dt) = @_;

    my ($syear, $dyear) = ($self->year, $dt->year);
    $_ < 0 and $_++ for $syear, $dyear;

    my $days_diff = ($syear       - $dyear    ) * 377 +
                    ($self->month - $dt->month) * 29 +
                    ($self->day   - $dt->day  );
    return DateTime::Duration->new( days => $days_diff );
}

use constant INFINITY     =>       100 ** 100 ** 100 ;
use constant NEG_INFINITY => -1 * (100 ** 100 ** 100);

sub _compare_overload
{
    # note: $_[1]->compare( $_[0] ) is an error when $_[1] is not a
    # DateTime (such as the INFINITY value)
    return $_[2] ? - $_[0]->compare( $_[1] ) : $_[0]->compare( $_[1] );
}

sub compare
{
    my ($class, $dt1, $dt2) = ref $_[0] ? (undef, @_) : @_;

    return undef unless defined $dt2;

    return -1 if ! ref $dt2 && $dt2 == INFINITY;
    return  1 if ! ref $dt2 && $dt2 == NEG_INFINITY;

    $dt2 = $class->from_object( object => $dt2 )
        unless $dt2->isa('DateTime::Calendar::Pataphysical');

    return $dt1->year <=> $dt2->year || $dt1->month <=> $dt2->month ||
           $dt1->day  <=> $dt2->day;
}


my @feasts;

sub feast {
    return $feasts[ $_[0]->day_of_year_0 ][1];
}

sub type_of_feast {
    return $feasts[ $_[0]->day_of_year_0 ][0];
}

# Feasts from
# http://perso.wanadoo.fr/mexiqueculture/nouvelles6-latumba.htm
@feasts = map [/(.) (.+)/], split /\n+/, <<EOF;
1 Nativité d'Alfred Jarry
4 St Ptyx, silentiaire (Abolition de)
4 St Phénix, solipsiste et St Hyx, factotum
4 St Lucien de Samosate, voyageur
4 St Bardamu, voyageur
4 Ste Vérola, assistante sociale
4 St Alambic, abstracteur
3 Absinthe, ci-devant St Alfred
4 Descente du St Esprit (de Vin)
v Dilution
4 Ste Purée, sportswoman
v Vide
4 St Canterel, l'illuminateur
4 St Sophrotatos l'Arménien, pataphysicien
3 Éthernité
4 St Ibicrate le Géomètre, pataphysicien
v Céphalorgie
v Flûtes de Pan
4 Stes Grues, ophiophiles
4 Ste Mélusine, souillarde de cuisine
4 St Venceslas, duc
2 Emmanuel Dieu
4 Ste Varia-Miriam, amphibie
4 Sts Rakirs et Rastrons, porte-côtelettes
4 Nativité de Sa Magnificence Opach
4 St Joseb, notaire à la mode de Bretagne
4 Stes Gigolette et Gaufrette, dogaresses
v Xylostomie
v Le Jet Musical

2 L'Âge du Dr Faustroll
4 Dissolution d'E. Poe, dinomythurge
4 St Gibus, franc-maçon
4 Ste Berthe de Courrière, égérie
4 Ste Belgique, nourrice
4 Ste Tourte, lyrique et Ste Bévue, sociologue
4 St Prout, abbé
2 Fête du Haha
v Tautologie
4 St Panmuphle, huissier
4 Sortie de St L. Cranach, apocalypticien
4 St Cosinus, savant
4 Bse Fenouillard, sainte famille
4 Exhibition de la Daromphe
3 Nativité de l'Œstre, artificier
4 Ste Vadrouille, emblème
4 St Homais d'Aquin, prudhomme
4 Nativité de Sa Magnificence le baron Mollet (St Pipe)
4 St Raphaël, apéritif et philistin
3 Strangulation de Bosse-de-Nage
3 Zimzoum de Bosse-de-Nage
2 Résurrection de Bosse-de-Nage
3 Chapeau de Bosse-de-Nage
4 St Cl. Terrasse, musicien des Phynances
4 St J.-P. Brisset, philologue, prince des penseurs
4 Commémoration du Cure-dent
1 Occultation d'Alfred Jarry
4 Fuite d'Ablou
v Marée Terrestre

3 Nativité de Pantagruel
4 Ste Rrose Sélavy, héroïne
4 Couronnement de Lord Patchogue, miroitier
4 St Cravan, boxeur
4 St Van Meegeren, faussaire
4 St Omnibus, satyre
4 St Cyrano de Bergerac, explorateur
3 St Rimbe, oisif
v Équarrissage pour tous
4 St Abstrait, bourreau
4 St Ossian, barde postiche
3 Dispute du Signe + et du Signe -
3 Moustaches du Dr Faustroll
4 St P. Bonnard, peintre des Phynances
1 Navigation du Dr Faustroll
4 St Cap, captain
4 St Pangloss, humoriste passif
4 St Chambernac, pauvriseur
4 St Courtial des Péreires, aérostier et inventeur
4 St Olibrius, augure
4 St Possible, schizophrène
2 St Lautréamont
4 St Quincey, critique d'art
4 St Berbiguier, martyr
4 St Lewis Carroll, professeur
4 St Mensonger, évêque
4 Ste Visité, fille du précédent
4 Nativité de St Swift, chanoine
v Traversée du Miroir

3 Noces de Balkis et de Salomon
4 St Doublemain, idéologue
4 St Phlegmon, doctrinaire
4 Ste Barbe (femme à), femme-canon
4 Ste Savate, avocate
4 St Navet et Ste Perruque, humanistes
4 St Birbe, juge
2 Conception du P. Ubu (A. J.)
4 St Sagouin, homme d'état
1 Exaltation d'Ubu Roi (Ubu d'hiver)
4 Nativité de St Grabbe, scherziste
4 Ste Choupe, mère de famille
4 St Flaive, concierge
4 Don Quichotte, champion du monde
2 Khurmookum du Dr Faustroll
4 St Nul, exempt
4 St Moyen, français
4 Ste Lurette, joconde
3 Gravidité de Mère Ubu
4 St Sabre, allopathe
4 Ste Tape, pompette
1 César - Antechrist
4 Ste Viole, vierge et martyre
4 Ste Pochetée, gouvernante
3 Nativité de l'Archéoptéryx
4 Monsieur Sisyphe
4 St Tic, conjoint
4 St Cervelas, penseur
v Aleph

3 St Alaodine, virtuose
4 Sts Hassassins, praticiens
4 Astu
1 Décervelage
4 Sts Giron, Pile et Cotice, palotins
4 Sts Polonais, prolétaires
4 Sts Forçats, poliorcètes
3 St Bordure, capitaine
4 Dormition de Jacques Vaché, interprète
v Drapaud (érection du)
4 St Eustache, libérateur
4 St Landru, gynécologue
4 St Guillotin, médecin
4 Sts 4 Sans-Cou, enchanteurs
3 Conscience d'Ubu
4 St Mauvais, sujet
4 St Mandrin, poète et philosophe
4 Sts Pirates et Flibustiers, thaumaturges
4 St et Ste Cartouche, vétérinaires
4 St Outlaw, aristocrate
1 Chaire du Dr Faustroll
2 Ostention du Bâton à Physique
4 St Tank, animal
4 St Weidman, patriarche
4 St Petiot, expert
v Escrime
4 Sts Chemins de fer, assassins
v Repopulation
v Lit de Procruste

3 Dépucelage de Mère Ubu
4 St Sigisbée, eunuque
4 St Anthropoïde, policier
4 Ste Goule ou Gudule, institutrice
4 Ste Gale, abbesse
4 Ste Touche, postulante
4 St Gueule, abbé
3 Fête de la Chandelle Verte
4 Ste Crêpe, laïque
4 St Préservatif, bedeau
4 St Baobab, célibataire
4 St Membre, compilateur
v Copulation
4 Nativité de St J. Verne, globe-trotter en chambre
3 Alice au Pays des Merveilles
4 St Münchhausen, baron
4 Le Bétrou, théurge
4 Nativité de St Deibler, prestidigitateur
4 St Sade ès liens
4 St Lafleur, valet
v Lavement
2 St Sexe, stylite
4 Occultation de St J. Torma, euphoriste
4 Conversion de St Matorel, bateleur
4 Ste Marmelade, inspirée
3 L'Amour Absolu, deliquium
4 Ste Tabagie, cosmogène
4 Sts Hylactor et Pamphagus
v Mouvement Perpétuel

3 Érection du Surmâle
4 St André Marcueil, ascète cycliste
4 St Ellen, hile
4 St Michet, idéaliste
4 St Ouducul, trouvère
4 Vers Belges
4 St Gavroche, forain
3 La Machine à Inspirer l'Amour
4 St Remezy, évêque in partibus
4 Nativité de St Tancrède, jeune homme
4 Testament de P. Uccello, le mal illuminé
4 St Hari Seldon, psychohistorien galactique
4 Ste Valburge, succube
v Sabbat
3 Sts Adelphes, ésotéristes
4 Sts Templiers, adeptes
4 St Dricarpe, prosélyte
4 St Nosocome, carabin
4 Ste Goutte, fête militaire
4 Ste Cuisse, dame patronnesse
4 St Inscrit, Converti
2 St Sengle, déserteur
4 St Masquarade, uniforme
4 Nativité de St Stéphane, faune
4 St Poligraf Poligrafovitch, chien
4 St Pâle, mineur
3 St Valens, frère onirique
v Dédicace du Tripode
4 Bse Escampette, dynamiteuse

3 St Ablou, page et St Haldern, duc
4 Sts Hiboux, maîtres-chanteurs
4 La Mandragore, solanée androïde
4 St Pagne, confident
4 Sts Aster et Vulpian, violateurs du Néant
4 St Ganymède, professionnel
v La Main de Gloire
3 La Machine à Peindre
4 Ste Trique, lunatique
4 Rémission des Poissons
4 St Maquereau, intercesseur
4 St Georges Dazet, poulpe au regard de soie
4 Nativité de Maldoror, corsaire aux cheveux d'or
4 Sortie d'A. Dürer, hermétiste
* Invention de la 'Pataphysique
4 Exit St Domenico Theotocopouli, el Greco
4 St Hiéronymus Bosch, démonarque
v Les 27 Êtres Issus des Livres Pairs
4 St Barbeau, procureur et Ste Morue, juste
v Capture du Fourneau
4 St Docteur Moreau, insulaire
2 Fête des Polyèdres
v Locus Solus
4 St Tupetu de Tupetu, organisateur de loteries
4 Exit St Goya, alchimiste
4 St Escargot, sybarite
4 Ste Hure de Chasteté, pénitente
4 St Turgescent, iconoclaste
v Cymbalum Mundi

3 Sts Crocodiles, crocodiles
4 Fête des Écluses
4 Sts Trolls, pantins
4 Ste Susan Calvin, docteur
4 Ste Poignée, veuve et Ste Jutte, recluse
4 Ste Oneille, gourgandine
4 St Fénéon ès Liens
3 St Bougrelas, prince
4 Sts Boleslas et Ladislas, polonais
4 St Forficule, Barnabite
v Explosion du Palotin
v Réprobation du Travail
4 Esquive de St Léonard (de Vinci), illusionniste
4 St Équivoque, sans-culotte
3 Adoration du Pal
4 Déploration de St Achras, éleveur de Polyèdres
4 St Macrotatoure, caudataire
v Canotage
4 Occultation de St Gauguin, océanide
4 St Ti Belot, séide
4 Occultation de Sa Magnificence le Dr Sandomir
2 Sts Palotins des Phynances
4 Sts Quatrezoneilles, Herdanpo, Mousched-Gogh, palotins
4 Ste Lumelle, écuyère
4 Sts Potassons, acolythes
4 Ste Prétentaine, rosière
4 St Foin, coryphée
4 Nativité de St Satie, Grand Parcier de l'Église d'Art
v Erratum

3 Accouchement de Ste Jeanne, papesse
v Le Moutardier du Pape
4 St Siège, sous-pape
4 Nativité de St H. Rousseau, douanier
4 St Crouducul, troupier
4 St Cucufat, mécène
4 Nativité de M. Plume, propriétaire
2 Cocuage de M. le P. Ubu
v Vidange
4 St Barbapoux, amant
4 St Memnon, vidangeur
4 Stes Miches, catéchumènes
4 Ste Lunette, solitaire
4 St Sphincter, profès
3 Sts Serpents d'Airain
4 Nativité de St Donatien A. François
4 St Woland, professeur
4 St Anal, cordelier et Ste Foire, anagogue
4 Ste Fétatoire, super
4 Ste Colombine, expurgée
4 Ste Pyrotechnie, illuminée
* Ontogénie Pataphysique
3 Interprétation de L'Umour
4 Ste Purge, sage-femme
2 Apparition D'Ubu Roi
4 Ste Barbaque, naïade
4 Sts Courts et Longs, gendarmes
4 St Raca, cagot
v Défaite du Mufle

3 Ste Bouzine, esprit
4 St Lucullus, amateur (Bloomsday)
4 Ste Dondon, amazone
4 Ste Tripe, républicaine
4 St Ugolin, mansuet
4 St Dieu, retraité
4 St Bébé Toutout, évangéliste
3 Ste Boudouille, bayadère
4 Ste Outre, psychiatre
4 St Boudin, recteur
4 Sacre de Talou VII, empereur du Ponukélé
4 Ste Confiture, dévote et Ste Cliche, donatrice
4 Sts Instintestins, conseillers intimes
4 St Colon, artilleur
3 Ste Giborgne, vénérable
4 St Inventaire, poète
4 Ste Femelle, technicienne
2 Visitation de Mère Ubu
4 St Sein, tautologue
4 St Périnée, zélateur
4 St Spéculum, confesseur
2 Fête de Gidouille
4 St Ombilic, gymnosophiste
4 St Gris-gris, ventre
4 St Bouffre, pontife
4 Ste Goulache, odalisque
4 Ste Gandouse, hygiéniste
v Poche du Père Ubu
2 Nom d'Ubu

1 Fête du P. Ubu (Ubu d'été)
4 Commémoration du P. Ébé
4 Ste Crapule, puriste et St Fantomas, archange
4 Ascension du Mouchard, statisticien, psychiatre et policier
4 St Arsouille, patricien
4 Sts Robot et Cornard, citoyens
4 St Biribi, taulier
2 Susception du Croc à Merdre
4 Sts Écrase-Merdre, sectateurs
4 Sts Pieds Nickelés, trinité
4 Stes Canicule et Canule, jouvencelles
4 Sts Cannibales, philanthropes
4 St Dada, prophète
4 Ste Anne, pèlerine, énergumène
2 Procession aux Phynances
4 Transfiguration de St V. van Gogh, transmutateur
4 Ste Flamberge, voyante
4 St Trou, chauffeur
4 Ste Taloche, matrone
4 St Tiberge, frère quêteur
4 Sts Catoblepas, lord et Anoblepas, amiral
2 Ubu ès Liens
4 St Pissembock, oncle
4 St Pissedoux, caporal des hommes libres
4 St Panurge, moraliste
4 St Glé, neurologue-aliéniste
4 St Pistolet à Merdre, jubilaire
4 Nativité de St Bruggle
v Le soleil solide froid

3 St Chibre, planton
4 Ste Ruth, zélatrice
4 St Zebb, passe-partout
4 St Mnester, confesseur
2 Assomption de Ste Messaline
v Penis Angelicus
4 St Patrobas, pompier
3 Ste Léda, ajusteuse
4 St Godemiché, économe
4 Ste Nitouche, orante
4 Ste Lèchefrite, botteuse
4 Ste Andouille, amphibologue
4 Ste Bitre, ouvreuse et St Étalon, couvreur
3 Bataille de Morsang
3 Mort de Dionysos, surhomme
4 Nativité de St Vibescu, pohète et Commémoration de Ste Cuculine d'Ancône
4 Ste Gallinacée, cocotte
4 St Lingam, bouche-trou
4 St Prélote, capucin
4 St Pie VIII, navigant
3 St Erbrand, polytechnicien
2 Ste Dragonne, pyrophage
4 St Lazare, gare
4 Ste Orchidée, aumonière
4 Nativité apparente d'Artaud le Momo
4 Disparition de l'Ancien Breughel, incendiaire
4 St Priape, franc-tireur
3 Transfixion de Ste Messaline
v Le Termès
EOF

1;

__END__

=for Pod::Coverage::TrustPod
     DefaultLocale
     day_0
     day_of_month_0
     day_of_week_0
     day_of_year_0
     locale
     mday_0
     mon
     mon_0
     month_0

=encoding utf-8

=head1 NAME

DateTime::Calendar::Pataphysical - Dates in the Pataphysical calendar

=head1 VERSION

version 0.07

=head1 SYNOPSIS

  use DateTime::Calendar::Pataphysical;

  $dt = DateTime::Calendar::Pataphysical->new( year  => 1752,
                                               month => 10,
                                               day   => 4 );

=head1 DESCRIPTION

DateTime::Calendar::Pataphysical is the implementation of the
Pataphysical calendar. Each year in this calendar contains 13 months of
29 days. This regularity makes this a convenient alternative for the
irregular Gregorian calendar.

This module is designed to be easy to use in combination with
L<DateTime>. Most of its methods correspond to a L<DateTime> method of the
same name.

=head1 CLASS METHODS

=head2 new

    my $dt = DateTime::Calendar::Pataphysical-new(
        year  => $year_in_the_pataphysical_era,
        month => $pataphysical_month_number,
        day   => $pataphysical_day_number,
    );

This class method accepts parameters for each date and time component:
C<year>, C<month>, C<day>.  Additionally, it accepts a C<locale>
parameter.

The C<rd_secs> parameter is also accepted. This parameter is only useful
in conversions to other calendars; this calendar does not use its value.

=head2 from_epoch

    my $dt = DateTime::Calendar::Pataphysical->from_epoch( epoch => $epoch, ... );

This class method can be used to construct a new object from an epoch
time instead of components. Just as with the L<new> constructor, it
accepts a C<locale> parameter.

=head2 now

    my $dt = DateTime::Calendar::Pataphysical->now;

This class method is equivalent to calling C<from_epoch()> with the
value returned from Perl's L<time|perlfunc/time> function.

=head2 from_object

    my $dt = DateTime::Calendar::Pataphysical->from_object( object => $object, ... );

This class method can be used to construct a new object from
any object that implements the L<utc_rd_values> method.  All
L<DateTime::Calendar> modules must implement this method in order to
provide cross-calendar compatibility.  This method accepts a
C<locale> parameter.

The time part of C<$object> is stored, and will only be used if the created
object is converted to another calendar. Only the date part of C<$object>
is used to calculate the pataphysical date. This calculation is based on
the local time and date of C<$object>.

=head2 last_day_of_month

    my $dt = DateTime::Calendar::Pataphysical->last_day_of_month( ... );

This constructor takes the same arguments as can be given to the
L<now> method, except for C<day>.  Additionally, both C<year> and
C<month> are required.

=head1 METHODS

=head2 clone

    my $clone = $dt->clone;

This object method returns a replica of the given object.

=head2 year

Returns the year.

=head2 month

Returns the month of the year, from C<1 .. 13>.

=head2 month_name

Returns the name of the current month.

=head2 day_of_month

=head2 day

=head2 mday

Returns the day of the month, from C<1 .. 29>.

=head2 day_of_week

=head2 wday

=head2 dow

Returns the day of the week as a number, from C<1 .. 7>, with C<1> being
Sunday and C<7> being Saturday. Returns C<undef> if the day is a "hunyadi".

=head2 day_name

Returns the name of the current day of the week.

=head2 day_of_year

=head2 doy

Returns the day of the year.

=head2 ymd

=head2 mdy

=head2 dmy

     my $string = $dt->ymd( $optional_separator );

Each method returns the year, month, and day, in the order indicated
by the method name.  Years are zero-padded to three digits.  Months and
days are 0-padded to two digits.

By default, the values are separated by a dash (C<->), but this can be
overridden by passing a value to the method.

=head2 date

Alias for L<ymd>.

=head2 datetime

Equivalent to

    $dt->ymd('-') . 'EP'

=head2 is_leap_year

This method returns a true or false indicating whether or not the
L<DateTime> object is in a leap year.

=head2 week

    my ( $week_year, $week_number ) = $dt->week;

Returns information about the calendar week which contains this
L<DateTime> object. The values returned by this method are also available
separately through the L<week_year> and L<week_number> methods.

=head2 week_year

Returns the year of the week. In the Pataphysical calendar, this is
equal to the year of the date, as all weeks fall in one year only.

=head2 week_number

Returns the week of the year, from C<1 .. 53>.

The 29th of each month falls outside of any week; C<week_number> returns
C<undef> for these dates.

=head2 utc_rd_values

Returns the current UTC Rata Die days and seconds as a two element
list.  This exists primarily to allow other calendar modules to create
objects based on the values provided by this object.

=head2 utc_rd_as_seconds

Returns the current UTC Rata Die days and seconds purely as seconds.
This is useful when you need a single number to represent a date.

=head2 strftime

    my $string = $dt->strftime( $format, ... );

This method implements functionality similar to the C<strftime()>
method in C.  However, if given multiple format strings, then it will
return multiple elements, one for each format string.

See L<DateTime> for a list of all possible format specifiers. This
module implements all specifiers related to dates. There is one
additional specifier: C<%*> represents the feast of that date.

=head2 feast

Returns the feast or vacuation of the given date.

=head2 type_of_feast

Returns the type of feast or vacuation.

  '*' means Fête Suprème Première première
  '1' means Fête Suprème Première seconde
  '2' means Fête Suprème Seconde
  '3' means Fête Suprème Tierce
  '4' means Fête Suprème Quarte
  'v' means Vacuation

=head2 is_imaginary

Returns true or false indicating whether the L<DateTime> object represents an
imaginary date.

=head2 set

This method can be used to change the local components of a date time,
or its locale.  This method accepts any parameter allowed by L<new>.

=head2 truncate

    $dt->truncate( to => ... );

This method allows you to reset some of the local time components in
the object to their C<zero> values.  The C<to> parameter is used to
specify which values to truncate, and it may be one of C<year>,
C<month>, or C<day>.

=head2 add_duration

    $dt->add_duration( $duration_object );

This method adds a C<DateTime::Duration> to the current L<DateTime>.
See the L<DateTime::Duration> documentation for more details.

=head2 add

    $dt->add( %arguments );

This method is syntactic sugar around the L<add_duration> method.  It
simply creates a new L<DateTime::Duration> object using the parameters
given, and then calls the L<add_duration> method.

=head2 subtract_duration

    $dt->subtract_duration( $duration_object );

When given a L<DateTime::Duration> object, this method simply calls
C<invert> on that object and passes that new duration to the
L<add_duration> method.

=head2 subtract

    $dt->subtract( %arguments );

Like L<add>, this is syntactic sugar for the L<subtract_duration> method.

=head2 subtract_datetime

    $dt->subtract_datetime( $datetime );

This method returns a new L<DateTime::Duration> object representing
the difference between the two dates.

=head2 compare

    $cmp = DateTime->compare( $dt1, $dt2 );

    @dates = sort { DateTime->compare( $a, $b ) } @dates;

Compare two DateTime objects.  The semantics are compatible with Perl's
L<sort|perlfunc/sort> function; it returns C<-1> if C<< $a < $b >>, C<0>
if C<$a == $b>, and C<1> if C<< $a > $b >>.

Of course, since L<DateTime> objects overload comparison operators, you
can just do this anyway:

    @dates = sort @dates;

=head1 BUGS

=over 4

=item *

Adding a week to a date is exactly equivalent to adding seven days in
this module because of the way L<DateTime::Duration> is implemented.
The Hunyadis are not taken into account.

=item *

L<from_epoch> and L<now> probably only work on Unix.

=back

=head1 SUPPORT

Support for this module is provided via the datetime@perl.org email
list. See L<http://lists.perl.org/> for more details.

=head1 SEE ALSO

L<DateTime>

datetime@perl.org mailing list

=head1 AUTHOR

Eugene van der Pijll <pijll@gmx.net>

Maintained by Philippe Bruhat (BooK) since 2014.

=head1 COPYRIGHT

Copyright (c) 2003, 2004 Eugene van der Pijll.  All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
