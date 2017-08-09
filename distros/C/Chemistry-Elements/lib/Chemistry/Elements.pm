use v5.10;

package Chemistry::Elements;

use strict;
use warnings;
use utf8;
no warnings;

use Carp qw(croak carp);
use Scalar::Util qw(blessed);

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD
             $debug %names %elements $maximum_Z
             %names_to_Z $Default_language %Languages
            );

use Exporter qw(import);

@EXPORT_OK = qw(get_Z get_symbol get_name);
@EXPORT    = qw();
$VERSION   = '1.072';

use subs qw(
	_get_name_by_Z
	_get_symbol_by_Z
	_get_name_by_symbol
	_get_Z_by_symbol
	_get_symbol_by_name
	_get_Z_by_name
	_is_Z
	_is_name
	_is_symbol
	_format_name
	_format_symbol
	);

BEGIN {
my @class_methods  = qw(can isa);
my @object_methods = qw(new Z name symbol can);
my %class_methods  = map { $_, 1 } @class_methods;
my %object_methods = map { $_, 1 } @object_methods;

sub can {
	my $thingy = shift;
	my @methods = @_;

	my $method_hash = blessed $thingy ? \%object_methods : \%class_methods ;

	foreach my $method ( @methods ) {
		return unless exists $method_hash->{ $method };
		}

	return 1;
	}

sub _add_object_method { # everyone gets it
	$object_methods{ $_[1] } = 1;
	}
}

$debug = 0;

%Languages = (
	'Pig Latin' => 0,
	'English'   => 1,
	'Japanese' => 2,
	);

$Default_language = $Languages{'English'};

