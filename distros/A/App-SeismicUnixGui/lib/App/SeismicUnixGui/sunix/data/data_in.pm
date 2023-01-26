package App::SeismicUnixGui::sunix::data::data_in;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PROGRAM NAME: data_in.pm 
 AUTHOR: 	Juan Lorenzo
 DATE: 		June 22 2017
  

 DESCRIPTION 
     

 BASED ON:
 Version 0.0.1 June 22 2017

 Version 0.0.2 July 22 2018
 
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
  path of PL_SEISMI	C
  
  V 0.0.4 allows seros at start of file name

=cut 

=head2 Notes from bash
 
=cut 

use Moose;
our $VERSION = '0.0.4';

=head2 Instantiation

=cut

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use App::SeismicUnixGui::misc::control '0.0.3';
use aliased 'App::SeismicUnixGui::misc::control';

my $get = L_SU_global_constants->new();

my (@file_in);
my ( @sudata_in, @inbound );

=head2 Import Special Variables

=cut

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

=head2 private hash

=cut

my $data_in = {
	_Step           => '',
	_base_file_name => '',
	_inbound        => '',
	_note           => '',
	_notes_aref     => '',
	_suffix_type    => '',
};

=head2 subroutine _get_DIR
	
  send PATH for suffix_type
  suffix_type can be su txt sgy or su
  

=cut

sub _get_DIR {
	my ($self) = @_;

	my $Project = Project_config->new();

	if ( length $data_in->{_suffix_type} ) {


		my $control = control->new();
		use App::SeismicUnixGui::misc::SeismicUnix qw($seg2 $segb $segd $segy $sgy $ps $su $txt $bin);

		my $DIR;

		# remove quotes
		my $suffix_type = $control->get_no_quotes( $data_in->{_suffix_type} );

	  #		print("data_in,_get_DIR,internal suffix_type,=---$suffix_type-----\n");
	  #		print("data_in,_get_DIR,su_type from SeismicUnix=---$su-----\n");

		if ( $suffix_type eq $su ) {

			my ($DATA_SEISMIC_SU) = $Project->DATA_SEISMIC_SU();
			$DIR = $DATA_SEISMIC_SU;

		}
		elsif ( $suffix_type eq $bin ) {

			my ($DATA_SEISMIC_BIN) = $Project->DATA_SEISMIC_BIN();
			$DIR = $DATA_SEISMIC_BIN;

		}
		elsif ( $suffix_type eq $ps ) {

			my ($PS_SEISMIC) = $Project->PS_SEISMIC();
			$DIR = $PS_SEISMIC;

		}
		elsif ( $suffix_type eq $txt ) {

			my ($DATA_SEISMIC_TXT) = $Project->DATA_SEISMIC_TXT();
			$DIR = $DATA_SEISMIC_TXT;

		}
		elsif ( $suffix_type eq $segb ) {

			my ($DATA_SEISMIC_SEGB) = $Project->DATA_SEISMIC_SEGB();
			$DIR = $DATA_SEISMIC_SEGB;

		}
		elsif ( $suffix_type eq $segd ) {

			my ($DATA_SEISMIC_SEGD) = $Project->DATA_SEISMIC_SEGD();
			$DIR = $DATA_SEISMIC_SEGD;

		}
		elsif ( $suffix_type eq $seg2 ) {

			my ($DATA_SEISMIC_SEG2) = $Project->DATA_SEISMIC_SEG2();
			$DIR = $DATA_SEISMIC_SEG2;

		}
		elsif ( $suffix_type eq $segy ) {

			my ($DATA_SEISMIC_SEGY) = $Project->DATA_SEISMIC_SEGY();
			$DIR = $DATA_SEISMIC_SEGY;

		}
		elsif ( $suffix_type eq $sgy ) {

			my ($DATA_SEISMIC_SEGY) = $Project->DATA_SEISMIC_SEGY();
			$DIR = $DATA_SEISMIC_SEGY;

			# print("data_in, _get_DIR, suffix_type=$suffix_type \n");

		}
		else {
			print(
"data_in, _get_DIR, suffix_type=($suffix_type) and is not recognized\n"
			);
			return ();
		}
		return ($DIR);

	}
	else {

#		print("data_in, _get_DIR, suffix_type missing. assume that the PL_SEISMIC is default \n");
		my ($PL_SEISMIC) = $Project->PL_SEISMIC();
		my $DIR = $PL_SEISMIC;
		return ($DIR);
	}

}

=head2 subroutine _get_suffix
	
  send PATH for suffix_type
  suffix_type can be su txt sgy or su
  

=cut

