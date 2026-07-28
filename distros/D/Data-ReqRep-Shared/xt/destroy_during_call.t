use strict;
use warnings;
use Test::More;
use Config;
use File::Temp 'tmpnam';

use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;

plan skip_all => 'fork required' unless $Config{d_fork};

# Argument magic that explicitly calls $obj->DESTROY frees the C handle
# mid-method.  Before the REEXTRACT_HANDLE fix the method dereferenced the
# freed pointer and SEGFAULTED; after it, the method must croak cleanly.
# Exit codes in the child: 0 = croaked (correct), 7 = ran on through freed
# memory (REEXTRACT removed or ineffective).

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
    [ 'Client::send' => sub {           # magic runs on payload (SvPV)
        my $cli  = Data::ReqRep::Shared::Client->new($path);
        my $evil = bless [$cli], 'Evil';
        return eval { $cli->send($evil); 1 };
    } ],
    [ 'reply' => sub {                  # magic runs on payload (SvPV)
        my $cli = Data::ReqRep::Shared::Client->new($path);
        $cli->send('x');
        my (undef, $rid) = $srv->recv;  # valid request id
        my $evil = bless [$srv], 'Evil';
        return eval { $srv->reply($rid, $evil); 1 };
    } ],
    [ 'recv_wait' => sub {              # magic runs on timeout (SvNV)
        my $evil = bless [$srv], 'Evil';
        return eval { $srv->recv_wait($evil); 1 };
    } ],
    [ 'drain' => sub {                  # magic runs on max_count (SvUV)
        my $evil = bless [$srv], 'Evil';
        return eval { $srv->drain($evil); 1 };
    } ],
);

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
