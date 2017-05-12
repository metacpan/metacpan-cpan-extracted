use strict;
use warnings;
use Test::More 0.88;
use Test::Deep;

{
    package App::Nopaste::Service::_MyTest;
    use parent 'App::Nopaste::Service';

    sub available { 1 }
    sub uri { 'test' }
    sub run {
        shift;
        my %a = @_;
        return (1, \%a);
    }
}

{
    package _MyTest::Cmd;
    use parent 'App::Nopaste::Command';

    sub read_text { 'test' }
}

cmp_deeply(
    [ App::Nopaste->plugins ],
    superbagof(
        map { 'App::Nopaste::Service::' . $_ }
            qw(Codepeek Debian Gist Mojopaste PastebinCom Pastie Shadowcat Snitch Ubuntu _MyTest ssh)
    ),
    'identified the service',
);

my $input = {
    desc => 'a test',
    nick => 'person',
    lang => 'text',
    services => ['App::Nopaste::Service::_MyTest'],
    extra_argv => []
};

my $cmd = _MyTest::Cmd->new($input);
isa_ok($cmd,'App::Nopaste::Command');

my $ret = $cmd->run;
ok(ref($ret) eq 'HASH') or diag $ret;

is($ret->{nick}, $input->{nick});
is($ret->{lang}, $input->{lang});
is($ret->{services}, $input->{services});
is($ret->{text},'test');

done_testing;

