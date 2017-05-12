use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
    use_ok 'App::perlhl', 'Can be use-d';
}

new_ok('App::perlhl');
my $highlighter = new_ok('App::perlhl' => ['html'], 'html works');
can_ok($highlighter, qw(new run));
