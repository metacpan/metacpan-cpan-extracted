use strict;
use warnings;

use Test::More tests => 9;
BEGIN { use_ok('Config::Lite') };

use Config::Lite qw(load_config);
my %t = load_config("t/tconfig/tconfig.conf");
is($t{'test1'}, 123);
is($t{'test2'}, 'abc');
is($t{'right'}, 'left');
is($t{'test1'}, '123');
is($t{'test1'}, '123');
is($t{'sharped'}, undef);
is($t{'#sharped'}, undef);

my $t2 = load_config("t/tconfig/tconfig_404.conf");
is($t2, 'no config file found');

