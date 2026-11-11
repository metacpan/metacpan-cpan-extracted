use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use ClamAV::Clamd;
use FakeClamd;

# The object is a hash, and the C side reads it as one: anything blessed
# into the class with the right keys works, every key it lacks takes the
# default, and anything that is not a hash reference is refused by name.

plan skip_all => 'needs UNIX sockets' unless ClamAV::Clamd::_sun_path_max();

sub exception {
    my ($code) = @_;
    my $err;
    { local $@; eval { $code->(); 1 } or $err = $@; }
    return defined $err ? $err : '';
}

# --- not an object ---------------------------------------------------------
{
    my %arity = (
        ping => 1, version => 1, stats => 1, reload => 1, error => 1,
        error_code => 1, transport => 1, scan_fd => 2, scan_path => 2,
        scan => 2, start_scan => 2,
    );
    for my $m (sort keys %arity) {
        my @args = ('x') x $arity{$m};
        like exception(sub { ClamAV::Clamd->can($m)->(@args) }),
            qr/ClamAV::Clamd::$m: not a ClamAV::Clamd object/,
            "$m refuses a plain string";
        like exception(sub { ClamAV::Clamd->can($m)->([], @args[1 .. $#args]) }),
            qr/not a ClamAV::Clamd object/, "  and an array reference";
    }

    for my $m (qw(state is_clean is_infected is_unscannable is_error
                  signature reason transport error raw)) {
        like exception(sub { ClamAV::Clamd::Verdict->can($m)->('x') }),
            qr/not a verdict/, "Verdict::$m refuses a plain string";
        like exception(sub { ClamAV::Clamd::Verdict->can($m)->([]) }),
            qr/not a verdict/, "  and an array reference";
    }
    like exception(sub { ClamAV::Clamd::Verdict->can('(bool')->('x') }),
        qr/not a verdict/, 'the bool overload too';

    for my $m (qw(fd want step is_done verdict cancel)) {
        like exception(sub { ClamAV::Clamd::Scan->can($m)->('x') }),
            qr/not a scan handle/, "Scan::$m refuses a plain string";
        like exception(sub { ClamAV::Clamd::Scan->can($m)->([]) }),
            qr/not a scan handle/, "  and an array reference";
    }
    is exception(sub { ClamAV::Clamd::Scan->can('DESTROY')->('x') }), '',
        'Scan::DESTROY on a plain string is a no-op, since a destructor must not die';
    is exception(sub { ClamAV::Clamd::Scan->can('DESTROY')->([]) }), '',
        '  nor on an array reference';
}

# --- a bare hash takes the defaults ----------------------------------------
{
    my $srv = FakeClamd->new(mode => 'ok');

    my $bare = bless { socket => $srv->path }, 'ClamAV::Clamd';
    ok $bare->ping, 'a hash holding only the socket pings on the defaults'
        or diag $bare->error;
    is $bare->error, undef, '  and has no error';
    is $bare->error_code, undef, '  nor a code';
    is $bare->transport, undef, '  nor a transport, having scanned nothing';

    my $undefs = bless {
        socket => $srv->path, host => undef, port => undef,
        connect_timeout => undef, reply_timeout => undef, reply_max => undef,
        chunk => undef, max_size => undef, frame => undef,
    }, 'ClamAV::Clamd';
    ok $undefs->ping, 'every setting given as undef falls back to its default'
        or diag $undefs->error;

    my $zero = bless { socket => $srv->path, reply_timeout => 0, reply_max => 0 },
        'ClamAV::Clamd';
    ok $zero->ping, 'a zero reply timeout and ceiling fall back as well'
        or diag $zero->error;
    is $zero->scan('x')->state, 'clean', '  for a scan too';

    my $blank = bless { error => undef, error_code => undef, transport => undef }, 'ClamAV::Clamd';
    is $blank->error, undef, 'an error slot holding undef reads as no error';
    is $blank->error_code, undef, '  and so does the code';
    is $blank->transport, undef, '  and the transport';

    my $tcp = FakeClamd->new(mode => 'ok', tcp => 1);
    my $hosted = bless { socket => undef, host => $tcp->host, port => $tcp->port }, 'ClamAV::Clamd';
    ok $hosted->ping, 'a socket slot holding undef leaves the host to connect to' or diag $hosted->error;
    $tcp->stop;

    my $none = bless {}, 'ClamAV::Clamd';
    ok !$none->ping, 'a hash with no address cannot connect';
    is $none->error_code, ClamAV::Clamd::ERR_CONFIG, '  reported as a config error';
    like $none->error, qr/no socket path and no host/, '  saying so';

    my $long = bless { socket => '/tmp/' . ('x' x 200) }, 'ClamAV::Clamd';
    ok !$long->ping, 'a socket path too long for sockaddr_un is refused at connect';
    is $long->error_code, ClamAV::Clamd::ERR_CONFIG, '  as a config error';
    like $long->error, qr/too long/, '  naming the problem';

    $srv->stop;
}

# --- the constructor's own edges ---------------------------------------------
{
    ok +ClamAV::Clamd->new(host => 'x', frame => undef), 'frame => undef means the default';
    ok +ClamAV::Clamd->new(host => 'x', socket => undef), 'socket => undef beside a host is one address';
    ok +ClamAV::Clamd->new(socket => '/tmp/x.sock', host => undef), 'host => undef beside a socket is too';
    like exception(sub { ClamAV::Clamd->new(host => 'x', frame => 'zz') }),
        qr/frame must be/, 'a two-letter frame croaks';
    like exception(sub { ClamAV::Clamd->new(host => 'x', connect_timeout => undef) }),
        qr/connect_timeout must be a positive number/, 'an undef timeout croaks';
    is +ClamAV::Clamd->new(host => 'x', port => 1234)->{port}, 1234, 'a given port is kept';
}

# --- the error is per command ------------------------------------------------
{
    my $srv = FakeClamd->new(mode => 'ok');
    my $c   = ClamAV::Clamd->new(socket => '/tmp/cc-not-here-either.sock');
    ok !$c->ping, 'a failed ping';
    ok defined $c->error, '  leaves an error';
    $c->{socket} = $srv->path;
    ok $c->ping, 'a ping that works';
    is $c->error, undef, '  clears it';
    is $c->error_code, undef, '  and the code';
    $srv->stop;
}

# --- a verdict is a hash too ---------------------------------------------------
{
    my $v = bless {}, 'ClamAV::Clamd::Verdict';
    is $v->state, undef, 'an empty verdict has no state';
    ok !$v->is_clean, '  and is not clean';
    ok !$v->is_infected, '  nor infected';
    ok !$v->is_unscannable, '  nor unscannable';
    ok !$v->is_error, '  nor even an error, having no state at all';
    is $v->signature, undef, '  no signature';
    is $v->reason, undef, '  no reason';
    is $v->transport, undef, '  no transport';
    is $v->error, undef, '  no error';
    is $v->raw, undef, '  no raw reply';
    ok !$v, '  and is false';
    is "$v", 'error', '  but stringifies as error, the safe reading';
    is +ClamAV::Clamd::Verdict->can('()')->(), undef,
        'the overload marker method answers undef';
}

# --- the verdict fields that are undef on one side or the other ----------------
{
    my $srv = FakeClamd->new(mode => 'ok');
    my $c   = ClamAV::Clamd->new(socket => $srv->path);
    my $v   = $c->scan('bytes');
    is $v->state, 'clean', 'a clean verdict';
    is $v->signature, undef, '  has no signature';
    is $v->reason, undef, '  no reason';
    is $v->error, undef, '  no error';
    is $v->transport, 'instream', '  the transport it used';
    is $v->raw, 'stream: OK', '  and the raw reply';
    is $c->transport, 'instream', 'the client remembers the transport';

    my $r = $c->scan_fd(undef);
    is $r->state, 'error', 'a refused descriptor is an error';
    is $r->transport, undef, '  with no transport';
    is $r->raw, undef, '  no raw reply';
    like $r->error, qr/scan_fd needs/, '  and the reason';
    is $c->transport, undef, '  and the client has no transport either';
    $srv->stop;
}

# --- a scan handle is a hash too -----------------------------------------------
for my $h (bless({}, 'ClamAV::Clamd::Scan'), bless({ _ptr => 'abc' }, 'ClamAV::Clamd::Scan')) {
    my $what = exists $h->{_ptr} ? 'a handle whose pointer is not a number' : 'an empty handle';
    is $h->fd, undef, "$what has no descriptor";
    is $h->want, undef, '  wants nothing';
    ok $h->step, '  is finished when stepped';
    ok $h->is_done, '  and says so';
    is $h->verdict, undef, '  but has no verdict';
    is exception(sub { $h->cancel }), '', '  cancel is harmless';
    is exception(sub { undef $h }), '', '  and so is letting it go';
}

done_testing;