sub _get_suffix {

	my ($self) = @_;

	if ( length $data_in->{_suffix_type} ) {

		use App::SeismicUnixGui::misc::SeismicUnix
		  qw($suffix_bin $suffix_segb $suffix_seg2 $suffix_segd $suffix_sgd $suffix_segy $suffix_sgy $suffix_ps $suffix_su $suffix_txt $sgy $ps $su $txt $bin);

		my $suffix;
		my $suffix_type = $data_in->{_suffix_type};
		my $control     = control->new();

		$suffix_type = $control->get_no_quotes($suffix_type);

   #		print("data_in,_get_suffix,internal suffix_type,=---$suffix_type-----\n");
   #		print("data_in,_get_suffix,su_type from SeismicUnix=---$su-----\n");

		if ( $suffix_type eq $su ) {

			$suffix = $suffix_su;

		}
		elsif ( $suffix_type eq $ps ) {

			$suffix = $suffix_ps;

		}
		elsif ( $suffix_type eq $bin ) {

			$suffix = $suffix_bin;

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
		elsif ( $suffix_type eq $sgy ) {

			$suffix = $suffix_sgy;

		}
		elsif ( $suffix_type eq $bin ) {

			$suffix = $suffix_bin;

		}
		elsif ( $suffix_type eq $txt ) {

			$suffix = $suffix_txt;

		}
		elsif ( $suffix_type eq $empty_string ) {

			print(
"data_in, suffix_type=($suffix_type) is not $ps, $su, $bin, $segy, $sgy or $txt\n"
			);
			$suffix = $empty_string;

		}
		else {
			print("data_in, unexpected suffix_type\n");
		}

		return ($suffix);

	}
	elsif ( not( length $data_in->{_suffix_type} ) ) {

#		print("data_in, _get_sufix, suffix_type is blank so assume that it means there is non\n");
		my $suffix = $empty_string;
		return ($suffix);

	}
	else {
		print("data_in, _get_sufix, suffix_type unexpected \n");
	}
}

=head2 subroutine clear

  sets all variable strings to '' 

=cut

sub clear {
	$data_in->{_Step}           = '';
	$data_in->{_base_file_name} = '';
	$data_in->{_inbound}        = '';
	$data_in->{_note}           = '';
	$data_in->{_notes_aref}     = '';
	$data_in->{_suffix_type}    = '';

}

my @notes;

# define a value
my $newline = '
';

=head2 subroutine _get_inbound

  suffix_type can be su txt sgy or su
  if it is empty then assume that you are accessing
  the local directory

=cut

sub _get_inbound {
	my ($self) = @_;

	my $inbound;
	my $suffix_type;
	my $DIR;
	my $file;
	my $suffix;

	if (   length $data_in->{_suffix_type}
		&& length $data_in->{_base_file_name} )
	{

		$file = $data_in->{_base_file_name};

		$DIR     = _get_DIR();
		$suffix  = _get_suffix();
		$inbound = '"'.$DIR . '/' . $file . $suffix.'"';

		# print ("data_in,get_inbound inbound: $inbound\n");
		return ($inbound);

	}
	elsif ( length $data_in->{_base_file_name}
		&& not( $data_in->{_suffix_type} ) )
	{

		$file = $data_in->{_base_file_name};

		$DIR     = _get_DIR();
		$inbound = '"'.$DIR . '/' . $file.'"';

		# print ("2. data_in,_get_outbound outbound: $outbound\n");
		return ($inbound);

	}
	else {
		print("data_in, missing base file name  \n");
	}
}

=head2 subroutine Step
 
 adds the program name

=cut

sub Step {
	my ($self) = @_;
	my $note;

	$data_in->{_note} = _get_inbound();
	
	$note = $data_in->{_note};

	return $note;
}

=head2 sub base_file_name 

	has no suffix
  
=cut

sub base_file_name {
	my ( $variable, $base_file_name ) = @_;

	if ($base_file_name) {

		$data_in->{_base_file_name} = $base_file_name;

		# print ("data_in, base_file_name $data_in->{_base_file_name}\n");

	}
	else {
		print("data_in, base_file_name, name missing \n");

	}
}

=head2 sub  base_file_name_sref  

	has no suffix
  
=cut

sub base_file_name_sref {
	my ( $variable, $base_file_name_sref ) = @_;

	if ($base_file_name_sref) {

		$data_in->{_base_file_name} = $$base_file_name_sref;

		# print ("data_in, base_file_name $data_in->{_base_file_name}\n");

	}
	else {
		print("data_in, base_file_name_sref, name missing \n");

	}
}

=head2 sub full_file_name  

	base plus suffix
  
=cut

sub full_file_name {
	my ( $self, $full_file_name ) = @_;

	if ($full_file_name) {

		$data_in->{_full_file_name} = $full_file_name;

	}
	else {
		print("data_in, full_file_name, name missing \n");
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

	if ( length $data_in->{_suffix_type}
		&& $data_in->{_base_file_name} )
	{

		$file = $data_in->{_base_file_name};

		$DIR     = _get_DIR();
		$suffix  = _get_suffix();
		$inbound = $DIR . '/' . $file . $suffix;

		# print ("data_in,get_inbound inbound: $inbound\n");
		return ($inbound);

	}
	elsif ( length $data_in->{_base_file_name}
		&& not( $data_in->{_suffix_type} ) )
	{

		print(
			"data_in, missing: suffix_type, base file name . 
		Assume that the expected output is PL_SEISMIC-- as default\n"
		);
		$DIR     = _get_DIR();
		$suffix  = _get_suffix();
		$inbound = $DIR . '/' . $file . $suffix;
		return ($inbound);

	}
	else {
		print(
"data_in, missing: suffix_type, base file name . Assume that is what the user wants NADA\n"
		);
		return ($empty_string);
	}
}

=head2 sub get_max_index

max index = number of input variables -1

=cut

sub get_max_index {
	my ($self) = @_;

	# file_name : index=0
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

	$notes[1] = "\t" . '$data_in[1] 	= ' . $data_in->{_note};

	$data_in->{_notes_aref} = \@notes;

	return $data_in->{_notes_aref};
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

		$data_in->{_suffix_type} = $suffix_type;

	}
	else {

		print("data_in, type missing \n");
	}
}

=head2 subroutine suffix_type

  suffix_type can be:
  	bin
    sgy
  	su 
  	txt

=cut

sub suffix_type {
	my ( $self, $suffix_type ) = @_;

	if ($suffix_type) {

		my $control = control->new();

		#		print("data_in, suffix_type =  $suffix_type\n");

		# put quotes on string
		$suffix_type = $control->get_string_or_number($suffix_type);
		$data_in->{_suffix_type} = $suffix_type;

	}
	else {
		print("data_in, suffix_type missing \n");
	}
}

1;
