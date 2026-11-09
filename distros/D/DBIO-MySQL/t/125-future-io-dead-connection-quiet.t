use strict;
use warnings;

use Test::More;

# OFFLINE test for karr k74: the handles of a pool connection that died warn as
# they are dropped -- DBI at the disconnect about the active statement handle
# (DBD::mysql), the statement handle's DESTROY when the next statement replaces
# it (both DBDs). On a connection known dead both are silenced, as
# _listen_close does for the listen connection; on a live one nothing is
# touched. The handles are fakes that warn the way the DBDs do.

BEGIN {
  eval { require DBIO::MySQL::Storage::Async; 1 }
    or plan skip_all => 'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
}

{
  package K74::Sth;
  # DESTROY reports a loss when the handle is allowed to (RaiseError or PrintError).
  sub new { bless { RaiseError => 1, PrintError => 1, fail => $_[1] }, $_[0] }
  sub execute { die "Lost connection\n" if $_[0]{fail}; 1 }
  sub DESTROY { my $s = shift; warn "(in cleanup) DBD::mysql::st DESTROY failed: Lost connection\n" if $s->{RaiseError} || $s->{PrintError} }
  sub FETCH { $_[0]{$_[1]} }
  sub STORE { $_[0]{$_[1]} = $_[2] }
}

{
  package K74::Dbh;
  sub new { bless { Driver => { Name => 'mysql' }, Active => 1, Warn => 1, err => $_[1], fail => $_[2] }, $_[0] }
  sub prepare { K74::Sth->new($_[0]{fail}) }
  sub err { $_[0]{err} }
  sub disconnect {
    my $s = shift;
    warn "disconnect invalidates 1 active statement handle\n" if $s->{Warn};
    $s->{Active} = 0;
  }
}

{
  package K74::Storage;
  use base 'DBIO::MySQL::Storage::Async';
  sub _async_prepare_attrs { {} }
}

sub conn {
  my ($err, $fail) = @_;
  my $dbh = K74::Dbh->new($err, $fail);
  return { dbh => $dbh, sth => $dbh->prepare('x') };
}

my $s = bless {}, 'K74::Storage';

sub warnings_of (&) {
  my $code = shift;
  my @w;
  local $SIG{__WARN__} = sub { push @w, @_ };
  $code->();
  return \@w;
}

# -- shutdown
{
  my $c = conn(2013);
  my $w = warnings_of { $s->_shutdown_pool_connection($c); delete $c->{sth} };
  is_deeply $w, [], 'dead connection: shutdown and dropping its statement handle warn about nothing';
}
{
  my $c = conn(undef);
  my $w = warnings_of { $s->_shutdown_pool_connection($c); delete $c->{sth} };
  is scalar(@$w), 2, 'live connection: both warnings stay untouched';
}

# -- the replacing statement
{
  my $c = conn(2013);
  my $w = warnings_of { $s->_submit_query($c, 'ROLLBACK', []) };
  { local $SIG{__WARN__} = sub { }; delete $c->{sth} }   # the new handle: not under test
  is_deeply $w, [], 'dead connection: replacing the old statement handle warns about nothing';
}
{
  my $c = conn(undef);
  my $w = warnings_of { $s->_submit_query($c, 'SELECT 1', []); delete $c->{sth} };
  is scalar(@$w), 2, 'live connection: the old statement handle reports as before';
}

# -- execute fails; the error is on the handle
{
  my $dbh = K74::Dbh->new(2006, 1);
  my $c = { dbh => $dbh };
  my $w = warnings_of { eval { $s->_submit_query($c, 'SELECT 1', []) } };
  is_deeply $w, [], 'execute failing on a dead connection: the dropped statement handle warns about nothing';
  like $@, qr/Lost connection/, 'and the error is rethrown';
}
{
  my $dbh = K74::Dbh->new(1064, 1);   # a statement error, connection alive
  my $c = { dbh => $dbh };
  my $w = warnings_of { eval { $s->_submit_query($c, 'SELECT 1', []) } };
  is scalar(@$w), 1, 'execute failing on a live connection: untouched';
}

done_testing;
