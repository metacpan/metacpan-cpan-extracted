use strict;
use warnings;
use Test::More;

use DBIO::Storage::PoolBase;
use DBIO::Test::Future ();

# karr k305. A pool talks to a transport the core knows nothing about, and a
# client library may quote the connection string it was given in the error it
# raises -- libpq quotes a postgresql:// URI whole, user:password@ included. The
# pool is the one place every transport's spawn passes through, so the core
# masks the error of a spawn there (DBIO::Util::mask_connect_secrets, the one
# place that knows how) and a transport does not have to. Claims:
#
#   1. an error that quotes a libpq keyword/value password or a URI password
#      reaches the caller of acquire (a failed Future) and of
#      _spawn_connection without it, and keeps its host and the rest;
#   2. a password the error repeats in a form no key gives away is masked when
#      the pool's conninfo names it -- a hash conninfo with password/Password;
#   3. a conninfo that is a plain string is the DSN slot: the DSN is masked
#      wherever the text quotes it whole;
#   4. an exception object goes through unchanged;
#   5. the same for an error of the conninfo provider and of
#      _transform_conninfo, not only of _create_connection.
#
# Mock only, no database.

{
  package K305::Pool;
  use base 'DBIO::Storage::PoolBase';

  # {fail_in}: the seam that dies, with what it dies with
  sub _transform_conninfo {
    my ($self, @args) = @_;
    die $self->{fail_in}{transform} if $self->{fail_in}{transform};
    return @args;
  }
  sub _create_connection {
    my ($self) = @_;
    die $self->{fail_in}{create} if $self->{fail_in}{create};
    return bless {}, 'K305::Conn';
  }
  sub _shutdown_connection {}
}

sub new_pool {
  my (%args) = @_;
  my $fail_in = delete $args{fail_in} || {};
  my $pool = K305::Pool->new(
    size         => 1,
    future_class => 'DBIO::Test::Future',
    %args,
  );
  $pool->{fail_in} = $fail_in;
  return $pool;
}

sub spawn_error {
  my ($pool) = @_;
  eval { $pool->_spawn_connection; 1 } and return undef;
  return $@;
}

sub acquire_error {
  my ($pool) = @_;
  my $f = $pool->acquire;
  return '' unless $f->is_failed;
  eval { $f->get };
  return $@;
}

my $leak = qr/geheim/;

# 1. keyword/value and URI, conninfo a string
for my $case (
  [ 'libpq keyword/value',
    'host=db.example.org dbname=app user=u password=geheim',
    'connection to server at "db.example.org" failed: invalid connection string: host=db.example.org dbname=app user=u password=geheim' ],
  [ 'URI',
    'postgresql://u:geheim@db.example.org/app',
    'could not parse connection URI postgresql://u:geheim@db.example.org/app: no such host' ],
) {
  my ($label, $conninfo, $text) = @$case;

  my $pool = new_pool(conninfo => $conninfo, fail_in => { create => $text });
  my $e = spawn_error($pool);
  ok defined $e, "$label: _spawn_connection dies";
  unlike $e, $leak, "$label: _spawn_connection error holds no password";
  like $e, qr/db\.example\.org/, "$label: _spawn_connection error keeps the host";

  $pool = new_pool(conninfo => $conninfo, fail_in => { create => $text });
  $e = acquire_error($pool);
  ok length $e, "$label: acquire fails";
  unlike $e, $leak, "$label: acquire error holds no password";
  like $e, qr/db\.example\.org/, "$label: acquire error keeps the host";
}

# 2. a password the text repeats without a key, conninfo a hash
for my $key (qw(password Password)) {
  my $pool = new_pool(
    conninfo => { host => 'db.example.org', $key => 'geheim' },
    fail_in  => { create => 'authentication failed for db.example.org with geheim' },
  );
  my $e = spawn_error($pool);
  unlike $e, $leak, "hash conninfo ($key): the password is masked";
  like $e, qr/db\.example\.org/, "hash conninfo ($key): the host stays";
}

# ... also the one a provider answers
{
  my $pool = new_pool(
    conninfo_provider => sub { { host => 'h.example.org', password => 'geheim' } },
    fail_in           => { create => 'rejected geheim at h.example.org' },
  );
  my $e = acquire_error($pool);
  unlike $e, $leak, 'provider answer: the password is masked';
  like $e, qr/h\.example\.org/, 'provider answer: the host stays';
}

# 3. a string conninfo is the DSN: quoted whole, its password goes with it
{
  my $dsn = 'dbi:Pg:dbname=app;host=h.example.org;sslpassword=geheim';
  my $pool = new_pool(
    conninfo => $dsn,
    fail_in  => { create => "could not connect to [$dsn]: refused" },
  );
  my $e = spawn_error($pool);
  unlike $e, $leak, 'DSN conninfo: a password in the quoted DSN is masked';
  like $e, qr/h\.example\.org/, 'DSN conninfo: the host stays';
}

# 4. an exception object is not touched
{
  my $exception = bless { message => 'password=geheim' }, 'K305::Error';
  my $pool = new_pool(conninfo => 'host=h', fail_in => { create => $exception });
  my $e = spawn_error($pool);
  is $e, $exception, 'an exception object goes through unchanged';
  is $e->{message}, 'password=geheim', '... and so does what it holds';
}

# 5. the other seams
{
  my $pool = new_pool(
    conninfo => 'host=h.example.org',
    fail_in  => { transform => 'bad conninfo: password=geheim host=h.example.org' },
  );
  my $e = spawn_error($pool);
  unlike $e, $leak, '_transform_conninfo error: password masked';
  like $e, qr/h\.example\.org/, '_transform_conninfo error: host stays';

  $pool = new_pool(
    conninfo_provider => sub { die "broker said password=geheim for h.example.org\n" },
  );
  $e = acquire_error($pool);
  unlike $e, $leak, 'provider error: password masked';
  like $e, qr/h\.example\.org/, 'provider error: host stays';
}

# a spawn that fails still frees its slot
{
  my $pool = new_pool(conninfo => 'host=h', fail_in => { create => 'password=geheim' });
  spawn_error($pool) for 1 .. 3;
  is scalar(keys %{ $pool->{_spawning} || {} }), 0, 'a failed spawn holds no slot';
}

done_testing;
