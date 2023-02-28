package App::SeismicUnixGui::developer::code::sunix::sunix_package_Step;

use Moose;
our $VERSION = '0.0.1';

my @lines;

=head2 encapsulated variables

=cut

my $sunix_package_Step = {
	_package_name => '',
	_sub_Step     => '',
};

=head2 sub get_section 

 print("sunix_package_Step,get_section,@lines\n");

=cut

sub get_section {
	my ($self) = @_;
	return ( \@lines );
}

=head2 sub set_sub_Step

  print("sunix_package_Step,name,@lines\n");

=cut

sub set_sub_Step {
	my ($self) = @_;

	my $package_name = $sunix_package_Step->{_package_name};

	$lines[0] =
		'=head2 sub Step' . "\n\n"
	  . 'collects switches and assembles bash instructions' . "\n"
	  . 'by adding the program name' . "\n\n" . '=cut' . "\n\n";

	$lines[1] =
		' sub  Step {' . "\n\n" . "\t" . '$'
	  . $package_name
	  . '->{_Step}     = '
	  . "'$package_name'." . '$'
	  . $package_name
	  . '->{_Step};' . "\n" . "\t"
	  . 'return ( $'
	  . $package_name
	  . '->{_Step} );' . "\n\n" . ' }'
	  . "\n\n\n";

	# print("sunix_packge_Step, set_sub_Step, lines= @lines \n");

	return ();

}

=head2 sub set_package_name

  print("sunix_package_Step,name,@lines\n");

=cut

sub set_package_name {

	my ( $self, $name_href ) = @_;

	if ($name_href) {

		# print("sunix_package_Step,set_package_name as: $name_href \n");
		$sunix_package_Step->{_package_name} = $name_href;

	}
	else {
		print("sunix_package_Step,set_package_name, mising package name \n");
	}

	return ();
}

1;
