package Apache::JAF::Session;

use DBI ();
use Apache ();
use Apache::Cookie ();
use Apache::Session::MySQL ();

our @ISA = qw(Apache::Session::MySQL);
our $FIXUP = { Columns => {} };

sub new {
  my ($class, $expire, @dsn) = @_;
  my $dbh = DBI->connect(@dsn);
  my $self = { };

  my %cookies = Apache::Cookie->fetch();
  my $id = $cookies{SESSION_ID} && $cookies{SESSION_ID}->value();
  my $t = time();

  my $expired = $dbh->selectall_arrayref(q{select id from sessions where ? - unix_timestamp(modified) > ?}, $FIXUP,  $t, $expire);
  foreach (@$expired) {
    tie %$_, $class, $_->{id}, { Handle => $dbh, LockHandle => $dbh };
    tied(%$_)->on_end($_) if tied(%$_)->can('on_end');
    tied(%$_)->delete();
  }

  $id = $dbh->selectrow_array(q{select id from sessions where id = ?}, undef, $id);
  tie %$self, $class, $id, { Handle => $dbh, LockHandle => $dbh };
  $self->{active} = $t;
  tied(%$self)->on_start($self) if !$id && tied(%$self)->can('on_start');
  Apache::Cookie->new(Apache->request, name => 'SESSION_ID', value => $self->{_session_id})->bake() unless $id;

  return bless $self, $class;
}

sub list {
  my ($self, @dsn) = @_;
  my $dbh = DBI->connect(@dsn);
  my $sessions = $dbh->selectall_arrayref(q{select id from sessions}, $FIXUP);
  foreach (@$sessions) {
    tie %{$_}, ref $self, $_->{id}, { Handle => $dbh, LockHandle => $dbh };
  }
  return $sessions; 
}

1;