# http://www.ptable.com/?lang=ja
%names = (
  1 => [ qw( Ydrogenhai      Hydrogen      水素) ],
  2 => [ qw( Eliumhai        Helium        ヘリウム) ],
  3 => [ qw( Ithiumlai       Lithium       リチウム) ],
  4 => [ qw( Erylliumbai     Beryllium     ベリリウム) ],
  5 => [ qw( Oronbai         Boron         ホウ素) ],
  6 => [ qw( Arboncai        Carbon        炭素) ],
  7 => [ qw( Itrogennai      Nitrogen      窒素) ],
  8 => [ qw( Xygenoai        Oxygen        酸素) ],
  9 => [ qw( Luorinefai      Fluorine      フッ素) ],
 10 => [ qw( Eonnai          Neon          ネオン) ],
 11 => [ qw( Odiumsai        Sodium        ナトリウム) ],
 12 => [ qw( Agnesiummai     Magnesium     マグネシウム) ],
 13 => [ qw( Luminiumaai     Aluminium     アルミニウム) ],
 14 => [ qw( Iliconsai       Silicon       ケイ素) ],
 15 => [ qw( Hosphoruspai    Phosphorus    リン) ],
 16 => [ qw( Ulfursai        Sulfur        硫黄) ],
 17 => [ qw( Hlorinecai      Chlorine      塩素) ],
 18 => [ qw( Rgonaai         Argon         アルゴン) ],
 19 => [ qw( Otassiumpai     Potassium     カリウム) ],
 20 => [ qw( Alciumcai       Calcium       カルシウム) ],
 21 => [ qw( Candiumsai      Scandium      スカンジウム) ],
 22 => [ qw( Itaniumtai      Titanium      チタン) ],
 23 => [ qw( Anadiumvai      Vanadium      バナジウム) ],
 24 => [ qw( Hromiumcai      Chromium      クロム) ],
 25 => [ qw( Anganesemai     Manganese     マンガン) ],
 26 => [ qw( Roniai          Iron          鉄) ],
 27 => [ qw( Obaltcai        Cobalt        コバルト) ],
 28 => [ qw( Ickelnai        Nickel        ニッケル) ],
 29 => [ qw( Oppercai        Copper        銅) ],
 30 => [ qw( Inczai          Zinc          亜鉛) ],
 31 => [ qw( Alliumgai       Gallium       ガリウム) ],
 32 => [ qw( Ermaniumgai     Germanium     ゲルマニウム) ],
 33 => [ qw( Rsenicaai       Arsenic       ヒ素) ],
 34 => [ qw( Eleniumsai      Selenium      セレン) ],
 35 => [ qw( Rominebai       Bromine       臭素) ],
 36 => [ qw( Ryptonkai       Krypton       クリプトン) ],
 37 => [ qw( Ubidiumrai      Rubidium      ルビジウム) ],
 38 => [ qw( Trontiumsai     Strontium     ストロンチウム) ],
 39 => [ qw( Ttriumyai       Yttrium       イットリウム) ],
 40 => [ qw( Irconiumzai     Zirconium     ジルコニウム) ],
 41 => [ qw( Iobiumnai       Niobium       ニオブ) ],
 42 => [ qw( Olybdenummai    Molybdenum    モリブデン) ],
 43 => [ qw( Echnetiumtai    Technetium    テクネチウム) ],
 44 => [ qw( Utheniumrai     Ruthenium     ルテニウム) ],
 45 => [ qw( Hodiumrai       Rhodium       ロジウム) ],
 46 => [ qw( Alladiumpai     Palladium     パラジウム) ],
 47 => [ qw( Ilversai        Silver        銀) ],
 48 => [ qw( Admiumcai       Cadmium       カドミウム) ],
 49 => [ qw( Ndiumiai        Indium        インジウム) ],
 50 => [ qw( Intai           Tin           スズ) ],
 51 => [ qw( Ntimonyaai      Antimony      アンチモン) ],
 52 => [ qw( Elluriumtai     Tellurium     テルル) ],
 53 => [ qw( Odineiai        Iodine        ヨウ素) ],
 54 => [ qw( Enonxai         Xenon         キセノン) ],
 55 => [ qw( Esiumcai        Cesium        セシウム) ],
 56 => [ qw( Ariumbai        Barium        バリウム) ],
 57 => [ qw( Anthanumlai     Lanthanum     ランタン) ],
 58 => [ qw( Eriumcai        Cerium        セリウム) ],
 59 => [ qw( Raesodymiumpai  Praseodymium  プラセオジム) ],
 60 => [ qw( Eodymiumnai     Neodymium     ネオジム) ],
 61 => [ qw( Romethiumpai    Promethium    プロメチウム) ],
 62 => [ qw( Amariumsai      Samarium      サマリウム) ],
 63 => [ qw( Uropiumeai      Europium      ユウロピウム) ],
 64 => [ qw( Adoliniumgai    Gadolinium    ガドリニウム) ],
 65 => [ qw( Erbiumtai       Terbium       テルビウム) ],
 66 => [ qw( Ysprosiumdai    Dysprosium    ジスプロシウム) ],
 67 => [ qw( Olmiumhai       Holmium       ホルミウム) ],
 68 => [ qw( Rbiumeai        Erbium        エルビウム) ],
 69 => [ qw( Huliumtai       Thulium       ツリウム) ],
 70 => [ qw( Tterbiumyai     Ytterbium     イッテルビウム) ],
 71 => [ qw( Utetiumlai      Lutetium      ルテチウム) ],
 72 => [ qw( Afniumhai       Hafnium       ハフニウム) ],
 73 => [ qw( Antalumtai      Tantalum      タンタル) ],
 74 => [ qw( Ungstentai      Tungsten      タングステン) ],
 75 => [ qw( Heniumrai       Rhenium       レニウム) ],
 76 => [ qw( Smiumoai        Osmium        オスミウム) ],
 77 => [ qw( Ridiumiai       Iridium       イリジウム) ],
 78 => [ qw( Latinumpai      Platinum      白金) ],
 79 => [ qw( Oldgai          Gold          金) ],
 80 => [ qw( Ercurymai       Mercury       水銀) ],
 81 => [ qw( Halliumtai      Thallium      タリウム) ],
 82 => [ qw( Eadlai          Lead          鉛) ],
 83 => [ qw( Ismuthbai       Bismuth       ビスマス) ],
 84 => [ qw( Oloniumpai      Polonium      ポロニウム) ],
 85 => [ qw( Statineaai      Astatine      アスタチン) ],
 86 => [ qw( Adonrai         Radon         ラドン) ],
 87 => [ qw( Ranciumfai      Francium      フランシウム) ],
 88 => [ qw( Adiumrai        Radium        ラジウム) ],
 89 => [ qw( Ctiniumaai      Actinium      アクチニウム) ],
 90 => [ qw( Horiumtai       Thorium       トリウム) ],
 91 => [ qw( Rotactiniumpai  Protactinium  プロトアクチニウム) ],
 92 => [ qw( Raniumuai       Uranium       ウラン) ],
 93 => [ qw( Eptuniumnai     Neptunium     ネプツニウム) ],
 94 => [ qw( Lutoniumpai     Plutonium     プルトニウム) ],
 95 => [ qw( Mericiumaai     Americium     アメリシウム) ],
 96 => [ qw( Uriumcai        Curium        キュリウム) ],
 97 => [ qw( Erkeliumbai     Berkelium     バークリウム) ],
 98 => [ qw( Aliforniumcai   Californium   カリホルニウム) ],
 99 => [ qw( Insteiniumeai   Einsteinium   アインスタイニウム) ],
100 => [ qw( Ermiumfai       Fermium       フェルミウム) ],
101 => [ qw( Endeleviummai   Mendelevium   メンデレビウム) ],
102 => [ qw( Obeliumnai      Nobelium      ノーベリウム) ],
103 => [ qw( Awerenciumlai   Lawrencium    ローレンシウム) ],
104 => [ qw( Utherfordiumrai Rutherfordium ラザホージウム) ],
105 => [ qw( Ubniumdai       Dubnium       ドブニウム) ],
106 => [ qw( Eaborgiumsai    Seaborgium    シーボーギウム) ],
107 => [ qw( Ohriumbai       Bohrium       ボーリウム) ],
108 => [ qw( Assiumhai       Hassium       ハッシウム) ],
109 => [ qw( Eitneriummai    Meitnerium    マイトネリウム) ],
110 => [ qw( Armstadtiumdai  Darmstadtium  ダームスタチウム) ],
111 => [ qw( Oentgeniumrai   Roentgenium   レントゲニウム) ],
112 => [ qw( Operniciumcai   Copernicium   コペルニシウム) ],
113 => [ qw( Ihoniumnai      Nihonium      ニホニウム) ],
114 => [ qw( Leroviumfai     Flerovium     フレロビウム) ],
115 => [ qw( Oscoviummai     Moscovium     モスコビウム) ],
116 => [ qw( Ivermoriumlai   Livermorium   リバモリウム) ],
117 => [ qw( Ennessinetai    Tennessine    テネシン) ],
118 => [ qw( Ganessonoai     Oganesson     オガネソン) ],
);

