package App::SeismicUnixGui::misc::oop_text;

=head2 for writing object-oriented perl lines of text
		2018 V 0.0.2
       
	V 0.0.3 July 24 2018 includes data_in and data_out
	 add \t to pod_prog_param
	 V0.04 April 4 2019
	  does not repeat program declaration
	
=head1 DOCUMENTATION


=head2 SYNOPSIS 

 PERL PROGRAM NAME: oop_text
 AUTHOR: 	Juan Lorenzo
 DATE: 	V 0.0.1	June 22 2017 

 DESCRIPTION 
     

 BASED ON:


=cut

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

=head2 CHANGES and their DATES

=cut 

use Moose;
our $VERSION = '0.0.4';
use aliased 'App::SeismicUnixGui::misc::manage_files_by2';
use aliased 'App::SeismicUnixGui::misc::dirs';
use aliased 'App::SeismicUnixGui::misc::oop_declare_data_in';
use aliased 'App::SeismicUnixGui::misc::oop_declare_data_out';
use aliased 'App::SeismicUnixGui::misc::oop_declare_pkg';
use aliased 'App::SeismicUnixGui::misc::oop_declaration_defaults';
use aliased 'App::SeismicUnixGui::misc::oop_flows'
  ;    # corrects data-program order for seismic unix;
use aliased 'App::SeismicUnixGui::misc::oop_pod_header';
use aliased 'App::SeismicUnixGui::misc::oop_instantiation_defaults';
use aliased 'App::SeismicUnixGui::misc::oop_log_flows';
use aliased 'App::SeismicUnixGui::misc::oop_use_pkg';
use aliased 'App::SeismicUnixGui::misc::pod_declare';
use aliased 'App::SeismicUnixGui::misc::pod_flows';
use aliased 'App::SeismicUnixGui::misc::pod_log_flows';
use aliased 'App::SeismicUnixGui::misc::pod_prog_param_setup';
use aliased 'App::SeismicUnixGui::misc::pod_run_flows';
use aliased 'App::SeismicUnixGui::misc::oop_print_flows';
use aliased 'App::SeismicUnixGui::misc::oop_prog_params';
use aliased 'App::SeismicUnixGui::misc::oop_run_flows';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

use Carp;

my $file_out;
my $file_in;
my $get                        = L_SU_global_constants->new();
my $dirs		               = dirs->new();
my $declare_data_in            = oop_declare_data_in->new();
my $declare_data_out           = oop_declare_data_out->new();
my $oop_flows                  = oop_flows->new();
my $oop_declare_pkg            = oop_declare_pkg->new();
my $oop_pod_header             = oop_pod_header->new();
my $oop_declaration_defaults   = oop_declaration_defaults->new();
my $oop_instantiation_defaults = oop_instantiation_defaults->new();
my $oop_run_flows              = oop_run_flows->new();
my $oop_log_flows              = oop_log_flows->new();
my $pod_declare                = pod_declare->new();
my $pod_flows                  = pod_flows->new();
my $pod_log_flows              = pod_log_flows->new();
my $pod_run_flows              = pod_run_flows->new();
my $pod_prog_param_setup       = pod_prog_param_setup->new();
my $print_flows                = oop_print_flows->new();
my $prog_params                = oop_prog_params->new();
my $oop_use_pkg                = oop_use_pkg->new();
my @lines                      = ();
my $self;

my $var   = $get->var();
my $true  = $var->{_true};
my $false = $var->{_false};

=head2 private hash

=cut

my $oop_text = {
	_suffix_type            => '',
	_suffix_type_in         => '',
	_suffix_type_out        => '',
	_filehandle             => '',
	_file_name_in           => '',
	_is_config              => $false,
	_is_data                => $false,
	_is_data_in             => $false,
	_is_data_out            => $false,
	_message_w              => '',
	_num_progs4flow         => '',
	_prog_name              => '',
	_prog_names_aref        => '',
	_prog_param_labels_aref => '',
	_prog_param_values_aref => '',
	_prog_version           => '',
	_prog_version_aref      => '',
};

# normally filehandle is undefined
# unless overwritten with another filehandle
# before use
$oop_text->{_filehandle} = undef;    # for future use perhaps

=head2 sub set_data_io_LSU

=cut

