use strict;
use warnings;
use utf8;
use Test::More;

my $class = 'App::RunCron::Reporter';
use_ok $class;
ok $class->can('new');
ok $class->can('run');
eval { $class->run };
like $@, qr/abstract/;

for my $reporter (qw/Stdout File None/) {
    my $class = "App::RunCron::Reporter::$reporter";
    use_ok $class;
    ok $class->can('new');
    ok $class->can('run');
}

done_testing;
