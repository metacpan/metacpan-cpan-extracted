package App::SeismicUnixGui::developer::code::sunix::sunix_package_header;
use Moose;
our $VERSION = '0.0.1';


=head2 Load modules

=cut

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $L_SU_global_constants = L_SU_global_constants->new();


=head2 private hash

=cut

my $sunix_package_header = { _package_name => '', };

=head2  sub  get_Moose_section

=cut

sub get_Moose_section {
	my ($self) = @_;
	my @head;
	$head[0] = ("use Moose;\n");

	return ( \@head );
}

=head2  sub  get_version_section

=cut

sub get_version_section {
	my ($self) = @_;
	my @head;
	$head[0] = ("our \$VERSION = '0.0.1';\n\n");

	#print("sunix_package_header,get_version_section: $head[0]");
	return ( \@head );
}

=head2  sub  get_package_name_section

=cut

sub get_package_name_section {
	my ($self) = @_;
	my $name = $sunix_package_header->{_package_name};
	
	my $program_category = $L_SU_global_constants->get_developer_sunix_category_h();
	
#	make key
	my $key = '_'.$name;
    my $category = $program_category->{$key};
    my $pathNname_w_colon= 'App::SeismicUnixGui::sunix::'.$category.'::'.$name;
    print("sunix_package_header,get_package_name_section,pathNname_w_colon=$pathNname_w_colon\n");
	my @head;
	$head[0] = ("package $pathNname_w_colon;\n\n");

	# print("sunix_package_header,get_package_name_section: $head[0]");
	return ( \@head );
}

=head2 sub get_section

 Top header section of the file
 print ("sunix_package_header,section:name $name\n");

=cut

sub get_section {
	my ($self) = @_;
	my @head;
	my @package_name = @{ get_package_name_section() };
	my @Moose        = @{ get_Moose_section() };
	my @version      = @{ get_version_section() };
	$head[0] = $package_name[0];
	$head[1] = $Moose[0];
	$head[2] = $version[0];

	# print("sunix_package_header,get_section: @head\n");
	return ( \@head );
}

=head2 sub set_package_name

 a small section of the file
 print ("sunix_package_header,section:name $name\n");

=cut

sub set_package_name {
	my ( $self, $package_name ) = @_;
	my @head;

	if ($package_name) {

		$sunix_package_header->{_package_name} = $package_name;

	}
	else {
		print("sunix_package_header, set_package_name, package name missing\n");
	}

}
1;