{
# There might be duplicates keys here, but it should never come out
# with the wrong Z
our %names_to_Z = ();
foreach my $Z ( keys %names ) {
	my @names = map { lc } @{ $names{$Z} };
#	print STDERR "Got names [@names] for $Z\n";
	@names_to_Z{@names} = ($Z) x @names;
	}

#print STDERR Dumper( \%names_to_symbol ); use Data::Dumper;
}

{
my @a = sort {$a <=> $b } keys %names;
$maximum_Z = pop @a;
}

my %elements = map { state $n = 0; $n++; $_ => $n, $n => $_ } qw(
H                                                                                            He
Li Be                                                                          B  C  N  O  F Ne
Na Mg                                                                         Al Si  P  S Cl Ar
K  Ca                                           Sc Ti  V Cr Mn Fe Co Ni Cu Zn Ga Ge As Se Br Kr
Rb Sr                                            Y Zr Nb Mo Tc Ru Rh Pd Ag Cd In Sn Sb Te  I Xe
Cs Ba La Ce Pr Nd Pm Sm Eu Gd Tb Dy Ho Er Tm Yb Lu Hf Ta W  Re Os Ir Pt Au Hg Tl Pb Bi Po At Rn
Fr Ra Ac Th Pa U  Np Pu Am Cm Bk Cf Es Fm Md No Lr Rf Ha Sg Bh Hs Mt Ds Rg Cn Nh Fl Mc Lv Ts Og
);

sub new {
	my( $class, $data, $language ) = @_;

	my $self = {};
	bless $self, $class;

	if(    _is_Z      $data ) { $self->Z($data) }
	elsif( _is_symbol $data ) { $self->symbol($data) }
	elsif( _is_name   $data ) { $self->name($data) }
	else                      { return }

	return $self;
	}

