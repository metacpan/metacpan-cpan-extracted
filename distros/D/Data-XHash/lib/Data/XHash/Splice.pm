package Data::XHash;

use Data::XHash;
use strict;
use warnings;

=head1 NAME

Data::XHash::Splice - Add splice to your XHash

=head1 VERSION

Version 0.09

=head1 SYNOPSIS

    $xhash->splice(\%options?, $offset, $length, @elements?);
    $xhash->spliceref(\%options?, $offset, $length, \@elements?);

=head1 DESCRIPTION

This module adds methods C<splice()> and C<spliceref()> to
L<Data::XHash>.

These are the only methods that deal explicitly with offsets rather than
keys. Using them *might* mean that you have chosen the wrong data
structure, but never say never. It's here if you need it.

=head1 METHODS

=head2 $xhash->splice(\%options?, $offset?, $length?, @elements?)

=head2 $xhash->spliceref(\%options?, $offset?, $length?, \@elements?)

Splice removes C<$length> elements (to the end of the XHash if missing
or C<undef>) beginning at C<$offset> (from the beginning of the XHash if
missing or C<undef>) and returns them (as an XHash by default).

The offset and/or length may be negative, in which case they are interpreted
as being from the end of the XHash instead of the start.

If you specify new elements, they are put in place of the removed ones.

Options:

=over

=item to => $destination

This option is passed to C<delete()>, and controls how the deleted
elements are returned.

=item nested => $boolean

This option is passed to C<pushref()> and controls whether added
elements are recursively converted to XHashes.

=back

=cut

sub splice : method {
    my $self = shift;
    my %options = ref($_[0]) eq 'HASH'? %{shift()}: ();
    my ($offset, $length) = (shift, shift);

    return $self->spliceref(\%options, $offset, $length, \@_);
}

sub spliceref {
    my $self = shift;
    my %options = ref($_[0]) eq 'HASH'? %{shift()}: ();
    my ($offset, $length, $elements) = @_;
    my @keys = $self->keys();
    my $return;

    # Default destination
    $options{to} = $self->new() unless exists($options{to});

    # Normalize undef and negative offset and length
    $offset = 0 unless defined($offset);
    $offset += @keys if $offset < 0;
    if (!defined($length)) {
	$length = @keys - $offset;
    } elsif ($length < 0) {
	$length = @keys + $length - $offset;
    }
    if ($offset < 0) {
	$length += $offset;
	$offset = 0;
    }

    if ($offset < @keys && $length > 0) {
	my @delete = splice(@keys, $offset, $length);
	$return = $self->delete({ to => $options{to} }, @delete);
    } else {
	$return = $options{to};
    }

    if ($elements && @$elements) {
	if ($offset > 0) {
	    # not spliced - add here - spliced - not spliced
	    $self->pushref($elements, at_key => $keys[$offset - 1],
	      nested => $options{nested});
	} else {
	    # add here - spliced - not spliced
	    $self->unshiftref($elements, nested => $options{nested});
	}
    }

    return $return;
}

=head1 SEE ALSO

perldoc -f splice

=head1 AUTHOR

Brian Katzung, C<< <briank at kappacs.com> >>

=head1 SUPPORT AND BUG TRACKING

See L<Data::XHash>.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Brian Katzung.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Data::XHash::Splice
