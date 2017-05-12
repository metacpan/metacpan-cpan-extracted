package DBIx::PgLink::Adapter::Roles::TraceDBI;

use Moose::Role;
use DBIx::PgLink::Logger;

has 'dbi_trace_level' => (
  isa => 'Int',
  is  => 'rw',
  lazy => 1,
  default => sub { 0 },
  trigger => sub {
    my $self = shift;
    my $value = shift;
    $self->dbh->{TraceLevel} = $value if defined $self->dbh;
  },
);


# From sample in DBI docs (Tracing to Layered Filehandles)
{
  package DBIx::PgLink::Roles::TraceDBI::Logger;

  use DBIx::PgLink::Logger;

  sub new {
    my $class = shift;
    my $self = {
      _buf    => '',
    };

    return bless $self, $class;
  }

  sub write {
    my $self = shift;
    # DBI feeds us pieces at a time, so accumulate a complete line
    # before outputing
    $self->{_buf} .= shift;
    do { 
      trace_msg('TRACE', $self->{_buf}); 
      $self->{_buf} = '';
    } if $self->{_buf} =~ tr/\n//;
  }

  sub close {
    my $self = shift;
    do { 
      trace_msg('TRACE', $self->{_buf}); 
      $self->{_buf} = '';
    } if $self->{_buf};
  }

  1;
}

{
  package DBIx::PgLink::Roles::TraceDBI::IOLayer;

  use Scalar::Util qw/blessed/;

  sub PUSHED {
    my ($class, $mode, $fh) = @_;
    return bless \my($anon_scalar), $class;
  }

  sub OPEN {
    my ($self, $path, $mode, $fh) = @_;
    # $path is actually our logger object
    ${$self} = $path;
    return 1;
  }

  sub WRITE {
    my ($self, $buf, $fh) = @_;
    ${$self}->write($buf); 
    return length($buf);
  }

  sub CLOSE {
    my $self = shift;
    ${$self}->close();
    return 0;
  }

  1;
}

after 'connect' => sub {
  my $self = shift;
  open my $log, '>:via(DBIx::PgLink::Roles::TraceDBI::IOLayer)', 
    DBIx::PgLink::Roles::TraceDBI::Logger->new;
  print $log "Redirecting DBI trace messages at level ", $self->dbi_trace_level, "\n"
    if trace_level >= 3;
  $self->dbh->trace($self->dbi_trace_level, $log);
};

1;
