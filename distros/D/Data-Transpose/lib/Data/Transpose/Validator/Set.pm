package Data::Transpose::Validator::Set;
use strict;
use warnings;
use Scalar::Util qw/looks_like_number/;
use Moo;
extends 'Data::Transpose::Validator::Base';
use MooX::Types::MooseLike::Base qw(:all);
use namespace::clean;

=head1 NAME

Data::Transpose::Validator::Set - Validate a string inside a set of values

=head1 METHODS

=head2 new(list => \@list, multiple => 1)

Constructor to set the list in which the value to be validated must be
present.

=cut

has list => (is => 'rw',
             isa => ArrayRef,
             required => 1,
            );

has multiple => (is => 'rw',
                 isa => Bool,
                 default => sub { 0 });


=head2 is_valid($value, [ $value, $value, ... ] )

The validator. Returns a true value if the value (or the values)
passed are all present in the set. Multiple values validate only if
the C<multiple> option is set in the constructor. It also accept an
arrayref as single argument, if the C<multiple> option is set.

=cut


sub is_valid {
    my ($self, @args) = @_;
    $self->reset_errors;
    my @input;
    if (@args == 1) {
        my $arg = shift @args;
        if (ref($arg) eq 'ARRAY') {
            if ($self->multiple) {
                push @input, @$arg
            }
            else {
                $self->error([nomulti => "No multiple values are allowed"])
            }
        }
        elsif (ref($arg) ne '') {
            die "Bad argument\n";
        }
        else {
            push @input, $arg;
        }
    }
    elsif (@args > 1) {
        if ($self->multiple) {
            push @input, @args;
        } else {
            $self->error([nomulti => "No multiple values are allowed"]);
        }
    }
    else {
        $self->error([noinput => "No value passed"]);
    }
    return undef if $self->error;
    return $self->_check_set(@input);

}

sub _check_set {
    my ($self, @input) = @_;
    my %list = $self->list_as_hash;
    foreach my $val (@input) {
        $self->error(["missinginset", "No match in the allowed values"])
          unless exists $list{$val};
    }
    $self->error ? return 0 : return 1;
}


=head1 INTERNAL METHODS

=head2 multiple

Accessor to the C<multiple> option

=head2 list

Accessor to the C<list> option

=head2 list_as_hash

Accessor to the list of values, as an hash.

=cut

sub list_as_hash {
    my $self = shift;
    my %list = map { $_ => 1 } @{$self->list};
    return %list;
}


1;
