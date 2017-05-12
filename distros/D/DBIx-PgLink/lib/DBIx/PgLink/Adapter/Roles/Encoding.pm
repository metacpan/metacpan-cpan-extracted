package DBIx::PgLink::Adapter::Roles::Encoding;

# NOTE: use native server/driver conversion when possible
# this role is for databases that completely lack encoding conversion 
#  (legacy XBase system integration)

use Moose::Role;
use Carp;
use Encode;
use DBIx::PgLink::Local;

has 'local_encoding' => (
  is   => 'rw',
  isa  => 'Str',
  lazy => 1,
  default => sub {
    my $self = shift;
    my $enc = pg_dbh->selectrow_array(q/SELECT current_setting('server_encoding')/); 
    return pg_dbh->pg_to_perl_encoding($enc);
  },
);

has 'remote_encoding' => (
  is   => 'rw',
  isa  => 'Str',
);

# recursive in-place recoding

sub recode_remote_to_local {
  my $self = shift;
  return unless $self->remote_encoding;
  for my $s (@_) {
    if (ref $s eq '') {
      Encode::from_to($s, $self->remote_encoding, $self->local_encoding);
    } elsif (ref $s eq 'SCALAR') {
      $self->recode_remote_to_local(${$s});
    } elsif (ref $s eq 'ARRAY') {
      $self->recode_remote_to_local(@{$s});
    } elsif (ref $s eq 'HASH') {
      # recode both keys and values (slow)
      my @t = %$s; 
      $self->recode_remote_to_local(@t);
      %$s = @t;
    }
  }
}

sub recode_local_to_remote {
  my $self = shift;
  return unless $self->remote_encoding;
  for my $s (@_) {
    if (ref $s eq '') {
      Encode::from_to($s, $self->local_encoding, $self->remote_encoding);
    } elsif (ref $s eq 'SCALAR') {
      $self->recode_local_to_remote(${$s});
    } elsif (ref $s eq 'ARRAY') {
      $self->recode_local_to_remote(@{$s});
    } elsif (ref $s eq 'HASH') {
      # recode both keys and values (slow)
      my @t = %$s; 
      $self->recode_local_to_remote(@t);
      %$s = @t;
    }
  }
}

sub recode_method {
  my $self = shift;
  my $coderef = shift;
  my $object = shift;
  my @args = @_;
  $self->recode_local_to_remote(@args);
  if (wantarray) {
    my @result = $coderef->($object, @args);
    $self->recode_remote_to_local(@result);
    return @result;
  } else {
    my $result = $coderef->($object, @args);
    $self->recode_remote_to_local($result);
    return $result;
  } # void context?
}


around qw/
  primary_key tables
  prepare prepare_cached
  selectrow_array selectrow_arrayref selectrow_hashref 
  selectall_arrayref selectall_hashref selectcol_arrayref 
/ => sub {
  $_[1]->recode_method(@_);
};


after 'connect' => sub {
  my $self = shift;
  push @{$self->statement_roles}, 'DBIx::PgLink::Adapter::Roles::Encoding::st';
};


1;



package DBIx::PgLink::Adapter::Roles::Encoding::st;

use Moose::Role;

around qw/
    bind_param bind_param_inout bind_param_array
    execute
    fetch fetchrow_arrayref fetchrow_array fetchrow_hashref fetchall_arrayref fetchall_hashref 
/ => sub {
  $_[1]->parent->recode_method(@_);
};


1;
