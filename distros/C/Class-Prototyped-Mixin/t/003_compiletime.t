# -*- perl -*-

# t/002_load.t - check runtime mixin generation

use Test::More qw(no_plan);

BEGIN { use_ok( 'Class::Prototyped::Mixin' ); }


require 't/packages.pl';


package CompileTime;
use base qw(Class::Prototyped);

my $uclass = Class::Prototyped::Mixin::mixin(
  'HelloWorld', 'HelloWorld::Uppercase', 'HelloWorld::Bold'
 );

__PACKAGE__->reflect->addSlot('*' => $uclass);

1;






Test::More::is (CompileTime->hello(88),
		'<b>HELLO WORLD! I AM 88 YEARS OLD</b>',
		'call compile-time generated class'
	       );


