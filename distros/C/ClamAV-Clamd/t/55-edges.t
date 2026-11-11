use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);
use ClamAV::Clamd;
use FakeClamd;

# The edges of the stream and the reply parser, each provoked from a peer
# this file controls.

plan skip_all => 'needs UNIX sockets' unless ClamAV::Clamd::_sun_path_max();

sub drive {
    my ($s) = @_;
    my $guard = 0;
    until ($s->is_done) {
        die 'drive() ran away' if ++$guard > 100_000;
        my $fd = $s->fd;
        if (defined $fd) {
            my $set = '';
            vec($set, $fd, 1) = 1;
            ($s->want // '') eq 'read'
                ? select($set, undef, undef, 0.5)
                : select(undef, $set, undef, 0.5);
        }
        $s->step;
    }
    return $s;
}

# --- reply shapes at the edge of the parser ------------------------------------------
for my $case (
    ["stream: OK\r\n",                              'clean',       undef,   undef,       'a reply with a carriage return and newline before the terminator'],
    ['OK',                                          'clean',       undef,   undef,       'a bare OK'],
    ['NO',                                          'error',       undef,   undef,       'two letters that are not OK'],
    ["\n",                                          'error',       undef,   undef,       'a newline and nothing else'],
    ['a:b Eicar FOUND',                             'infected',    'a:b Eicar', undef,   'a colon not followed by a space does not cut the signature'],
    ['Eicar FOUND',                                 'infected',    'Eicar', undef,       'a FOUND with no description before the signature'],
    ['stream:  FOUND',                              'infected',    undef,   undef,       'a FOUND with an empty signature'],
    ['fd[1]: Heuristics.Limits.Exceeded. FOUND',    'unscannable', 'Heuristics.Limits.Exceeded.', undef, 'a limit with no name after the family'],
) {
    my ($reply, $state, $sig, $reason, $label) = @$case;
    my $srv = FakeClamd->new(mode => 'literal', literal => $reply);
    my $c   = ClamAV::Clamd->new(socket => $srv->path);
    my $v   = $c->scan('x');
    is $v->state, $state, $label;
    is $v->signature, $sig, '  signature';
    is $v->reason, $reason, '  reason';
    $srv->stop;
}

# --- a peer gone before the command is sent ------------------------------------------
# start_scan connects and sends nothing, so the peer can close first.
{
    my $flag = "/tmp/cc-slam-$$.flag";
    unlink $flag;
    my $srv = FakeClamd->new(mode => 'slam', flag => $flag);
    my $c   = ClamAV::Clamd->new(socket => $srv->path, reply_timeout => 5);
    my $s   = $c->start_scan('x');
    ok !$s->is_done, 'the scan is connected and waiting';
    my $waited = 0;
    select undef, undef, undef, 0.02 until -e $flag or ++$waited > 250;
    ok -e $flag, 'the peer has hung up';
    drive($s);
    is $s->verdict->state, 'error', 'the command cannot be sent';
    like $s->verdict->error, qr/send/, '  and the failure names the send';
    unlink $flag;
    $srv->stop;
}

# --- the deadline, checked on entry to a step ------------------------------------------
{
    my $srv = FakeClamd->new(mode => 'stall');
    my $c   = ClamAV::Clamd->new(socket => $srv->path, reply_timeout => 0.01);
    my $s   = $c->start_scan('x');
    select undef, undef, undef, 0.05;
    ok $s->step, 'a step after the deadline finishes the scan';
    is $s->verdict->state, 'error', '  as an error';
    like $s->verdict->error, qr/deadline/, '  naming the deadline';
    ok $s->step, 'a step after that is still finished';
    is exception(sub { $s->cancel }), '', 'cancel after the end is harmless';
    ok $s->is_done, '  and it stays finished';
    is $s->verdict->state, 'error', '  with the verdict it had';
    $srv->stop;
}

# --- the verdict is built once ----------------------------------------------------------
{
    my $srv = FakeClamd->new(mode => 'literal', literal => 'stream: Eicar-Test-Signature FOUND');
    my $c   = ClamAV::Clamd->new(socket => $srv->path);
    my $s   = drive($c->start_scan('x'));
    is $s->verdict->state, 'infected', 'the first verdict';
    is $s->verdict->signature, 'Eicar-Test-Signature', '  and the second is the same one';
    $srv->stop;
}

# --- a scan waiting for the reply wants to read -----------------------------------------
{
    my $srv = FakeClamd->new(mode => 'stall');
    my $c   = ClamAV::Clamd->new(socket => $srv->path, reply_timeout => 60);
    my $s   = $c->start_scan('x');
    ok !$s->step, 'a small stream goes out in one step';
    is $s->want, 'read', '  and the scan then wants to read';
    $s->cancel;
    $srv->stop;
}

# --- bytes under max_size are started ------------------------------------------------------
{
    my $srv = FakeClamd->new(mode => 'ok');
    my $c   = ClamAV::Clamd->new(socket => $srv->path, max_size => 10);
    is drive($c->start_scan('four'))->verdict->state, 'clean', 'bytes under max_size scan';
    $srv->stop;
}

# --- a source that cannot be read ---------------------------------------------------------
# Over TCP a descriptor is streamed, and a pipe with nothing in it and
# nobody blocking on it reads as an error rather than waiting forever.
{
    my $srv = FakeClamd->new(mode => 'ok', tcp => 1);
    my $c   = ClamAV::Clamd->new($srv->target);
    pipe(my $r, my $w) or die $!;
    my $fl = fcntl($r, F_GETFL, 0);
    fcntl($r, F_SETFL, $fl | O_NONBLOCK) or die "fcntl: $!";
    my $s = drive($c->start_scan($r, 'fd'));
    is $s->verdict->state, 'error', 'a source that cannot be read ends the scan';
    like $s->verdict->error, qr/read/, '  naming the read';
    close $r; close $w;
    $srv->stop;
}

# --- small chunks, large payload, over both transports -------------------------------------
{
    my $srv = FakeClamd->new(mode => 'ok', tcp => 1);
    my $c   = ClamAV::Clamd->new($srv->target, chunk => 1);
    is $c->scan('x' x 20_000)->state, 'clean', 'twenty thousand one-byte chunks over TCP';
    $srv->stop;

    $srv = FakeClamd->new(mode => 'ok');
    $c   = ClamAV::Clamd->new(socket => $srv->path, chunk => 7);
    is $c->scan('x' x 20_000)->state, 'clean', 'and seven-byte chunks over a UNIX socket';
    $srv->stop;
}

# --- a socket full at every position in the stream ---------------------------------------------
# One-byte chunks, so every fifth byte starts a header, and a peer that
# stops reading a different number of bytes in on each connection: the
# client meets the full socket on a header and on a payload byte alike,
# and sees the hangup that follows as a stream cut off without a verdict.
{
    my $srv = FakeClamd->new(mode => 'drip');
    my $c   = ClamAV::Clamd->new(socket => $srv->path, chunk => 1, reply_timeout => 10);
    my @states;
    for my $n (1 .. 10) {
        my $s = drive($c->start_scan('d' x 100_000));
        push @states, $s->verdict->state . '/' . ($s->verdict->reason // '-');
    }
    is_deeply \@states, [('unscannable/StreamMaxLength') x 10],
        'ten streams stopped a byte apart are each cut off without a verdict';
    $srv->stop;
}

# --- a stream the peer stops reading --------------------------------------------------------
{
    my $srv = FakeClamd->new(mode => 'stall');
    my $c   = ClamAV::Clamd->new(socket => $srv->path, reply_timeout => 60);
    my $s   = $c->start_scan('x' x (4 * 1024 * 1024));
    my $steps = 0;
    $steps++ until $s->want eq 'write' && $steps > 2 or $s->step or $steps > 1000;
    is $s->want, 'write', 'a stream nobody reads wants to write';
    $s->cancel;
    is $s->verdict->state, 'error', '  and cancelled is an error';
    like $s->verdict->error, qr/cancelled/, '  saying so';
    $srv->stop;
}

sub exception {
    my ($code) = @_;
    my $err;
    { local $@; eval { $code->(); 1 } or $err = $@; }
    return defined $err ? $err : '';
}

done_testing;
