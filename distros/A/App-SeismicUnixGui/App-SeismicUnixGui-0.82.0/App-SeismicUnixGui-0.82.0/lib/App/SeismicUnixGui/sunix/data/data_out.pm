package App::SeismicUnixGui::sunix::data::data_out;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PROGRAM NAME: data_out.pm 
 AUTHOR: 	Juan Lorenzo
 DATE: 		June 22 2017
  

 DESCRIPTION 
     

 BASED ON:
 Version 0.0.1 June 22 2017

 Version 0.0.2 July 26 2018
 
 Version 0.0.3 August 30 2021


=cut

=head2 USE

Use abbreviations such as 
bin sgy txt and su to automatically access directories
that contain the types of files represented by these suffixes.

For example, all segy-type files are placed in the same directory
If you want to find one of these files, place the parameter =
sgy on the second line (suffix_type)

To automatically go to the segy-type directory, click on MB-3 while
over the first parameter input (base_file_name)

=head3 NOTES

=head4 Examples


=head2 CHANGES and their DATES

  Version 0.02 July 22 2018 added subs: 
  	suffix_type, inbound  _get_inbound
  	_get_suffix, _get_DIR

  Version 0.03  All file without a suffix
  in which case the default PATH is the
  path of PL_SEISMIC
  
=cut 

=head2 Notes from bash
 
=cut 

use Moose;
our $VERSION = '0.0.3';

my $data_out = {
	_Step           => '',
	_base_file_name => '',
	_note           => '',
	_notes_aref     => '',
	_suffix_type    => '',
};

=head2 

Instantiate packages

=cut

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

=head2 subroutine _get_DIR
	
  send PATH for suffix_suffix_type
  suffix_type can be su txt sgy or su
  or nothing, in which case the file
  goes to the PL_SEISMIC directory
  by default
  

=cut

sub _get_DIR {
	my ($self) = @_;

	use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
	my $Project = Project_config->new();
	my $DIR;

	if ( length $data_out->{_suffix_type} ) {

		use App::SeismicUnixGui::misc::SeismicUnix
		  qw($bin $ps $seg2 $segb $segd $sgd $segy $sgy $su $txt );

		my $suffix_type = $data_out->{_suffix_type};

		if ( $suffix_type eq $ps ) {

			my ($PS_SEISMIC) = $Project->PS_SEISMIC();
			$DIR = $PS_SEISMIC;

		}
		elsif ( $suffix_type eq $su ) {

			my ($DATA_SEISMIC_SU) = $Project->DATA_SEISMIC_SU();
			$DIR = $DATA_SEISMIC_SU;

		}
		elsif ( $suffix_type eq $bin ) {

			my ($DATA_SEISMIC_BIN) = $Project->DATA_SEISMIC_BIN();
			$DIR = $DATA_SEISMIC_BIN;

		}
		elsif ( $suffix_type eq $txt ) {

			my ($DATA_SEISMIC_TXT) = $Project->DATA_SEISMIC_TXT();
			$DIR = $DATA_SEISMIC_TXT;

		}
		elsif ( $suffix_type eq $seg2 ) {

			my ($DATA_SEISMIC_SEG2) = $Project->DATA_SEISMIC_SEG2();
			$DIR = $DATA_SEISMIC_SEG2;

		}
		elsif ( $suffix_type eq $segb ) {

			my ($DATA_SEISMIC_SEGB) = $Project->DATA_SEISMIC_SEGB();
			$DIR = $DATA_SEISMIC_SEGB;

		}
		elsif ( $suffix_type eq $segd ) {

			my ($DATA_SEISMIC_SEGD) = $Project->DATA_SEISMIC_SEGD();
			$DIR = $DATA_SEISMIC_SEGD;

		}

		elsif ( $suffix_type eq $sgd ) {

			my ($DATA_SEISMIC_SEGD) = $Project->DATA_SEISMIC_SEGD();
			$DIR = $DATA_SEISMIC_SEGD;

		}
		elsif ( $suffix_type eq $sgy ) {

			my ($DATA_SEISMIC_SEGY) = $Project->DATA_SEISMIC_SEGY();
			$DIR = $DATA_SEISMIC_SEGY;

		}
		elsif ( $suffix_type eq $segy ) {

			my ($DATA_SEISMIC_SEGY) = $Project->DATA_SEISMIC_SEGY();
			$DIR = $DATA_SEISMIC_SEGY;

		}
		else {
			print("data_out, _get_DIR, unexpected suffix_type\n");
			return ($empty_string);
		}

		return ($DIR);

	}
	else {
		my ($PL_SEISMIC) = $Project->PL_SEISMIC();
		$DIR = $PL_SEISMIC;

		#		print("data_out, _get_DIR, suffix_type default is PL_SEISMIC \n");
		return ($DIR);
	}
}

