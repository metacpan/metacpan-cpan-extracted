package Business::ISBN13;
use strict;
use base qw(Business::ISBN);

use Business::ISBN qw(:all);
use Data::Dumper;

use vars qw(
	$VERSION
	$debug
	);

use Carp qw(carp croak cluck);

my $debug = 0;

$VERSION   = '3.004';

sub _max_length { 13 }

sub _set_type { $_[0]->{type} = 'ISBN13' }

sub _parse_prefix {
	my $isbn = $_[0]->isbn; # stupid workaround for 'Can't modify non-lvalue subroutine call'
	( $isbn =~ /\A(97[89])(.{10})\z/g )[0];
	}

sub _set_prefix {
	croak "Cannot set prefix [$_[1]] on an ISBN-13"
		unless $_[1] =~ m/\A97[89]\z/;

	$_[0]->{prefix} = $_[1];
	}

sub _hyphen_positions {
	[
	$_[0]->_prefix_length,
	$_[0]->_prefix_length + $_[0]->_group_code_length,
	$_[0]->_prefix_length + $_[0]->_group_code_length + $_[0]->_publisher_code_length,
	$_[0]->_checksum_pos,
	]
	}

# sub group { 'Bookland' }

sub as_isbn10 {
	my $self = shift;

	return unless $self->prefix eq '978';

	my $isbn10 = Business::ISBN->new(
		substr( $self->isbn, 3 )
		);
	$isbn10->fix_checksum;

	return $isbn10;
	}

sub as_isbn13 {
	my $self = shift;

	my $isbn13 = Business::ISBN->new( $self->as_string );
	$isbn13->fix_checksum;

	return $isbn13;
	}

#internal function.  you don't get to use this one.
sub _checksum {
	my $data = $_[0]->isbn;

	return unless defined $data;

	my $sum    = 0;

	foreach my $index ( 0, 2, 4, 6, 8, 10 )
		{
		$sum +=     substr($data, $index, 1);
		$sum += 3 * substr($data, $index + 1, 1);
		}

	#take the next higher multiple of 10 and subtract the sum.
	#if $sum is 37, the next highest multiple of ten is 40. the
	#check digit would be 40 - 37 => 3.
	my $checksum = ( 10 * ( int( $sum / 10 ) + 1 ) - $sum ) % 10;

	return $checksum;
	}

1;

__END__

=encoding utf8

=head1 NAME

Business::ISBN13 - work with 13 digit International Standard Book Numbers

=head1 SYNOPSIS

See L<Business::ISBN>

=head1 DESCRIPTION

See L<Business::ISBN>

=head1 SOURCE AVAILABILITY

This source is in Github.

	https://github.com/briandfoy/business-isbn

=head1 AUTHOR

brian d foy C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2001-2017, brian d foy <bdfoy@cpan.org>. All rights reserved.

This module is licensed under the Artistic License 2.0. See the LICENSE
file in the distribution, or https://opensource.org/licenses/Artistic-2.0

=cut
