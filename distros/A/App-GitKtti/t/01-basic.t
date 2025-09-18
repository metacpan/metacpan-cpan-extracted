use strict;
use warnings;
use Test::More tests => 3;

BEGIN {
    use_ok('App::GitKtti');
}

# Test version
ok(defined $App::GitKtti::VERSION, 'Version is defined');
ok($App::GitKtti::VERSION =~ /^\d+\.\d+\.\d+$/, 'Version format is correct');

done_testing();
