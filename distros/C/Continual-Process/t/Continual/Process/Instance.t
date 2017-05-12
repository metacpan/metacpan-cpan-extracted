use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;

use_ok('Continual::Process::Instance');

subtest 'constructor' => sub {
    throws_ok {
        Continual::Process::Instance->new();
    } qr/name attribute required/, 'name attribute';

    throws_ok {
        Continual::Process::Instance->new(name => 'test');
    } qr/instance_id attribute required/, 'instance_id attribute';

    throws_ok {
        Continual::Process::Instance->new(name => 'test', instance_id => 1);
    } qr/code attribute required/, 'code attribute';

    throws_ok {
        Continual::Process::Instance->new(name => 'test', instance_id => 1, code => 'blabla');
    } qr/code attribute .+ CodeRef/, 'code attribute isn\'t coderef';

    done_testing(4);
};

subtest 'invalid pid' => sub {
    my $proc = Continual::Process::Instance->new(
        name        => 'test',
        instance_id => 1,
        code        => sub {
            return;
        }
    );

    throws_ok {
        $proc->start();
    } qr/^Undefined PID/, 'undefined pid';

    $proc = Continual::Process::Instance->new(
        name        => 'test',
        instance_id => 1,
        code        => sub {
            return 'invalid pid';
        }
    );

    throws_ok {
        $proc->start();
    } qr/PID .+ isn't number/, 'isn\'t number check';

    done_testing(2);
};

my $pid;
my $proc = Continual::Process::Instance->new(
    name        => 'test',
    instance_id => 1,
    code        => sub {
        if ($pid = fork) {
            return $pid;
        }

        sleep 10;

        exit 1;
    }
);

lives_ok {
    $proc->start();
} 'start';

ok($proc->is_alive(), 'process is alive');

#destroy check
undef $proc;

$proc = Continual::Process::Instance->new(
    name        => 'test',
    instance_id => 1,
    code        => sub {
        return $pid;
    }
);

ok(!$proc->is_alive(), 'proccess is death after destrcution');
