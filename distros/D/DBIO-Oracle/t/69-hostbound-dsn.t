use strict;
use warnings;

use Test::More;

use DBI;
use DBIO::Storage::DBI;
use DBIO::Oracle::Storage;
use DBIO::Oracle::Storage::WhereJoins;
use DBIO::AccessBroker;

# OFFLINE (karr k48; core k276). A DBIO::AccessBroker::HostBound view puts its
# host (and port) into the DSN of the answer it wraps, through the storage's
# seam _bind_host_into_dsn($driver, $dsn, $host, $port). Core's default knows
# the host=/port= key form and declines everything else, which for DBD::Oracle
# was every DSN a user writes. This driver's seam claims:
#
#   1. Easy Connect, dbi:Oracle://host[:port][/service], gets the view's host
#      and port; the service stays; with no port in view and none in the DSN
#      none is written (the client's default 1521 is its to apply); a view
#      without a port keeps the answer's port; an IPv6 host is bracketed;
#   2. the key form (host=..;sid=..;port=..) stays the core default's;
#   3. a name the client resolves (dbi:Oracle:<alias or SID>, or empty) and a
#      full TNS descriptor are REFUSED: a tnsnames alias resolves at the
#      client, and a descriptor may hold several ADDRESS entries, so which one
#      a host replaces is ambiguous. The refusal names the form, never the
#      DSN, host or a credential;
#   4. through a storage, DBI->connect never sees the server of the answer;
#   5. both Oracle storage classes (plain and WhereJoins) do the same.
#
# DBI->connect is replaced; no database is reached.

delete @ENV{qw( DBI_DSN DBI_DRIVER )};

{
  package T::Broker;
  use base 'DBIO::AccessBroker';
  sub new { bless { answer => $_[1] }, $_[0] }
  sub connect_info_for { $_[0]{answer} }
}

{
  package T::Handle;
  sub new   { bless { Active => 1, AutoCommit => 1, RaiseError => 1 }, shift }
  sub FETCH { $_[0]->{ $_[1] } }
}

our @CONNECTS;
{
  no warnings 'redefine';
  *DBI::connect = sub { shift; push @CONNECTS, [ @_ ]; T::Handle->new };
}

sub view_over {
  my ($answer, $host) = @_;
  T::Broker->new($answer)->for_host($host || { host => 'replica.example', port => 6000 });
}

sub bound_dsn {
  my ($class, $dsn, $host) = @_;
  my $info;
  my $view = view_over([ $dsn, 'k48-user', 'k48-pw', {} ], $host);
  return (undef, "$@")
    unless eval { $info = $view->connect_info_for_storage($class->new(undef)); 1 };
  return ($info->[0], undef);
}

