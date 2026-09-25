use strict;
use warnings;
use Test::More;
use Config;
use File::Temp 'tmpnam';
use Time::HiRes ();

use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;

plan skip_all => 'fork required' unless $Config{d_fork};

{
    package Evil;
    use overload
        '""' => sub { $_[0][0]->DESTROY; 'k' },
        '0+' => sub { $_[0][0]->DESTROY; 0 },
        fallback => 1;
}

my $path = tmpnam();
my $srv  = Data::ReqRep::Shared->new($path, 8, 4, 256);

my @cases = (
    [ 'Client::send' => sub {
        my $cli  = Data::ReqRep::Shared::Client->new($path);
        my $evil = bless [$cli], 'Evil';
        return eval { $cli->send($evil); 1 };
    } ],
    [ 'reply' => sub {
        my $cli = Data::ReqRep::Shared::Client->new($path);
        $cli->send('x');
        my (undef, $rid) = $srv->recv;
        my $evil = bless [$srv], 'Evil';
        return eval { $srv->reply($rid, $evil); 1 };
    } ],
    [ 'recv_wait' => sub {
        my $evil = bless [$srv], 'Evil';
        return eval { $srv->recv_wait($evil); 1 };
    } ],
    [ 'drain' => sub {
        my $evil = bless [$srv], 'Evil';
        return eval { $srv->drain($evil); 1 };
    } ],
);

# A signal interrupts the wait and the payload is read again: that second read destroys the handle.
{
    package Late;
    use overload '""' => sub { $_[0]{cli}->DESTROY if ++$_[0]{n} == 2; 'k' }, fallback => 1;
}
for my $meth (qw(send_wait send_wait_notify req req_wait)) {
    push @cases, [ "Client::$meth after a signal" => sub {
        my $s = Data::ReqRep::Shared->new(undef, 2, 8, 64);
        my $cli = Data::ReqRep::Shared::Client->new_from_fd($s->memfd);
        if ($meth =~ /^send_wait/) { $cli->send("fill$_") for 1 .. 2 }
        my $late = bless { n => 0, cli => $cli }, 'Late';
        local $SIG{ALRM} = sub {};
        Time::HiRes::ualarm(100_000);
        return eval { $cli->$meth($late, $meth eq 'req' ? () : 1); 1 };
    } ];
}

for my $case (@cases) {
    my ($method, $code) = @$case;
    my $pid = fork();
    die "fork failed: $!" unless defined $pid;
    unless ($pid) {
        my $ok = $code->();
        exit($ok ? 7 : 0);
    }
    waitpid($pid, 0);
    my $st = $?;
    ok !($st & 127), "$method: no crash when argument magic destroys the handle"
        or diag sprintf('died with signal %d', $st & 127);
    is $st >> 8, 0, "$method: croaks instead of using the freed handle";
}

$srv->unlink;
done_testing;
