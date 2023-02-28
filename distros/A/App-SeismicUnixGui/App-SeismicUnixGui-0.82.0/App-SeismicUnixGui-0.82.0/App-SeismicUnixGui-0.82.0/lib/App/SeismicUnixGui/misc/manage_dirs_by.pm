package App::SeismicUnixGui::misc::manage_dirs_by;

use Moose;
our $VERSION = '0.0.1';

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $L_SU_global_constants = L_SU_global_constants->new();
my $var = {_skip_directory         => 'archive',};

# manage_dirs_by  class
# Contains methods/subroutines/functions to operate on directories
# V 1. March 3 2008
# Juan M. Lorenzo

=head2 private hash of shared variables

=cut

my $manage_dirs_by = {

	_directory => '',

};

=head2 clear shared variable(s)
in memory


=cut

sub clear {

	$manage_dirs_by->{_directory} = '';

}

=head2 sub _get_contents_aref

Reference of array with contents of 
the search directory

=cut

sub _get_contents_aref {

	my ($self) = @_;

	my $result_aref;

	if ( length $manage_dirs_by->{_directory} ) {

		my $SEARCH_DIR = $manage_dirs_by->{_directory};

#		print("manage_dirs_by, _get_contents_aref, SEARCH_DIR=$SEARCH_DIR\n");

		if ( opendir( DIR, $SEARCH_DIR ) ) {

			my @directory_list = readdir(DIR);

			$result_aref = \@directory_list;
#			print("manage_dirs_by, _get_contents_aref, directory_list=@directory_list\n");
			close(DIR);

		}
		else {
#           print("manage_dirs_by, _get_contents_aref,directory not found; NADA\n");
		}

	}
	else {
	  #		print("manage_dirs_by, _get_contents_aref, missing directory; NADA\n");
	}
	return ($result_aref);
}

sub get_file_list_aref {

	my ($self) = @_;

	my $list_aref;
	my @filtered_directory;

	if ( length $manage_dirs_by->{_directory} ) {

		$list_aref = _get_contents_aref();

		if ( length $list_aref ) {

			my @directory_list = @$list_aref;

			foreach my $thing (@directory_list) {

				if (   $thing eq '.'
					or $thing eq '..'
					or $thing eq $var->{_skip_directory} )
				{
#					print(
#						"manage_dirs_by, get_file_list_aref,skip directory\n");
#					print("manage_dirs_by, get_file_list_aref,thing:$thing\n");
					next;

				}
				else {
					push @filtered_directory, $thing;
				}
			}

			my $result_aref = \@filtered_directory;
#			print ("manage_dirs_byfiltered directory = @filtered_directory\n");
			return ($result_aref);

		}
		else {
#			print("manage_dirs_by,get_file_list_aref, empty directory list NADA\n");
			return();
		}

	}
	else {
		print("manage_dirs_by,$self,get_list_aref missing variable\n");
		return ();
	}
	
}

sub get_list_aref {

	my ($self) = @_;

	my $list_aref;
	my @filtered_directory;

	if ( length $manage_dirs_by->{_directory} ) {

		$list_aref = _get_contents_aref;

		if ( length $list_aref ) {

			my @directory_list  = @$list_aref;
			@filtered_directory = @directory_list;

			foreach my $thing (@directory_list) {

				if (   $thing eq '.'
					or $thing eq '..' )
				{

					next;

				}
				else {
					push @filtered_directory, $thing;
					print("manage_dirs_by, get_list_aref,filtered_directory= $thing\n");
				}
			}

			my $result_aref = \@filtered_directory;
			return ($result_aref);

		}
		else {
			print("empty directory list NADA\n");
		}

	}
	else {
		print("manage_dirs_by,$self,get_list_aref missing variable\n");
		return ();
	}

}

sub lsc1_dir_files {

	# this function makes a list of the directory contents
	# one file name per line
	# leaves the list inside the directory of interest
	# writes the list to .lsc1
	#get directory names
	my ($directory) = shift @_;
	system(
		" cd $directory;   		\\
		ls -c1 > .lsc1;			\\
	"
	);
}

sub lsc1_grep_dir_files {

	# this function makes a list of the directory contents
	# one file name per line
	# leaves the list inside the directory of interest
	# writes the list to .lsc1_grep

	#get directory names
	my ($directory) = shift @_;
	my ($pattern)   = shift @_;

	#$pattern = 'asc';
	print("pattern-$pattern\n\n");
	print("directory-$directory\n\n");
	system(
		" cd $directory;   		\\
		ls -c1 | grep $pattern |sort -n > .lsc1_grep;\\
	"
	);
}

sub make_dir {

	# this function/method  makes a  directory
	# if it does not exist already

	# get directory names
	my ($self, $directory) = @_;

#    print ("\nmanage_dirs_by, make_dir, Making directories----$self, $directory---\n");

	system(
		"                       	\\
                mkdir -p $directory       	\\
        "
	);

}

sub rm_dir {

	# this function/method deletes a directory

	#get directory names
	my ($directory) = shift @_;

	print("\n Cleaning directory $directory \n");

	system(
		"                       	\\
                rm -r $directory		\\
        "
	);
}

sub set_directory {

	my ( $self, $dir ) = @_;

	if ( length $dir ) {

		$manage_dirs_by->{_directory} = $dir;
#		print("manage_dirs_by, set_directory, manage_dirs_by->{_directory}=$manage_dirs_by->{_directory}\n");

	}
	else {
		print("manage_dirs_by,self=$self, set_directory, missing variable\n");
	}
	return ();

}

sub set_suffix_type {

	my ( $self, $suffix_type ) = @_;

	if ( length $suffix_type ) {

	}
	else {
		print("manage_dirs_by,$self, set_suffix_type, missing variable\n");
	}

	return ();
}

1;
