use Test::More;

use lib 'lib','../lib','t/lib';

use strict;

use Data::Dumper;

my $class = 'Class::Rebirth';

use_ok( $class );


# DO NOT USE THEM! It must load them dynamically!
# use Local::Foo;
# use Local::Bar;
# use Local::More;



subtest 'rebirth' => sub {

  #my $data = _classData();

  my $s = _classDump();
  my $obj = Class::Rebirth::_createObjectByDump( $s );

  my $obj = Class::Rebirth::rebirth( $obj );

  is($obj->{'data1'}, 'd1', "method returned data");

  is($obj->method1(), 1, "method returned data");
  is($obj->method2(), 2, "method returned data");

  is($obj->{'bar'}->methodA(), "A", "method of subobject returned data");
  is($obj->{'bar'}->methodB(), "B", "method of subobject returned data");

  done_testing();
}; 


done_testing();




##########

sub _classData{

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







sub _classDump{

  my $s = "\$VAR1 = bless( {
                 'data1' => 'd1',
                 'bar' => bless( {
                                   'more' => bless( {
                                                      'm' => 'me'
                                                    }, 'Local::More' )
                                 }, 'Local::Bar' )
               }, 'Local::Foo' );";



  return $s;
}