for my $class (qw( DBIO::Oracle::Storage DBIO::Oracle::Storage::WhereJoins )) {
  note $class;

  isnt $class->can('_bind_host_into_dsn'), DBIO::Storage::DBI->can('_bind_host_into_dsn'),
    "$class has a _bind_host_into_dsn of its own";

  # 1. Easy Connect
  for my $case (
    [ 'host, port and service',
      'dbi:Oracle://master.example:1521/svc', undef,
      'dbi:Oracle://replica.example:6000/svc' ],
    [ 'host and service, no port in the DSN',
      'dbi:Oracle://master.example/svc', undef,
      'dbi:Oracle://replica.example:6000/svc' ],
    [ 'no service',
      'dbi:Oracle://master.example:1521', undef,
      'dbi:Oracle://replica.example:6000' ],
    [ 'a view without a port keeps the answer\'s port',
      'dbi:Oracle://master.example:1522/svc', { host => 'replica.example' },
      'dbi:Oracle://replica.example:1522/svc' ],
    [ 'no port in view or DSN: none written',
      'dbi:Oracle://master.example/svc', { host => 'replica.example' },
      'dbi:Oracle://replica.example/svc' ],
    [ 'an IPv6 view host is bracketed',
      'dbi:Oracle://master.example:1521/svc', { host => '::1', port => 1521 },
      'dbi:Oracle://[::1]:1521/svc' ],
    [ 'an already bracketed IPv6 host stays as is',
      'dbi:Oracle://master.example/svc', { host => '[fe80::1]' },
      'dbi:Oracle://[fe80::1]/svc' ],
    [ 'an IPv6 host in the answer is replaced',
      'dbi:Oracle://[2001:db8::1]:1521/svc', undef,
      'dbi:Oracle://replica.example:6000/svc' ],
    [ 'upper-case prefix and driver attributes',
      'DBI:Oracle(RaiseError=1)://master.example/svc', undef,
      'DBI:Oracle(RaiseError=1)://replica.example:6000/svc' ],
    [ 'host only in the answer',
      'dbi:Oracle://master.example', undef,
      'dbi:Oracle://replica.example:6000' ],
  ) {
    my ($label, $dsn, $host, $expected) = @$case;
    my ($got, $error) = bound_dsn($class, $dsn, $host);
    is $got, $expected, "Easy Connect, $label" or diag $error;
    unlike $got // '', qr/master\.example/, '... the answer\'s host is gone';
  }

  # 2. key form: the core default
  {
    my ($got, $error) = bound_dsn($class, 'dbi:Oracle:host=master.example;sid=XE;port=1521');
    is $got, 'dbi:Oracle:host=replica.example;sid=XE;port=6000',
      'the keyed form is bound by the core default' or diag $error;
  }

  # 3. refusals
  for my $case (
    [ 'a tnsnames alias', 'dbi:Oracle:MASTERALIAS', qr/MASTERALIAS/, qr/name the Oracle client resolves/ ],
    [ 'an empty identifier', 'dbi:Oracle:', qr/\bNOPE\b/, qr/name the Oracle client resolves/ ],
    [ 'a TNS descriptor',
      'dbi:Oracle:(DESCRIPTION=(ADDRESS=(HOST=master.example)(PORT=1521))(CONNECT_DATA=(SID=x)))',
      qr/master\.example/, qr/TNS descriptor/ ],
    [ 'an Easy Connect without a host', 'dbi:Oracle:///svc', qr/svc/, qr/Easy Connect/ ],
    [ 'an Easy Connect with a junk authority', 'dbi:Oracle://a:b:c/svc', qr/a:b:c/, qr/Easy Connect/ ],
  ) {
    my ($label, $dsn, $secret, $form) = @$case;
    my ($got, $error) = bound_dsn($class, $dsn);
    ok !defined $got, "$label: no DSN handed on";
    like $error // '', $form, '... the refusal names the form';
    unlike $error // '', $secret, '... without quoting the DSN';
    unlike $error // '', qr/replica\.example|k48-/, '... or the view\'s host or a credential';
  }

  # 4. through a storage
  for my $case (
    [ 'dbi:Oracle://master.example:1521/svc', 'dbi:Oracle://replica.example:6000/svc' ],
    [ 'dbi:Oracle:MASTERALIAS', undef ],
    [ 'dbi:Oracle:(DESCRIPTION=(ADDRESS=(HOST=master.example)))', undef ],
  ) {
    my ($dsn, $expected) = @$case;
    my $storage = $class->new(undef);
    local @CONNECTS;
    my $view = view_over([ $dsn, 'k48-user', 'k48-pw', {} ]);
    my $error = eval { $storage->connect_info([ $view ]); $storage->_connect; 1 } ? undef : "$@";

    if (defined $expected) {
      ok !defined $error, 'the storage connects' or diag $error;
      is $CONNECTS[0][0], $expected, '... DBI->connect sees the view\'s server';
    }
    else {
      ok defined $error, 'a form not translatable: the storage refuses the connection';
      is scalar @CONNECTS, 0, '... DBI->connect is never called with the answer\'s server';
      unlike $error // '', qr/master|k48-/i, '... and the error quotes no DSN part or credential';
    }
  }
}

done_testing;
