# -*- perl -*-

# t/002_load.t - check runtime mixin generation

use Test::More qw(no_plan);

BEGIN { use_ok( 'Class::Prototyped::Mixin' ); }


require 't/packages.pl';

my $runtime = Class::Prototyped::Mixin::mixin('HelloWorld', 'HelloWorld::Uppercase', 'HelloWorld::Italic');
#warn $runtime->hello(74);

is ($runtime->hello(74),
    '<i>HELLO WORLD! I AM 74 YEARS OLD</i>',
    'call runtime generated class'
   );


