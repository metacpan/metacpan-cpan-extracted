package CSS::DOM::Array;

$VERSION = '0.17';

use warnings;
use strict;

sub new {
	bless[@_[1..$#_]], shift;
}

sub length { scalar @{+shift} }
sub item {
	my $self = shift;
	$_[0] > $#$self ? () : $self->[$_[0]]
};

                              !()__END__()!

=head1 NAME

CSS::DOM::Array - Array class for CSS::DOM

=head1 VERSION

Version 0.17

=head1 SYNOPSIS

  use CSS::DOM::Array;
  
  $array = new CSS::DOM::Array 'this', 'that';

  @$array;
  $array->[0];
  # etc.

  $array->length;
  $array->item(0);

=head1 DESCRIPTION

This module serves as a base class for array-like objects required by
L<CSS::DOM>.

A CSS::DOM::Array object is simply a blessed array reference. You can use
it as an array directly, or use the methods below.

=head1 METHODS

=head2 Constructor

  $array = new CSS::DOM::Array;

Creates a new blessed array.

=head2 Object Methods

=over 4

=item length

Returns the length of the array.

=item item ( $index)

Returns the array element at the given C<$index>.

=back

=head1 SEE ALSO

L<CSS::DOM>

L<CSS::DOM::RuleList>

L<CSS::DOM::StyleSheetList>

L<CSS::DOM::MediaList>
