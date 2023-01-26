package App::SeismicUnixGui::misc::array;

=head1 DOCUMENTATION


=head2 SYNOPSIS 
Tools to manage arrays

 PERL PROGRAM NAME: array.pm
 AUTHOR: 	Juan Lorenzo
 DATE: 		Dec. 2021

 DESCRIPTION 
     

 BASED ON:

=cut

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

=head2 CHANGES and their DATES

=cut 

=head2 Notes from bash
 
=cut

=head2 declare libraries

=cut

use Moose;
our $VERSION = '0.0.1';

=head2 define private hash
to share

=cut

my $array = { _ref => '', };

=head2 sub clear
all memory

=cut

sub clear {
	$array->{_ref} = '';
}

=head2 sub set_ref

set array ref

=cut

sub set_ref {
	my ( $self, $array_ref ) = @_;

	if ( length $array_ref ) {

		$array->{_ref} = $array_ref;

	}
	else {
		print("array, set_ref, missing variable\n");
	}

}

=head2 sub get_elements_number_of

for an aray reference

=cut

sub get_elements_number_of {

	my ($self) = @_;

	if ( length $array->{_ref} ) {

		my $result;
		my $array_ref2          = $array->{_ref};
		my @array2              = @{$array_ref2};
		my $arrays_number_of    = scalar @array2;
		my $elements_number_of = 0;
		my @array;
  
#		print("array, get_elements_number_of, arrays_number_of = $arrays_number_of\n");
		
		for ( my $i = 0 ; $i < $arrays_number_of ; $i++ ) {
			
	        @array = @{$array2[$i]};
			$elements_number_of = scalar @array  + $elements_number_of;
		}
		
		$result = $elements_number_of;
		return ($result);

	}
	else {
		print("cmpcc, get_elements_number_of, missing array reference \n");
	}
}


=head2 sub get_one_row_aref

join an array of array_refs
into a single-component array
containint one list of numbers

		print("@piece\n");
		print("array,joined_array=@joined_array\n");
		my $number_of_elements = scalar @joined_array;
		print("array,number_of_elements=$number_of_elements\n");

=cut

sub get_one_row_aref {

	my ($self) = @_;

	if ( length $array->{_ref} ) {

		my $result;
		my $array_ref2          = $array->{_ref};
		my @array2              = @{$array_ref2};
		my $arrays_number_of    = scalar @array2;
		my @joined_array		= ();
		my @piece;
  
#		print("array, get_one_row_aref, arrays_number_of = $arrays_number_of\n");
		
		for ( my $i = 0 ; $i < $arrays_number_of ; $i++ ) {
			
	        @piece = @{$array2[$i]};
			push (@joined_array, @piece)			

		}
		
		$result = \@joined_array;
		return ($result);

	}
	else {
		print("cmpcc, get_one_row_aref, missing array reference \n");
	}
}

1;
