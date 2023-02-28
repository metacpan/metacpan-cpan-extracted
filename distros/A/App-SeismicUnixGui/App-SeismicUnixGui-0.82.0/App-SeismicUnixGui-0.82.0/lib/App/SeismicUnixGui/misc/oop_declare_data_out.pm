package App::SeismicUnixGui::misc::oop_declare_data_out;
use Moose;
our $VERSION = '0.0.1';

=pod

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PACKAGE NAME: oop_declare_data_out 
 AUTHOR: Juan Lorenzo
 DATE:   Nov 29 2017,

 DESCRIPTION: 
 Version: 1.1

=head2 USE

=head3 NOTES 

=head4 
 Examples

=head3 SEISMIC UNIX NOTES  


=head4 CHANGES and their DATES


=cut

=head2 Default perl lines for

     declaring required packages

=cut

=head2 data
	 
  private hash

=cut

my $oop_declare_data_out = {
	_suffix_type       => '',
	_suffix_type_in    => '',
	_suffix_type_out   => '',
	_param_labels_aref => '',
	_param_values_aref => '',
};

my ( @data_in, @data_out, @inbound_notes, @outbound_notes );

=head2 sub get_section


=cut

sub empty {
	my ($self) = @_;

	$outbound_notes[0] = "";

	return ();
}

sub inbound_section {
	my ($self) = @_;

	# print("oop_declare_data_out ,inbound_section,notes:\n @inbound_notes\n");

	return ( \@inbound_notes );

}

sub outbound_section {
	my ($self) = @_;

   # print("oop_declare_data_out ,outbound_section,notes:\n @outbound_notes\n");
	return ( \@outbound_notes );

}

sub set_bin_in {

	$inbound_notes[1] =
	  "\t" . 'my (@file_in);' . "\n\t" . 'my (@bin_file_in,@inbound);';
	$inbound_notes[2] =
	  "\t" . '$bin_file_in[1]' . "\t" . '= $file_in[1].$suffix_bin;';
	$inbound_notes[3] = "\t"
	  . '$inbound[1]' . "\t"
	  . '= $DATA_SEISMIC_BIN.' . "'/'"
	  . '.$bin_file_in[1];';
}

sub set_bin_out {
	$outbound_notes[1] =
	  "\t" . 'my (@file_out);' . "\n\t" . 'my (@bin_file_out,@outbound);';

	$outbound_notes[2] =
	  "\t" . '$bin_file_out[1]' . "\t" . '= $file_out[1].$suffix_bin;';
	$outbound_notes[3] = "\t"
	  . '$outbound[1]' . "\t"
	  . '= $DATA_SEISMIC_BIN.' . "'/'"
	  . '.$bin_file_out[1];';
}

sub set_text_in {

	$inbound_notes[1] =
	  "\t" . 'my (@file_in);' . "\n\t" . 'my (@text_file_in,@inbound);';
	$inbound_notes[2] =
	  "\t" . '$text_data_in[1]' . "\t" . '= $file_in[1].$suffix_text;';
	$inbound_notes[3] = "\t"
	  . '$inbound[1]' . "\t"
	  . '= $DATA_SEISMIC_TXT.' . "'/'"
	  . '.$text_data_in[1];';

}

sub set_text_out {
	$outbound_notes[1] =
	  "\t" . 'my (@file_out);' . "\n\t" . 'my (@text_file_out,@outbound);';

	$outbound_notes[2] =
	  "\t" . '$text_data_out[1]' . "\t" . '= $file_out[1].$suffix_text;';
	$outbound_notes[3] = "\t"
	  . '$outbound[1]' . "\t"
	  . '= $DATA_SEISMIC_TXT.' . "'/'"
	  . '.$text_data_out[1];';

}

sub set_su_in {
	$inbound_notes[1] =
	  "\t" . 'my (@file_in);' . "\n\t" . 'my (@sudata_in,@inbound);';

	$inbound_notes[2] =
	  "\t" . '$sudata_in[1]' . "\t" . '= $file_in[1].$suffix_su;';
	$inbound_notes[3] = "\t"
	  . '$inbound[1]' . "\t"
	  . '= $DATA_SEISMIC_SU.' . "'/'"
	  . '.$sudata_in[1];';

}

sub set_su_out {

	$outbound_notes[1] =
	  "\t" . 'my (@file_out);' . "\n\t" . 'my (@sudata_out,@outbound);';
	$outbound_notes[2] =
	  "\t" . '$sudata_out[1]' . "\t" . '= $file_out[1].$suffix_su;';
	$outbound_notes[3] = "\t"
	  . '$outbound[1]' . "\t"
	  . '= $DATA_SEISMIC_SU.' . "'/'"
	  . '.$sudata_out[1];';

}

