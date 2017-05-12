package Business::ISSN;

use strict;

use warnings;
no warnings;

use subs qw(_common_format _checksum is_valid_checksum);
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use Exporter;

@ISA       = qw(Exporter);
@EXPORT_OK = qw(is_valid_checksum);

$VERSION = '0.91';

sub new 
	{
	my $class       = shift;
	my $common_data = _common_format shift;
	
	return unless $common_data;

	my $self = bless {}, $class;

	$self->{'issn'}      = $common_data;

	$common_data =~m/(\d{7,7})([\dxX])$/;
	
	@{$self}{ qw(checksum code) } = ( $2, $1 );

	$self->_check_validity;

	return $self;
	}

sub _issn             { $_[0]->{'issn'}         }
sub is_valid          { $_[0]->{'valid'}        }
sub checksum          { $_[0]->{'checksum'}     }
sub _hyphen_positions { 4 }

sub fix_checksum
	{
	my $self = shift;
	my $debug = 1;
	
	my $last_char = substr($self->_issn, -1, 1);

	my $checksum = _checksum $self->_issn;

	substr( $self->{issn}, -1, 1) = $checksum;
   
	$self->_check_validity;
	
	return 0 if $last_char eq $checksum;
	return 1;
	}

sub as_string
	{		
	return unless $_[0]->is_valid;

	my $issn = $_[0]->_issn;
	
	substr($issn, $_[0]->_hyphen_positions, 0) = '-';

	return $issn;
	}

sub is_valid_checksum
	{
	my $data = _common_format shift;
	return 0 unless $data;        
	return 1 if substr($data, -1, 1) eq _checksum $data;
	return 0;
	}

sub _check_validity
	{
	$_[0]->{'valid'}  = is_valid_checksum( $_[0]->_issn );
	}

sub _checksum
	{
	my $data = _common_format shift;
	
	return unless $data;
	
	my @digits = split //, $data;
	my $sum    = 0;         

	foreach( reverse 2..8 ) # oli 10
		{
		$sum += $_ * (shift @digits);
		}
	
	#return what the check digit should be
	my $checksum = (11 - ($sum % 11))%11;
	
	$checksum = 'X' if $checksum == 10;
	
	return $checksum;
	}

sub _common_format
	{
	#we want uppercase X's
	my $data = uc shift;
	
	#get rid of everything except decimal digits and X
	$data =~ s/[^0-9X]//g;
	
	return $data if $data =~ m/^\d{7}[0-9X]\z/;
					  
	return;
	}

1;
__END__

=head1 NAME

Business::ISSN - Perl extension for International Standard Serial Numbers

=head1 SYNOPSIS

	use Business::ISSN;
	$issn_object = Business::ISSN->new('1456-5935');
	
	$issn_object = Business::ISSN->new('14565935');
	
	# print the ISSN (with hyphen)
	print $issn_object->as_string;
	
	# check to see if the ISSN is valid
	$issn_object->is_valid;
	
	#fix the ISSN checksum.  BEWARE:  the error might not be
	#in the checksum!
	$issn_object->fix_checksum;
	
	#EXPORTABLE FUNCTIONS
		
	use Business::ISSN qw( is_valid_checksum );
		
	#verify the checksum
	if( is_valid_checksum('01234567') ) { ... }

=head1 DESCRIPTION

=over 4

=item new($issn)

The constructor accepts a scalar representing the ISSN.

The string representing the ISSN may contain characters
other than [0-9xX], although these will be removed in the
internal representation.  The resulting string must look
like an ISSN - the first seven characters must be digits and
the eighth character must be a digit, 'x', or 'X'.

The string passed as the ISSN need not be a valid ISSN as
long as it superficially looks like one.  This allows one to
use the C<fix_checksum> method. 

One should check the validity of the ISSN with C<is_valid()>
rather than relying on the return value of the constructor. 

If all one wants to do is check the validity of an ISSN, 
one can skip the object-oriented  interface and use the
c<is_valid_checksum()> function which is exportable on demand.

If the constructor decides it can't create an object, it
returns undef.  It may do this if the string passed as the
ISSN can't be munged to the internal format.

=item $obj->checksum

Return the ISSN checksum.

=item $obj->as_string

Return the ISSN as a string. 

A terminating 'x' is changed to 'X'.

=item  $obj->is_valid

Returns 1 if the checksum is valid.

Returns 0 if the ISSN does not pass the checksum test.  
The constructor accepts invalid ISSN's so that
they might be fixed with C<fix_checksum>.  

=item  $obj->fix_checksum

Replace the eighth character with the checksum the
corresponds to the previous seven digits.  This does not
guarantee that the ISSN corresponds to the product one
thinks it does, or that the ISSN corresponds to any product
at all.  It only produces a string that passes the checksum
routine.  If the ISSN passed to the constructor was invalid,
the error might have been in any of the other nine positions.

=back

=head2 EXPORTABLE FUNCTIONS

Some functions can be used without the object interface.  These
do not use object technology behind the scenes.

=over 4

=item is_valid_checksum('01234567')

Takes the ISSN string and runs it through the checksum
comparison routine.  Returns 1 if the ISSN is valid, 0 otherwise.

=back

=head1 AUTHOR

Currently maintained by brian d foy C<< <brian.d.foy@gmail.com> >>.
Sami Poikonen <sp@iki.fi>

Original module by Sami Poikonen, based on Business::ISBN by brian d foy.

This module is released under the terms of the Perl Artistic License.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1999-2008, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut
