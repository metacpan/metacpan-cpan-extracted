package Business::ISBN10;
use strict;
use base qw(Business::ISBN);

use Business::ISBN qw(:all);

use vars qw(
	$VERSION
	$debug
	$MAX_GROUP_CODE_LENGTH
	%ERROR_TEXT
	);

use Carp qw(carp croak cluck);

my $debug = 0;

$VERSION   = '3.004';

sub _max_length { 10 }

sub _set_type { $_[0]->{type} = 'ISBN10' }

sub _parse_prefix { '' }
sub _set_prefix {
	croak "Cannot set prefix [$_[1]] on an ISBN-10" if length $_[1];

	$_[0]->{prefix} = $_[1];
	}

sub _hyphen_positions {
	[
	$_[0]->_group_code_length,
	$_[0]->_group_code_length + $_[0]->_publisher_code_length,
	9
	]
	}

sub as_isbn10 {
	my $self = shift;

	my $isbn10 = Business::ISBN->new( $self->isbn );
	$isbn10->fix_checksum;

	return $isbn10;
	}

sub as_isbn13 {
	my $self = shift;

	my $isbn13 = Business::ISBN->new( '978' . $self->isbn );
	$isbn13->fix_checksum;

	return $isbn13;
	}

#internal function.  you don't get to use this one.
sub _checksum {
	my $data = $_[0]->isbn;

	return unless defined $data;

	my @digits = split //, $data;
	my $sum    = 0;

	foreach( reverse 2..10 ) {
		$sum += $_ * (shift @digits);
		}

	#return what the check digit should be
	my $checksum = (11 - ($sum % 11))%11;

	$checksum = 'X' if $checksum == 10;

	return $checksum;
	}


1;

__END__

=encoding utf8

=head1 NAME

Business::ISBN10 - work with 10 digit International Standard Book Numbers

=head1 SYNOPSIS

See L<Business::ISBN>

=head1 DESCRIPTION

See L<Business::ISBN>

=head1 SOURCE AVAILABILITY

This source is in Github:

    https://github.com/briandfoy/business-isbn

=head1 AUTHOR

brian d foy C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2001-2017, brian d foy <bdfoy@cpan.org>. All rights reserved.

This module is licensed under the Artistic License 2.0. See the LICENSE
file in the distribution, or https://opensource.org/licenses/Artistic-2.0

=cut
