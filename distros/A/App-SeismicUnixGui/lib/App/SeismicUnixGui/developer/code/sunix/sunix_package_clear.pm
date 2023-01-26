package App::SeismicUnixGui::developer::code::sunix::sunix_package_clear;

use Moose;
our $VERSION = '0.0.1';

my @lines;

=head2 encapsulated variables

=cut

my $sunix_package_clear = {
	_package_name => '',
	_param_names  => '',
};

=head2 sub set_param_names

  print("sunix_package_clear,name,@lines\n");

=cut

sub set_param_names {
	my ( $self, $name_aref ) = @_;

	my ( $first, $last, $i, $package_name );

	if ($name_aref) {

		# print("sunix_package_clear,set_param_names, @{$name_aref}\n");
		$sunix_package_clear->{_set_param_names} = $name_aref;
		$package_name = $sunix_package_clear->{_package_name};

		# print("sunix_package_clear,set_param_names, $package_name\n");

		my $length = scalar @$name_aref;
		$lines[0] = "";
		$lines[1] = (" sub clear") . " {\n\n";

		for ( $i = 2, my $j = 0 ; $j < $length ; $i++, $j++ ) {
			$lines[$i] =
				"\t\t" . '$'
			  . $package_name . '->{_'
			  . @$name_aref[$j] . '}'
			  . "\t\t\t"
			  . '= \'\';'
			  . ("\n");
		}

		$lines[$i] =
			"\t\t" . '$'
		  . $package_name
		  . '->{_Step}'
		  . "\t\t\t"
		  . '= \'\';'
		  . ("\n");
		$lines[ ++$i ] =
			"\t\t" . '$'
		  . $package_name
		  . '->{_note}'
		  . "\t\t\t"
		  . '= \'\';'
		  . ("\n");
		$lines[ ++$i ] = ' }' . ("\n");
		$lines[ ++$i ] = ("\n");

	}
	else {
		print(
			"sunix_package_clear,set_param_names, missing parameter names \n");
	}

}

=head2 sub set_package_name

  print("sunix_package_clear,name,@lines\n");

=cut

sub set_package_name {

	my ( $self, $name_href ) = @_;

	if ($name_href) {

		#print("sunix_package_clear,set_package_name as: $name_href \n");
		$sunix_package_clear->{_package_name} = $name_href;

	}
	else {
		print("sunix_package_clear,set_package_name, mising package name \n");
	}

	return ();
}

=head2 sub get_section 

 print("sunix_package_clear,get_section,@lines\n");

=cut

sub get_section {
	my ($self) = @_;
	return ( \@lines );
}

1;
