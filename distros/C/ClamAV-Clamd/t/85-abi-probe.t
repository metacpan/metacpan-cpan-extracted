use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp ();
use ClamAV::Clamd;
use FakeClamd;

# Every entry of the C ABI, driven through the table the way a consumer
# drives it, including the refusals and the no-handle answers.

plan skip_all => 'needs UNIX sockets' unless ClamAV::Clamd::_sun_path_max();

my $dir = File::Temp->newdir();
my $file = "$dir/f.bin";
{
    open my $fh, '>:raw', $file or die $!;
    print {$fh} 'q' x 70_000;
    close $fh;
}

sub probe { my %r = ClamAV::Clamd::_abi_probe({ @_ }); return \%r }

sub exception {
    my ($code) = @_;
    my $err;
    { local $@; eval { $code->(); 1 } or $err = $@; }
    return defined $err ? $err : '';
}

# --- no handle at all -------------------------------------------------------------
{
    my @null = ClamAV::Clamd::_abi_probe({ null => 1 });
    is_deeply \@null, [-1, 0, 1, 1, 3, 1, 1, 1, 0, 1, 1],
        'without a handle: no socket, wants nothing, is done, an error verdict with no strings, no transport, and no scan from no target';
}

# --- targets refused ------------------------------------------------------------------
like exception(sub { ClamAV::Clamd::_abi_selftest(undef, 'x') }),
    qr/need a socket path/, 'the selftest needs a socket path';
like exception(sub { ClamAV::Clamd::_abi_selftest('/tmp/' . ('x' x 200), 'x') }),
    qr/target_new failed/, '  and a target it can make';
is probe()->{target}, 0, 'no address is refused';
is probe(socket => '/x', host => 'h')->{target}, 0, 'both addresses are refused';
is probe(socket => '/tmp/' . ('x' x 200))->{target}, 0, 'a socket path too long for sockaddr_un is refused';

# --- bytes, blocking -----------------------------------------------------------------------
{
    my $srv = FakeClamd->new(mode => 'literal', literal => 'stream: Eicar-Test-Signature FOUND');
    my $r = probe(socket => $srv->path, bytes => 'anything');
    is $r->{target}, 1, 'a target';
    is $r->{state}, 1, '  infected';
    is $r->{signature}, 'Eicar-Test-Signature', '  with the signature and its length';
    is $r->{reason}, undef, '  no reason';
    is $r->{error}, undef, '  no error';
    is $r->{transport}, 2, '  over instream';
    is $r->{finished}, 1, '  finished';
    $r = probe(socket => $srv->path, bytes => 'anything', nolen => 1);
    is $r->{signature}, 'Eicar-Test-Signature', 'the signature without asking for its length';
    $srv->stop;

    $srv = FakeClamd->new(mode => 'literal', literal => 'stream: Heuristics.Encrypted.Zip FOUND');
    $r = probe(socket => $srv->path, bytes => 'x');
    is $r->{state}, 2, 'unscannable';
    is $r->{reason}, 'Encrypted', '  with the reason and its length';
    is probe(socket => $srv->path, bytes => 'x', nolen => 1)->{reason}, 'Encrypted',
        '  and without the length';
    $srv->stop;
}

# --- the limits -----------------------------------------------------------------------------
{
    my $srv = FakeClamd->new(mode => 'ok');
    my $r = probe(socket => $srv->path, bytes => 'x' x 10, max_size => 5);
    is $r->{state}, 2, 'bytes over max_size are unscannable';
    is $r->{reason}, 'max_size', '  for the local ceiling';
    is $r->{error}, 'larger than max_size; refused without scanning', '  with the error and its length';
    is probe(socket => $srv->path, bytes => 'x' x 10, max_size => 5, nolen => 1)->{error},
        'larger than max_size; refused without scanning', '  and without the length';
    is probe(socket => $srv->path, bytes => 'x' x 10, max_size => 10)->{state}, 0,
        'bytes at max_size scan';
    $r = probe(socket => $srv->path, bytes => 'x', reply_max => 3);
    is $r->{state}, 3, 'a reply over reply_max is an error';
    like $r->{error}, qr/ceiling/, '  naming the ceiling';
    is probe(socket => $srv->path, bytes => 'x' x 100, chunk => 7)->{state}, 0, 'a chunk size is taken';
    $srv->stop;
}

