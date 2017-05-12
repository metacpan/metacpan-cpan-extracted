
package Class::Lego::Constructor;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.004';

use Scalar::Defer 0.13 ();

sub mk_constructor0 {
  my $self = shift;
  my $params = shift;

  my $class = ref $self || $self;
  my @defaults = $self->_arrange_defaults0($params);
  my $sub = $self->make_constructor(@defaults);
  my $subname = $class . '::' . 'new';

  no strict 'refs';
  *{$subname} = $sub;
}

sub mk_constructor1 {
  my $self = shift;
  my $params = shift;

  my $class = ref $self || $self;
  my @defaults = $self->_arrange_defaults1($params);
  my $sub = $self->make_constructor(@defaults);
  my $subname = $class . '::' . 'new';

  no strict 'refs';
  *{$subname} = $sub;
}

use SUPER;

# turn the arguments of mk_constructor0 into 
# two maps, one for immediate default values
#   'field' => 'value' 
# and other for deferred defaults
#   'field' => 'deferred value'
sub _arrange_defaults0 {
  my $self = shift;
  my $params = shift || {};

  my (%deferred, %values);
  while ( my ($k, $v) = each %$params ) { 
    if ( Scalar::Defer::is_deferred($v) ) { # already deferred
      $deferred{$k} = $v;
    } elsif ( ref $v && ref $v eq 'CODE' ) { # defer sub
      $deferred{$k} = &Scalar::Defer::defer($v);
    } else { # immediate value
      $values{$k} = $v; 
    }
  }
  return (\%values, \%deferred);

}

# turn the arguments of mk_constructor1 into 
# two maps, one for immediate default values
#   'field' => 'value' 
# and other for deferred defaults
#   'field' => 'deferred value'
sub _arrange_defaults1 {
  my $self = shift;
  my $params = shift || {};

  my (%deferred, %values);
  while ( my ($k, $v) = each %$params ) { 
    if ( ref $v ne 'HASH' ) {
      die "all entries must be hash refs: $k => $v"; # FIXME croak
    }
    if ( exists $v->{default} ) {
      if ( exists $v->{default_value} ) {
        die "at entry $k, 'default' takes precedence over 'default_value'"; # FIXME croak
      }

      my $default = $v->{default};
      if ( Scalar::Defer::is_deferred($default) ) { # already deferred
        $deferred{$k} = $default;
      } elsif ( ref $default && ref $default eq 'CODE' ) { # defer sub
        $deferred{$k} = &Scalar::Defer::defer($default);
      } else { # immediate value
        $values{$k} = $default;
      }
    } elsif ( exists $v->{default_value} ) {
      # immediate value
      $values{$k} = $v->{default_value};
    } else {
      die "entry $k has no 'default' or 'default_value'"; # FIXME croak
    }
  }
  return (\%values, \%deferred);

}

sub make_constructor {
  my $self = shift;
  my $default_values = shift;
  my $deferred_defaults = shift;

  # return a closure
  return sub {
    my $self = shift;
    my $fields = shift;
    my %f = %{ $fields || {} };
    while ( my ($k, $v) = each %$default_values ) {
      if ( !exists $f{$k} ) {
        $f{$k} = $v;
      }
    }
    while ( my ($k, $v) = each %$deferred_defaults ) {
      if ( !exists $f{$k} ) {
        $f{$k} = Scalar::Defer::force($v);
      }
    }
    return $self->super('new')->( $self, \%f );

  };
}

# fallback constructor, from Class::Accessor
sub new {
  my($proto, $fields) = @_;
  my($class) = ref $proto || $proto;

  $fields = {} unless defined $fields;

  # make a copy of $fields.
  bless {%$fields}, $class;
}

1;
