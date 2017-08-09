package Blessed::Merge;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.02';

use Scalar::Util qw/reftype/;
use Carp qw/croak/;
use Combine::Keys qw/combine_keys/;

sub new {
	my ($pkg, $args) = (shift, $_[0] && reftype $_[0] eq 'HASH' ? $_[0] : {@_});
	my $self = bless $args, $pkg;
	$self->{same} = 1 unless exists $self->{same};
	return $self;
}

sub merge {
	my ($self, $base_bless, $new) = (shift, ref $_[0], shift);
	map {
		if ( $self->{same} ) {
			croak 'Attempting to merge two differnt *packages*' unless $base_bless eq ref $_;
		}
		$new = $self->_merge($new, $_);
	} @_;
	return bless $new, $base_bless;
}

sub _merge {
	my ($self, $new, $merger) = @_;
	return $new unless defined $merger;

	my $new_ref = reftype($new);
	my $merger_ref = reftype($merger) // reftype(\$merger);
	if ( $merger_ref eq 'SCALAR' ) {
		return $merger;
	}
	elsif ( $merger_ref eq 'HASH' ) {
		$new = {} if ( $new_ref ne 'HASH' );
		return { map +( $_ => $self->_merge( $new->{$_}, $merger->{$_} ) ), combine_keys($new, $merger) };
	}
	elsif ( $merger_ref eq 'ARRAY') {
		if ( $new_ref eq 'ARRAY' ) {
			my $length = sub {$_[0] < $_[1] ? $_[1] : $_[0]}->(scalar @{$new}, scalar @{$merger});
			return [ map { $self->_merge($new->[$_], $merger->[$_]) } 0 .. $length - 1 ];
		}
		return [ map { $self->_merge('', $_ ) } @{ $merger } ]; # destroy da references
	}
	return $merger;
}

=head1 NAME

Blessed::Merge - Merge Blessed Refs.

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

	use Blessed::Merge;

	my $blessed = Blessed::Merge->new();

	my $world = $blessed->merge($obj1, $obj2, $obj3, $obj4, $obj5);

=head1 AUTHOR

Robert Acock, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-blessed-merge at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Blessed-Merge>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Blessed::Merge


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Blessed-Merge>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Blessed-Merge>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Blessed-Merge>

=item * Search CPAN

L<http://search.cpan.org/dist/Blessed-Merge/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Robert Acock.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Blessed::Merge
