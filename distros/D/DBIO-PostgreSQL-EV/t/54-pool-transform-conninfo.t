use strict;
use warnings;
use Test::More;

# OFFLINE test: what DBIO::PostgreSQL::EV::Pool opens a connection from
# (karr k59).
#
# WHY: core's pool hands every spawn's connect info to the driver seam
# _transform_conninfo, and what the seam returns is the conninfo EV::Pg is
# constructed with. Here the seam is conninfo_string: a hashref of libpq
# parameters is rendered, a libpq conninfo string is handed back as it is.
# Those are the two things the storage gives the pool -- the hash
# _async_broker_conninfo makes of a broker's answer, and the static conninfo
# string -- and reading any other shape of connect info is the storage's job
# (connect_info, _async_broker_conninfo), where the rules about it live.
#
# The seam's POD said for as long as the method existed that it took an
# arrayref as well. It never did, and it must not start to by accident: an
# arrayref at this point is connect info nobody has read -- the DBI form
# [ $dsn, $user, $password, \%attrs ], or a [ \%conninfo, \%opts ] pair. Joined
# or stringified into "a conninfo string" it would be a connection opened from
# something libpq makes whatever it likes of, and the user and password would
# sit in a string that libpq's own errors quote.
#
# What this file claims:
#   1. a hashref of libpq parameters becomes a conninfo string libpq reads
#      back to the same parameters, an undefined one left out;
#   2. a conninfo string comes back unchanged;
#   3. an arrayref is refused -- the DBI form and the pair alike -- and the
#      complaint holds nothing of what was in it;
#   4. the same on the pool's own spawn path, with the seam where core calls
#      it: a provider that answers a hash gets a connection constructed with
#      that string, a provider that answers an arrayref gets a failed acquire,
#      no connection constructed and none counted.
#
# WHAT RUNS FOR REAL: this dist's Pool and ConnectInfo, core's spawn path,
# libpq's own conninfo parser (PQconninfoParse, through EV::Pg). THE
# SUBSTITUTION: the pool's _new_connection records what it is given and
# connects nowhere.

use EV::Pg;
use DBIO::PostgreSQL::EV::Pool;

my $POOL = 'DBIO::PostgreSQL::EV::Pool';

# Nothing of these may turn up in a complaint.
my ($DSN, $USER, $SECRET) = ('dbi:Pg:dbname=app;host=db1.example', 'k59_user', 'k59-s3cret');
my $LEAK = qr/\Q$SECRET\E|\Q$USER\E|dbi:Pg|db1\.example/;

my %PARAMS = (
  dbname   => 'app',
  host     => 'db1.example',
  user     => $USER,
  password => "it's $SECRET",   # a blank and a quote: rendered so that libpq reads them back
);

my @ARRAYREFS = (
  [ 'the DBI form'             => [ $DSN, $USER, $SECRET, { pool_size => 3 } ] ],
  [ 'a [ \%conninfo, \%opts ]' => [ { %PARAMS, password => $SECRET }, {} ] ],
);

# --- 1.-3. the seam itself ---

{
  my $string = $POOL->_transform_conninfo({ %PARAMS, sslmode => undef });
  ok defined $string && !ref $string, 'a hashref of libpq parameters: a plain string comes back';
  is_deeply scalar eval { EV::Pg->conninfo_parse($string) }, \%PARAMS,
    '... which libpq reads back to the same parameters, the undefined one left out';

  my $given = "host=db1.example dbname='app one'";
  is $POOL->_transform_conninfo($given), $given, 'a libpq conninfo string comes back unchanged';

  for my $case (@ARRAYREFS) {
    my ($label, $arrayref) = @$case;
    my $rendered = eval { $POOL->_transform_conninfo($arrayref) };
    my $error    = $@;
    ok !defined $rendered && $error, "$label is refused, not rendered"
      or diag 'rendered: ' . ($rendered // '(undef)');
    unlike $error, $LEAK, '... and the complaint holds nothing of what was in it';
  }
}

# --- 4. the spawn path ---

{
  package RecordingPg;
  sub new          { my ($class, %args) = @_; bless { %args }, $class }
  sub is_connected { 0 }
  sub finish       { }

  # The real pool with the one substitution: its connection constructor.
  package RecordingPool;
  use base 'DBIO::PostgreSQL::EV::Pool';
  our @CONSTRUCTED;
  sub _new_connection {
    my ($self, %args) = @_;
    push @CONSTRUCTED, $args{conninfo};
    return RecordingPg->new(%args);
  }
}

{
  @RecordingPool::CONSTRUCTED = ();
  my $pool = RecordingPool->new(conninfo_provider => sub { +{ %PARAMS } }, size => 1);
  my $f    = $pool->acquire;
  is scalar @RecordingPool::CONSTRUCTED, 1, 'a provider answering a hash: one connection is constructed';
  is_deeply scalar eval { EV::Pg->conninfo_parse($RecordingPool::CONSTRUCTED[0]) }, \%PARAMS,
    '... with a conninfo string libpq reads back to the provider\'s parameters';
  $f->cancel;
  $pool->shutdown;
}

for my $case (@ARRAYREFS) {
  my ($label, $arrayref) = @$case;
  @RecordingPool::CONSTRUCTED = ();
  my $pool = RecordingPool->new(conninfo_provider => sub { $arrayref }, size => 1);
  my $f    = $pool->acquire;
  my $failure = $f->is_ready ? $f->failure : undef;
  ok $failure, "a provider answering $label: the acquire fails";
  is scalar @RecordingPool::CONSTRUCTED, 0, '... no connection is constructed';
  is scalar @{ $pool->{_connections} }, 0, '... and the pool counts none';
  unlike $failure // '', $LEAK, '... the failure holds nothing of what was in it';
  $pool->shutdown;
}

done_testing;
