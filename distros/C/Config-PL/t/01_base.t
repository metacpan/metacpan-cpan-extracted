use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use Cwd;

BEGIN { use_ok 'Config::PL' }

subtest 'dirname(__FILE__)' => sub {
    my $config = config_do 'config/ok.pl';
    isa_ok $config, 'HASH';
    is $config->{ok}, 1;
};

subtest 'Cwd' => sub {
    my $config = config_do 't/config/ok.pl';
    isa_ok $config, 'HASH';
    is $config->{ok}, 1;
};

subtest 'Abs' => sub {
    my $cwd = getcwd;
    my $abs = File::Spec->catfile($cwd, qw/t config ok.pl/);
    my $config = config_do $abs;
    isa_ok $config, 'HASH';
    is $config->{ok}, 1;
};

subtest 'Nest' => sub {
    my $config = config_do 'config/nest.pl';
    isa_ok $config, 'HASH';
    is $config->{ok}, 1;
};

subtest 'INC' => sub {
    my @orig_inc = @INC;
    local @INC = (@orig_inc, 't/dummy');
    my $dummy = do 'config/ok.pl';
    isa_ok $dummy, 'HASH';
    is $dummy->{ok}, 0;

    my $config = config_do 'config/ok.pl';
    isa_ok $config, 'HASH';
    is $config->{ok}, 1;
};

subtest 'invalid config' => sub {
    local $@;
    eval {
        config_do 'config/ng.pl';
    };
    ok $@;
};

subtest 'file not found' => sub {
    local $@;
    eval {
        config_do 'config/blahblah.pl';
    };
    ok $@;
};

done_testing;
