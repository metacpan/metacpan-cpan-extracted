package APISchema::Validator::Result;
use strict;
use warnings;

# core
use List::MoreUtils qw(all);

# cpan
use Hash::Merge::Simple ();
use Class::Accessor::Lite (
    new => 1,
);

sub new_valid {
    my ($class, @targets) = @_;
    return $class->new(values => { map { ($_ => [1]) } @targets });
}

sub new_error {
    my ($class, $target, $err) = @_;
    return $class->new(values => { ( $target // '' ) => [ undef, $err] });
}

sub _values { shift->{values} // {} }

sub merge {
    my ($self, $other) = @_;
    $self->{values} = Hash::Merge::Simple::merge(
        $self->_values,
        $other->_values,
    );
    return $self;
}

sub errors {
    my $self = shift;
    return +{ map {
        my $err = $self->_values->{$_}->[1];
        $err ? ( $_ => $err ) : ();
    } keys %{$self->_values} };
}

sub is_valid {
    my $self = shift;
    return all { $self->_values->{$_}->[0] } keys %{$self->_values};
}

1;