# --- a target that cannot be reached, and one that does not answer ---------------------------
{
    my $r = probe(socket => '/tmp/cc-abi-nothing.sock', bytes => 'x');
    is $r->{state}, 3, 'nothing listening is an error';
    like $r->{error}, qr/connect/, '  from the connect';
    is $r->{finished}, 1, '  and finished';

    my $srv = FakeClamd->new(mode => 'stall');
    $r = probe(socket => $srv->path, bytes => 'x', connect_timeout => 1, reply_timeout => 0.2);
    is $r->{state}, 3, 'a peer that never answers is an error';
    like $r->{error}, qr/timed out/, '  from the timeout';
    $srv->stop;
}

# --- over TCP ----------------------------------------------------------------------------------
{
    my $srv = FakeClamd->new(mode => 'ok', tcp => 1);
    my $r = probe(host => $srv->host, port => $srv->port, bytes => 'x');
    is $r->{state}, 0, 'clean over TCP';
    is $r->{transport}, 2, '  over instream';
    open my $fh, '<:raw', $file or die $!;
    $r = probe(host => $srv->host, port => $srv->port, fd => fileno $fh);
    is $r->{state}, 0, 'a descriptor over TCP';
    is $r->{transport}, 2, '  is streamed';
    close $fh;
    $srv->stop;

    $r = probe(host => '127.0.0.1', port => 0, bytes => 'x', connect_timeout => 0.5);
    ok defined $r->{state}, 'port 0 means the default port, whatever answers there';

    $srv = FakeClamd->new(mode => 'ok', tcp => 1);
    is probe(socket => undef, host => $srv->host, port => $srv->port, bytes => 'x')->{state}, 0,
        'a socket given as undef leaves the host to connect to';
    $srv->stop;
}

# --- descriptors ------------------------------------------------------------------------------------
{
    my $srv = FakeClamd->new(mode => 'ok');
    open my $fh, '<:raw', $file or die $!;
    my $r = probe(socket => $srv->path, fd => fileno $fh);
    is $r->{state}, 0, 'a descriptor over a UNIX socket';
    is $r->{transport}, (ClamAV::Clamd->have_fd_passing ? 1 : 2), '  is passed where the platform allows';

    $r = probe(socket => $srv->path, fd => -1);
    is $r->{state}, 3, 'a bad descriptor is an error';
    like $r->{error}, qr/fstat/, '  from fstat';

    pipe(my $p, my $w) or die $!;
    $r = probe(socket => $srv->path, fd => fileno $p);
    is $r->{state}, 3, 'a pipe is an error';
    like $r->{error}, qr/not a regular file/, '  since it is not a regular file';
    close $p; close $w;

    $r = probe(socket => $srv->path, fd => fileno $fh, max_size => 1);
    is $r->{state}, 2, 'a file over max_size is unscannable';
    is $r->{reason}, 'max_size', '  for the local ceiling';
    is probe(socket => $srv->path, fd => fileno $fh, max_size => 1_000_000)->{state}, 0,
        '  and one under it scans';
    is probe(socket => $srv->path, fd => fileno $fh, bytes => undef)->{state}, 0,
        '  as does a descriptor beside bytes given as undef';
    close $fh;

    $r = probe(
        null => 0, socket => $srv->path, host => undef, port => undef,
        connect_timeout => undef, reply_timeout => undef, reply_max => undef,
        chunk => undef, max_size => undef, fd => undef, bytes => 'x',
        async => 0, cancel => 0, nolen => 0,
    );
    is $r->{state}, 0, 'every option given as undef or false is its default';
    $srv->stop;
}

# --- driven on a loop --------------------------------------------------------------------------------
{
    my $srv = FakeClamd->new(mode => 'ok');
    my $r = probe(socket => $srv->path, bytes => 'x' x 1000, async => 1);
    cmp_ok $r->{socket}, '>=', 0, 'a started scan has a socket';
    is $r->{want}, 2, '  and wants to write';
    is $r->{done}, 0, '  and is not done';
    cmp_ok $r->{steps}, '>=', 1, '  it took steps';
    is $r->{finished}, 1, '  and finished';
    is $r->{want_after}, 0, '  wanting nothing more';
    is $r->{state}, 0, '  clean';

    open my $fh, '<:raw', $file or die $!;
    $r = probe(socket => $srv->path, fd => fileno $fh, async => 1);
    is $r->{state}, 0, 'a descriptor driven on a loop';
    is $r->{finished}, 1, '  finishes';
    close $fh;

    $r = probe(socket => $srv->path, bytes => 'x', async => 1, cancel => 1);
    is $r->{state}, 3, 'a cancelled scan is an error';
    is $r->{error}, 'scan cancelled', '  saying so';
    is $r->{steps}, 0, '  and takes no step';
    is $r->{finished}, 1, '  being finished';
    $srv->stop;
}

done_testing;
