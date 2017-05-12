use Test::More;

use strict;
use warnings;

use_ok('App::TeleGramma::Plugin::Core::Thants');

my $t = App::TeleGramma::Plugin::Core::Thants->new;
ok($t, 'created');

done_testing();
