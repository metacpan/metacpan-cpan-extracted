use Test::More;
use strict;
use warnings;

use Articulate::TestEnv;
use Articulate::Validation;
use Articulate::Item;

my $app = app_from_config();

my $nav = Articulate::Navigation->new( app => $app, );

is ref $nav->locations, ref [];
is scalar @{ $nav->locations }, 0;

$nav->define_locspec('/zone/*');
is scalar @{ $nav->locations }, 1;
ok $nav->valid_location('/zone/public');
$nav->undefine_locspec('/zone/*');
is scalar @{ $nav->locations }, 0;

ok !$nav->valid_location('/zone/public');

done_testing;
