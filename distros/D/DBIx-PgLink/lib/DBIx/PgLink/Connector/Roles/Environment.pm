package DBIx::PgLink::Connector::Roles::Environment;

use Moose::Role;
use DBIx::PgLink::Logger;
use DBIx::PgLink::Local;


sub load_environment {
  my $self = shift;
  # user value override global value
  my $env_href = pg_dbh->selectall_arrayref(<<'END_OF_SQL', {Slice=>{}}, $self->conn_name);
SELECT env_action, env_name, env_value
FROM dbix_pglink.environment
WHERE conn_name = $1
  AND (local_user = '' or local_user = session_user)
ORDER BY local_user
END_OF_SQL
  my %env = map { 
    $_->{env_name} => { 
      action => $_->{env_action},
      value  => $_->{env_value},
    }
  } @{$env_href};
  return \%env;
}

after 'init_roles' => sub {
  my $self = shift;
  my $env_href = $self->load_environment;
  while (my ($n, $v) = each %{$env_href}) {
    no warnings;
    trace_msg('INFO', "$v->{action} environment variable $n = $v->{value}") 
      if trace_level >= 2;
    if (defined $v->{value}) {
      if ($v->{action} eq 'set') {
        $ENV{$n} = $v->{value};
      } elsif ($v->{action} eq 'append') {
        my $delim =  ($^O =~ /MSWin/) ? ';' : ':';
        $ENV{$n} = ($ENV{$n} eq '') ? $v->{value} : $ENV{$n} . $delim . $v->{value};
      }
    } else {
      delete $ENV{$n};
    }
  }
};

1;

__END__

=pod

=head1 NAME

DBIx::PgLink::Connector::Roles::Environment - role to set process environment before connection

=cut
