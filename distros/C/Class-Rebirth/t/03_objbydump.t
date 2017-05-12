use Test::More;

use lib 'lib','../lib','t/lib';

use strict;

use Data::Dumper;

my $class = 'Class::Rebirth';

use_ok( $class );

use Local::Foo;
use Local::Bar;
use Local::More;



subtest 'object by dump' => sub {

  my $s = _classDump();

  my $obj = Class::Rebirth::_createObjectByDump( $s );

  is($obj->{'a'}, '1', "method returned data");

 

  done_testing();
}; 


done_testing();




##########

sub _classDump{

  my $s = "\$VAR1 = bless( {
                'a' => 1,
                'bar' => bless( {
                                  'a' => 1
                                }, 'Bar' )
              }, 'Foo' );";



  return $s;
}