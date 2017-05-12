package Person::Base;
use warnings;
use strict;

# This constructor and the accessors in the subclasses were taken from
# Class::Accessor::Complex. I didn't use Class::Accessor::Complex, however, in
# order not to burden the user with additional requirements when it was easy
# to avoid them.

sub new {
    my $class = shift;
    my $self = ref($class) ? $class : bless {}, $class;
    my %args =
      (scalar(@_ == 1) && ref($_[0]) eq 'HASH')
      ? %{ $_[0] }
      : @_;
    $self->$_($args{$_}) for keys %args;
    $self->init(%args) if $self->can('init');
    $self;
}

1;