sub set_data_io_L_SU {

	my ( $self, $hash_ref ) = @_;
	use App::SeismicUnixGui::misc::SeismicUnix
	  qw($segb $segd $segy $sgd $sgy $su $txt $text $bin);

	$oop_text->{_suffix_type_in}  = $hash_ref->{_suffix_type_in};
	$oop_text->{_suffix_type_out} = $hash_ref->{_suffix_type_out};
	$oop_text->{_is_data_in}      = $hash_ref->{_is_data_in};
	$oop_text->{_is_data_out}     = $hash_ref->{_is_data_out};

	#	  foreach my $key (keys %$hash_ref) {
	#	 		  print("oop_text,set_data_io_L_SU $key is $hash_ref->{$key}\n");
	#	 }
	#			 print("oop_text,set_data_io_L_SU made it\n");

	my $suffix_type_in  = $oop_text->{_suffix_type_in};
	my $suffix_type_out = $oop_text->{_suffix_type_out};
	my $is_data_out     = $oop_text->{_is_data_out};
	my $is_data_in      = $oop_text->{_is_data_in};

	if ($is_data_in) {

		if ( $suffix_type_in eq $segb ) {

			print(
				"oop_text,set_data_io_L_SU, is data_in suffix_type eq $segb\n");
			$declare_data_in->set_suffix_type_in($segb);
			$declare_data_in->set_segb_in();

		}
		elsif ( $suffix_type_in eq $segd or $suffix_type_in eq $sgd ) {

			print(
				"oop_text,set_data_io_L_SU, is data_in suffix_type eq $segd\n");
			$declare_data_in->set_suffix_type_in($segd);
			$declare_data_in->set_segd_in();

		}
		elsif ( $suffix_type_in eq $segy or $suffix_type_in eq $sgy ) {

			print("oop_text,set_data_io_L_SU, is data_in suffix_type eq $su\n");
			$declare_data_in->set_suffix_type_in($sgy);
			$declare_data_in->set_segy_in();

		}
		elsif ( $suffix_type_in eq $su ) {

		  # print("oop_text,set_data_io_L_SU, is data_in suffix_type eq $su\n");
			$declare_data_in->set_suffix_type_in($su);
			$declare_data_in->set_su_in();

		}
		elsif ( $suffix_type_in eq $bin ) {

			# print("oop_text,set_data_io_L_SU_in type eq $suffix_bin\n");
			$declare_data_in->set_suffix_type_in($bin);
			$declare_data_in->set_bin_in();

		}
		elsif ( $suffix_type_in eq $txt || $suffix_type_in eq $text ) {

			# print("oop_text,set_data_io_L_SU_in suffix_type eq $txt\n");
			$declare_data_in->set_suffix_type_in($txt);
			$declare_data_in->set_text_in();

		}
		else {
			print("oope_text,set_data_io_L_SU, unexpected suffix type \n");
		}

	}
	elsif ($is_data_out) {

		# print("oop_text,set_data_io_L_SU out\n");
		# print("oop_text,set_data_io_L_SU suffix_type_out=$suffix_type_out\n");
		# do not repeat delarations
		if ( $suffix_type_in ne $suffix_type_out ) {

			# print("oop_text,in and out data different suffix_types\n");

			if ( $suffix_type_out eq $segb ) {

				# print("oop_text,set_data_io_L_SU,out suffix_type eq $segb\n");
				$declare_data_out->set_suffix_type_out($segb);
				$declare_data_out->set_segb_out();
			}

			if ( $suffix_type_out eq $segd ) {

				# print("oop_text,set_data_io_L_SU,out suffix_type eq $segd\n");
				$declare_data_out->set_suffix_type_out($segd);
				$declare_data_out->set_segd_out();
			}

			if ( $suffix_type_out eq $su ) {

				# print("oop_text,set_data_io_L_SU,out suffix_type eq $su\n");
				$declare_data_out->set_suffix_type_out($su);
				$declare_data_out->set_su_out();

			}
			elsif ( $suffix_type_out eq $bin ) {

				# print("oop_text,set_data_io_L_SU out type eq $bin\n");
				$declare_data_out->set_suffix_type_out($bin);
				$declare_data_out->set_bin_out();

			}
			elsif ( $suffix_type_out eq $text || $suffix_type_out eq $txt ) {

				# print("oop_text,set_data_io_L_SU out suffix_type eq 'txt'\n");
				$declare_data_out->set_suffix_type_out($txt);
				$declare_data_out->set_text_out();

			}
			elsif ( $suffix_type_out eq $sgy ) {

				print("oop_text,set_data_io_L_SU out suffix_type eq $sgy\n");
				$declare_data_out->set_suffix_type_out($sgy);
				$declare_data_out->set_segy_out();

			}
			else {
				print("oop_text,set_data_io_L_SU out suffix_type missing \n");
			}

			# when input and output formats are the same
		}
		elsif ( $suffix_type_in eq $suffix_type_out ) {

			if ( $suffix_type_out eq $segy ) {

				$declare_data_out->empty();
				$declare_data_out->set_bin_out();

			}
			elsif ( $suffix_type_out eq $segb ) {

				$declare_data_out->empty();
				$declare_data_out->set_segb_out();

				# print("oop_text,in and out data same suffix_types\n");
			}
			elsif ( $suffix_type_out eq $segd ) {

				$declare_data_out->empty();
				$declare_data_out->set_segd_out();

				# print("oop_text,in and out data same suffix_types\n");
			}
			elsif ( $suffix_type_out eq $su ) {

				$declare_data_out->empty();
				$declare_data_out->set_su_out();

			}
			elsif ( $suffix_type_out eq $bin ) {

				$declare_data_out->empty();
				$declare_data_out->set_bin_out();

			}
			elsif ($suffix_type_out eq $text
				|| $suffix_type_out eq $txt )
			{

				$declare_data_out->empty();
				$declare_data_out->set_text_out();

			}
			else {
				print(
"oop_text,in and out data same suffix_types, missing suffix_type_out\n"
				);

			}

		}
		else {
			print(
"oop_text,in and out data suffix_types are neight the same or different\n"
			);
		}
	}
	else {
		# print("oop_text,neither data_in nor data_out\n");
	}

	return ();
}

