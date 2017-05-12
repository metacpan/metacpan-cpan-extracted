
package Class::Lego::Myself;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.003';

use Sub::Exporter -setup => {
  exports => [ qw(give_my_self) ],
  groups => {
    default => [ qw(give_my_self) ],
  }
};

use Scalar::Defer 0.13 ();
use Sub::Install ();
use Carp qw( croak );

sub give_my_self {
  my $self = shift;
  my $class = ref $self || $self;
  my $options = shift || {};

  my $default = $options->{default} || Scalar::Defer::lazy(sub { $class->new });
  if ( Scalar::Defer::is_deferred($default) ) {
    # ok
  } elsif ( ref $default eq 'CODE' ) {
    # given a code, defer it
    $default = &Scalar::Defer::lazy($default);
  } else {
    croak "default should be a code ref";
  }

  my $find_my_self = make_find_my_self( $default );
  Sub::Install::install_sub({
    code => $find_my_self,
    into => $class,
    as   => 'find_my_self',
  });

#  my $get_default = sub { return $default };
#  Sub::Install::install_sub({
#    code => $get_default,
#    into => $class,
#    as   => 'get_default',
#  });

}

sub make_find_my_self {
  my $default_object = shift;

  return sub {
    my $self = shift;
    if ( !ref $self ) {
      $self = $default_object;
    }
    if ( wantarray ) {
      return $self, @_;
    } else {
      return $self;
    }
  };
}

"me, myself and Zellweger";