sub Z {
	my $self = shift;

	return $self->{'Z'} unless @_;
	my $data = shift;

	unless( _is_Z $data ) {
		$self->error('$data is not a valid proton number');
		return;
		}

	$self->{'Z'}      = $data;
	$self->{'name'}   = _get_name_by_Z $data;
	$self->{'symbol'} = _get_symbol_by_Z $data;

	return $data;
	}

sub name {
	my $self = shift;

	return $self->{'name'} unless @_;
	my $data = shift;

	unless( _is_name $data ) {
		$self->error('$data is not a valid element name');
		return;
		}

	$self->{'name'}   = _format_name $data;
	$self->{'Z'}      = _get_Z_by_name $data;
	$self->{'symbol'} = _get_symbol_by_Z($self->Z);

	return $data;
	}

sub symbol {
	my $self = shift;

	return $self->{'symbol'} unless @_;
	my $data = shift;

	unless( _is_symbol $data ) {
		$self->error('$data is not a valid element symbol');
		return;
		}

	$self->{'symbol'} = _format_symbol $data;
	$self->{'Z'}      = _get_Z_by_symbol $data;
	$self->{'name'}   = _get_name_by_Z $self->Z;

	return $data;
	}

sub get_symbol {
	my $thingy = shift;

	#since we were asked for a name, we'll suppose that we were passed
	#either a chemical symbol or a Z.
	return _get_symbol_by_Z($thingy)      if _is_Z $thingy;
	return _get_symbol_by_name($thingy)   if _is_name $thingy;

	#maybe it's already a symbol...
	return _format_symbol $thingy if _is_symbol $thingy;

	#we were passed something wierd.  pretend we don't know anything.
	return;
	}

sub _get_symbol_by_name {
	my $name = lc shift;

	return unless _is_name $name;

	my $Z = $names_to_Z{$name};

	$elements{$Z};
	}

sub _get_symbol_by_Z {
	return unless _is_Z $_[0];

	return $elements{$_[0]};
	}

sub get_name {
	my $thingy   = shift;
	my $language = defined $_[0] ? $_[0] : $Default_language;

	#since we were asked for a name, we'll suppose that we were passed
	#either a chemical symbol or a Z.
	return _get_name_by_symbol( $thingy, $language ) if _is_symbol $thingy;
	return _get_name_by_Z(      $thingy, $language ) if _is_Z $thingy;

	#maybe it's already a name, might have to translate it
	if( _is_name $thingy )
		{
		my $Z = _get_Z_by_name( $thingy );
		return _get_name_by_Z( $Z, $language );
		}

	#we were passed something wierd.  pretend we don't know anything.
	return;
	}


sub _get_name_by_symbol {
	my $symbol   = shift;

	return unless _is_symbol $symbol;

	my $language = defined $_[0] ? $_[0] : $Default_language;

	my $Z = _get_Z_by_symbol($symbol);

	return _get_name_by_Z( $Z, $language );
	}

sub _get_name_by_Z {
	my $Z        = shift;
	my $language = defined $_[0] ? $_[0] : $Default_language;

	return unless _is_Z $Z;

	#not much we can do if they don't pass a proper number
	# XXX: check for language?
	return $names{$Z}[$language];
	}

sub get_Z {
	my $thingy = shift;

	croak "Can't call get_Z on object. Use Z instead" if ref $thingy;

	#since we were asked for a name, we'll suppose that we were passed
	#either a chemical symbol or a Z.
	return _get_Z_by_symbol( $thingy ) if _is_symbol( $thingy );
	return _get_Z_by_name( $thingy )   if _is_name( $thingy );

	#maybe it's already a Z
	return $thingy                     if _is_Z( $thingy );

	return;
	}

# gets the proton number for the name, no matter which language it
# is in
sub _get_Z_by_name {
	my $name = lc shift;

	$names_to_Z{$name}; # language agnostic
	}

sub _get_Z_by_symbol {
	my $symbol = _format_symbol( shift );

	return $elements{$symbol} if exists $elements{$symbol};

	return;
	}

########################################################################
########################################################################
#
# the _is_* functions do some minimal data checking to help other
# functions guess what sort of input they received

########################################################################
sub _is_name { exists $names_to_Z{ lc shift } ? 1 : 0	}

