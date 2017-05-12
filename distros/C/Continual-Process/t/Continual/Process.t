use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;

use_ok('Continual::Process');

subtest 'constructor' => sub {
    throws_ok {
        Continual::Process->new();
    } qr/name attribute required/, 'name attribute';

    throws_ok {
        Continual::Process->new(name => 'test');
    } qr/code attribute required/, 'code attribute';

    throws_ok {
        Continual::Process->new(name => 'test', code => 'blabla');
    } qr/code attribute .+ CodeRef/, 'code attribute isn\'t coderef';
};

subtest 'default instances' => sub {
    my $proc = Continual::Process->new(
        name => 'test',
        code => sub { },
    );

    my @instances = $proc->create_instance();

    is(scalar @instances, 1, 'count of instances');
    isa_ok($instances[0], 'Continual::Process::Instance');
};

subtest 'more instances' => sub {
    my $proc = Continual::Process->new(
        name        => 'test',
        code        => sub { },
        instances   => 10,
    );

    my @instances = $proc->create_instance();

    is(scalar @instances, 10, 'count of instances');
    isa_ok($instances[0], 'Continual::Process::Instance');
};