=head2 subroutine _get_suffix
	
  send PATH for suffix_type
  suffix_type can be su txt sgy or su
  

=cut

sub _get_suffix {
	my ($self) = @_;

	if ( $data_out->{_suffix_type} ) {

		my $suffix;
		my $suffix_type = $data_out->{_suffix_type};

		use App::SeismicUnixGui::misc::SeismicUnix
		  qw($suffix_seg2 $suffix_segb $suffix_segd $suffix_sgd $suffix_sgy $suffix_segy $suffix_su $suffix_bin $suffix_ps $suffix_txt $segy $sgy $su $txt $bin);

		if ( $suffix_type eq $ps ) {

			$suffix = $suffix_ps;

		}
		elsif ( $suffix_type eq $su ) {

			$suffix = $suffix_su;

		}
		elsif ( $suffix_type eq $seg2 ) {

			$suffix = $suffix_seg2;

		}
		elsif ( $suffix_type eq $segb ) {

			$suffix = $suffix_segb;

		}
		elsif ( $suffix_type eq $segd ) {

			$suffix = $suffix_segd;

		}
		elsif ( $suffix_type eq $sgd ) {

			$suffix = $suffix_sgd;
		}
		elsif ( $suffix_type eq $sgy ) {

			$suffix = $suffix_sgy;

		}
		elsif ( $suffix_type eq $segy ) {

			$suffix = $suffix_segy;

		}
		elsif ( $suffix_type eq $bin ) {

			$suffix = $suffix_bin;

		}
		elsif ( $suffix_type eq $txt ) {

			$suffix = $suffix_txt;

		}
		elsif ( $suffix_type eq $empty_string ) {

			print(
"data_out, suffix_type is not su, bin, seg2, segb, segd, segy or txt\n"
			);
			$suffix = $empty_string;

		}
		else {
			print("data_out, unexpected suffix_type\n");
		}

		return ($suffix);

	}
	elsif ( not( length $data_out->{_suffix_type} ) ) {

#		print("data_out _get_sufix, suffix_type is blank so assume that it means there is non\n");
		my $suffix = $empty_string;
		return ($suffix);

	}
	else {
		print("data_out, _get_suffix, suffix_type unexpected  \n");
		return ();
	}
}

=head2 subroutine Step
 
 adds the program name

=cut

sub Step {
	my ($self) = @_;
	my $note;

	$data_out->{_note} = _get_outbound();
	$note = $data_out->{_note};

	return $note;

}

=head2 subroutine _get_outbound

  suffix_type can be su txt sgy or su

=cut

sub _get_outbound {
	my ($self) = @_;

	my $outbound;
	my $suffix_type;
	my $DIR;
	my $file;
	my $suffix;

	if ( length $data_out->{_suffix_type}
		&& $data_out->{_base_file_name} )
	{

		$file = $data_out->{_base_file_name};

		$DIR      = _get_DIR();
		$suffix   = _get_suffix();
		$outbound = $DIR . '/' . $file . $suffix;

		# print ("1. data_out,_get_outbound outbound: $outbound\n");
		return ($outbound);

	}
	elsif ( length $data_out->{_base_file_name}
		&& not( $data_out->{_suffix_type} ) )
	{

		$file = $data_out->{_base_file_name};

		$DIR      = _get_DIR();
		$outbound = $DIR . '/' . $file;

		# print ("2. data_out,_get_outbound outbound: $outbound\n");
		return ($outbound);

	}
	else {
		print("data_out, missing: suffix_type, base file name  \n");
	}
}

=head2 sub  base_file_name 

	has no suffix
  
=cut