sub set_file_name_in {
	my ( $self, $file_name ) = @_;
	if ($file_name) {

		# print("oop_text,set_file_name_in = $file_name\n");
		$oop_text->{_file_name_in} = $file_name;
	}

	return ();
}

sub set_file_name_out {
	my ( $self, $file_name ) = @_;
	if ($file_name) {

		# print("oop_text,set_file_name_out = $file_name\n");
		$oop_text->{_file_name_out} = $file_name;
	}

	return ();
}

=pod sub declare_data_in 
 
 write declare_data_in 
 data can be indifferent formats,
 e.g. su, text, binary etc. 

 data can be for input or output

=cut

sub declare_data_in {
	my ($self) = @_;

	#print("oop_text,declare_data_in\n");

	my $ref_array  = $declare_data_in->inbound_section();
	my @array      = @$ref_array;
	my $filehandle = $oop_text->{_filehandle};
	my $length     = scalar @array;

	print $filehandle $array[0] . "\n";
	print $filehandle $array[1] . "\n";

	print $filehandle "\t"
	  . '$file_in[1]' . "\t" . '= ' . "'"
	  . $oop_text->{_file_name_in} . "'" . ';' . "\n";

	for ( my $i = 2 ; $i < $length ; $i++ ) {
		print $filehandle $array[$i] . "\n";
	}

	return ();
}

=pod sub declare_data_out 
 
 write declare_data_out 
 data can be in different formats,
 e.g. su, text, binary etc. 

 data can be for input or output

=cut

sub declare_data_out {
	my ($self) = @_;
	print("oop_text,declare_data_out\n");
	my $ref_array  = $declare_data_out->outbound_section();
	my $filehandle = $oop_text->{_filehandle};

	foreach (@$ref_array) {
		print $filehandle "$_\n";
	}

	return ();
}

=pod sub get_declare_pkg 
 
  write get_declare_pkgs 
  V0.0.2 July 24 2018, includes data_out and  data_in

=cut

sub get_declare_pkg {
	my ($self) = @_;

	my $ref_array  = $oop_declare_pkg->section();
	my $filehandle = $oop_text->{_filehandle};

	foreach (@$ref_array) {
		print $filehandle "$_\n";
	}

# print("1. oop_text,get_declare_pkg: prog_names= @{$oop_text->{_prog_names_aref}}\n");
	$oop_declaration_defaults->set_prog_names_aref($oop_text);
	my $non_duplicate_aref = $oop_declaration_defaults->section();
	my $num_progs4flow     = scalar @$non_duplicate_aref;

	for ( my $j = 0 ; $j < $num_progs4flow ; $j++ ) {

		# exclude declaring data files here
		# data file declarations are handled by declare_data
		my $prog_name = @{$non_duplicate_aref}[$j];

		print $filehandle "\t" . 'my (@' . $prog_name . ');' . "\n";

		# print "\t" . 'my (@' . $prog_name . ');' . "\n";

	}

	return ();
}

