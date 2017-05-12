# WORK IN PROGRESS
package DBIx::PgLink::Adapter::Roles::Safe;

use Moose::Role;
use DBIx::Safe;
use Carp;
use DBIx::PgLink::Local;
use DBIx::PgLink::Logger;

has 'safe_dbh' => (
  is  => 'rw',
  isa => 'Object',
  required => 1,
  lazy => 1,
  default => sub {
    my $self = shift;

    my $safe = DBIx::Safe->new({ dbh => $self->dbh });

    # cannot replace dbh!
    # $self->dbh( $safe );
    return $safe;
  },
);

after 'connect' => sub {
  my $self = shift;
  $self->require_plperl(__PACKAGE__);
  $self->load_safe;
};

sub load_safe {
  my $self = shift;

  my $safe = $self->safe_dbh;

  return unless defined $self->connector && defined $safe;

  # load settings for default user ('' in local_user) and current user
  # rows for current user comes later, overriding settings of default user
  my $rules_aref = pg_dbh->selectall_arrayref(<<'END_OF_SQL',
SELECT local_user, safe_kind, safe_text, safe_perm
FROM dbix_pglink.safe
WHERE conn_name = $1
  and local_user in ('', $2)
ORDER BY local_user, safe_kind, safe_text, safe_perm
END_OF_SQL
     {Slice=>{}}, 
     $self->connector->conn_name, 
     pg_dbh->pg_session_user()
   );

  my $rules = {
    'command' => {
      'allow'   => sub { $safe->allow_command(@_) },
      'unallow' => sub { $safe->unallow_command(@_) },
    },
    'regex' => {
      'allow'   => sub { my $re = shift; $safe->allow_regex(qr/$re/) },
      'unallow' => sub { my $re = shift; $safe->unallow_regex(qr/$re/) },
      'deny'    => sub { my $re = shift; $safe->deny_regex(qr/$re/) },
      'undeny'  => sub { my $re = shift; $safe->undeny_regex(qr/$re/) },
    },
    'attribute' => {
      'allow'   => sub { $safe->allow_attribute(@_) },
      'unallow' => sub { $safe->unallow_attribute(@_) },
    },
  };
  for my $rule (@{$rules_aref}) {
    trace_msg('INFO', 
        "Safe role: $rule->{safe_perm} $rule->{safe_kind} $rule->{safe_text}"
        ." for user $rule->{local_user}")
      if trace_level >= 2;
    my $coderef = $rules->{ $rule->{safe_kind} }->{ $rule->{safe_perm} } or next;
    $coderef->( $rule->{safe_text} );
  }
};

around 'dbi_method' => sub {
  my $next = shift;
  my $self = shift;
  my $dbi_handle = shift; # dbh or sth
  my $func_name = shift;

  if ($dbi_handle eq $self->dbh) {
    return $self->safe_dbh->$func_name(@_);
  } else { # statement method
    return $dbi_handle->$func_name(@_);
  }
};


# prepare_cached not supported by DBIx::Safe 1.2.5
around 'prepare_cached' => sub {
  my $next = shift;
  my $self = shift;

  $self->prepare(@_); 
};


1;

__DATA__

=pod

=head1 NAME

DBIx::PgLink::Roles::Safe - DBIx::Safe wrapper

=head1 DESCRIPTION

Role add L<DBIx::Safe> protection to DBI handle
and load security rules from PostgreSQL table I<dbix_pglink.safe>.
Can be applied only in PL/Perl environment.

For now, L<DBIx::Safe> support only PostgreSQL (DBD::Pg). 

=cut
