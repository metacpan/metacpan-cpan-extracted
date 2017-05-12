use Test::More;

use lib 'lib','../lib','t/lib';

use strict;

use Data::Dumper;

my $class = 'Class::Rebirth';

use_ok( $class );


use Local::Foo;
use Local::Bar;
use Local::More;




$|=1;


subtest 'list of packages' => sub {

  my $obj = _classDump();


  my @pkgs = Class::Rebirth::_getUsedPackagesOfObject( $obj );

  is(scalar(@pkgs), 3, "amount of found packages");
 
  done_testing();
}; 


done_testing();




##########
sub _classDump{

  my $foo = Local::Foo->new();
  $foo->{'data1'} = 'd1';

  # serialize object
  my $target;
  my $ser = Data::Dumper->Dump([$foo],['$target']);

  # deserialize object
  eval $ser;
  # target holds death object now (zombie)


  return $target;
}