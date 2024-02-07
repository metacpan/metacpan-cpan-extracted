package App::SeismicUnixGui::misc::pm_io;

=head1 DOCUMENTATION

=head2 SYNOPSIS 
 Common i/p o/p requests for all packages

 PROGRAM NAME: 
 AUTHOR: Juan Lorenzo
 DATE:   V 0.0.1 January 2024
         
 DESCRIPTION: 

 =head2 USE

=head3 NOTES 

=head4 
 Examples

=head3 NOTES  

=head4 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';

=head2 

Define private hash
to share

=cut

my $pm_io = {
	_directory_in => '',
	_file_in      => '',
	_pathNfile    => '',
};

=head2 sub clear

Clear all memory

=cut

sub clear {
	my $self = @_;

	$pm_io->{_directory_in} = '';
	$pm_io->{_file_in}      = '';
	$pm_io->{_pathNfile_in} = '';
}

=head2 sub get_file_in

=cut

sub get_file_in {

	my ( $self, ) = @_;

	if ( length( $pm_io->{_file_in} ) ) {

		my $result = $pm_io->{_file_in};

#		print("pm_io, get_file_in, file=$pm_io->{_file_in} \n");
		return ($result);

	}
	else {
		print("pm_io, get_file_in, missing value\n");

		return ();
	}

}


=head2 sub get_pathNfile_in

=cut

sub get_pathNfile_in {

	my ($self) = @_;

	if (
		length $pm_io->{_file_in}
		and length $pm_io->{_directory_in}
	  )
	{

		my $result = $pm_io->{_directory_in} .'/'. $pm_io->{_file_in};
#		print("pm_io, get_pathNfile_in, pathNfile=$result \n");
		return ($result);
	}
	else {
		print("pm_io, get_pathNfile_in, missing value\n");
		print("pm_io, file_in:$pm_io->{_file_in}\n");
		return ();
	}

}

=head2 sub set_directory_in

=cut

sub set_directory_in {

	my ( $self, $dir ) = @_;

	if ( length($dir) ) {

		$pm_io->{_directory_in} = $dir;

#		print("pm_io, set_directory_in_in, dir=$pm_io->{_directory_in} \n");

	}
	else {
		print("pm_io, set_directory_in, missing value\n");
	}

	return ();
}

=head2 sub set_file_in

=cut

sub set_file_in {

	my ( $self, $file_in ) = @_;

	if ( length($file_in) ) {

		$pm_io->{_file_in} = $file_in;

#		print("pm_io, set_file_in, file=$pm_io->{_file_in} \n");

	}
	else {
		print("pm_io, set_file_in, missing value\n");
	}

	return ();

}

1;
