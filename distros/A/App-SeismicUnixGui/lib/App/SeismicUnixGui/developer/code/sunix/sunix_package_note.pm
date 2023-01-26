package App::SeismicUnixGui::developer::code::sunix::sunix_package_note;

use Moose;
our $VERSION = '0.0.1';

my @lines;

=head2 encapsulated variables

=cut

my $sunix_package_note = {
	_package_name => '',
	_sub_note     => '',
};

=head2 sub get_section 

 print("sunix_package_note,get_section,@lines\n");

=cut

sub get_section {
	my ($self) = @_;
	return ( \@lines );
}

=head2 sub set_sub_note

  print("sunix_package_note,name,@lines\n");

=cut

sub set_sub_note {
	my ($self) = @_;

	my $package_name = $sunix_package_note->{_package_name};

	$lines[0] =
		'=head2 sub note' . "\n\n"
	  . 'collects switches and assembles bash instructions' . "\n"
	  . 'by adding the program name' . "\n\n" . '=cut' . "\n\n";

	$lines[1] =
		' sub  note {' . "\n\n" . "\t" . '$'
	  . $package_name
	  . '->{_note}     = '
	  . "'$package_name'." . '$'
	  . $package_name
	  . '->{_note};' . "\n" . "\t"
	  . 'return ( $'
	  . $package_name
	  . '->{_note} );' . "\n\n" . ' }'
	  . "\n\n\n";

	# print("sunix_packge_note, set_sub_note, lines= @lines \n");

	return ();

}

=head2 sub set_package_name

  print("sunix_package_note,name,@lines\n");

=cut

sub set_package_name {

	my ( $self, $name_href ) = @_;

	if ($name_href) {

		# print("sunix_package_note,set_package_name as: $name_href \n");
		$sunix_package_note->{_package_name} = $name_href;

	}
	else {
		print("sunix_package_note,set_package_name, mising package name \n");
	}

	return ();
}

1;