########################################################################
sub _is_symbol {
	my $symbol = _format_symbol( $_[0] );

	exists $elements{$symbol} ? 1 : ();
	}

########################################################################
sub _is_Z { $_[0] =~ /^[123456789]\d*\z/ && exists $elements{$_[0]}  }

########################################################################
# _format_symbol
#
# input: a string that is supoosedly a chemical symbol
# output: the string with the first character in uppercase and the
#  rest lowercase
#
# there is no data checking involved.  this function doens't know
# and doesn't care if the data are valid.  it just does its thing.
sub _format_symbol { $_[0] =~ m/^[a-z]/i && ucfirst lc $_[0] }

########################################################################
# _format_name
#
# input: a string that is supoosedly a chemical element's name
# output: the string with the first character in uppercase and the
#  rest lowercase
#
# there is no data checking involved.  this function doens't know
# and doesn't care if the data are valid.  it just does its thing.
#
# this looks like _format_symbol, but it logically isn't.  someday
# it might do something different than _format_symbol
sub _format_name {
	my $data = shift;

	$data =~ s/^(.)(.*)/uc($1).lc($2)/e;

	return $data;
	}

########################################################################
sub AUTOLOAD {
	my $self = shift;
	my $data = shift;

	return unless ref $self;

	my $method_name = $AUTOLOAD;

	$method_name =~ s/.*:://;

	if( $data )
		{ # only add new method if they add data
	   	$self->{$method_name} = $data;
	   	$self->_add_object_method( $method_name );
	   	}
	elsif( defined $self->{$method_name} ) { return $self->{$method_name}  }
	else                                   { return }

	}

1;

__END__

=encoding utf8

=head1 NAME

Chemistry::Elements - Perl extension for working with Chemical Elements

=head1 SYNOPSIS

  use Chemistry::Elements qw(get_name get_Z get_symbol);

  # the constructor can use different input
  $element = Chemistry::Elements->new( $atomic_number   );
  $element = Chemistry::Elements->new( $chemical_symbol );
  $element = Chemistry::Elements->new( $element_name    );

  # you can make up your own attributes by specifying
  # a method (which is really AUTOLOAD)
        $element->molar_mass(22.989) #sets the attribute
  $MM = $element->molar_mass         #retrieves the value

=head1 DESCRIPTION

There are two parts to the module:  the object stuff and the exportable
functions for use outside of the object stuff.  The exportable
functions are discussed in L</Exportable functions>.

Chemistry::Elements provides an easy, object-oriented way to
keep track of your chemical data.  Using either the atomic
number, chemical symbol, or element name you can construct
an Element object.  Once you have an element object, you can
associate your data with the object by making up your own
methods, which the AUTOLOAD function handles.  Since each
chemist is likely to want to use his or her own data, or
data for some unforesee-able property, this module does not
try to be a repository for chemical data.

The Element object constructor tries to be as flexible as possible -
pass it an atomic number, chemical symbol, or element name and it
tries to create the object.

  # the constructor can use different input
  $element = Chemistry::Elements->new( $atomic_number );
  $element = Chemistry::Elements->new( $chemical_symbol );
  $element = Chemistry::Elements->new( $element_name );

Once you have the object, you can define your own methods simply
by using them.  Giving the method an argument (others will be
ignored) creates an attribute with the method's name and
the argument's value.

  # you can make up your own attributes by specifying
  # a method (which is really AUTOLOAD)
        $element->molar_mass(22.989) #sets the attribute
  $MM = $element->molar_mass         #retrieves the value

The atomic number, chemical symbol, and element name can be
retrieved in the same way.

   $atomic_number = $element->Z;
   $name          = $element->name;
   $symbol        = $element->symbol;

These methods can also be used to set values, although changing
any of the three affects the other two.

   $element       = Chemistry::Elements->new('Lead');

   $atomic_number = $element->Z;    # $atomic_number is 82

   $element->Z(79);

   $name          = $element->name; # $name is 'Gold'

=head2 Instance methods

=over 4

=item new( Z | SYMBOL | NAME )

Create a new instance from either the atomic number, symbol, or
element name.

=item can( METHOD [, METHOD ... ] )

Returns true if the package or object can respond to METHOD. This
distinguishes between class and instance methods.

=item Z

