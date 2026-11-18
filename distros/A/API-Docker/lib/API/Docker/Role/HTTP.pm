package API::Docker::Role::HTTP;
# ABSTRACT: HTTP transport role for Docker Engine API
our $VERSION = '0.006';
use Moo::Role;
use IO::Socket::UNIX;
use IO::Socket::INET;
# For the sysread method on a plain filehandle: _pull calls it as a method so
# that IO::Socket::SSL's own gets picked up rather than the builtin. See _pull.
use IO::Handle;
use Socket qw( SOL_SOCKET SO_RCVTIMEO );
# How a read that delivered nothing says it ran out of time rather than out of
# stream (EAGAIN/EWOULDBLOCK), and how it says it was interrupted rather than
# either (EINTR). See _pull and _timed_out.
use Errno qw( EAGAIN EWOULDBLOCK EINTR );
use JSON::MaybeXS qw( encode_json decode_json );
use Scalar::Util qw( looks_like_number );
use Path::Tiny;
use Carp qw( croak shortmess );
use Log::Any qw( $log );
use API::Docker::Error::HTTP;
use API::Docker::Error::Stream;
use API::Docker::Error::Timeout;
use API::Docker::Error::Truncated;
use namespace::clean;


requires 'host';
requires 'api_version';
requires 'tls';
requires 'cert_path';
requires 'tls_insecure';

# Docker stream frame types, indexed by the first byte of the frame header.
my @STREAM_TYPE = qw( stdin stdout stderr );