=pod sub get_define_flows 

  write built flows 
		  print("oop_text,flows,prog_version_aref=@{$oop_text->{_prog_version_aref}}\n");

=cut

sub get_define_flows {
	my ($self) = @_;

	$oop_flows->set_message($oop_text);
	$oop_flows->set_prog_version_aref($oop_text);
	$oop_flows->set_num_progs4flow($oop_text);
	$oop_flows->set_prog_names_aref($oop_text);
	$oop_flows->set_specs();

	my $ref_array  = $oop_flows->get_section();
	my $filehandle = $oop_text->{_filehandle};

	foreach (@$ref_array) {
		print $filehandle "$_\n";

		# print "oop_text, get_define_flows$_\n";
	}

	return ();
}

=pod sub get_pod_header 
 
 import standard perl
 pod_headers 
 and write to output file

=cut

sub get_pod_header {
	my ($self) = @_;

	my $ref_array  = $oop_pod_header->section();
	my $filehandle = $oop_text->{_filehandle};

	# my $length 		= scalar @$ref_array;

	foreach (@$ref_array) {
		print $filehandle "$_\n";
	}

	return ();
}

=head2 sub instantiation

 oop_instantiation_defaults removes duplicate file names

=cut

sub instantiation {
	my ($self) = @_;

# print("1. oop_text,instantiation: prog_names= @{$oop_text->{_prog_names_aref}}\n");
	$oop_instantiation_defaults->set_prog_names_aref($oop_text);
	my $ref_array = $oop_instantiation_defaults->section();

	# print("2. oop_text,instantiation: prog_names= @$ref_array\n");
	my $filehandle = $oop_text->{_filehandle};

	foreach (@$ref_array) {
		print $filehandle "$_\n";

		# print "oop_text,instantiation, $_\n";
	}

	return ();
}

=head2 sub get_log_flows

=cut

sub get_log_flows {
	my ($self) = @_;

	my $ref_array  = $oop_log_flows->section();
	my $filehandle = $oop_text->{_filehandle};

	foreach (@$ref_array) {
		print $filehandle "$_\n";
	}
	return ();

}

=head2 sub get_pod_declare

=cut

sub get_pod_declare {
	my ($self) = @_;

	my $ref_array  = $pod_declare->section();
	my $filehandle = $oop_text->{_filehandle};

	foreach (@$ref_array) {
		print $filehandle "$_\n";
	}
	return ();
}

=head2 sub pod_flows

=cut

sub get_pod_flows {
	my ($self) = @_;

	my $ref_array  = $pod_flows->section();
	my $filehandle = $oop_text->{_filehandle};

	foreach (@$ref_array) {
		print $filehandle "$_\n";
	}
	return ();
}

=head2 sub get_pod_log_flows

=cut

sub get_pod_log_flows {
	my ($self) = @_;

	my $ref_array  = $pod_log_flows->section();
	my $filehandle = $oop_text->{_filehandle};

	foreach (@$ref_array) {
		print $filehandle "$_\n";
	}
	return ();
}

=head2 sub set_pod_prog_param_setup

	write pod on
	Setup

=cut

sub set_pod_prog_param_setup {
	my ($self) = @_;
	my $program_name = $oop_text->{_prog_name};

	my $ref_array  = $pod_prog_param_setup->section();
	my @array      = @$ref_array;
	my $filehandle = $oop_text->{_filehandle};
	my $length     = scalar @$ref_array;
	my $i;

	for ( $i = 0 ; $i < ( $length - 1 ) ; $i++ ) {
		print $filehandle $array[$i] . "\n";
	}
	print $filehandle "\t" . $program_name . ' parameter values' . "\n";
	print $filehandle $array[$i];
	return ();
}

=head2 sub get_pod_run_flows

=cut

sub get_pod_run_flows {

	my ($self) = @_;

	my $ref_array  = $pod_run_flows->section();
	my $filehandle = $oop_text->{_filehandle};

	foreach (@$ref_array) {
		print $filehandle "$_\n";
	}

	#	return();
}

=head2 sub get_print_flows

=cut