Return the atomic number of the element.

=item name

Return the name of the element.

=item symbol

Return the symbol of the element.

=back

=head2 Exportable functions

These functions can be exported.  They are not exported by default. At the
moment, only the functional interface supports multi-language names.

=over 4

=item get_symbol( NAME|Z )

This function attempts to return the symbol of the chemical element given
either the chemical symbol, element name, or atmoic number.  The
function does its best to interpret inconsistent input data (e.g.
chemcial symbols of mixed and single case).

	use Chemistry::Elements qw(get_symbol);

	$name = get_symbol('Fe');     #$name is 'Fe'
	$name = get_symbol('fe');     #$name is 'Fe'
	$name = get_symbol(26);       #$name is 'Fe'
	$name = get_symbol('Iron');   #$name is 'Fe'
	$name = get_symbol('iron');   #$name is 'Fe'

If no symbol can be found, nothing is returned.

Since this function will return the symbol if it is given a symbol,
you can use it to test whether a string is a chemical symbol
(although you have to play some tricks with case since get_symbol
will try its best despite the case of the input data).

	if( lc($string) eq lc( get_symbol($string) ) )
		{
		#stuff
		}

You can modify the symbols (e.g. you work for UCal ;) ) by changing
the data at the end of this module.

=item get_name( SYMBOL|NAME|Z [, LANGUAGE] )

This function attempts to return the name the chemical element given
either the chemical symbol, element name, or atomic number.  The
function does its best to interpret inconsistent input data (e.g.
chemical symbols of mixed and single case).

	$name = get_name('Fe');     #$name is 'Iron'
	$name = get_name('fe');     #$name is 'Iron'
	$name = get_name(26);       #$name is 'Iron'
	$name = get_name('Iron');   #$name is 'Iron'
	$name = get_name('iron');   #$name is 'Iron'

If no Z can be found, nothing is returned.

Since this function will return the name if it is given a name,
you can use it to test whether a string is a chemical element name
(although you have to play some tricks with case since get_name
will try its best despite the case of the input data).

	if( lc($string) eq lc( get_name($string) ) )
		{
		#stuff
		}

You can modify the names (e.g. for different languages) by changing
the data at the end of this module.

=item get_Z( SYMBOL|NAME|Z )

This function attempts to return the atomic number of the chemical
element given either the chemical symbol, element name, or atomic
number.  The function does its best to interpret inconsistent input data
(e.g. chemcial symbols of mixed and single case).

	$name = get_Z('Fe');     #$name is 26
	$name = get_Z('fe');     #$name is 26
	$name = get_Z(26);       #$name is 26
	$name = get_Z('Iron');   #$name is 26
	$name = get_Z('iron');   #$name is 26

If no Z can be found, nothing is returned.

Since this function will return the Z if it is given a Z,
you can use it to test whether a string is an atomic number.
You might want to use the string comparison in case the
$string is not a number (in which case the comparison
will be false save for the case when $string is undefined).

	if( $string eq get_Z($string) ) {
		#stuff
		}

=back

The package constructor automatically finds the largest defined
atomic number (in case you add your own heavy elements).

=head2 AUTOLOADing methods

You can pseudo-define additional methods to associate data with objects.
For instance, if you wanted to add a molar mass attribute, you
simply pretend that there is a molar_mass method:

	$element->molar_mass($MM); #add molar mass datum in $MM to object

Similarly, you can retrieve previously set values by not specifying
an argument to your pretend method:

	$datum = $element->molar_mass();

	#or without the parentheses
	$datum = $element->molar_mass;

If a value has not been associated with the pretend method and the
object, the pretend method returns nothing.

I had thought about providing basic data for the elements, but
thought that anyone using this module would probably have their
own data.  If there is an interest in canned data, perhaps I can
provide mine :)

=head2 Localization support

XXX: Fill this stuff in later. For now see the test suite

=head1 TO DO

I would like make this module easily localizable so that one could
specify other names or symbols for the elements (i.e. a different
language or a different perspective on the heavy elements).  If
anyone should make changes to the data, i would like to get a copy
so that i can include it in future releases :)

=head1 SOURCE AVAILABILITY

The source for this module is in Github:

	https://github.com/briandfoy/chemistry-elements

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2000-2016, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
