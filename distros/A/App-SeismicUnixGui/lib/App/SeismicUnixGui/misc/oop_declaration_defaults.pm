package App::SeismicUnixGui::misc::oop_declaration_defaults;

use Moose;
our $VERSION = '0.0.2';

=head2 Default perl lines for oop_declaration_defaults
       of imported packages V 0.0.1
       ew 
	V 0.0.2 July 24 2018 include data_in, include data_out
	V 0.0.3 4-5-19 remove duplicate program names

=cut

use aliased 'App::SeismicUnixGui::misc::manage_files_by2';

=head2 program parameters
	 
  private hash
  
=cut

my $oop_declaration_defaults = { _prog_names_aref => '', };

sub section {
	my ($self) = @_;

	my $ref_declaration_lines = _get_declaration();
	return ($ref_declaration_lines);
}

=head2 sub _get_declaration

		filter duplicates 4-5-2019

=cut

sub _get_declaration {

	my ($self) = @_;

	if ( $oop_declaration_defaults->{_prog_names_aref} ) {


		my @unique_progs;
		my $unique_progs_ref;
		my $num_unique_progs;
		my @prog_name = @{ $oop_declaration_defaults->{_prog_names_aref} };
		my $length    = scalar @prog_name;
		my @oop_declaration_defaults;
		my $filter = manage_files_by2->new();

		# user-defined programs
		# remove repeated programs from the list
		$unique_progs_ref = $filter->unique_elements( \@prog_name );
		my $results = $unique_progs_ref;
		return ($results);
	}
	else {
		print("declaration,_get_declaration, missing declaration->{_prog_names_aref} \n");
	}

}

=head2 sub set_prog_names_aref

=cut

sub set_prog_names_aref {
	my ( $self, $hash_aref ) = @_;

	if ($hash_aref) {
		$oop_declaration_defaults->{_prog_names_aref} = $hash_aref->{_prog_names_aref};

	}
	else {
		print("declaration, set_prog_names_aref, missing hash_aref\n");
	}

	return ();
}

1;
