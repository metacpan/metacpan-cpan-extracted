package Crypt::Sodium::XS::OO::Base;
use warnings;
use strict;

sub _set_primitive {
  my $self = shift;
  my $new = shift || 'default';
  die ref($self).": no such primitive '$new'" unless $self->has_primitive($new);
  $self->{primitive} = $new;
  return $self;
}

sub new {
  my $pkg = shift;
  my %args;
  if (@_ % 2) {
    my $args = shift;
    die "usage: ${pkg}::new(\%args) or ${pkg}::new(\\%args)" unless ref($args) eq 'HASH';
    %args = %$args;
  }
  else {
    %args = @_;
  }
  my $obj = bless({}, $pkg);
  return $obj->_set_primitive($args{primitive});
}

sub primitive {
  if (@_ == 1) {
    return $_[0]->{primitive};
  }
  if (@_ == 2) {
    return $_[0]->_set_primitive($_[1]);
  }
  die "usage: ->primitive([\$new_primitive])";
}

# should not be called, to be implemented by subclass
sub primitives { die "BUG: primitives() method not override" }

sub has_primitive { !!grep { $_ eq $_[1] } $_[0]->primitives }

1;
