use Test::More;
use Test::Compile;


=head1 Test for specs modules

require_ok tests if a module or file loads successfully

=cut


=head2 Important definitions

298 test for specs

=cut

my $SeismicUnixGui='./lib/App/SeismicUnixGui';
print("configs.t,SeismicUnixGui=$SeismicUnixGui\n");

=head2 import modules

=cut

use strict;
use warnings;
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

=head2 Instantiation 

=cut

my $L_SU_global_constants = L_SU_global_constants->new();
my $test = Test::Compile->new();


my @dirs = ("$SeismicUnixGui/sunix");
print @dirs;
$test->all_files_ok(@dirs);

=head2 Important definitions 

of directory structure

=cut 

my $GRANDPARENT_DIR = $SeismicUnixGui;


=head2 privately shared hash

=cut

my $change_a_line = {
	_child_directory_su_number_of  => '',
	_file_name                     => '',
	_line_of_interest_aref         => '',
	_parent_directory_su_number_of => '',
	_pathNfile_aref                => '',
};


=head2 Get all the files and their paths

from the SU category

=cut

$L_SU_global_constants->set_CHILD_DIR_type('SU');
$L_SU_global_constants->set_PARENT_DIR_type('SU');
$L_SU_global_constants->set_GRANDPARENT_DIR($GRANDPARENT_DIR);
my ( $su_pathNfile_aref, $su_dimension_aref ) =
  $L_SU_global_constants->get_pathNfile2search();


=head2 search for lines of interest

in SU-type files and replace them

=cut 

my @dimension_su                  = @$su_dimension_aref;
my $parent_directory_su_number_of = $dimension_su[0];
my $child_directory_su_number_of  = $dimension_su[1];

print("parent_directory_su_number_of=$parent_directory_su_number_of\n");
print("child_directory_su_number_of=$child_directory_su_number_of\n");

my @su_pathNfile = @$su_pathNfile_aref;

_set_parent_directory_number_of($parent_directory_su_number_of);
_set_child_directory_number_of($child_directory_su_number_of);
_set_pathNfile_aref($su_pathNfile_aref);
_test();


=head2 sub _set_child_directory_number_of 

=cut

sub _set_child_directory_number_of {

	my ($self) = @_;

	$change_a_line->{_child_directory_number_of} = $self;

	#	print ("_set_child_directory_number_of=$self\n");

	return ();
}


=head2 sub _set_parent_directory_number_of 

=cut

sub _set_parent_directory_number_of {

	my ($self) = @_;

	$change_a_line->{_parent_directory_number_of} = $self;

	#    print ("_set_parent_directory_number_of=$self\n");
	return ();
}

=head2 sub _set_pathNfile_aref 

=cut

sub _set_pathNfile_aref {
	my ($self) = @_;

	$change_a_line->{_pathNfile_aref} = $self;
	
	return ();
}

=head2 sub _test 

=cut

sub _test{
	
	my ($self) = @_;
	

	my $child_directory_number_of =
	  $change_a_line->{_child_directory_number_of};
	my $parent_directory_number_of =
	  $change_a_line->{_parent_directory_number_of};
	my @pathNfile = @{ $change_a_line->{_pathNfile_aref} };

	my @line_of_interest_aref;

	for (
		my $parent = 0, my $count_idx = 0 ;
		$parent < $parent_directory_number_of ;
		$parent++
	  )
	{
		for ( my $child = 0 ; $child < $child_directory_number_of ; $child++ ) {

			# print("starting inner count=$count; parent=$parent\n");
			my @pathNfile_list        = @{ $pathNfile[$parent][$child] };
			my $pathNfile_list_length = scalar @pathNfile_list;

			for (
				my $i = 0, my $j = $count_idx ;
				$i < $pathNfile_list_length ;
				$i++, $j++
			  )
			{

#                   print $pathNfile_list[$i]."\n";
#                   require_ok($pathNfile_list[$i]);
#					system("perl $pathNfile_list[$i]");

			}    #for files in a list

		}    # for each child directory

	}    #for each parent directory

	my $result = \@line_of_interest_aref;
	return ($result);



	
	return ();
}

done_testing();
