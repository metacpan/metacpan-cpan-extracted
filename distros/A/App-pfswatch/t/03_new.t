use strict;
use warnings;
use Test::More;
use App::pfswatch;

subtest 'new' => sub {
    my $watcher = new_ok 'App::pfswatch', [ exec => [qw/ls -l/] ];
    is_deeply $watcher->{exec}, [qw/ls -l/], 'exec ok';
    is_deeply $watcher->{path}, [qw/./],     'path ok';
    is $watcher->{pipe},  0, 'pipe option is off';
    is $watcher->{quiet}, 0, 'quiet option is off';
};

subtest 'new_with_options' => sub {
    my $watcher = App::pfswatch->new_with_options(qw/--exec ls -l/);
    isa_ok $watcher, 'App::pfswatch';
    is_deeply $watcher->{exec}, [qw/ls -l/], 'exec ok';
    is_deeply $watcher->{path}, [qw/./],     'path ok';
    is $watcher->{pipe},  0, 'pipe option is off';
    is $watcher->{quiet}, 0, 'quiet option is off';
};

subtest 'execption' => sub {
    local $@;
    eval { App::pfswatch->new };
    like $@, qr/^Mandatory parameter 'exec'/, 'exec is required';
};

done_testing;
