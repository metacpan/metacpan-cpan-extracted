use strict;
use warnings;
use Test::More 0.82 tests => 3;

BEGIN {
    use_ok('App::Pastebin::sprunge');
}

my $app = new_ok('App::Pastebin::sprunge');
can_ok($app, qw(new run));