sub set_segb_in {

	$outbound_notes[1] =
	  "\t" . 'my (@file_in);' . "\n\t" . 'my (@segbdata_in,@inbound);';
	$outbound_notes[2] =
	  "\t" . '$segbdata_in[1]' . "\t" . '= $file_in[1].$suffix_segb;';
	$outbound_notes[3] = "\t"
	  . '$inbound[1]' . "\t"
	  . '= $DATA_SEISMIC_SEGB.' . "'/'"
	  . '.$segbdata_in[1];';

}

sub set_segb_out {

	$outbound_notes[1] =
	  "\t" . 'my (@file_out);' . "\n\t" . 'my (@segbdata_out,@outbound);';
	$outbound_notes[2] =
	  "\t" . '$segbdata_out[1]' . "\t" . '= $file_out[1].$suffix_segb;';
	$outbound_notes[3] = "\t"
	  . '$outbound[1]' . "\t"
	  . '= $DATA_SEISMIC_SEGB.' . "'/'"
	  . '.$segbdata_out[1];';

}

sub set_segd_in {

	$outbound_notes[1] =
	  "\t" . 'my (@file_in);' . "\n\t" . 'my (@segddata_in,@inbound);';
	$outbound_notes[2] =
	  "\t" . '$segddata_in[1]' . "\t" . '= $file_in[1].$suffix_segd;';
	$outbound_notes[3] = "\t"
	  . '$inbound[1]' . "\t"
	  . '= $DATA_SEISMIC_SEGD.' . "'/'"
	  . '.$segddata_in[1];';

}

sub set_segd_out {

	$outbound_notes[1] =
	  "\t" . 'my (@file_out);' . "\n\t" . 'my (@segbdata_out,@outbound);';
	$outbound_notes[2] =
	  "\t" . '$segddata_out[1]' . "\t" . '= $file_out[1].$suffix_segd;';
	$outbound_notes[3] = "\t"
	  . '$outbound[1]' . "\t"
	  . '= $DATA_SEISMIC_SEGD.' . "'/'"
	  . '.$segbdata_out[1];';

}

sub set_segy_in {

	$inbound_notes[1] =
	  "\t" . 'my (@file_in);' . "\n\t" . 'my (@segydata_in,@inbound);';
	$inbound_notes[2] =
	  "\t" . '$segydata_in[1]' . "\t" . '= $file_in[1].$suffix_segy;';
	$inbound_notes[3] = "\t"
	  . '$inbound[1]' . "\t"
	  . '= $DATA_SEISMIC_SEGY.' . "'/'"
	  . '.$segydata_in[1];';

}

sub set_segy_out {

	$outbound_notes[1] =
	  "\t" . 'my (@file_out);' . "\n\t" . 'my (@segydata_out,@outbound);';
	$outbound_notes[2] =
	  "\t" . '$segydata_out[1]' . "\t" . '= $file_out[1].$suffix_segy;';
	$outbound_notes[3] = "\t"
	  . '$outbound[1]' . "\t"
	  . '= $DATA_SEISMIC_SU.' . "'/'"
	  . '.$segydata_out[1];';

}

=head2 sub _set_segb_out   

prepare to use segb files

=cut

sub _set_segb_out {
	my ($self) = @_;
	$outbound_notes[0] =
	  "\n\t" . 'my ($DATA_SEISMIC_SEGB) = $Project->DATA_SEISMIC_SEGB();';

}

=head2 sub _set_segd_out   

prepare to use segd files

=cut

sub _set_segd_out {
	my ($self) = @_;
	$outbound_notes[0] =
	  "\n\t" . 'my ($DATA_SEISMIC_SEGD) = $Project->DATA_SEISMIC_SEGD();';

}

=head2 sub _set_segy_out   

prepare to use segy files

=cut

sub _set_segy_out {
	my ($self) = @_;
	$outbound_notes[0] =
	  "\n\t" . 'my ($DATA_SEISMIC_SEGY) = $Project->DATA_SEISMIC_SEGY();';

}

=head2 sub _set_su_out   

prepare to use su files

=cut

sub _set_su_out {
	my ($self) = @_;
	$outbound_notes[0] =
	  "\n\t" . 'my ($DATA_SEISMIC_SU) = $Project->DATA_SEISMIC_SU();';

}

=head2 sub _set_text_out   