# A field name is an RFC 9110 token and nothing else. Anything outside this
# set -- CR, LF, a space, a colon -- is rejected rather than stripped; see
# _assert_header_name.
my $HEADER_NAME = qr/\A[0-9A-Za-z!#\$%&'*+.^_`|~-]+\z/;

# The request-target path is caller data -- a container name, an image
# reference -- spliced straight into the request line as /v$version$path, so a
# byte the line's own grammar reads rewrites the request rather than naming a
# resource: CR or LF ends the line, a space opens the HTTP-version field, and
# a ? or # opens the query or fragment. It is held to the RFC 3986 origin-form
# path character set -- unreserved, the sub-delims, and : @ % / -- and
# rejected, not sanitised, for the reason a header name is (see
# _assert_request_path). Query parameters carry the ? and everything after it
# and are assembled separately below, each element run through _uri_encode.
my $REQUEST_PATH = qr{\A[A-Za-z0-9\-._~:/\@!\$&'()*+,;=%]*\z};

# The three units a response can be cut into, one option each. A request picks
# one of them, or none and gets the buffered path; see _stream_handler.
my @STREAM_OPTION = qw( on_event on_frame on_chunk );

# What a response body has to start with to be worth handing to decode_json.
# An object or an array is not the whole of JSON: the engine answers several
# endpoints with a bare JSON scalar, and a `null` used to come back as the
# four-character string 'null'. See _request.
my $JSON_BODY = qr/\A\s*(?:[\[\{"]|-?[0-9]|true|false|null)/;

# How much is asked for per sysread. Strictly an upper bound -- sysread
# returns what has arrived rather than filling to it (see _pull), so on a live
# feed a call typically comes back with one burst, and asking for 64K costs
# nothing but the size of the buffer it lands in.
my $READ_SIZE = 64 * 1024;

has read_timeout => (
  is => 'ro',
);


has connect_timeout => (
  is => 'ro',
);


has _socket => (
  is      => 'lazy',
  clearer => '_clear_socket',
);

# The connect timeout and the endpoint it belongs to, on their way to
# _build__socket. It is a lazy builder and so cannot be handed an argument,
# and the value is per request rather than per client -- hence rw, with
# _reconnect as the only writer, setting it immediately before the build and
# clearing it immediately after. Unset is the whole of the old behaviour: no
# Timeout on any constructor, and the plain croak on a failure.
has _pending_connect => (
  is       => 'rw',
  init_arg => undef,
);

sub _build__socket {
  my ($self) = @_;
  my $host    = $self->host;
  my $pending = $self->_pending_connect;
  my $timeout = $pending ? $pending->{timeout} : undef;

  if ($host =~ m{^unix://(.+)$}) {
    my $path = $1;
    $log->debugf("Connecting to Unix socket: %s", $path);
    my $sock = IO::Socket::UNIX->new(
      Peer => $path,
      Type => SOCK_STREAM,
      $timeout ? (Timeout => $timeout) : (),
    );
    unless ($sock) {
      # Asked before anything else can touch $@ or $!, which is the whole of
      # the evidence; see _connect_expired.
      $self->_croak_connect_timeout($pending, 'unix://' . $path)
        if $self->_connect_expired($timeout);
      croak "Cannot connect to Unix socket $path: $!";
    }
    return $sock;
  }
  elsif ($host =~ m{^tcp://([^:]+):(\d+)$}) {
    my ($addr, $port) = ($1, $2);

    unless ($self->tls) {
      $log->debugf("Connecting to TCP %s:%s", $addr, $port);
      my $sock = IO::Socket::INET->new(
        PeerAddr => $addr,
        PeerPort => $port,
        Proto    => 'tcp',
        $timeout ? (Timeout => $timeout) : (),
      );
      unless ($sock) {
        $self->_croak_connect_timeout($pending, $addr . ':' . $port)
          if $self->_connect_expired($timeout);
        croak "Cannot connect to $addr:$port: $!";
      }
      return $sock;
    }

    # Built before the connection is opened: a cert_path that names nothing,
    # or half a client certificate, is a configuration mistake and the caller
    # should hear about it as one rather than as a handshake failure.
    my %ssl = $self->_ssl_options($addr);

    $log->debugf("Connecting to TCP %s:%s over TLS (verification %s)",
      $addr, $port, $self->tls_insecure ? 'off' : 'on');
    my $sock = IO::Socket::SSL->new(
      PeerAddr => $addr,
      PeerPort => $port,
      Proto    => 'tcp',
      $timeout ? (Timeout => $timeout) : (),
      %ssl,
    );
    unless ($sock) {
      $self->_croak_connect_timeout($pending, $addr . ':' . $port . ' (TLS)')
        if $self->_connect_expired($timeout);
      # $SSL_ERROR carries the handshake failure -- an untrusted certificate,
      # a name that does not match -- and $! the plain connect failure. Both
      # are named because either can be the one that happened. The pragma is
      # for the package variable of a module that is not loaded at compile
      # time, which perl would otherwise report as a probable typo.
      no warnings 'once';
      croak 'Cannot connect to ' . $addr . ':' . $port . ' over TLS: '
        . ($IO::Socket::SSL::SSL_ERROR || $! || 'unknown error');
    }
    return $sock;
  }
  else {
    croak "Unsupported host format: $host (expected unix:// or tcp://)";
  }
}

# Loaded here rather than with the other modules at the top of the file.
# IO::Socket::SSL pulls in Net::SSLeay, which is XS compiled against libssl,
# and the unix:// transport -- local Docker, rootless Podman, the default and
# the only one most installations use -- never needs a byte of it. A hard
# dependency would make this client unbuildable on a machine with no OpenSSL
# headers for the sake of a transport it is not using, so it is a recommended
# one and this is the point where its absence becomes an error.
sub _load_ssl {
  my ($self) = @_;

  return 1 if eval { require IO::Socket::SSL; 1 };
  my $why = $@ || 'unknown error';
  $why =~ s/\s+\z//;
  croak __PACKAGE__ . ': tls => 1 needs IO::Socket::SSL, which failed to '
    . 'load (' . $why . '). It is a recommended rather than a required '
    . 'dependency because the unix:// transport never uses it -- install it '
    . 'with `cpanm IO::Socket::SSL` (or `cpanm --with-recommends '
    . 'API::Docker`)';
}

# The IO::Socket::SSL arguments for this client, as a plain hash, so the
# policy can be read off without opening a connection.
sub _ssl_options {
  my ($self, $addr) = @_;

  $self->_load_ssl;

  # SNI, sent whether or not the certificate is checked: a terminator serving
  # several names needs it to pick the right one, and that is true of an
  # unverified connection too.
  my %ssl = ( SSL_hostname => $addr );

  if ($self->tls_insecure) {
    # Everything below is off deliberately, and the attribute that got us here
    # says so in its name. Encryption without verification stops a passive
    # listener and nothing else: whoever answers the connection chooses the
    # certificate, so anyone able to redirect it reads and rewrites the
    # traffic -- credentials, image contents, container commands.
    $ssl{SSL_verify_mode}     = IO::Socket::SSL::SSL_VERIFY_NONE();
    $ssl{SSL_verifycn_scheme} = undef;
  }
  else {
    $ssl{SSL_verify_mode}     = IO::Socket::SSL::SSL_VERIFY_PEER();
    # The name is checked against the certificate as well as the chain: a
    # valid certificate for some other host is not this host.
    $ssl{SSL_verifycn_scheme} = 'http';
    $ssl{SSL_verifycn_name}   = $addr;
  }

  return (%ssl, $self->_ssl_certificates);
}

# cert.pem, key.pem and ca.pem in one directory -- the layout the docker CLI
# writes and the one cert_path has always pointed at, whether or not anything
# read it.
sub _ssl_certificates {
  my ($self) = @_;

  my $dir = $self->cert_path;
  return () unless defined $dir && length $dir;

  # cert_path defaults from DOCKER_CERT_PATH, so it can arrive from a machine's
  # environment rather than from this caller -- but it is only looked at once
  # TLS was asked for, and at that point a path naming nothing is a mistake
  # worth stopping on rather than quietly connecting without the certificates
  # the caller believes are in use.
  my $path = path($dir);
  croak __PACKAGE__ . ": cert_path $dir is not a directory. TLS expects the "
    . 'layout the docker CLI writes -- ca.pem, cert.pem and key.pem in one '
    . 'directory -- and this names nothing that could hold it'
    unless $path->is_dir;

  my %ssl;

  # No ca.pem is not an error: verifying a daemon behind a terminator with a
  # publicly trusted certificate needs no private trust anchor, and the
  # default store is then the right one. See L</"TLS on a tcp:// connection">.
  my $ca = $path->child('ca.pem');
  $ssl{SSL_ca_file} = "$ca" if $ca->exists;

  my $cert = $path->child('cert.pem');
  my $key  = $path->child('key.pem');
  my @half = grep { !$_->[1]->exists }
    ( [ 'cert.pem', $cert ], [ 'key.pem', $key ] );

  # One of the two is never a mode, only ever an accident: a key with no
  # certificate proves nothing and a certificate with no key cannot be used.
  croak __PACKAGE__ . ': cert_path ' . $dir . ' has ' . $half[0][0]
    . ' missing while the other half of the client certificate is there. '
    . 'Both cert.pem and key.pem are needed, or neither'
    if @half == 1;

  if (!@half) {
    $ssl{SSL_cert_file} = "$cert";
    $ssl{SSL_key_file}  = "$key";
  }

  return %ssl;
}

sub _reconnect {
  my ($self, $pending) = @_;
  $self->_clear_socket;

  # Cleared on the way out whichever way the build went, so a later _socket
  # built by anything but a request -- a test subclass, a caller reaching for
  # it directly -- never picks up the last request's bound.
  $self->_pending_connect($pending);
  my $sock;
  my $ok  = eval { $sock = $self->_socket; 1 };
  my $err = $@;
  $self->_pending_connect(undef);
  die $err unless $ok;

  return $sock;
}

# Whether the connect that has just failed failed because the bound fired.
# Asked with nothing in between, because $@ and $! are the whole of the
# evidence and both are global.
#
# $@ rather than errno: IO::Socket writes 'connect: timeout' there, and only
# there, when its own select() ran out -- measured, against a host that drops
# SYNs, where $! is ETIMEDOUT, which the kernel also produces on its own after
# two minutes with no Timeout set at all.
#
# EAGAIN is the second shape and belongs to unix:// alone. Measured against a
# listener whose backlog is full: with no Timeout the connect blocks
# indefinitely (still blocked after 8s), and with one it fails at once with
# EAGAIN, because IO::Socket does the timed connect non-blocking and an
# AF_UNIX connect has no in-progress state to wait on. So on that transport
# the option does not wait, it refuses -- but a connect that failed with
# EAGAIN is still one the bound ended, and reporting it as anything else would
# name a cause the caller cannot act on.
sub _connect_expired {
  my ($self, $timeout) = @_;

  return 0 unless $timeout;
  return 1 if defined $@ && $@ =~ /connect: timeout\z/;
  return 1 if $! == EAGAIN || $! == EWOULDBLOCK;
  return 0;
}

sub _croak_connect_timeout {
  my ($self, $pending, $where) = @_;

  my $endpoint = $pending->{endpoint};
  # See _croak_timeout for why the object goes into a variable first and why
  # the location is captured by hand.
  my $error = API::Docker::Error::Timeout->new(
    message  => 'Docker API connect timeout'
      . (defined $endpoint && length $endpoint ? ' (' . $endpoint . ')' : '')
      . ': ' . $where . ' did not accept within ' . $pending->{timeout} . 's',
    location => shortmess(''),
    endpoint => defined $endpoint ? $endpoint : '',
    timeout  => $pending->{timeout},
    phase    => 'connect',
  );
  croak $error;
}

# undef for "no timeout", which is both the default and the explicit 0, so a
# client carrying a default can be opted out of for one request. Anything that
# is not a non-negative number is a caller mistake and is refused rather than
# rounded to something: silently reading a typo as "off" would hand back the
# hang the caller was asking to be protected from.
sub _timeout_value {
  my ($self, $name, $timeout) = @_;

  return undef unless defined $timeout;
  croak __PACKAGE__ . '->_request ' . $name . ' must be a non-negative number '
    . 'of seconds (0 or undef for none), not "' . $timeout . '"'
    unless !ref $timeout && looks_like_number($timeout) && $timeout >= 0;

  return $timeout > 0 ? $timeout : undef;
}

sub _read_timeout_value {
  my ($self, $timeout) = @_;
  return $self->_timeout_value('read_timeout', $timeout);
}

sub _connect_timeout_value {
  my ($self, $timeout) = @_;
  return $self->_timeout_value('connect_timeout', $timeout);
}

# Why SO_RCVTIMEO and not select(): a bound that reads the socket cannot see
# what is already buffered above it, and would fire while the data it was
# waiting for was in hand. That was true of PerlIO's read-ahead when this was
# written (measured: after one readline of a socket holding
# "one\ntwo\nthree\n", two whole lines sit in the PerlIO buffer and select()
# says the handle is not ready), and it is true of _read_buffer now. A
# select-based bound would have to be asked only when that buffer is empty,
# which is one more invariant to keep for no gain: SO_RCVTIMEO bounds the one
# syscall in _pull for one setsockopt, and gets idle-since-the-last-byte
# semantics for free, which is the semantics these endpoints need (karr k52:
# the buffered frames arrive, and *then* the socket stalls -- a
# time-to-first-byte bound would never fire).
sub _apply_read_timeout {
  my ($self, $sock, $timeout) = @_;

  return unless $timeout;

  my $packed;
  if ($^O eq 'MSWin32' || $^O eq 'cygwin') {
    # Winsock takes a DWORD of milliseconds here rather than a struct timeval,
    # and reads a zero as "wait forever" -- so a sub-millisecond request is
    # rounded up instead of becoming the hang it asked to avoid. Reasoned from
    # the Winsock documentation and NOT measured: there is no Windows here.
    # What makes that safe to ship is the croak below -- a shape the platform
    # rejects is reported rather than ignored.
    my $ms = int($timeout * 1000 + 0.5);
    $ms = 1 if $ms < 1;
    $packed = pack('L', $ms);
  }
  else {
    # struct timeval: two native longs, seconds then microseconds. Measured on
    # Linux x86_64 against unix://, plain tcp:// and TLS.
    my $sec  = int($timeout);
    my $usec = int(($timeout - $sec) * 1_000_000 + 0.5);
    if ($usec >= 1_000_000) { $sec++; $usec -= 1_000_000 }
    $packed = pack('l!l!', $sec, $usec);
  }

  # Never a warning and never a silent pass. A caller that asked for a bound
  # and did not get one is left waiting on exactly the hang the option exists
  # to end, and would have no way to tell that from a daemon being slow.
  setsockopt($sock, SOL_SOCKET, SO_RCVTIMEO, $packed)
    or croak __PACKAGE__ . ': cannot set a read timeout of ' . $timeout
      . 's on this socket: ' . $! . '. Refusing to continue without it -- a '
      . 'bound that is not in force is worse than no bound at all, because '
      . 'the caller is relying on it';

  return;
}

# A read that did not deliver did not deliver for one of two reasons, and they
# are not the same thing: the stream ended, or the clock ran out. errno is the
# only thing that separates them -- measured, both eof() and $fh->error are
# true after a timeout just as they are at a clean end, and asking eof() costs
# a second full timeout. So $! is zeroed immediately before the read in _pull
# and captured immediately after it, with nothing in between: it is only
# meaningful after a failure, and any operation in between would overwrite it.
#
# Without this the readers would take a timeout for the end of the response and
# return a truncated body as a whole one. That is the reason karr k59 is not
# just the setsockopt: switching the option on alone would turn a hang into
# silent data loss, which is the worse of the two.
sub _timed_out {
  my ($self, $ctx, $errno) = @_;

  return 0 unless $ctx->{timeout};
  return ($errno == EAGAIN || $errno == EWOULDBLOCK) ? 1 : 0;
}

sub _croak_timeout {
  my ($self, $ctx, $partial) = @_;

  $partial = '' unless defined $partial;
  # Only ever set once a stream is past its status line, so an error body read
  # whole on the way to a >= 400 croak is still reported in bytes.
  my $summary = $ctx->{summary} ? $ctx->{summary}->() : undef;

  my $after = $summary
    ? ' after ' . $summary->{delivered} . ' unit'
      . ($summary->{delivered} == 1 ? '' : 's')
    : length($partial)
      ? ' after ' . length($partial) . ' byte'
        . (length($partial) == 1 ? '' : 's')
      : ', nothing arrived at all';

  # Carp hands a reference straight back rather than decorating it, so this
  # croak is a die with an object -- hence the location captured by hand,
  # which names the same frame a croak of a plain string would have named.
  # The object goes into a variable first: `croak CLASS->new(...)` is indirect
  # object syntax and parses as CLASS->croak(new(...)).
  my $error = API::Docker::Error::Timeout->new(
    message  => 'Docker API read timeout (' . $ctx->{endpoint} . '): '
      . $ctx->{timeout} . 's of silence' . $after,
    location => shortmess(''),
    endpoint => $ctx->{endpoint},
    timeout  => $ctx->{timeout},
    partial  => $partial,
    summary  => $summary,
  );
  croak $error;
}

# The other way a response ends before it is finished, and the one that needs
# no option to be armed: the daemon closed mid-sentence (karr k64).
#
# It is deliberately not folded into _croak_timeout. A timeout is the absence
# of an answer inside a bound the caller asked for, and it can fire on a
# response that would have completed; this is a statement about the response
# itself, made by comparing the body against what the response announced, and
# it fires whether or not anything was bounded. The two carry the same
# "here is what did arrive" contract and nothing else.
#
# $ctx->{partial} and $ctx->{summary} are read exactly as _croak_timeout reads
# them, so a buffered read reports bytes and a streamed one reports units,
# with no site having to know which it is.
sub _croak_truncated {
  my ($self, $ctx, %what) = @_;

  my $summary = $ctx->{summary} ? $ctx->{summary}->() : undef;
  my $partial = $ctx->{partial} ? ${ $ctx->{partial} } : '';

  my $arrived = $summary
    ? $summary->{delivered} . ' unit'
      . ($summary->{delivered} == 1 ? '' : 's') . ' delivered'
    : length($partial)
      ? length($partial) . ' byte'
        . (length($partial) == 1 ? '' : 's') . ' arrived'
      : 'nothing arrived at all';

  # Empty when a reader is driven directly rather than through _request, which
  # is how t/role_http.t drives them: an endpoint nobody named is left out of
  # the message rather than interpolated as the empty string.
  my $endpoint = defined $ctx->{endpoint} ? $ctx->{endpoint} : '';

  # The two phases with an announced length say the same sentence about it, so
  # they name the piece and let this write it; the two without pass the whole
  # detail, there being no count to put in one.
  my $detail = $what{detail};
  unless (defined $detail) {
    my $short = $what{expected} - $what{received};
    $detail = $what{piece} . ' stopped ' . $short . ' byte'
      . ($short == 1 ? '' : 's') . ' short of the ' . $what{expected}
      . ' it announced';
  }

  # Carp hands a reference straight back rather than decorating it, so this
  # croak is a die with an object -- hence the location captured by hand,
  # which names the same frame a croak of a plain string would have named.
  # The object goes into a variable first: `croak CLASS->new(...)` is indirect
  # object syntax and parses as CLASS->croak(new(...)).
  my $error = API::Docker::Error::Truncated->new(
    message => 'Docker API response truncated'
      . (length $endpoint ? ' (' . $endpoint . ')' : '') . ': '
      . $detail . '; ' . $arrived,
    location => shortmess(''),
    endpoint => $endpoint,
    phase    => $what{phase},
    expected => $what{expected},
    received => $what{received},
    partial  => $partial,
    summary  => $summary,
  );
  croak $error;
}

# ---------------------------------------------------------------------------
# Reading, in one buffer regime
#
# Every byte of a response is taken off the handle by _pull and by nothing
# else, and every reader below is served out of the buffer _pull fills. That
# is not an optimisation, it is the only shape that works (karr k60).
#
# What forced it: perl's read() is fread-shaped. It loops until it has the
# LENGTH it was asked for or the stream ends -- it does not return what has
# arrived. Measured on an AF_UNIX socketpair whose peer writes 6 bytes, waits
# half a second, writes 6 more and closes: read($sock, $buf, 65536) came back
# with 12 after 0.90s, having waited for the close, while sysread came back
# with 6 in 0.00s. On the endpoints with neither a Content-Length nor chunked
# encoding -- attach, logs(follow), exec/start, all
# application/vnd.docker.raw-stream -- the reader asks for $READ_SIZE, so
# read() delivered nothing to an on_frame/on_chunk callback until 64K had
# piled up or the daemon hung up. On a stream that never ends it would deliver
# nothing at all. The POD promised those callbacks the bytes as they arrive,
# and that promise was not kept.
#
# Why it could not be fixed at the one site that had the bug: _read_head read
# the status line and the headers with <$sock>, and PerlIO reads ahead. The
# bytes past the header block were sitting in a buffer this code cannot reach
# -- there is no supported way to take them back out; ungetc is layer-
# dependent, seek does not work on a socket, and select/MSG_PEEK see the
# kernel's buffer rather than PerlIO's. So switching only the body reads to
# sysread would have silently dropped the start of every body. Either all read
# sites move together or none do.
#
# The buffer lives on the handle rather than on the client or in the context:
# it is the unconsumed bytes of *that* handle, its lifetime is the handle's,
# and a client that opens a socket per request therefore has nothing to reset.
# ${*$sock}{...} is the IO::Socket idiom for exactly this and was measured to
# work on a real socket, a lexical filehandle, a bareword glob and a tied
# handle alike.
my $RBUF = __PACKAGE__ . '/rbuf';

sub _read_buffer {
  my ($self, $sock) = @_;

  ${*$sock}{$RBUF} = '' unless defined ${*$sock}{$RBUF};
  return \${*$sock}{$RBUF};
}

# The one physical read. It answers with what happened rather than with a
# count, because a count makes every reader re-derive the same distinction and
# an undef quietly becoming an end of stream at any one of them is the silent
# truncation this transport must not have:
#
#   'data'     something was appended to the buffer -- however little
#   'eof'      the stream ended
#   'timeout'  the read_timeout expired with nothing to show for it
#
# What TLS does here, since it is not obvious from the call. IO::Socket::SSL
# ties the glob, so the builtin sysread reaches the same place -- SSL_HANDLE's
# READ delegates to the object's own sysread -- and the method form is written
# out only so that the dispatch is visible rather than accidental. What does
# matter is sysread rather than read: IO::Socket::SSL's sysread is a single
# Net::SSLeay::read, one record, while its read is ssl_read_all on a blocking
# socket, which is the same fill semantics this is here to get away from.
#
# A short positive read is never an end of stream and never an expiry. Over
# TLS it is the normal case, one plaintext record at a time; over a plain
# socket it is whatever the kernel had. Both are data.
#
# SSL_WANT_READ and SSL_WANT_WRITE are deliberately not retried. On a blocking
# socket they arrive as EWOULDBLOCK (IO::Socket::SSL's _skip_rw_error does
# `$! ||= EWOULDBLOCK`) and mean the underlying receive would have blocked --
# which, with SO_RCVTIMEO in force, is the bound firing and nothing else.
# Retrying would be a busy loop on WANT_READ and could not make progress on
# WANT_WRITE in any case, so they are reported as the timeout they are.
sub _pull {
  my ($self, $sock, $ctx) = @_;

  my $buf = $self->_read_buffer($sock);

  while (1) {
    # errno immediately before, errno immediately after, nothing in between:
    # it is only meaningful after a failure, and any operation at all would
    # overwrite it. See _timed_out.
    $! = 0;
    my $n = $sock->sysread(my $got, $READ_SIZE);
    my $errno = 0 + $!;

    if (defined $n) {
      return 'eof' unless $n;
      $$buf .= $got;
      return 'data';
    }

    # A signal is not an answer. perl's read() retried here of its own accord
    # (PerlIOUnix_read loops while errno is EINTR), so retrying keeps the
    # behaviour this replaces rather than introducing one.
    next if $errno == EINTR;

    return 'timeout' if $self->_timed_out($ctx, $errno);

    # Anything else -- a reset connection, a handle that cannot be read at
    # all -- ends the response, which is what it did before this too: every
    # reader answered a failed read with `last unless $n`. Whether the
    # response was complete when it ended is a question about its structure,
    # and is asked by the readers that know the structure.
    return 'eof';
  }
}

# The two reads every reader below is built out of. Both serve from the buffer
# and pull only when it is empty, so both hand back what has arrived rather
# than waiting for what was asked for.
sub _read_line {
  my ($self, $sock, $ctx) = @_;
  $ctx ||= {};

  my $buf = $self->_read_buffer($sock);
  my $idx = index($$buf, "\n");

  while ($idx < 0) {
    my $kind = $self->_pull($sock, $ctx);
    # The part of a line already in the buffer is dropped, exactly as the
    # readline this replaces dropped it: every line read here is protocol --
    # a status line, a header, a chunk header -- never payload, so there is no
    # callback it could belong to. What a buffered body had collected is
    # reported instead, from $ctx->{partial}.
    $self->_croak_timeout($ctx, $ctx->{partial} ? ${ $ctx->{partial} } : '')
      if $kind eq 'timeout';
    last if $kind eq 'eof';
    $idx = index($$buf, "\n");
  }

  return substr($$buf, 0, $idx + 1, '') if $idx >= 0;

  # The stream ended. Whatever is left is a final line with no terminator,
  # which is what readline hands back there as well; nothing left is undef.
  return undef unless length $$buf;
  return substr($$buf, 0, length($$buf), '');
}

# Returns (count, bytes) like the read() it replaces, so `last unless $n`
# still ends a loop at the end of the response. What changed is the count: it
# is now what had arrived, never more and no longer padded out by waiting.
# Every caller loops until it has what it needs, so a short count is a
# delivery rather than a truncation.
sub _read_bytes {
  my ($self, $sock, $want, $ctx) = @_;
  $ctx ||= {};

  my $buf = $self->_read_buffer($sock);

  if (!length $$buf) {
    my $kind = $self->_pull($sock, $ctx);
    # Nothing is lost with this exception, and unlike under read() nothing has
    # to be rescued for it either. sysread does not hand back data and EAGAIN
    # together the way PerlIO's read() did: the bytes of every successful pull
    # are already in the accumulator or already through the callback by the
    # time a later pull expires, and the pull that expires carries none.
    $self->_croak_timeout($ctx, $ctx->{partial} ? ${ $ctx->{partial} } : '')
      if $kind eq 'timeout';
    return (0, '') if $kind eq 'eof';
  }

  my $take = $want < length($$buf) ? $want : length($$buf);
  return ($take, substr($$buf, 0, $take, ''));
}

# _read_bytes for a length the response announced, which is the whole of the
# difference: it appends onto the accumulator until it has all of $want, and
# an end of stream before then is truncation rather than the end of the body.
#
# Every `last unless $n` in a buffered reader used to be both -- the loop
# ended and what had been collected was returned as the response. Nothing
# compared the two, so a daemon that closed mid-body handed back a short body
# that every return shape this role promises accepts (karr k64).
#
# $into is the same scalar the reader is accumulating into, so the bytes of
# the incomplete piece are in $ctx->{partial} by the time this croaks and go
# out on the exception rather than being dropped.
sub _read_exact {
  my ($self, $sock, $want, $into, $ctx, $phase, $piece) = @_;

  my $read = 0;
  while ($read < $want) {
    my ($n, $buf) = $self->_read_bytes($sock, $want - $read, $ctx);
    last unless $n;
    $$into .= $buf;
    $read += $n;
  }

  $self->_croak_truncated($ctx, phase => $phase, piece => $piece,
    expected => $want, received => $read) if $read < $want;

  return $read;
}

sub _request {
  my ($self, $method, $path, %opts) = @_;

  # Checked while the request is assembled, like a header name: a caller that
  # passes something else gets told before anything reaches the daemon,
  # instead of after the round trip when the metadata fails to arrive.
  croak __PACKAGE__ . '->_request response option must be a HashRef'
    if exists $opts{response} && ref $opts{response} ne 'HASH';

  # Checked here for the same reason, and one at a time: the three units are
  # three shapes the engine's streaming endpoints have, not three views of one
  # stream, so a request asking for two of them has no answer.
  my @streaming = grep { exists $opts{$_} } @STREAM_OPTION;
  croak __PACKAGE__ . '->_request takes one of ' . join(', ', @STREAM_OPTION)
    . ', not ' . join(' and ', @streaming) if @streaming > 1;
  croak __PACKAGE__ . '->_request ' . $streaming[0] . ' option must be a CodeRef'
    if @streaming && ref $opts{$streaming[0]} ne 'CODE';

  my $version = $self->api_version;

  # Caller data -- a container name, an image reference -- is spliced straight
  # into the request line through $path, so it is validated before it can reach
  # the wire, exactly as a header name is. See _assert_request_path.
  $self->_assert_request_path($path);

  my $url_path = defined $version ? "/v$version$path" : $path;

  # Kept before the query string is appended: it names the request in an
  # error message, and the query string is where /build carries buildargs,
  # which can hold credentials and have no business in an exception.
  my $endpoint = $method . ' ' . $url_path;

  # Definedness, not truth. A raw_body of '' (an empty tar) or of the string
  # '0' is a body the caller asked to send, and testing it for truth dropped
  # both: they fell through to the body branch, and the request then went out
  # with no Content-Length, no Content-Type and no payload at all. Whether
  # there is a body is therefore tracked separately from what it says.
  my $body_content;
  my $content_type = 'application/json';
  if (defined $opts{raw_body}) {
    $body_content = $opts{raw_body};
    $content_type = $opts{content_type} // 'application/x-tar';
  }
  elsif ($opts{body}) {
    $body_content = encode_json($opts{body});
  }

  if ($opts{params}) {
    my @pairs;
    for my $k (sort keys %{$opts{params}}) {
      my $v = $opts{params}{$k};
      next unless defined $v;
      # An ArrayRef is one parameter given more than once, not one value:
      # `names => ['a', 'b']` is `names=a&names=b`. That spelling is the only
      # one GET /images/get accepts -- the comma-joined form is read as a
      # single image reference and answered with 500 -- and Go's r.Form[k] is
      # a list for every parameter, so it is the general shape rather than
      # that endpoint's quirk. Element order is the caller's and is kept;
      # only the keys are sorted.
      for my $item (ref $v eq 'ARRAY' ? @$v : ($v)) {
        next unless defined $item;
        push @pairs, _uri_encode($k) . '='
          . _uri_encode(ref $item eq 'HASH' ? encode_json($item) : $item);
      }
    }
    $url_path .= '?' . join('&', @pairs) if @pairs;
  }

  $log->debugf("%s %s", $method, $url_path);

  my $request = "$method $url_path HTTP/1.1\r\n";
  $request .= "Host: localhost\r\n";
  $request .= "Connection: close\r\n";
  $request .= "User-Agent: API-Docker\r\n";

  if (defined $body_content) {
    $request .= "Content-Type: $content_type\r\n";
    $request .= "Content-Length: " . length($body_content) . "\r\n";
  }

  if ($opts{headers}) {
    for my $h (sort keys %{$opts{headers}}) {
      # The name is validated before the value is even looked at: a name that
      # cannot go on the wire is a caller bug whether or not the header ends
      # up being sent.
      $self->_assert_header_name($h);
      my $v = $opts{headers}{$h};
      next unless defined $v;
      $v =~ s/[\r\n]//g;
      $request .= "$h: $v\r\n";
    }
  }

  $request .= "\r\n";
  $request .= $body_content if defined $body_content;

  my $handler = @streaming
    ? $self->_stream_handler($endpoint, $streaming[0], $opts{$streaming[0]},
        $opts{croak_on_error} // 1)
    : undef;

  # Resolved with exists rather than truth, so `read_timeout => 0` is a
  # request to wait as long as it takes and can turn a client-wide default off
  # for one call -- which `//` would have read as "no opinion" and overridden.
  my $timeout = $self->_read_timeout_value(
    exists $opts{read_timeout} ? $opts{read_timeout} : $self->read_timeout);

  # Same resolution, same reason.
  my $connect_timeout = $self->_connect_timeout_value(
    exists $opts{connect_timeout}
      ? $opts{connect_timeout} : $self->connect_timeout);

  # The endpoint without its query string, for the same reason the >= 400
  # croak uses that form.
  my $ctx = { endpoint => $endpoint, timeout => $timeout };

  my $sock = $self->_reconnect(
    { timeout => $connect_timeout, endpoint => $endpoint });
  # Applied here rather than in _build__socket because the value is per
  # request, not per client: a socket is opened and closed for each one, so
  # this is the connection the option belongs to.
  $self->_apply_read_timeout($sock, $timeout);

  # The request goes out with SIGPIPE ignored and every write checked
  # (karr k114). A daemon that answers and closes before it has read the
  # body -- dockerd does this for a rejected put_archive or build -- used to
  # raise SIGPIPE on the next write and end the calling process with status
  # 141, no exception. Now the failed write is only remembered: the response
  # the daemon may already have sent is still read, so a 4xx reaches the
  # caller as an Error::HTTP, and only when there is none is the write error
  # the answer.
  my $write_error;
  # print rather than syswrite: it also serves the in-memory sinks the test
  # transports use, and IO::Socket handles are autoflushed, so its result is
  # the result of the write.
  {
    local $SIG{PIPE} = 'IGNORE';
    $write_error = $!.'' unless print $sock $request;
  }

  # Reading can croak, and now does so from further in than it used to: an
  # on_event stream raises Error::Stream at the event that reports the
  # failure, and an on_frame stream refuses a header that is not one. Without
  # the eval those exceptions leave the socket open until the next request
  # replaces it, so it is closed on the way out either way and the exception
  # re-raised unchanged.
  my $response;
  my $ok  = eval { $response = $handler
    ? $self->_read_streaming_response($sock, $method, $handler, $ctx)
    : $self->_read_response($sock, $method, $ctx); 1 };
  my $err = $@;
  close $sock;
  $self->_clear_socket;
  if (!$ok && defined $write_error) {
    # The daemon sent nothing usable and the write had failed: the write is
    # the cause, and the endpoint belongs in the message.
    croak 'Docker API request to '.$endpoint.' failed: could not send the '
      .'request ('.$write_error.') and no response followed';
  }
  die $err unless $ok;

  my ($status_code, $status_text, $headers, $body, $summary) = @$response;

  $log->debugf("Response: %s %s", $status_code, $status_text);

  # The status line and the response headers are metadata the return value
  # cannot carry: it is the decoded body and nothing else, so 204 and 304 are
  # both undef and a header holding the payload -- HEAD
  # /containers/{id}/archive answers with an empty body and
  # X-Docker-Container-Path-Stat -- is unreachable. They go into a hash the
  # caller supplies, so no existing caller's return shape changes. Filled
  # before the croak below, so an eval'ing caller can still read the status.
  if (my $out = $opts{response}) {
    %$out = (
      status  => $status_code,
      reason  => $status_text,
      headers => $headers,
    );
  }

  if ($status_code >= 400) {
    my $error_msg = $body;
    my $data;
    if ($body && $body =~ /^\s*[\{\[]/) {
      eval {
        $data = decode_json($body);
        # Docker answers with {"message":...}. Podman answers a failed push
        # with the stream shape instead -- {"errorDetail":{"message":...},
        # "error":...} and no message key at all -- so without these two
        # fallbacks the whole JSON object became the croak text (karr k13).
        my $detail = ref $data->{errorDetail} eq 'HASH'
          ? $data->{errorDetail}{message} : undef;
        $error_msg = $data->{message} // $detail // $data->{error} // $body;
      };
    }

    # Carp hands a reference straight back rather than decorating it, so this
    # croak is a die with an object -- hence the location captured by hand,
    # which names the same frame a croak of a plain string would have named.
    # message . location is byte for byte what the string croak produced,
    # newline-terminated engine messages included: Carp appends the suffix
    # after the newline rather than skipping it (karr k50).
    my $error = API::Docker::Error::HTTP->new(
      message  => "Docker API error ($status_code): $error_msg",
      location => shortmess(''),
      status   => $status_code,
      reason   => $status_text,
      body     => $body // '',
      data     => $data,
    );
    croak $error;
  }

  # A streamed request has handed every unit to the callback already and kept
  # none of them, so there is no body left to decode and return. What the
  # caller cannot know otherwise is how the stream ended, and that is what
  # comes back instead.
  return $summary if $summary;

  # Zero bytes is a different answer in each shape a request can ask for, so
  # the two options that promise one are answered before the empty-body check
  # rather than after it. `raw` promises the response bytes and a body of no
  # bytes is '', which a caller can take length() of; `ndjson` promises an
  # ArrayRef of events even for a stream carrying a single object, so a stream
  # that carried none is []. Returning undef for both broke each promise
  # exactly where the engine legitimately says nothing.
  $body = '' unless defined $body;

  # The framed endpoints (logs, attach, exec/start) carry arbitrary bytes
  # that must not be mistaken for JSON -- a TTY container printing a JSON
  # line would otherwise come back decoded.
  return $body if $opts{raw};

  # Streaming endpoints (/build, /images/create, /images/*/push) always
  # return an ArrayRef of events, even when the stream carried exactly one
  # object.  See _decode_stream.
  if ($opts{ndjson}) {
    my $events = $self->_decode_stream($body);
    # A failed build, pull or push is HTTP 200 with the failure buried in the
    # stream, so the status line above cannot catch it.  Opt out for a stream
    # whose objects are engine data rather than the outcome of one operation.
    $self->_assert_no_stream_error($endpoint, $events)
      if $opts{croak_on_error} // 1;
    return $events;
  }

  # Nothing was asked of the body's shape and there is no body, so there is
  # nothing to hand back. 204 says so in the status line and is taken at its
  # word even if bytes follow it.
  return undef if $status_code == 204 || $body eq '';

  # A body that is JSON is decoded, whichever JSON value it is. The guard was
  # `{` or `[` alone, which returned a body that is a bare JSON scalar as its
  # own bytes: `null` came back as the four-character string 'null'. The
  # engine sends exactly that where a Go nil slice or pointer is the whole
  # response -- GET /plugins/privileges for a plugin that demands nothing,
  # GET /containers/{id}/changes for a container that changed nothing -- and
  # the string is neither the ArrayRef those endpoints document nor anything
  # a caller can iterate.
  #
  # The eval decides, not the pattern: a plain-text body that happens to
  # start with one of these characters fails to decode and is returned as
  # itself. So must the eval's success, not its result -- decode_json('null')
  # is a successful decode to undef.
  if ($body =~ $JSON_BODY) {
    my $decoded;
    return $decoded if eval { $decoded = decode_json($body); 1 };
  }

  return $body;
}

sub _decode_stream {
  my ($self, $body) = @_;

  # Newline-delimited JSON: one object per line.  A literal newline cannot
  # occur inside a JSON string, so splitting on lines is safe.
  my @events;
  for my $line (split /\r?\n/, $body) {
    next unless $line =~ /\S/;
    my $event = eval { decode_json($line) };
    push @events, $event if defined $event;
  }

  # Fall back to the whole body for a stream that is not newline-framed
  # (a single pretty-printed object), so nothing is silently dropped.
  unless (@events) {
    my $event = eval { decode_json($body) };
    push @events, $event if defined $event;
  }

  return \@events;
}

sub _assert_no_stream_error {
  my ($self, $endpoint, $events) = @_;

  for my $event (@$events) {
    next unless ref $event eq 'HASH';
    my $detail = $event->{errorDetail};
    next unless defined $detail;

    # errorDetail is a HashRef carrying the message. The engine sends a flat
    # `error` next to it with the same text; that is the fallback, not the
    # trigger -- the trigger is errorDetail, and nothing else.
    my $reason = ref $detail eq 'HASH' ? $detail->{message} : undef;
    $reason = $event->{error}   unless defined $reason && length $reason;
    $reason = 'no message given' unless defined $reason && length $reason;
    # Engine messages end in a newline, and Carp appends no location to a
    # message that already does.
    $reason =~ s/\s+\z//;

    # Carp hands a reference straight back rather than decorating it, so this
    # croak is a die with an object -- hence the location captured by hand,
    # which names the same frame a croak of a plain string would have named.
    # The object goes into a variable first: `croak CLASS->new(...)` is
    # indirect object syntax and parses as CLASS->croak(new(...)).
    my $error = API::Docker::Error::Stream->new(
      message  => 'Docker API stream error (' . $endpoint . '): ' . $reason,
      events   => $events,
      location => shortmess(''),
    );
    croak $error;
  }

  return;
}

sub _assert_header_name {
  my ($self, $name) = @_;

  return if defined $name && $name =~ $HEADER_NAME;

  my $display = defined $name ? $name : '';
  $display =~ s/([^\x20-\x7E])/sprintf('\\x%02X', ord $1)/ge;
  croak __PACKAGE__ . '->_request invalid header name "' . $display . '": a '
    . 'header name must be an RFC 9110 token (letters, digits and '
    . '!#$%&\'*+-.^_`|~). A name is rejected rather than sanitised: unlike a '
    . 'value, there is no benign way for one to carry CR, LF, a space or a '
    . 'colon, and rewriting it would send a header the caller never wrote';
}

sub _assert_request_path {
  my ($self, $path) = @_;

  return if defined $path && $path =~ $REQUEST_PATH;

  my $display = defined $path ? $path : '';
  $display =~ s/([^\x20-\x7E])/sprintf('\\x%02X', ord $1)/ge;
  croak __PACKAGE__ . '->_request invalid request path "' . $display . '": a '
    . 'path may hold only request-target characters (letters, digits, -._~ '
    . 'and :/@!$&\'()*+,;=%). It is spliced straight into the request line, so '
    . 'a space, CR, LF, ? or # in a container name or image reference would '
    . 'rewrite the request rather than name a resource. A path is rejected '
    . 'rather than sanitised: percent-encoding it here cannot tell a path '
    . 'separator from data -- pass query parameters as `params`, not in the '
    . 'path';
}

sub _read_response {
  my ($self, $sock, $method, $ctx) = @_;
  # A context is what _request builds to say how long a silence may last and
  # what the exception has to name. It defaults to an empty one -- no timeout,
  # every read exactly as it was -- so the readers stay drivable directly, as
  # t/role_http.t drives them.
  $ctx ||= {};

  my $head = $self->_read_head($sock, $ctx);
  return [ @$head, $self->_read_body($sock, $head->[2], $method, $ctx) ];
}

sub _read_head {
  my ($self, $sock, $ctx) = @_;
  $ctx ||= {};

  # Looped so a 1xx informational response is read whole and passed by: it is a
  # complete head -- a status line and an optional field section closed by the
  # blank line -- with no body of its own, sent before the real response
  # (RFC 9110 section 15.2). Without this the reader took the 1xx status as the
  # response and then read the real response as its body. A 100 Continue is the
  # one an HTTP/1.1 client is most likely to be sent; 102 and 103 have the same
  # framing.
  while (1) {
    my $status_line = $self->_read_line($sock, $ctx);
    # A daemon that closed without answering at all, which is the one shape here
    # that was never silent and is left saying exactly what it always said.
    croak "No response from Docker daemon" unless defined $status_line;
    $self->_assert_status_line($ctx, $status_line);
    $status_line =~ s/\r?\n$//;

    my ($proto, $status_code, $status_text) = split /\s+/, $status_line, 3;

    # while(1)-and-assert rather than `while (my $line = ...)`, which is the
    # same shape _read_chunked uses and for the same reason: the loop used to
    # end on anything false, so an end of stream inside the header block left it
    # exactly as the blank line would have. The assert is now the only way out
    # that is not the blank line.
    my %headers;
    while (1) {
      my $line = $self->_read_line($sock, $ctx);
      $self->_assert_header_line($ctx, $line);
      $line =~ s/\r?\n$//;
      last if $line eq '';
      if ($line =~ /^([^:]+):\s*(.*)$/) {
        $headers{lc $1} = $2;
      }
    }

    # The status code is three digits by now (_assert_status_line), so a 1xx is
    # exactly 100..199. Its headers are dropped with it and the next head read.
    next if $status_code >= 100 && $status_code < 200;

    return [$status_code, $status_text, \%headers];
  }
}

# The two ways the head ends early, and neither of them has a byte count to
# compare either (karr k73).
#
# karr k64 left the head out on the grounds that nothing in a status line or a
# header block announces its own length, so there was no announcement to hold
# a short one against. True, and beside the point: an announcement is not what
# is being checked here, any more than it is in _assert_chunk_header one level
# down. HTTP/1.1 frames the head by terminating every line, and the field
# section by an empty line that is mandatory even when there are no fields at
# all (RFC 9112 section 2.1), so "the stream ended where the terminator
# belongs" is a complete test on its own. It is the same question that reader
# already asks about a chunk header, asked of the head.
#
# What it was worth. A head cut short is not just a bogus status: the response
# is then read with whichever headers happened to arrive, and a cut landing
# before Content-Length or Transfer-Encoding leaves neither -- which is
# exactly the close-delimited branch of _read_body, where an EOF is the
# legitimate end and nothing looks wrong. Measured over a socketpair whose
# peer writes "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nX-Half"
# and closes: status 200, one header, an empty body, no complaint. The cuts
# that did get caught were caught by accident one level lower, because the
# half-arrived header happened to be one of those two.
#
# Nothing legitimate ends a head without the blank line, which was measured
# rather than taken from the RFC, on both engines and including the two heads
# an engine writes by hand instead of through its HTTP server: attach and
# /exec/{id}/start answer with "HTTP/1.1 200 OK", one Content-Type line and
# the blank line, on Docker 29.7.2 and on rootless Podman 5.8.4 alike. So do
# 204, 304, HEAD, chunked and every other shape either of them produces.
sub _assert_status_line {
  my ($self, $ctx, $line) = @_;

  # Only the unterminated half: a status line that never started at all is the
  # croak above, which says something better than this could.
  $self->_croak_truncated($ctx, phase => 'status-line',
    detail => 'the stream ended inside the status line, after '
      . length($line) . ' byte' . (length($line) == 1 ? '' : 's') . ' of one')
    unless $line =~ /\n\z/;

  # Terminated, and now: is it an HTTP status line at all? RFC 9112 section 4:
  # HTTP-version SP status-code SP [ reason-phrase ], with status-code exactly
  # three digits. A line that arrived whole but is not this shape -- a proxy's
  # plain-text banner, an ICY greeting, an HTML error page -- would otherwise
  # be split on whitespace in _read_head and its second word run through the
  # >= 400 comparison as the status. It is refused here rather than silently
  # misread, the same way a non-hexadecimal chunk size is one level down.
  my $stripped = $line =~ s/\r?\n\z//r;
  $self->_croak_truncated($ctx, phase => 'status-line',
    detail => "the status line '" . $stripped
      . "' is not a well-formed HTTP status line")
    unless $stripped =~ m{\AHTTP/[0-9]+\.[0-9]+ [0-9]{3}(?: .*)?\z};

  return;
}

# Both halves here, because the header block has no equivalent of that croak:
# undef is a block that was never closed -- with no headers at all, or after
# some -- and an unterminated line is one cut in the middle of a field.
sub _assert_header_line {
  my ($self, $ctx, $line) = @_;

  $self->_croak_truncated($ctx, phase => 'header-block',
    detail => 'the stream ended where a header line belongs, with no blank '
      . 'line to close the header block')
    unless defined $line;

  $self->_croak_truncated($ctx, phase => 'header-block',
    detail => 'the stream ended inside a header line, after '
      . length($line) . ' byte' . (length($line) == 1 ? '' : 's') . ' of one')
    unless $line =~ /\n\z/;

  return;
}

sub _read_body {
  my ($self, $sock, $headers, $method, $ctx) = @_;
  $ctx ||= {};

  # A HEAD response repeats the header fields the equivalent GET would send --
  # Content-Length and Transfer-Encoding included -- and then sends no body at
  # all. Every branch below would wait for bytes that never arrive: until the
  # daemon closes the connection at best, and forever if it does not. So the
  # body is not read for HEAD, whatever the headers promise.
  return '' if defined $method && uc($method) eq 'HEAD';

  if ($headers->{'transfer-encoding'}
      && lc($headers->{'transfer-encoding'}) eq 'chunked') {
    return $self->_read_chunked($sock, $ctx);
  }

  if (defined $headers->{'content-length'}) {
    my $len = $self->_assert_content_length($ctx, $headers->{'content-length'});
    return '' unless $len > 0;
    my $body = '';
    # What a timeout hands over instead of dropping: see
    # API::Docker::Error::Timeout/partial. localised so the context goes back
    # to carrying nothing once this body is done with.
    local $ctx->{partial} = \$body;
    # An announced length is a promise, and a stream that ends before it is
    # kept is truncation rather than the end of the body; see _read_exact.
    $self->_read_exact($sock, $len, \$body, $ctx, 'content-length',
      'the body');
    return $body;
  }

  # Read until the daemon closes. This used to be a `local $/; <$sock>` slurp;
  # it is a loop over the same primitive as the other two branches now, which
  # is what karr k60 needed and what the timeout wanted anyway -- with $/ undef
  # a whole body and a truncated one are both just bytes, so the slurp's own
  # result could never say which it was. This is the path karr k52's hang is
  # on, an attach whose buffered frames arrive and whose socket then never
  # closes.
  #
  # And the one shape with no completeness check to make: the response
  # announced no end, so the close IS the end (karr k64). Treating an EOF here
  # as truncation would make every attach, every logs(follow) and every
  # exec/start fail on the daemon hanging up, which is how all three finish.
  my $body = '';
  # What a timeout hands over instead of dropping; see the content-length
  # branch above.
  local $ctx->{partial} = \$body;
  while (1) {
    my ($n, $buf) = $self->_read_bytes($sock, $READ_SIZE, $ctx);
    last unless $n;
    $body .= $buf;
  }

  return $body;
}

# The incremental sibling of _read_response. Same [status, reason, headers,
# body] shape, plus a fifth element: the summary of what the callback was
# handed. The body it returns is empty -- that is the point, nothing is kept --
# except on the two paths that fall back to reading whole, which return undef
# as the summary instead so _request treats them exactly as before.
sub _read_streaming_response {
  my ($self, $sock, $method, $handler, $ctx) = @_;
  $ctx ||= {};

  my ($status_code, $status_text, $headers) = @{ $self->_read_head($sock, $ctx) };

  # Neither of these is a stream. A >= 400 body is a short JSON object naming
  # the failure and _request has to croak with it, so it is read whole and the
  # callback never sees it; a HEAD response has no body at all.
  if ($status_code >= 400 || (defined $method && uc($method) eq 'HEAD')) {
    return [$status_code, $status_text, $headers,
      $self->_read_body($sock, $headers, $method, $ctx), undef];
  }

  # Set only here, past the two branches above, so a timeout while reading an
  # error body is still reported in bytes rather than in units nothing
  # delivered. From this point on an expiry carries the callback's own summary
  # instead: the units are with the caller already, and how many is the part it
  # cannot know otherwise.
  local $ctx->{summary} = $handler->{summary};

  my $feed = $handler->{feed};
  my $more = 1;

  # There is deliberately nothing here to hand the callback the bytes of the
  # read that expires. karr k59 needed that hook because PerlIO's read() could
  # come back with data *and* EAGAIN at once, so a stall could land with the
  # whole response read and none of it fed; sysread cannot (karr k60). Every
  # byte reaches the callback in the pull that delivered it, and the pull that
  # expires delivers none -- so the property k59 established now holds by
  # construction instead of by rescue.

  if ($headers->{'transfer-encoding'}
      && lc($headers->{'transfer-encoding'}) eq 'chunked') {
    while ($more) {
      my $chunk_header = $self->_read_line($sock, $ctx);
      my $chunk_size   = $self->_assert_chunk_header($ctx, $chunk_header);
      last if $chunk_size == 0;

      my $read = 0;
      while ($read < $chunk_size) {
        my ($n, $buf) = $self->_read_bytes($sock, $chunk_size - $read, $ctx);
        last unless $n;
        $read += $n;
        # Fed per read rather than per completed chunk. A chunk is the
        # daemon's framing, not the caller's -- the engine is free to send an
        # hour of log output as one chunk -- so waiting for the whole of one
        # would reintroduce exactly the buffering this path exists to avoid.
        $more = $feed->($buf);
        last unless $more;
      }

      # Every truncation check on this path is guarded by $more, and that is
      # the whole of what distinguishes the two ways a streamed chunk ends
      # early: the daemon ran out, or the callback said stop. A caller that
      # stopped left the rest of the chunk unread on purpose (karr k64).
      $self->_croak_truncated($ctx, phase => 'chunk-data', piece => 'a chunk',
        expected => $chunk_size, received => $read)
        if $more && $read < $chunk_size;
      last unless $more;

      # The CRLF that terminates the chunk data. Skipped when the caller
      # stopped mid-chunk: the socket is closed straight after, and the
      # remaining bytes of that chunk are still unread in front of it.
      $self->_assert_chunk_terminator($ctx, $self->_read_line($sock, $ctx));
    }
  }
  elsif (defined $headers->{'content-length'}) {
    my $len  = $self->_assert_content_length($ctx, $headers->{'content-length'});
    my $read = 0;
    while ($more && $read < $len) {
      my $want = $len - $read;
      $want = $READ_SIZE if $want > $READ_SIZE;
      my ($n, $buf) = $self->_read_bytes($sock, $want, $ctx);
      last unless $n;
      $read += $n;
      $more = $feed->($buf);
    }
    $self->_croak_truncated($ctx, phase => 'content-length',
      piece => 'the body', expected => $len, received => $read)
      if $more && $read < $len;
  }
  else {
    while ($more) {
      my ($n, $buf) = $self->_read_bytes($sock, $READ_SIZE, $ctx);
      last unless $n;
      $more = $feed->($buf);
    }
  }

  # Only a stream the daemon ended has a tail worth flushing, or a leftover
  # worth complaining about. One the caller stopped has bytes in the carry
  # buffer by construction, and treating those as truncation would turn every
  # early stop into an error.
  $handler->{finish}->() unless $handler->{stopped}->();

  return [$status_code, $status_text, $headers, '', $handler->{summary}->()];
}

# One unit per call, and the unit is whichever of the three the caller asked
# for. The engine's streaming endpoints do not share one: /events and the
# build/pull/push progress streams are newline-delimited JSON, logs and
# exec/start are 8-byte-framed, and an image export is bytes with no structure
# above them at all. Forcing one unit on all three would mean handing two of
# them back undecoded and calling it streaming.
#
# The three decoders differ only in how they cut the byte stream up; the carry
# buffer, the delivery and the stop handling below are common to all of them.
sub _stream_handler {
  my ($self, $endpoint, $option, $cb, $croak_on_error) = @_;

  my $carry     = '';
  my $delivered = 0;
  my $stopped   = 0;

  # Stopping is an explicit call, not a return value, and the callback's
  # return value is deliberately never looked at. Every truthiness convention
  # has a silent failure mode here: `push @got, $_[0]` returns a count and
  # `$last = $event->{status}` returns whatever the engine said -- and a
  # container event's status is literally 'stop'. Both would end the stream by
  # accident and hand back a truncated one with no diagnostic. A closure the
  # caller has to invoke cannot be produced by accident.
  my $stop = sub { $stopped = 1; return };

  my $deliver = sub {
    my ($unit) = @_;
    $delivered++;
    $cb->($unit, $stop);
    return !$stopped;
  };

  my ($feed, $finish);

  if ($option eq 'on_chunk') {
    # No carry: the bytes as they arrive are the unit, so there is no boundary
    # to reassemble across.
    $feed = sub {
      my ($bytes) = @_;
      return 1 unless defined $bytes && length $bytes;
      return $deliver->($bytes);
    };
    $finish = sub { return };
  }
  elsif ($option eq 'on_event') {
    my $emit_line = sub {
      my ($line) = @_;
      $line =~ s/\r\z//;
      return 1 unless $line =~ /\S/;
      my $event = eval { decode_json($line) };
      return 1 unless defined $event;
      # Checked per event rather than over the finished list, so a failed
      # build croaks at the event that reports it instead of when the daemon
      # eventually closes. The Error::Stream then carries that one event: a
      # callback stream keeps no history, having been given all of it already.
      $self->_assert_no_stream_error($endpoint, [$event]) if $croak_on_error;
      return $deliver->($event);
    };
    $feed = sub {
      my ($bytes) = @_;
      $carry .= $bytes;
      # A JSON string cannot contain a literal newline, so a newline in the
      # buffer always ends an event -- and everything after the last one is
      # an event still arriving, which stays in the carry for the next read.
      while ((my $idx = index($carry, "\n")) >= 0) {
        my $line = substr($carry, 0, $idx, '');
        substr($carry, 0, 1, '');
        return 0 unless $emit_line->($line);
      }
      return 1;
    };
    $finish = sub {
      # A last event with no trailing newline is a complete event, not a
      # truncated one: the daemon closing is what ended it.
      return unless length $carry;
      my $line = $carry;
      $carry = '';
      $emit_line->($line);
      return;
    };
  }
  else {
    $feed = sub {
      my ($bytes) = @_;
      $carry .= $bytes;
      while (length($carry) >= 8) {
        my ($type, $pad1, $pad2, $pad3, $size) = unpack 'C4 N', substr($carry, 0, 8);
        croak __PACKAGE__ . '->_request on_frame: not a framed stream (header '
          . 'byte 0 is ' . $type . ', bytes 1-3 are ' . $pad1 . '/' . $pad2
          . '/' . $pad3 . '). A callback stream cannot sniff its own framing '
          . 'the way the buffered path does -- that needs the whole body, '
          . 'which is what is not being kept. Declare an unframed stream with '
          . 'tty => 1'
          if $type > $#STREAM_TYPE || $pad1 || $pad2 || $pad3;
        # The header is complete but the payload is not yet: leave the whole
        # frame in the carry and wait for the rest of it. This is the case a
        # per-chunk reader gets wrong -- an 8-byte header can be split across
        # two chunks just as easily as a payload can.
        last if length($carry) < 8 + $size;
        my $frame = {
          stream => $STREAM_TYPE[$type],
          data   => substr($carry, 8, $size),
        };
        substr($carry, 0, 8 + $size, '');
        return 0 unless $deliver->($frame);
      }
      return 1;
    };
    $finish = sub {
      return unless length $carry;
      croak __PACKAGE__ . '->_request on_frame: the daemon closed mid-frame, '
        . 'leaving ' . length($carry) . ' bytes that do not complete one';
    };
  }

  return {
    feed    => $feed,
    finish  => $finish,
    stopped => sub { $stopped },
    summary => sub { { delivered => $delivered, stopped => $stopped ? 1 : 0 } },
  };
}

sub _read_chunked {
  my ($self, $sock, $ctx) = @_;
  $ctx ||= {};
  my $body = '';
  # See _read_body: the accumulator a timeout hands over. The chunk data is
  # appended to it directly rather than to a per-chunk temporary, so a stall
  # in the middle of a chunk still carries the bytes of that chunk out with
  # the exception. The two are otherwise the same -- the temporary was only
  # ever concatenated onto $body straight afterwards.
  local $ctx->{partial} = \$body;

  while (1) {
    my $chunk_header = $self->_read_line($sock, $ctx);
    my $chunk_size   = $self->_assert_chunk_header($ctx, $chunk_header);
    last if $chunk_size == 0;

    $self->_read_exact($sock, $chunk_size, \$body, $ctx, 'chunk-data',
      'a chunk');

    # Read trailing \r\n after chunk data
    $self->_assert_chunk_terminator($ctx, $self->_read_line($sock, $ctx));
  }

  return $body;
}

# The two places a chunked body ends without saying so, and neither of them
# has a byte count to compare (karr k64).
#
# A chunked body is terminated by a chunk of size zero and by nothing else, so
# an end of stream where the next chunk header belongs is the daemon hanging
# up mid-body -- not the end of it. The reader used to `last unless defined`
# there and hand back the chunks that had completed as the whole response.
#
# _read_line answers an end of stream with what is left in the buffer and no
# terminator, exactly as the readline it replaces did (see there), so an
# unterminated line is the other half of the same question: a header cut in
# half is `hex('1')` and reads as a perfectly good chunk of one byte.
sub _assert_chunk_header {
  my ($self, $ctx, $line) = @_;

  $self->_croak_truncated($ctx, phase => 'chunk-header',
    detail => 'the stream ended where a chunk header belongs, with no '
      . 'terminating zero chunk')
    unless defined $line;

  $self->_croak_truncated($ctx, phase => 'chunk-header',
    detail => 'the stream ended inside a chunk header, after '
      . length($line) . ' byte' . (length($line) == 1 ? '' : 's') . ' of one')
    unless $line =~ /\n\z/;

  # The line arrived whole and terminated, and its size is not a hexadecimal
  # number. Left to hex() that warns once and reads as 0 -- the terminating
  # zero chunk -- so a 200 whose framing is corrupt used to come back as an
  # empty body, the same body-shaped lie a truncation is. A chunk size is hex
  # digits, optionally followed by a ';' extension (RFC 9112 section 7.1.1),
  # which is read past and discarded; anything else is refused here rather than
  # silently misread by the caller. The returned size is parsed from the same
  # match, so hex() is called on nothing but hex digits and never has cause to
  # warn on a legal extension either.
  my ($size) = $line =~ /^([0-9A-Fa-f]+)(?:;.*)?\r?\n\z/;
  $self->_croak_truncated($ctx, phase => 'chunk-header',
    detail => "the chunk size line '" . ($line =~ s/\r?\n\z//r)
      . "' is not a hexadecimal number")
    unless defined $size;

  return hex($size);
}

# Completeness only, never content: a terminator that arrived but is not CRLF
# is a daemon speaking chunked wrongly, which is a different complaint and one
# this reader has never made.
sub _assert_chunk_terminator {
  my ($self, $ctx, $line) = @_;

  $self->_croak_truncated($ctx, phase => 'chunk-terminator',
    detail => 'the stream ended before the CRLF that terminates a chunk')
    unless defined $line && $line =~ /\n\z/;

  return;
}

# The declared body length, validated to be the digits RFC 9110 section 8.6
# requires before it is compared against or counted down (karr k113). The
# sibling of _assert_chunk_header's hex check: a Content-Length that is not a
# number -- 'abc', an empty value, a duplicated '11, 11', a leading space --
# left as it stood is run through `$len > 0`, which warns once ("isn't
# numeric") and reads as 0, so the body is taken to be empty and a response
# that had one comes back blank. Refused here rather than silently misread, so
# hex()'s sibling warning is never reached either.
sub _assert_content_length {
  my ($self, $ctx, $value) = @_;

  return $value if $value =~ /\A[0-9]+\z/;

  $self->_croak_truncated($ctx, phase => 'content-length',
    detail => "the Content-Length header '" . $value . "' is not a number");
}

sub _uri_encode {
  my ($str) = @_;
  # Escape a character string by its UTF-8 bytes ('ü' -> %C3%BC, not %FC), and
  # a byte string as it stands. ord() on a character is not its wire byte: a
  # name or tag typed under `use utf8`, or read through a :utf8 layer, arrives
  # as characters and used to escape to a lone high byte or a bare codepoint
  # (%FC, %4E2D) that is not UTF-8 at all. But the encoding cannot be
  # unconditional: encode_json has already handed a HASH param (filters among
  # them) its UTF-8 octets, and re-encoding those would double them
  # (%C3%BC -> %C3%83%C2%BC). The utf8 flag is exactly that distinction -- on
  # for a decoded string, off for encode_json's output -- so a copy is encoded
  # only when it carries one, leaving the caller's own value untouched either
  # way.
  my $bytes = $str;
  utf8::encode($bytes) if utf8::is_utf8($bytes);
  $bytes =~ s/([^A-Za-z0-9\-_.~:\/])/sprintf("%%%02X", ord($1))/ge;
  return $bytes;
}

sub get {
  my ($self, $path, %opts) = @_;
  return $self->_request('GET', $path, %opts);
}


sub post {
  my ($self, $path, $body, %opts) = @_;
  $opts{body} = $body if defined $body;
  return $self->_request('POST', $path, %opts);
}


sub put {
  my ($self, $path, $body, %opts) = @_;
  $opts{body} = $body if defined $body;
  return $self->_request('PUT', $path, %opts);
}


sub delete_request {
  my ($self, $path, %opts) = @_;
  return $self->_request('DELETE', $path, %opts);
}


sub head {
  my ($self, $path, %opts) = @_;
  return $self->_request('HEAD', $path, %opts);
}


sub stream_frames {
  my ($self, $method, $path, %opts) = @_;

  my $tty = delete $opts{tty};

  if (my $cb = delete $opts{on_frame}) {
    # tty is a declaration here, not the hint it is on the buffered path. The
    # sniff below needs the whole body to decide, and the whole body is what a
    # callback stream does not have; so an unframed stream has to say so, and
    # anything not declared is required to be framed.
    return $self->_request($method, $path, %opts,
      $tty
        ? ( on_chunk => sub { $cb->({ stream => 'raw', data => $_[0] }, $_[1]) } )
        : ( on_frame => $cb ),
    );
  }

  my $body = $self->_request($method, $path, %opts, raw => 1);

  return [] unless defined $body && length $body;

  my $frames = $tty ? undef : $self->_demux_frames($body);

  return $frames if $frames;
  return [ { stream => 'raw', data => $body } ];
}


sub _demux_frames {
  my ($self, $body) = @_;

  my $len = length $body;
  my $pos = 0;
  my @frames;

  while ($pos < $len) {
    return undef if $len - $pos < 8;
    my ($type, $pad1, $pad2, $pad3, $size) = unpack 'C4 N', substr($body, $pos, 8);
    return undef if $type > $#STREAM_TYPE;
    return undef if $pad1 || $pad2 || $pad3;
    return undef if $len - $pos - 8 < $size;
    push @frames, {
      stream => $STREAM_TYPE[$type],
      data   => substr($body, $pos + 8, $size),
    };
    $pos += 8 + $size;
  }

  return undef unless @frames;
  return \@frames;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Role::HTTP - HTTP transport role for Docker Engine API

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    package MyDockerClient;
    use Moo;

    has host         => (is => 'ro', required => 1);
    has api_version  => (is => 'ro');
    has tls          => (is => 'ro', default => 0);
    has cert_path    => (is => 'ro');
    has tls_insecure => (is => 'ro', default => 0);

    with 'API::Docker::Role::HTTP';

    # Now use get, post, put, delete_request, head methods
    my $data = $self->get('/containers/json');

=head1 DESCRIPTION

This role provides HTTP transport for the Docker Engine API. It implements
HTTP/1.1 communication over Unix sockets and TCP sockets without depending on
heavy HTTP client libraries like LWP.

Features:

=over

=item * Unix socket transport (C<unix://...>)

=item * TCP socket transport (C<tcp://host:port>), in the clear or over TLS
with client certificates (L</"TLS on a tcp:// connection">)

=item * HTTP/1.1 chunked transfer encoding

=item * Automatic JSON encoding/decoding

=item * Newline-delimited JSON event streams (C<< ndjson => 1 >>), including
the failures the engine reports inside an HTTP 200 body

=item * Demultiplexing of the Docker stream format (L</stream_frames>)

=item * Incremental delivery of a response through a per-request callback, so
the endpoints that never close are usable at all (L</"Streaming a response as
it arrives">)

=item * Request/response logging via L<Log::Any>

=item * Automatic connection management

=back

Consuming classes must provide C<host>, C<api_version>, C<tls>, C<cert_path>
and C<tls_insecure> attributes. The last three are read only by the C<tcp://>
branch of the socket builder, and only when TLS is asked for, but the contract
is stated once rather than probed for at connect time.

A C<unix://> connection is a local socket with no wire to protect and is never
encrypted; it ignores all three attributes, and L<API::Docker> refuses the
combination at construction rather than letting a request for an encrypted
transport be answered with an unencrypted one. A C<tcp://> connection is
B<plaintext unless C<< tls => 1 >>>, which is the whole of the difference --
see L</"TLS on a tcp:// connection">.

=head2 TLS on a tcp:// connection

C<< tls => 1 >> replaces the L<IO::Socket::INET> connection with an
L<IO::Socket::SSL> one and changes nothing else: the same request writer, the
same reader, the same everything above the socket.

    my $docker = API::Docker->new(
      host      => 'tcp://dockerhost:2376',
      tls       => 1,
      cert_path => '/home/me/.docker',
    );

=head3 What the certificates are, and where

C<cert_path> names a directory in the layout the C<docker> CLI writes, and
each of the three files is used if it is there:

=over

=item * F<ca.pem> - the trust anchor the daemon's certificate is checked
against

=item * F<cert.pem> and F<key.pem> - this client's certificate and private
key, sent when the daemon asks the client to identify itself

=back

The two halves of the client certificate go together: one of them present
without the other is a croak, because a key with no certificate proves nothing
and a certificate with no key cannot be used. A directory holding only
F<ca.pem> is fine -- that is a daemon this client verifies but does not
authenticate to. A C<cert_path> that names nothing is a croak: it is read only
once TLS was asked for, and at that point a path pointing nowhere means the
caller believes certificates are in use that are not.

C<cert_path> defaults from C<DOCKER_CERT_PATH>, so on a machine that also runs
the C<docker> CLI it arrives set. Without C<< tls => 1 >> nothing reads it, so
that costs nothing; with it, pass C<< cert_path => undef >> to use the system
trust store instead of the CLI's private one.

=head3 TLS with no certificates at all

It means B<encrypt and verify against the system trust store>, not an error.

C<tls> asks for a connection that is encrypted and whose far end is
authenticated. It does not ask to authenticate this client, which is what the
files on disk are for, and treating the absence of a client certificate as a
missing precondition would conflate the two. The deployment with no
certificate files is real, and is the one this role's documentation used to
recommend before there was any TLS here: a terminator -- nginx, stunnel,
Traefik -- in front of the daemon, holding a publicly trusted certificate.
There is nothing for a C<cert_path> to point at in that setup.

It is also the safe reading rather than the lax one: verification stays on
either way, so the mode reached by configuring nothing is the verifying mode.
A stock C<dockerd --tlsverify> uses a private CA that the system store does
not have, and such a connection fails with a verification error naming exactly
that -- which is the intended outcome, not a silent downgrade. Point
C<cert_path> at the directory holding its F<ca.pem> and it verifies.

=head3 Turning verification off

C<< tls_insecure => 1 >>, and the name is the whole of the warning. It sets
C<SSL_VERIFY_NONE> and switches the hostname check off, which leaves a
connection that is encrypted against a passive listener and against nothing
else: whoever answers chooses the certificate, so anyone able to redirect the
connection reads and rewrites everything on it -- registry credentials,
image contents, the commands containers are started with.

It exists for a self-signed daemon certificate whose CA is genuinely not to
hand. The better answer to that is nearly always F<ca.pem>: a self-signed
certificate is its own CA and can be used as the anchor directly.

=head3 The dependency

L<IO::Socket::SSL> is a B<recommended>, not a required, dependency, and it is
loaded at the moment the first TLS connection is opened. It brings in
L<Net::SSLeay>, which is XS compiled against libssl, and the C<unix://>
transport -- local Docker, rootless Podman, the default -- never needs any of
it; requiring it would make this client unbuildable on a machine with no
OpenSSL headers for the sake of a transport it is not using. Without it,
C<< tls => 1 >> croaks naming the module and how to install it, at the same
point every other connection failure is reported.

=head2 read_timeout

Seconds of silence after which a request gives up and croaks with an
L<API::Docker::Error::Timeout>. C<undef> -- the default, and what every
existing caller gets -- means no timeout at all and is the behaviour this
distribution has always had. C<0> means the same and is the way to say it
explicitly, so a client carrying a default can be opted out of per request.

    my $docker = API::Docker->new(read_timeout => 30);
    $docker->system->using(read_timeout => 0)->events;   # this one may wait

Per request it is an option of L</get>, L</post>, L</put>, L</delete_request>
and L</head>. A resource class carries it through
L<API::Docker::Role::Using/using>, which clones the class rather than taking
it per method -- up for a slow endpoint, down for a stream that should not
stall, off with C<0>.

See L</"Bounding a request that never ends"> for what it does and does not
cover, and L<API::Docker/"What a timeout covers"> for the same question
asked of both bounds at once.

=head2 connect_timeout

Seconds after which opening the connection gives up and croaks with an
L<API::Docker::Error::Timeout> whose C<< ->phase >> is C<'connect'>. C<undef>
-- the default, and what every existing caller gets -- means no bound and is
the behaviour this distribution has always had; C<0> means the same and is the
way to say it explicitly.

    my $docker = API::Docker->new(connect_timeout => 5);
    $docker->system->using(connect_timeout => 0)->version;  # may wait

Separate from L</read_timeout> rather than folded into it, because the two
bound different things and want different numbers: a connect is either
immediate or broken, while a read is waiting on work the daemon has to do.

Per request it is an option of L</get>, L</post>, L</put>, L</delete_request>
and L</head>. A resource class carries it through
L<API::Docker::Role::Using/using>. See L</"Bounding the connection itself">
for what it does on each transport, which is not the same thing on all
three.

=head2 get

    my $data = $client->get($path, %opts);

Perform HTTP GET request. Returns decoded JSON or raw response body.

Options:

=over

=item * C<params> - HashRef of query parameters; a HashRef value is JSON-encoded

=item * C<headers> - HashRef of extra HTTP headers, e.g.
C<< { 'X-Registry-Auth' => $b64 } >>

=item * C<ndjson> - Parse the body as newline-delimited JSON and always
return an ArrayRef of events, even for a stream carrying a single object.
Named for the format rather than C<stream>, which is already a query
parameter of C</events> and C</containers/{id}/stats>. An C<errorDetail>
event in such a stream croaks; see L</"Failure inside a 200 response">

=item * C<croak_on_error> - Default true, and only consulted with
C<< ndjson => 1 >>. Set it false for a stream whose objects are engine data
rather than the outcome of one operation -- C</events> is the only such
endpoint here

=item * C<raw> - Never decode the body; return the response bytes verbatim

=item * C<response> - HashRef the status line and the response headers are
written into; see L</"Reading the status line and the response headers">

=item * C<on_event>, C<on_frame>, C<on_chunk> - CodeRef called with each unit
of the response as it arrives, instead of the body being buffered and
returned. At most one of the three; see L</"Streaming a response as it
arrives">

=item * C<read_timeout> - Seconds of silence after which this request gives up
and croaks with an L<API::Docker::Error::Timeout>. Overrides the
L</read_timeout> attribute; C<0> means no timeout. See L</"Bounding a request
that never ends">

=item * C<connect_timeout> - Seconds after which opening the connection gives
up and croaks with an L<API::Docker::Error::Timeout> whose C<< ->phase >> is
C<'connect'>. Overrides the L</connect_timeout> attribute; C<0> means no
bound. See L</"Bounding the connection itself">

=item * C<headers> names are validated, not sanitised; see
L</"Header names are rejected, header values are stripped">

=back

=head2 Bounding a request that never ends

Nothing above stops a request waiting forever. C<Connection: close> asks the
daemon to hang up when it is done, and the readers wait for that -- so a
daemon that has nothing more to send and does not hang up leaves the client
blocked with no way out. That is not hypothetical: attaching to a container
that has B<already exited> answers, delivers the buffered frames and then
holds the connection open indefinitely on rootless Podman, and
C</containers/{id}/stats> opened on a running container does not end when that
container exits on Docker -- it degrades into zero-filled readings and keeps
going.

L</read_timeout> bounds that:

    # Give up after two seconds of silence rather than waiting forever.
    my $frames = $docker->containers->using(read_timeout => 2)->attach($id);

=head3 It is an idle timeout, not a deadline

The clock measures the time since the last byte arrived, not the time since
the request started. A stream that keeps producing runs as long as it likes;
one that stops producing is cut off. That distinction is the whole point --
both hangs above deliver data first and stall afterwards, so a bound on the
total time would have to be set longer than any legitimate stream, and a bound
on the time to the first byte would never fire at all.

=head3 There is no default, and no per-endpoint default either

Off unless asked for, everywhere. Whether a silence is a stall or normal is a
property of the workload rather than of the endpoint: C</build> with a large
context is legitimately quiet for as long as C</events> is, and a built-in
default on C<attach> would kill a perfectly healthy session at an idle shell
prompt. So no existing call changes behaviour, and picking the number is the
caller's -- who is the only one who knows what the request is for.

For the two endpoints above, if you want a figure to start from: a couple of
seconds is right for C<attach> or C<logs> used to collect what is already
there, and something above the daemon's own emit interval -- Docker sends a
stats reading about once a second -- for C<stats>.

=head3 What happens when it expires

The request croaks, on every path, with an L<API::Docker::Error::Timeout>. It
never returns a truncated response: a short body satisfies every return shape
this role promises and would be indistinguishable from a complete one. The
exception carries what did arrive -- C<< ->partial >> for a buffered request,
C<< ->summary >> for a streamed one -- so collecting what there is and then
stopping is an C<eval>:

    my $out = '';
    eval {
        $docker->containers->using(read_timeout => 2)->attach($id,
            on_frame => sub { $out .= $_[0]{data} });
    };
    die $@ if $@ && !(ref $@
        && $@->isa('API::Docker::Error::Timeout'));

That class's own documentation has the reasoning for why this is fatal even
where the caller already holds every unit.

=head3 What it does not cover

Only reading. Connecting is bounded separately by L</connect_timeout>, and
writing the request is not bounded at all -- which matters only for a large
C</build> context sent to a daemon that has stopped reading.

It is implemented with C<SO_RCVTIMEO> on the socket, which was measured to
behave the same over C<unix://>, plain C<tcp://> and TLS: the timeout fires,
the handle is not left unusable, and reading afterwards works. The C<struct
timeval> it is set with was measured on Linux; on Windows the millisecond
C<DWORD> Winsock documents is sent instead, which is reasoned rather than
measured. A platform that rejects either croaks rather than continuing without
the bound.

Over TLS it is not quite an idle timer on the plaintext. C<SO_RCVTIMEO> bounds
each blocking receive on the underlying socket, and one plaintext read can
consume several of those while a TLS record arrives in pieces -- so a record
dribbling in slowly enough resets the clock without a byte reaching the
caller. It still bounds the hang, which is what it is for.

=head2 Bounding the connection itself

L</connect_timeout> is the other half, and it is off by default for the same
reason: nothing here changes behaviour unless it is asked for.

    my $docker = API::Docker->new(connect_timeout => 5, read_timeout => 30);

What it does is not the same on all three transports, and the difference was
measured rather than assumed:

=over

=item * C<tcp://> -- a real bound. Against a host that drops SYNs, an unbounded
connect waits for the kernel's own timeout, which on Linux is over two
minutes; C<< connect_timeout => 2 >> gave up after 2.00s. This is the case the
option exists for.

=item * C<unix://> -- a bound, but it does not wait. A connect to a Unix socket
whose listen backlog is full blocks: measured against a listener with
C<< Listen => 1 >> and nobody accepting, still blocked after 8 seconds. With a
C<connect_timeout> set it fails at once instead, with C<EAGAIN> -- because
C<IO::Socket> performs a timed connect non-blocking, and an C<AF_UNIX> connect
has no in-progress state to wait on. So the hang is gone, at the price of not
tolerating even a momentary backlog. A socket path that does not exist is
C<ENOENT> either way and is not affected.

=item * TLS -- bounds the TCP connect only. The handshake that follows it runs
on the connected socket, before L</read_timeout>'s C<SO_RCVTIMEO> is applied,
and is not covered by either.

=back

An expiry croaks with an L<API::Docker::Error::Timeout> carrying
C<< ->phase >> C<'connect'>, C<< ->timeout >> the value that expired and an
empty C<< ->partial >> -- there is no response to have part of. Every other
connect failure croaks with the plain string it always did: a refused
connection, a missing socket path and a rejected certificate are diagnoses,
not timeouts, and rewriting them as one would name a cause the caller cannot
act on.

=head2 Streaming a response as it arrives

Without one of these options a request is read whole, then parsed. That is
right for a request/response endpoint and wrong for every endpoint whose point
is that it keeps going: C<< logs(follow => 1) >>, C</events> with no C<until>
and C</containers/{id}/stats> with no C<< stream => 0 >> never return, because
the daemon never closes and there is nothing else to wait for.

A callback is half the answer -- it decides what to do with each unit, and it
can stop. L</"Bounding a request that never ends"> is the other half, for the
stream that stops arriving without ever ending.

Pass a callback and the body is handed over piece by piece instead:

    my $summary = $client->get('/events',
      croak_on_error => 0,
      on_event       => sub {
        my ($event, $stop) = @_;
        print $event->{status}, "\n";
        $stop->() if $event->{status} eq 'destroy';
      },
    );

    $summary;   # { delivered => 7, stopped => 1 }

=head3 One unit per call, and three units to choose from

The engine's streaming endpoints do not share a natural unit, so there is an
option per unit and a request picks one:

=over

=item * C<on_event> - one decoded HashRef per newline-delimited JSON object.
For C</events> and the C</build>, C</images/create>, C</images/*/push>
progress streams

=item * C<on_frame> - one C<< { stream => ..., data => ... } >> HashRef per
demultiplexed frame of the Docker stream format. For
C<< /containers/{id}/logs >> and C<< /exec/{id}/start >>; normally reached
through L</stream_frames> rather than directly

=item * C<on_chunk> - the response bytes as they arrive, undecoded and
unbuffered. For an image export, and for anything with no structure this role
knows about

=back

Passing two of them croaks before the request is sent: they are three shapes
different endpoints have, not three views of one stream.

=head3 Saying stop

The callback is called as C<< $cb->($unit, $stop) >> and its return value is
ignored. To end the stream it calls C<< $stop->() >>; C<_request> checks after
the callback returns, delivers nothing further, and comes back.

An explicit closure rather than a return value, because every truthiness
convention has a silent failure mode here. C<< sub { push @got, $_[0] } >>
returns a count and C<< sub { $last = $event->{status} } >> returns whatever
the engine said -- and a container event's C<status> is literally C<stop>.
Under either polarity one of those ends the stream by accident and hands back
a truncated one with nothing to show for it. A closure the caller has to
invoke cannot be produced by accident.

=head3 What comes back

A streamed request returns a summary HashRef, not the body:

    { delivered => 7, stopped => 1 }

C<delivered> is how many units went to the callback; C<stopped> is 1 when the
callback ended the stream and 0 when the daemon did. Nothing is accumulated
along the way -- an unbounded feed must not cost memory in proportion to how
long it runs, and the caller has been handed every unit already. What it could
not otherwise know is how the stream ended, and that is what the summary says.

Only a complete unit is buffered while it is still arriving: the current
ndjson line or the current frame. A line, and equally an 8-byte frame header,
can be split across two chunks or two reads, so partial ones are carried
forward rather than decoded early.

=head3 How often the callback is called

Once per unit the daemon has finished sending, as soon as the bytes that
complete it have arrived -- not once per read of a fixed size, and not once
at the end.

That is worth stating because it was not true before karr k60. The reads were
C<read()>, which is C<fread>-shaped: it loops until it has the length it was
asked for or the stream ends, rather than returning what has arrived. On the
raw-stream endpoints -- C<attach>, C<< logs(follow => 1) >>, C<exec/start>,
which carry neither a C<Content-Length> nor chunked encoding -- the reader
asks for 64K, so nothing reached the callback until 64K had accumulated or the
daemon hung up. On a stream that never ends, nothing reached it at all.

Measured on an C<AF_UNIX> socket pair with no daemon involved, a peer writing
three frames 0.15s apart and then closing:

    before:  1 call  at 0.45s          (the moment it closed)
    after:   3 calls at 0.15s, 0.30s, 0.45s

Every read now goes through one C<sysread> and a buffer this role keeps
itself, which is also why the status line and the headers are read the same
way: PerlIO's read-ahead put the first bytes of the body somewhere the body
reader could not get at them, so the header reads had to move too or those
bytes would have been dropped.

=head3 What is not streamed

A response with status >= 400 is read whole and croaked with as always: it is
a short JSON object naming a failure, not a stream, and the callback never
sees it. C<response> is still filled. A C<HEAD> response has no body, so a
callback on one is never called and C<undef> comes back as usual.

With C<on_event>, C<croak_on_error> works as it does for C<ndjson> -- except
that the check runs per event, so a failed build croaks at the event that
reports it instead of when the daemon eventually closes. The
L<API::Docker::Error::Stream> then carries that one event in C<< ->events >>
rather than the whole stream: the callback was handed the rest as it arrived,
and none of it was kept.

C<on_frame> requires the stream to be framed. The buffered path decides
framing by walking the whole body (see L</"Detecting a framed stream">), which
is exactly what a streamed one does not have, so an unframed stream has to
declare itself with C<< tty => 1 >> to L</stream_frames> and an undeclared one
that turns out not to be framed croaks. A stream the daemon cuts off mid-frame
croaks too -- there is no whole body left to fall back to raw with. Neither
applies after a C<< $stop->() >>, which leaves a partial unit in the buffer by
construction.

=head2 Reading the status line and the response headers

The return value is the decoded body and nothing else, which leaves two things
the engine said unreachable: the status code, and the response headers. Pass a
HashRef as C<response> to get them:

    my %res;
    my $data = $client->post("/containers/$id/start", undef,
      response => \%res);

    $res{status};             # 204
    $res{reason};             # 'No Content'
    $res{headers}{'api-version'};   # header names are lowercased

The hash is overwritten on every call and filled B<before> the C<< >= 400 >>
croak, so a caller that wraps the request in C<eval> can still read the status
of a failed one. The return value is unaffected, so passing C<response> never
changes what a method hands back.

Two things need it. The engine answers a state change that did nothing with
B<304 Not Modified> -- starting a running container, stopping a stopped one --
which carries no body, exactly like the 204 of a change that did happen; see
L<API::Docker::API::Containers/start>. And C<< HEAD /containers/{id}/archive >>
carries its whole payload in the C<X-Docker-Container-Path-Stat> header, with
no body to return at all.

=head2 Failure on the status line

A status of 400 or above croaks with an L<API::Docker::Error::HTTP>. The
message is the engine's C<message> field, its C<errorDetail.message>, its flat
C<error> key or the raw body, in that order of preference, wrapped as
C<Docker API error (STATUS): REASON> -- the same text this croak has always
carried, and the object stringifies to it byte for byte, Carp's location
suffix included. Code that catches C<$@> as a string cannot tell the
difference and needs no change.

What the object adds is C<< $err->status >>. The message is engine-specific
prose: killing a stopped container answers 409 with C<can only kill running
containers ... container state improper> on rootless Podman 5.4.2, while
Docker's own example for that case reads C<Container E<lt>idE<gt> is not
running>. Anything that had to tell "no such container" from "wrong state"
apart was matching on that prose; the status code is the same distinction
without it. C<< ->reason >>, C<< ->body >> and C<< ->data >> carry the rest of
what the engine said.

This is B<not> a replacement for the C<response> option above, which stays the
only way to the status of a request that did not fail -- a 304, or a header
carrying the whole payload of a successful C<HEAD>.

=head2 Failure inside a 200 response

C</build>, C</images/create> (pull) and C</images/{name}/push> report a failed
operation as an C<errorDetail> object B<inside> a stream the daemon already
answered with HTTP 200. The status line is committed before the operation is
attempted, so the C<< >= 400 >> check above cannot see it, and a client that
trusts the status hands a broken build back as a success.

So an C<< ndjson => 1 >> request scans the decoded events and croaks with an
L<API::Docker::Error::Stream> the moment one carries C<errorDetail>. That
object stringifies to the reason plus Carp's usual location suffix, so
C<eval>-and-inspect-C<$@> code cannot tell it from the plain croak it
replaces; C<< $err->events >> carries the complete event list, so the progress
output that led up to the failure is not lost with the return value.

The trigger is the C<errorDetail> key alone. The flat C<error> key the engine
sends beside it holds the same text and is used only as a fallback message,
never as the trigger on its own.

C<< croak_on_error => 0 >> turns the scan off for a stream that is a feed
rather than an operation. The check is on by default, and opting out is per
endpoint, because the set of operation-shaped streaming endpoints is
open-ended while the feed-shaped ones are C</events> and nothing else: a new
endpoint added without a thought about this gets the loud behaviour, not the
silent one.

=head2 Failure in the middle of a response

The daemon can also stop saying anything in the middle of saying it. A status
line with no terminator, a header block with no blank line to close it, a body
shorter than its C<Content-Length>, a chunk shorter than its own header, a
chunk header cut in half, a chunked body with no terminating zero chunk: each
of those is a response that ended before it was finished, and each croaks with
an L<API::Docker::Error::Truncated>.

    my $tar = eval { $docker->images->get_tar('busybox') };
    die $@ if $@ && !(ref $@
        && $@->isa('API::Docker::Error::Truncated'));

It is a structural check, so it needs no option, applies to every request, and
cannot fire on a response that is complete. Which question it asks depends on
how the piece is framed: where the response announced a length, what arrived
is compared against it; where the framing is by terminator instead -- the head
and the chunk headers -- it asks whether the terminator came before the stream
ended, which is decidable without anything to compare. The exception carries
what did arrive: C<< ->partial >> for a buffered request, C<< ->summary >> for
a streamed one, and C<< ->phase >> for which piece of the framing ran out.

This B<is> a behaviour change and not a bug fix in passing. Until it existed
every shape above was returned rather than raised, and none of them was
distinguishable from a complete response: C<ndjson> gave a shorter ArrayRef,
C<raw> gave fewer bytes, the default gave whatever the truncated bytes
happened to parse as. A cut head was quieter still -- the response was read on
with whichever headers had arrived, and one cut before C<Content-Length> and
C<Transfer-Encoding> left neither, which is the close-delimited path below,
where an EOF is the legitimate end and nothing looks wrong. Code that was
silently receiving half a response now gets an exception where it used to get
a value.

The one thing here that is B<not> raised as an object: a connection that
closed without a single byte of a status line still croaks with the plain
C<No response from Docker daemon> string it always has. Nothing about it was
ever silent, and it is a message callers may be matching on.

=head3 Where an end of stream is still the end

A body delimited by nothing but the close. C<attach>,
C<< logs(follow => 1) >>, C</exec/{id}/start> -- the whole
C<application/vnd.docker.raw-stream> family -- carry neither a
C<Content-Length> nor chunked encoding, so the response announces no end and
there is nothing for a short one to be short of. That is how every one of them
finishes, and treating it as truncation would break all of them.

Their B<heads> are another matter and are checked like every other head. An
engine writes those two by hand rather than through its HTTP server, so it is
worth saying that they are well-formed: both answer with C<HTTP/1.1 200 OK>, a
single C<Content-Type> line and the blank line, measured on Docker 29.7.2 and
on rootless Podman 5.8.4. So does every other shape either of them produces --
200, 204, 304, C<HEAD>, chunked. Nothing legitimate ends a head without its
blank line.

The same goes for a stream a callback ended with C<< $stop->() >>: the rest of
the response is unread because the caller said so, and every check on the
streaming path is skipped once it has.

=head3 Against a timeout, and against a status

L<API::Docker::Error::Timeout> is the daemon going B<quiet> for longer than a
bound the caller asked for; this is the daemon B<closing> mid-response, and
needs no bound to be noticed. The two share a contract -- neither ever returns
a short body, and both hand over what arrived -- and are separate classes
because only one of them is about an option, and only one of them can fire on
a response that would have completed.

A response whose status is 400 or above raises this rather than an
L<API::Docker::Error::HTTP> when it is B<its> body that was cut short, which
is the rule the timeout already follows in the same place: the transport
cannot tell a caller what the engine said when it did not finish saying it.
C<< ->partial >> holds the part of the error body that did arrive.

=head2 Header names are rejected, header values are stripped

A CR or LF in a header B<value> is stripped and the value is flattened onto
its own line. A header B<name> that is not an RFC 9110 token is refused with
a croak instead.

The asymmetry is deliberate. A value can pick up a stray newline honestly --
C<MIME::Base64::encode_base64> wraps its output by default, and a token pasted
out of a file brings its line ending along -- and flattening it preserves what
the caller meant. A name is a literal the programmer wrote; there is no benign
way for one to contain CR, LF, a space or a colon, and quietly rewriting
C<< "X-Foo\r\nX-Bar" >> into C<X-FooX-Bar> would put a header on the wire
under a name nobody asked for. Validating against the token grammar also
catches the separators that would corrupt the request without injecting
anything.

=head2 A request path is rejected, not sanitised

The C<$path> given to L</get>, L</post>, L</put>, L</delete_request>, L</head>
and C<_request> is spliced straight into the request line as
C<< $method /v$version$path HTTP/1.1 >>, and it carries caller data: the
resource methods build it by interpolation -- C<< "/containers/$id/json" >>,
C<< "/images/$name/push" >> -- so a container name or an image reference the
user typed ends up in the request line unescaped. A byte the line's own
grammar reads therefore rewrites the request rather than naming a resource: a
CR or LF ends the line and opens a header of its own, a space starts the
HTTP-version field, and a C<?> or C<#> opens the query string or fragment.

So the path is checked against the RFC 3986 origin-form character set --
unreserved, the sub-delims, and C<:> C<@> C<%> C<< / >>, which is the set an
image reference lives in -- and a path outside it is refused with a croak
before anything reaches the wire, the same treatment and for the same reason a
header name gets. Sanitising is not on the table here: percent-encoding the
path at this layer cannot tell a separator from data, so it would either
mangle every C<< / >> and C<:> or leave the injection open. Query parameters
belong in C<params>, which is assembled separately and runs each element
through C<_uri_encode>.

=head2 post

    my $data = $client->post($path, $body, %opts);

Perform HTTP POST request. C<$body> is automatically JSON-encoded if provided.

Options: C<params>, C<headers>, C<ndjson>, C<croak_on_error>, C<raw>,
C<response> and the C<on_event>/C<on_frame>/C<on_chunk> callbacks as for
L</get>, plus C<raw_body> and C<content_type> for sending a non-JSON payload
such as a build context tarball.

=head2 put

    my $data = $client->put($path, $body, %opts);

Perform HTTP PUT request. C<$body> is automatically JSON-encoded if provided.

Options: C<params>, C<headers>, C<ndjson>, C<croak_on_error>, C<raw>,
C<response> and the C<on_event>/C<on_frame>/C<on_chunk> callbacks as for
L</get>, plus C<raw_body> and C<content_type> for sending a non-JSON payload
-- C<< containers->put_archive >> uses both to send a tar stream.

=head2 delete_request

    my $data = $client->delete_request($path, %opts);

Perform HTTP DELETE request.

Options: C<params> (hashref of query parameters).

=head2 head

    my %res;
    $client->head("/containers/$id/archive",
      params   => { path => '/etc/hostname' },
      response => \%res,
    );
    my $stat = decode_json(decode_base64($res{headers}{'x-docker-container-path-stat'}));

Perform HTTP HEAD request. Always returns C<undef>: a HEAD response has no
body by definition, so everything it says is in the status line and the
headers, and C<response> is the only way to reach them.

The body is not read even when the response announces one. A HEAD response
repeats the header fields the equivalent GET would send, C<Content-Length>
among them, and then sends nothing -- reading it would block on bytes that
never arrive. Measured against Podman 5.4.2 (API 1.41),
C<< HEAD /containers/{id}/archive >> in fact announces no length at all, only
C<X-Docker-Container-Path-Stat> -- but an engine that does announce one is not
waited on either.

Options: C<params>, C<headers> and C<response> as for L</get>.

=head2 stream_frames

    my $frames = $client->stream_frames('GET', "/containers/$id/logs", %opts);

Perform a request against one of the engine's framed endpoints
(C<< /containers/{id}/logs >>, C<< /exec/{id}/start >>) and return an ArrayRef
of frames:

    [ { stream => 'stdout', data => "OUT\n" },
      { stream => 'stderr', data => "ERR\n" } ]

C<stream> is C<stdout>, C<stderr> or C<stdin> for a multiplexed stream, and
C<raw> for an unframed one. It is always a plain string, so callers never need
a defined-check. Joining the payloads gives the plain text:

    my $text = join '', map { $_->{data} } @$frames;

The response body is never JSON-decoded, so a container printing JSON lines is
returned verbatim.

Options are those of C<_request> (C<params>, C<body>, C<headers>), plus:

=over

=item * C<tty> - Skip demultiplexing and return the body as a single C<raw>
frame. Set it when the container or exec instance was created with a TTY and
its output is binary; see L</"Detecting a framed stream"> for why.

=item * C<on_frame> - CodeRef called with each frame as it arrives instead of
the whole ArrayRef being returned at the end; see below.

=back

=head2 Following a framed stream

With C<on_frame> the frames are handed over as they arrive and the return
value is the summary HashRef described in L</"Streaming a response as it
arrives">, not an ArrayRef:

    my $summary = $client->stream_frames('GET', "/containers/$id/logs",
      params   => { follow => 1, stdout => 1, stderr => 1 },
      on_frame => sub {
        my ($frame, $stop) = @_;
        print $frame->{data};
        $stop->() if $frame->{data} =~ /listening on/;
      },
    );

This is the only way to use C<< follow => 1 >> at all: without it the request
does not return until the container exits.

The frame shape is the same either way, C<tty> included -- a TTY stream
arrives as a series of C<< { stream => 'raw', ... } >> frames rather than the
single one the buffered path builds, so a caller still never branches on it.

C<tty> is a declaration here rather than the hint it is on the buffered path.
Deciding framing from the bytes needs the whole body, which is precisely what
is not being kept; so an unframed stream must say so, and one that does not
and is not framed croaks instead of inventing frames from its payload.

=head2 Detecting a framed stream

A container created without a TTY produces the Docker stream format -- an
8-byte header per frame (byte 0 the stream type, bytes 4-7 a big-endian uint32
payload length) followed by that many payload bytes. With a TTY there is no
header and the payload is raw pty output.

The engine is supposed to distinguish the two with the response C<Content-Type>
(C<application/vnd.docker.multiplexed-stream> against
C<application/vnd.docker.raw-stream>), but that signal is not dependable.
Measured against Podman 5.4.2 (API 1.41): C<< GET /containers/{id}/logs >>
sends no C<Content-Type> at all, for either kind of container, and
C<< POST /exec/{id}/start >> sends C<application/vnd.docker.raw-stream> for
both -- including the non-TTY exec whose body is in fact multiplexed. Trusting
the header would therefore hand frame headers to the caller on that engine.

The framing is decided from the bytes instead. The body is walked as frames:
each header must have a stream type of 0, 1 or 2, three zero bytes after it,
and a payload length that leaves at least that many bytes in the buffer. The
body is treated as framed only when the walk consumes it exactly and yields at
least one frame; anything else is returned as a single C<raw> frame.

This can be fooled in one direction only. Raw TTY output is misread as framed
if it begins with a byte no greater than C<0x02>, followed by three NUL bytes
and a length that happens to chain exactly to the end of the body. Text output
cannot do that -- a printable character is C<0x20> or above -- so it takes
binary output from a TTY-allocated container. Pass C<< tty => 1 >> for that
case. The reverse mistake cannot happen silently: a genuine frame stream is
only ever reported as raw when its final frame is truncated, which needs the
daemon to close the connection mid-frame.

=head1 SEE ALSO

=over

=item * L<API::Docker> - Main client using this role

=item * L<API::Docker::Error::HTTP> - Raised for a status of 400 or above;
carries the status code

=item * L<API::Docker::Error::Stream> - Raised for a failure reported inside
a 200 event stream

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/p5-api-docker/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
