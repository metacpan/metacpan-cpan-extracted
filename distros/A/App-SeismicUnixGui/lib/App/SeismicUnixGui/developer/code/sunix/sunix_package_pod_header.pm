package App::SeismicUnixGui::developer::code::sunix::sunix_package_pod_header;
use Moose;
our $VERSION = '0.0.1';

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

=pod

private hash

=cut

my $sunix_package_pod_header = {

	_prog_docs => '',

};

sub set_prog_docs_aref {

	my ( $self, $prog_docs_aref ) = @_;

	if ( defined $prog_docs_aref
		&& $prog_docs_aref ne $empty_string )
	{
		my @prog_docs = @$prog_docs_aref;
		my $length    = scalar @prog_docs;

		$sunix_package_pod_header->{_prog_docs} = \@$prog_docs_aref;

		# print("sunix_package_pod_header,set_prog_docs, @$prog_docs_aref\n");

	}
	else {
		print("sunix_package_pod_header,set_prog_docs, missing prog_docs\n");
	}

}

=head2 Default perl lines for the pod_headers of the file


=cut

sub set_header {

	my ($self) = @_;

	my @head;

	$head[0] =

		'=head2 SYNOPSIS

PACKAGE NAME: 

AUTHOR:  

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES'. "\n";

	if ( $sunix_package_pod_header->{_prog_docs} ) {

		# add a NEW LINE character to each element of the array
		my $prog_docs_aref = $sunix_package_pod_header->{_prog_docs};
		my @prog_docs      = @$prog_docs_aref;
		my $length         = scalar @prog_docs;
		my $last_line		= $length + 1;

		for ( my $i = 0; $i < $length; $i++) {

			# print("set_header\n");

			$head[0] = $head[0] . $prog_docs[$i] . "\n\n";

			# print("sunix_package_pod_header,prog_docs,line#$i : $head[0]");
		}

		# print("sunix_package_pod_header,prog_docs,line#0 : $head[0]");
		$head[0] = $head[0] .
		
'=head2 User\'s notes (Juan Lorenzo)
untested

=cut


=head2 CHANGES and their DATES

=cut' . "\n\n";

		$sunix_package_pod_header->{_header} = \@head;
		# print("sunix_package_pod_header,get_section,result: @head");

	}
	else {
		print("sunix_package_pod_header,set_header,missing paramters");
	}

}

sub get_section {

	if ( $sunix_package_pod_header->{_header} ) {

		my $result = $sunix_package_pod_header->{_header};
		# print("sunix_package_pod_header,get_section,result: @$result\n");
		return ($result);

	}
	else {
		print("sunix_package_pod_header,get_section, missing header\n");
	}

}

1;