prepare to use su files

=cut

sub _set_text_out {
	my ($self) = @_;
	$outbound_notes[0] =
	  "\n\t" . 'my ($DATA_SEISMIC_TXT) = $Project->DATA_SEISMIC_TXT();';

}

=head2 sub _set_bin_out   

prepare to use su files

=cut

sub _set_bin_out {
	my ($variable) = @_;
	$outbound_notes[0] =
	  "\n\t" . 'my ($DATA_SEISMIC_BIN) = $Project->DATA_SEISMIC_BIN();';

}

=head2 sub _set_segb_in   

prepare to use segb files

=cut

sub _set_segb_in {
	my ($self) = @_;
	$inbound_notes[0] =
	  "\n\t" . 'my ($DATA_SEISMIC_SEGB) = $Project->DATA_SEISMIC_SEGB();';
}

=head2 sub _set_segd_in   

prepare to use segd files

=cut

sub _set_segd_in {
	my ($self) = @_;
	$inbound_notes[0] =
	  "\n\t" . 'my ($DATA_SEISMIC_SEGD) = $Project->DATA_SEISMIC_SEGD();';
}

=head2 sub _set_segy_in   

prepare to use segy files

=cut

sub _set_segy_in {
	my ($self) = @_;
	$inbound_notes[0] =
	  "\n\t" . 'my ($DATA_SEISMIC_SEGY) = $Project->DATA_SEISMIC_SEGY();';
}

=head2 sub _set_su_in   

prepare to use su files

=cut

sub _set_su_in {
	my ($self) = @_;
	$inbound_notes[0] =
	  "\n\t" . 'my ($DATA_SEISMIC_SU) = $Project->DATA_SEISMIC_SU();';
}

=head2 sub _set_text_in   

prepare to use su files

=cut

sub _set_text_in {
	my ($self) = @_;
	$inbound_notes[0] =
	  "\n\t" . 'my ($DATA_SEISMIC_TXT) = $Project->DATA_SEISMIC_TXT();';
}

=head2 sub _set_bin_in   

prepare to use su files

=cut

sub _set_bin_in {
	my ($variable) = @_;
	$inbound_notes[0] =
	  "\n\t" . 'my ($DATA_SEISMIC_BIN) = $Project->DATA_SEISMIC_BIN();';

}

=pod

=head2 subroutine  set_suffix_type_in

  you need to know how many numbers per line
  will be in the output file 

=cut

sub set_suffix_type_in {
	my ( $variable, $suffix_type_in ) = @_;

	if ($suffix_type_in) {

		if ( $suffix_type_in eq 'segb' ) {

			_set_segb_in();

		}
		elsif ( $suffix_type_in eq 'segd' ) {

			_set_segd_in();

		}
		elsif ( $suffix_type_in eq 'segy' ) {

			_set_segy_in();

		}
		elsif ( $suffix_type_in eq 'su' ) {

# print("oop_declare_data_out,set_suffix_type_in,suffix_type_in:$suffix_type_in\n");
			_set_su_in();

		}
		elsif ( $suffix_type_in eq 'text' ) {

			_set_text_in();

		}
		elsif ( $suffix_type_in eq 'bin' ) {

			_set_bin_in();

		}
		else {
			print("\n");
		}
	}
}

=head2 subroutine  set_suffix_type_out

  you need to know how many numbers per line
  will be in the output file 

=cut

sub set_suffix_type_out {
	my ( $variable, $suffix_type_out ) = @_;

	if ($suffix_type_out) {

		if ( $suffix_type_out eq 'segb' ) {

			_set_segb_out();
		}
		elsif ( $suffix_type_out eq 'segd' ) {

# print("oop_declare_data_out,set_suffix_type_out,suffix_type_out:$suffix_type_out\n");
			_set_segd_out();

		}
		elsif ( $suffix_type_out eq 'segy' ) {

# print("oop_declare_data_out,set_suffix_type_out,suffix_type_out:$suffix_type_out\n");
			_set_segy_out();

		}
		elsif ( $suffix_type_out eq 'su' ) {

# print("oop_declare_data_out,set_suffix_type_out,suffix_type_out:$suffix_type_out\n");
			_set_su_out();

		}
		elsif ( $suffix_type_out eq 'text' ) {

			_set_text_out();

		}
		elsif ( $suffix_type_out eq 'bin' ) {

			_set_bin_out();

		}
		else {
			print(
"oop_declare_data_out,set_suffix_type_out,suffix_type_out:$suffix_type_out\n"
			);
		}
	}
}

1;