sub base_file_name {
	my ( $variable, $base_file_name ) = @_;

	if ($base_file_name) {

		$data_out->{_base_file_name} = $base_file_name;

		#		print ("data_out, base_file_name $data_out->{_base_file_name}\n");

	}
	else {
		print("data_out, base_file_name, name missing \n");
	}
}

=head2 sub  base_file_name_sref  

	has no suffix
  
=cut

sub base_file_name_sref {
	my ( $variable, $base_file_name_sref ) = @_;

	if ($base_file_name_sref) {

		$data_out->{_base_file_name} = $$base_file_name_sref;

		# print ("data_out, base_file_name $data_out->{_base_file_name}\n");

	}
	else {
		print("data_out, base_file_name_sref, name missing \n");

	}
}

=head2 subroutine clear

  sets all variable strings to '' 

=cut

sub clear {
	$data_out->{_Step}           = '';
	$data_out->{_base_file_name} = '';
	$data_out->{_note}           = '';
	$data_out->{_notes_aref}     = '';
	$data_out->{_suffix_type}    = '';
}

my @notes;

# define a value
my $newline = '
';

=head2 sub  full_file_name  

	hase plus suffix
  
=cut

sub full_file_name {
	my ( $self, $full_file_name ) = @_;

	if ($full_file_name) {

		$data_out->{_full_file_name} = $full_file_name;

	}
	else {
		print("data_out, full_file_name, name missing \n");
	}
}

=head2 subroutine get_inbound

  suffix_type can be su txt sgy or su

=cut

sub get_inbound {
	my ($self) = @_;

	my $inbound;
	my $suffix_type;
	my $DIR;
	my $file;
	my $suffix;

	if ( length $data_out->{_suffix_type}
		&& $data_out->{_base_file_name} )
	{

		$file = $data_out->{_base_file_name};

		$DIR     = _get_DIR();
		$suffix  = _get_suffix();
		$inbound = $DIR . '/' . $file . $suffix;

		# print ("data_out,get_inbound inbound: $inbound\n");
		return ($inbound);

	}
	elsif ( length $data_out->{_base_file_name}
		&& not( $data_out->{_suffix_type} ) )
	{

		print(
			"data_out, missing: suffix_type, base file name . 
		Assume that the expected output is PL_SEISMIC-- as default\n"
		);
		$DIR     = _get_DIR();
		$suffix  = _get_suffix();
		$inbound = $DIR . '/' . $file . $suffix;
		return ($inbound);

	}
	else {
		print(
"data_out, missing: suffix_type, base file name . Assume that is what the user wants NADA\n"
		);
		return ($empty_string);
	}
}

=head2 sub  file_name  you need to know how many numbers per line
  will be in the output file 

=cut

sub file_name {
	my ( $variable, $file_name ) = @_;
	if ($file_name) {
		$data_out->{_file_name} = $file_name;
		$data_out->{_note} =
		  $data_out->{_note} . ' data_out=' . $data_out->{_file_name};
		$data_out->{_Step} =
		  $data_out->{_Step} . ' data_out=' . $data_out->{_file_name};
	}
}

=head2 sub get_max_index

max index = number of input variables -1

=cut

sub get_max_index {
	my ($self) = @_;

	# base_file_name : index=0
	# suffix_type      : index=1
	my $max_index = 1;

	return ($max_index);
}

=pod

=head2 subroutine note 
 adds the program name

=cut

sub notes_aref {
	my ($self) = @_;

	$notes[1] = "\t" . '$data_out[1] 	= ' . $data_out->{_note};

	$data_out->{_notes_aref} = \@notes;

	return $data_out->{_notes_aref};
}

=head2 subroutine suffix_type

  suffix_type can be su txt sgy or su

=cut

sub suffix_type {
	my ( $self, $suffix_type ) = @_;

	if ($suffix_type) {

		$data_out->{_suffix_type} = $suffix_type;

	}
	else {
		print("data_out, suffix_type missing \n");
	}
}

=head2 subroutine type

  suffix_type can be:
  	bin
    sgy
  	su 
  	txt
  	legacy: as of Oct 31, 2018

=cut

sub type {
	my ( $self, $suffix_type ) = @_;

	if ($suffix_type) {

		$data_out->{_suffix_type} = $suffix_type;

	}
	else {
		print("data_out, type missing \n");
	}
}

1;