sub get_print_flows {
	my ($self) = @_;

	my $ref_array  = $print_flows->section();
	my $filehandle = $oop_text->{_filehandle};

	foreach (@$ref_array) {
		print $filehandle "$_\n";
	}
	return ();

}

=head2 sub get_program_params

	Sets labels and their values
	 	print("oop_text,get_program_params,version=$oop_text->{_prog_version}\n");
	 	print("oop_text,get_program_params,labels=@{$oop_text->{_prog_param_labels_aref}}\n");
	 	print("oop_text,get_program_params,values=@{$oop_text->{_prog_param_values_aref}}\n");
	 	print("oop_text,get_program_params,prog_name=$oop_text->{_prog_name}\n");

=cut

sub get_program_params {
	my ($self) = @_;

	my $filehandle = $oop_text->{_filehandle};

	$prog_params->set_a_prog_name($oop_text);
	$prog_params->set_a_prog_version($oop_text);
	$prog_params->set_many_param_labels($oop_text);
	$prog_params->set_many_param_values($oop_text);

	my $ref_array = $prog_params->get_a_section();

	if ( ( @$ref_array[0] ) ) {    # refuse an empty case

		# print("1. oop_text,prog_params, flow item detected \n");
		foreach (@$ref_array) {
			print $filehandle "$_\n";    # NOT FORMATTED
		}
	}
	else {
		print("Warning: oop_text,prog_params, no flow item detected\n");
	}
	return ();

}

=head2 sub get_run_flows

=cut

sub get_run_flows {
	my ($self) = @_;

	my $ref_array  = $oop_run_flows->section();
	my $filehandle = $oop_text->{_filehandle};

	foreach (@$ref_array) {
		print $filehandle "$_\n";
	}

	return ();
}

=head2 sub set_message

=cut

sub set_message {
	my ( $self, $hash_ref ) = @_;

	if ($hash_ref) {
		$oop_text->{_message_w} = $hash_ref->{_message_w};

		# my $message_w     = $oop_text->{_message_w};
		# my	$m          = "oop_text,set_message,$message_w\n";
		# $message_w->delete("1.0",'end');
		# $message_w->insert('end', $m);
		# print("oop_text,set_message, message=$oop_text->{_message}\n");
	}
	return ();
}

=head2 sub set_filehandle

=cut

sub set_filehandle {
	my ( $self, $filehandle ) = @_;

	if ($filehandle) {
		$oop_text->{_filehandle} = $filehandle;

	  # print("oop_text,set_filehandle, filehandle=$oop_text->{_filehandle}\n");
	}
	return ();
}

=head2 sub set_macro_head

=cut

=head2 sub set_macro_tail

=cut

=head2 sub set_prog_name

=cut

sub set_prog_name {
	my ( $self, $prog_name ) = @_;

	if ($prog_name) {
		$oop_text->{_prog_name} = $prog_name;

		#		 print("oop_text,set_prog_name,prog_name=$oop_text->{_prog_name}\n");
	}
	return ();
}

=head2 sub set_prog_version

=cut

sub set_prog_version {
	my ( $self, $prog_version ) = @_;

	if ($prog_version) {
		$oop_text->{_prog_version} = $prog_version;

 # print("oop_text,set_prog_version,prog_version=$oop_text->{_prog_version}\n");
	}
	return ();
}

=head2 sub set_prog_version_aref

		  print("oop_text,set_prog_version_aref,prog_version_aref=@{$hash_aref->{_items_versions_aref}}\n");
		  print("oop_text,set_prog_version_aref,prog_version_aref=@{$oop_text->{_prog_version_aref}}\n");

=cut

sub set_prog_version_aref {
	my ( $self, $hash_aref ) = @_;

	if ($hash_aref) {
		$oop_text->{_prog_version_aref} = $hash_aref->{_items_versions_aref};
	}
	return ();
}

=head2 sub set_num_progs4flow

=cut

sub set_num_progs4flow {
	my ( $self, $prog_names_aref ) = @_;

	if ($prog_names_aref) {
		$oop_text->{_num_progs4flow} = scalar @$prog_names_aref;

# print("oop_text,set_num_progs4flow,num_progs4flow =$oop_text->{_num_progs4flow}\n");
	}
	return ();
}

=head2 sub set_prog_names_aref

=cut

