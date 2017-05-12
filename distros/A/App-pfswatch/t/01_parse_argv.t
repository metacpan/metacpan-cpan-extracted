use strict;
use warnings;
use Test::More;
use App::pfswatch;

my $watcher = 'App::pfswatch';

subtest 'path' => sub {
    my %opts = $watcher->parse_argv(qw(lib t));
    is_deeply $opts{path}, [qw/lib t/];

    my %opts2 = $watcher->parse_argv();
    is_deeply $opts2{path}, [];
};

subtest '-e' => sub {
    my %opts = $watcher->parse_argv(qw(lib t -e echo Hello world));
    is_deeply $opts{exec}, [qw/echo Hello world/];
};

subtest '--exec' => sub {
    my %opts = $watcher->parse_argv(qw(lib --exec echo Hello world));
    is_deeply $opts{exec}, [qw/echo Hello world/];
};

subtest 'others' => sub {
    my %opts = $watcher->parse_argv(qw(-h -q -p));
    ok $opts{help},  'help';
    ok $opts{quiet}, 'quiet';
    ok $opts{pipe},  'pipe';
};

done_testing;
