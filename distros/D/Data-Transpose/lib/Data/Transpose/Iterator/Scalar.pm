package Data::Transpose::Iterator::Scalar;
use strict;
use warnings;

use Moo;

extends 'Data::Transpose::Iterator::Base';

=head1 NAME

Data::Transpose::Iterator::Scalar - Scalar iterator for Data::Transpose.

This iterator extends L<Data::Transpose::Iterator::Base>, but as
argument to the constructor accepts a arrayref with scalar values.

Internally, the records are kept and returned as hashrefs. You can set
the key of the hashrefs with with the C<key> method.

=cut

=head1 SYNOPSIS

  my $iter = Data::Transpose::Iterator::Scalar->new([1, 2, 3, 4, 5]);
  $iter->next;
  # return { value => 1 };
  $iter->key('string');
  $iter->next;
  # return { string => 2 };

=head1 ACCESSORS

=head2 key

Internally, the records are kept and returned as hashrefs. This
accessor controls then name of the key.

=cut

has key => (is => 'rw',
            trigger => 1,
            default => sub { 'value' });

sub _trigger_records {
    my ($self, $records) = @_;

	if (ref($records) eq 'ARRAY') {
		$self->_set_count(scalar @$records);
        @$records = map { { $self->key => $_ } } @$records;
	}
	else {
		die "Arguments for records should be an arrayref.\n";
	}

    $self->reset;
}

sub _trigger_key {
    my ($self, $newkey) = @_;
    my $records = $self->records;
    foreach my $i (@$records) {
        my ($k, @unhandled) = keys %$i;
        die "One key expected, got " . join(" ", @unhandled) . " instead!"
          if @unhandled;
        $i->{$newkey} = delete $i->{$k};
    }
}



1;
