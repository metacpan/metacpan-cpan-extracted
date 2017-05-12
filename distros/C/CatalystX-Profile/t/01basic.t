use strict;
use warnings;
use Test::More tests => 1;

{
    package MyApp;
    use Catalyst qw( +CatalystX::Profile );
    MyApp->setup;
}

ok(MyApp->controller('Profile'), 'has the profile controller');