sub set_prog_names_aref {
	my ( $self, $prog_names_aref ) = @_;

	if ($prog_names_aref) {
		$oop_text->{_prog_names_aref} = $prog_names_aref;

# print("oop_text,set_prog_names_aref, prog_names=@{$oop_text->{_prog_names_aref}}\n");
	}
	return ();
}

=head2 sub set_prog_param_values_aref

=cut

sub set_prog_param_values_aref {
	my ( $self, $prog_param_values_aref ) = @_;

# print("oop_text,set_prog_param_values_aref, prog_param_values=@{$prog_param_values_aref}\n");

	if ($prog_param_values_aref) {
		$oop_text->{_prog_param_values_aref} = $prog_param_values_aref;

# print("oop_text,set_prog_param_values_aref, prog_param_values=@{$oop_text->{_prog_param_values_aref}}\n");
	}
	return ();
}

=head2 sub set_prog_param_labels_aref

=cut

sub set_prog_param_labels_aref {
	my ( $self, $prog_param_labels_aref ) = @_;

	if ($prog_param_labels_aref) {
		$oop_text->{_prog_param_labels_aref} = $prog_param_labels_aref;

# print("oop_text,set_prog_param_labels_aref, prog_param_labels=@{$oop_text->{_prog_param_labels_aref}}\n");
	}
	return ();
}

=head2 sub get_use_pkg
	
		origanize output text in the declaration section
		of the perl script

		N.B. @{$oop_text->{_prog_names_aref}}[$j] contains other programs
		N.B. ref-array contains: 
e.g., 	use aliased 'App::SeismicUnixGui::misc::message';
		use aliased 'App::SeismicUnixGui::misc::flow';
	
output in the text file should look something like 
	    use aliased 'App::SeismicUnixGui::misc::message';
		use aliased 'App::SeismicUnixGui::misc::flow';
		use  data_in	
		use  suxwigb
		
		4-4-19: prevent repetition of programs being output
		
		July 2022: program name needs to know its full path
		within the project e.g., 
		name is now App::SeismicGui::misc::name
		use L_SU_global_constants, e.g.,->get_path4convert_file.

=cut

sub get_use_pkg {

	my ($self) = @_;

	my @unique_progs;
	my $unique_progs_ref;
	my $num_unique_progs;
	my $array_ref             = $oop_use_pkg->section();
	my $length                = scalar @$array_ref;
	my $filter                = manage_files_by2->new();
	my $L_SU_global_constants = L_SU_global_constants->new();
	my $var                   = $L_SU_global_constants->var();
	my $filehandle            = $oop_text->{_filehandle};

#	print("oop,text,get_use_pkg,length=$length\n");
#	print("oop_text,get_use_pkg filehandle =$filehandle \n");

	# print first two use lines
	for ( my $i = 0 ; $i < $length ; $i++ ) {

		print $filehandle @{$array_ref}[$i];
#		print("oop_text,get_use_pkg i=$i, @{$array_ref}[$i]\n");

	}

	# remove repeated programs from the list
	$unique_progs_ref =
	  $filter->unique_elements( $oop_text->{_prog_names_aref} );
	@unique_progs     = @{$unique_progs_ref};
	$num_unique_progs = scalar @unique_progs;

	for ( my $j = 0 ; $j < $num_unique_progs ; $j++ ) {
		my $prog_name = $unique_progs[$j];

		my $module_name_pm = $prog_name . $var->{_suffix_pm};
		my $separation     = $var->{_App} . '/' . $var->{_SeismicUnixGui};

		$dirs->set_file_name($module_name_pm);
		my $PATH = $dirs->get_path4convert_file();
#		carp $PATH;

		if ( length $PATH ) {

			my $pathNmodule_pm = $PATH . '/' . $module_name_pm;
			my @next_string    = split( $separation, $pathNmodule_pm );

#			warn 'b4:' . $next_string[0];
#			warn 'After:' . $next_string[1];
#			warn $next_string[2];

			# substitute "/" with "::"
			$next_string[1] =~ s/(\/)+/::/g;
			$next_string[1] =~ s/.pm//g;
			$next_string[1] =
			  $var->{_App} . '::' . $var->{_SeismicUnixGui} . $next_string[1];

			print $filehandle "\t"
			  . 'use aliased \''
			  . $next_string[1] . '\';' . "\n";

			#			print "\t"
			#			  . 'use aliased \''.$next_string[1] .'\';'
			#			  . "\n";

		}
		else {
			warn 'Warning: variable missing';
		}

	}
	return ();
}

1;
