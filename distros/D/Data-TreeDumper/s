package Vegetable ;

package Potatoe ;
use AutoLoader ;
@ISA = ("Vegetable");

sub AUTOLOAD{} ;

package SuperObject ;
@ISA = ("Potatoe");

package SuperObjectWithAutoload ;
@ISA = ("Potatoe");
sub AUTOLOAD{} ;

package TiedHash;
use Tie::Hash;

@ISA = (Tie::StdHash);

package TiedArray;
use Tie::Array;

@ISA = ('Tie::StdArray');

package TiedScalar;
use Tie::Scalar;

@ISA = (Tie::StdScalar);


package main ;

$s = {
  'STDIN' => \*STDIN,
  'REGEX' => qr/^this|that/,
  'RS' => \4,
  
  'A' => {
    'a' => {},
    'code1' => sub { "DUMMY" },
    'b' => {
      'a' => 0,
      'b' => 1,
      'c' => {
        'a' => 1,
        'b' => 1,
        'c' => 1,
        }
      },
    'b2' => {
      'a' => 1,
      'b' => 1,
      'c' => 1,
      }
  },
  'C' => {
    'b' => {
      'a' => {
        'c' => 42,
        'a' => {},
        'b' => sub { "DUMMY" },
	'empty' => undef,
	'z_array' => [1]
      }
    }
  },
  'ARRAY' => [
    'elment_1',
    'element_2',
    'element_3',
    [1, 2],
    {a => 1, b => 2}
  ],
  'STRING_WITH_EMBEDED_NEW_LINE' => "line1\nline2\r\nline3\nlong line4 lkjdfljkdjfklsdfkldjflkjdkfjksldfjldjfklsdjfkljdklfjksljfkldsjfkldsjklfjlfjlsdjflsjfklsjdfldjkslfjklsdfj\nline5",
};

my $scalar = "hi" ;
$s->{SCALAR} = $scalar ;
$s->{SCALAR_REF} = \$scalar ;
$s->{SCALAR_REF2} = \$scalar ;
${$s->{'A'}{'code3'}} = $s->{'A'}{'code1'};
$s->{'A'}{'code2'} = $s->{'A'}{'code1'};
$s->{'CopyOfARRAY'} = $s->{'ARRAY'};
$s->{'C1'} = \($s->{'C2'});
$s->{'C2'} = \($s->{'C1'});

$s->{za} = '';

$object = bless {A =>[], B => 123}, 'SuperObject' ;
$s->{object} = $object ;

$object_with_autoload = bless {}, 'SuperObjectWithAutoload' ;
$s->{object_with_autoload} = $object_with_autoload ;

tie my %tied_hash, "TiedHash" ;
$tied_hash{'x'}++ ;
$s->{tied_hash} = \%tied_hash ;

tie my @tied_array, "TiedArray" ;
$tied_array[0]++ ;
$s->{tied_array} = \@tied_array ;

tie my $tied_scalar, "TiedScalar" ;
$tied_scalar++ ;
$s->{tied_scalar} = $tied_scalar ;

my %tied_hash_object ;
tie my %tied_hash_object, "TiedHash" ;
%tied_hash_object = (m1 => 1) ;
bless \%tied_hash_object, 'SuperObject' ;
$s->{tied_hash_object} = \%tied_hash_object ;

tie my @tied_array_object, "TiedArray" ;
@tied_array_object = (0) ;
bless \@tied_array_object, 'SuperObject' ;
$s->{tied_array_object} = \@tied_array_object;

