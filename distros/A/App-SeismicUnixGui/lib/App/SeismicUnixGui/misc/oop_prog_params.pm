package App::SeismicUnixGui::misc::oop_prog_params;

=head1 DOCUMENTATION


=head2 SYNOPSIS 

 PERL PACKAGE NAME: oop_prog_params
 AUTHOR: 	Juan Lorenzo
 DATE: 		2018

 DESCRIPTION 
     

 BASED ON:
 Version 0.0.2 July 26 2018   
 changed _private_* to _*
 removed exceptions to data_in and data_out


=cut

=head2 USE

=head3 NOTES

=head_for_ Examples

=head2 CHANGES and their DATES

Version 0.0. _for_ Oct 5, 2018
suffixes and prefixes to program parameter values are allowed
by importing the conditions set in each 'program_spec.pm module

 V 0.0.3 September 1 2019
 Allows multiple-valued parameters (e.g., curve1, curve2 in suximage) 
 each each with a separate prefix  ->label(quotemeta($PREFIX.'/'.$curve1,$PREFIX.'/'.$curve2));
 Changes occur in get_a_section
 Only one suffix and prefix allowed per label
 

=cut

use Moose;
our $VERSION = '0.0.1';

use aliased 'App::SeismicUnixGui::misc::param_sunix';
use App::SeismicUnixGui::misc::control '0.0.3';
use aliased 'App::SeismicUnixGui::misc::control';
use aliased 'App::SeismicUnixGui::misc::L_SU_path';

=head2 Instantiation

=cut

my $L_SU_path = L_SU_path->new();

=head2 program parameters
	 
  private hash
  
=cut

my $oop_prog_params = {
	_label             => '',
	_prog_name         => '',
	_prog_version      => '',
	_param_labels_aref => '',
	_param_values_aref => '',
};

=head2 sub _get_prefix_aref

	obstain prefix values externally for the module
	MUST first use prefix_aref method to 
	set prefixes internally 
	
	use program_name_spec.pm
	bring in a different module 
	each program
	prefix rules are in *_spec.pm
	prefixes can include a directory path e.g.,
	
=cut

sub _get_prefix_aref {

	my ($self) = @_;

	if ( $oop_prog_params->{_prog_name} ) {

		#		my $L_SU_global_constants = L_SU_global_constants->new();
		my $program_name = $oop_prog_params->{_prog_name};

		$L_SU_path->set_program_name($program_name);

		my $pathNmodule_spec_w_slash_pm =
		  $L_SU_path->get_pathNmodule_spec_w_slash_pm();
		my $pathNmodule_spec_w_colon =
		  $L_SU_path->get_pathNmodule_spec_w_colon();

		require $pathNmodule_spec_w_slash_pm;

		# INSTANTIATE
		my $package = $pathNmodule_spec_w_colon->new();

#		my $module_spec_pm        = $program_name . '_spec.pm';
#
#		$L_SU_global_constants->set_file_name($module_spec_pm);
#		my $slash_path4spec = $L_SU_global_constants->get_path4spec_file();
#		my $slash_pathNmodule_spec_pm =
#		  $slash_path4spec . '/' . $module_spec_pm;
#
#		$L_SU_global_constants->set_program_name($program_name);
#		my $colon_pathNmodule_spec =
#		  $L_SU_global_constants->get_colon_pathNmodule_spec();
#
#	  #	 	print("1. oop_prog_params _get_suffix_aref, prog_name: $slash_pathNmodule_spec_pm\n");
#	  #	 	print("1. oop_prog_params , _get_suffix_aref, prog_name: $colon_pathNmodule_spec\n");
#
#		require $slash_pathNmodule_spec_pm;
#
#		# INSTANTIATE
#		my $package = $colon_pathNmodule_spec->new();

		$package->binding_index_aref();
		$package->prefix_aref();
		my $prefix_aref = $package->get_prefix_aref();

	# print("oop_prog_params,_get_prefix_aref, prefix_aref=@{$prefix_aref} \n");

		return ($prefix_aref);

	}
	else {
		print("oop_prog_params,_get_prefix, missing program name\n");
	}

	return ();

}

=head2 sub _get_suffix_aref

	use program_name_spec.pm
	to bring in a different module 
	for each program
	suffix rules are in *_spec.pm
	
	bring in suffixes, if they exist
	
=cut

sub _get_suffix_aref {

	my ($self) = @_;

	if ( $oop_prog_params->{_prog_name} ) {

		my $program_name = $oop_prog_params->{_prog_name};

		$L_SU_path->set_program_name($program_name);

		my $pathNmodule_spec_w_slash_pm =
		  $L_SU_path->get_pathNmodule_spec_w_slash_pm();
		my $pathNmodule_spec_w_colon =
		  $L_SU_path->get_pathNmodule_spec_w_colon();

		require $pathNmodule_spec_w_slash_pm;

		# INSTANTIATE
		my $package = $pathNmodule_spec_w_colon->new();

		#		my $L_SU_global_constants = L_SU_global_constants->new();
		#		my $module_spec_pm        = $program_name . '_spec.pm';
		#
		#		$L_SU_global_constants->set_file_name($module_spec_pm);
		#		my $slash_path4spec = $L_SU_global_constants->get_path4spec_file();
		#		my $slash_pathNmodule_spec_pm =
		#		  $slash_path4spec . '/' . $module_spec_pm;
		#
		#		$L_SU_global_constants->set_program_name($program_name);
		#		my $colon_pathNmodule_spec =
		#		  $L_SU_global_constants->get_colon_pathNmodule_spec();
		#
##	 	print("1. oop_prog_params _get_suffix_aref, prog_name: $slash_pathNmodule_spec_pm\n");
##	 	print("1. oop_prog_params , _get_suffix_aref, prog_name: $colon_pathNmodule_spec\n");
		#
		#		require $slash_pathNmodule_spec_pm;
		#
		#		#$refresher->refresh_module("$module_spec_pm");
		#
		#		# INSTANTIATE
		#		my $package = $colon_pathNmodule_spec->new();

		# set internally and get suffix values externally for the module
		$package->binding_index_aref();
		$package->suffix_aref();
		my $suffix_aref = $package->get_suffix_aref();

  #		print("oop_prog_params,_get_suffix_aref, suffixes are: @{$suffix_aref}\n");
		return ($suffix_aref);

	}
	else {
		print("oop_prog_params,_get_suffix, missing program name\n");
	}

	return ();

}

=head2 sub _get_prefix_for_a_label 

To place a prefix in front of a sunix parameter
for o/p to a perl flow

=cut

sub _get_prefix_for_a_label {

	my ($self) = @_;

	my $param_sunix = param_sunix->new();
	my $control     = control->new();

	my $prefix = '';
	my @all_program_labels;
	my $labels_aref;
	my @prefixes;

	# The following must exist
	my @all_prog_prefixes = @{ _get_prefix_aref() };
	my $label             = $oop_prog_params->{_label};
	my $program_name      = $oop_prog_params->{_prog_name};

	# find all the possible names/labels for this program
	$param_sunix->set_program_name( \$program_name );
	$labels_aref        = $param_sunix->get_names();
	@all_program_labels = @$labels_aref;

	# number of all possible labels
	my $length = $param_sunix->get_length4perl_flow();

# print("2. oop_prog_params,_get_prefix_for_label, prefix length: $length\n");
# print(
# 	"2. oop_prog_params,_get_prefix_for_label, prefix labels: @all_program_labels\n"
# );

	# what's the index in the configuration file
	# (not the o/p perl script)
	# when label names match?
	for ( my $i = 0 ; $i < $length ; $i++ ) {

		# both labels should contain SOMETHING
		if ( $label && $all_program_labels[$i] ) {

			# clean the label so that only the last program name is used
			# e.g., boundary_conditions|abs becomes abs
			my $clean_config_label = $control->ors( $all_program_labels[$i] );

# print(
# "oop_prog_params,_get_prefix_for_label, program_name =$program_name\n"
# );
# print("2. oop_prog_params,_get_prefix_for_label, label: $label\n");
# print("1. oop_prog_params,_get_prefix_for_label, clean_config_label = $clean_config_label\n");

			@prefixes = @{ _get_prefix_aref() };

			# a match locates the index to read from
			# in the program_spec.pm file
			if ( $label eq $clean_config_label ) {

				# pick correct prefix
				$prefix = $prefixes[$i];

# print(
# "oop_prog_params,_get_prefix_for_label, match i=$i, this label=$label MATCHES $all_program_labels[$i]\n"
# );
# print(
# "oop_prog_params,_get_prefix_for_label, prefix = $prefix\n" );

			}
			else {

		# print("2. oop_prog_params,_get_prefix_for_label: no match NADA \n\n");
		# );
			}
		}
		else {

# print("2. oop_prog_params,_get_prefix_for_label, this or the other label are empty NADA \n");
		}
	}
	return ($prefix);
}

sub _get_suffix_for_a_label {
	my ($self) = @_;

	my $param_sunix = param_sunix->new();
	my $control     = control->new();

	my $suffix = '';
	my @all_program_labels;
	my $labels_aref;

	# The following must exist
	my $label        = $oop_prog_params->{_label};
	my $program_name = $oop_prog_params->{_prog_name};

	# find all the available names/labels for this program
	$param_sunix->set_program_name( \$program_name );
	$labels_aref        = $param_sunix->get_names();
	@all_program_labels = @$labels_aref;

	# number of all possible labels
	my $length = $param_sunix->get_length4perl_flow();

# print("2. oop_prog_params,_get_suffix_for_label, suffix length: $length\n");
# print("2. oop_prog_params, _get_suffix_for_label,suffix labels: @all_program_labels\n");

# find index in the configuration file (not the perl script) when label names match
	for ( my $i = 0 ; $i < $length ; $i++ ) {

		# both labels should contain SOMETHING
		if ( $label && $all_program_labels[$i] ) {

			# clean the label so that only the last program name is used
			# e.g., boundary_conditions|abs becomes abs
			my $clean_config_label = $control->ors( $all_program_labels[$i] );

			my @suffixes = @{ _get_suffix_aref() };

			# a match locates the index to read from the program_spec.pm file
			if ( $label eq $clean_config_label ) {

				$suffix = $suffixes[$i];

				#				print(
				#					"oop_prog_params,_get_suffix_for_label, match i=$i,
				#						this label = $label, this suffix=$suffix\n "
				#				);

			}
			else {
		#NADA print(" 2. oop_prog_params, _get_suffix_for_label, no match \n ");
			}
		}
		else {
			# print(" 2. oop_prog_params, _get_suffix_for_label this
			# or the other label are empty \n ");
		}
	}

	return ($suffix);
}

sub _set_label_for_a_suffix {
	my ($label) = @_;

	# needs a program name
	if ( $label && $oop_prog_params->{_prog_name} ) {

		$oop_prog_params->{_label} = $label;

	  #		print(" oop_prog_params, _set_label_for_a_suffix, label = $label \n ");

	}
	else {
		print(
" oop_prog_params, _set_label_for_a_suffix, missing label and /or program name\n"
		);
	}

	return ();
}

=head2  sub _set_label_for_a_prefix 

=cut

sub _set_label_for_a_prefix {
	my ($label) = @_;

	# needs a program name
	if ( $label && $oop_prog_params->{_prog_name} ) {

		$oop_prog_params->{_label} = $label;

	}
	else {
		print(
"oop_prog_params,_set_label_for_prefix, missing label and/or program name \n "
		);
	}

	return ();
}

=head2 sub get_a_section

Herein, the output text is assembled
 
In order to write the following:
 e.g., 
 	$sugain		        ->clear();
	$sugain				->pbal(1);
	$sugain[1] 			= $sugain->Step();	
 e.g.,
    $suop2			    ->clear();
    $suop2			    ->file1(quotemeta($SEISMIC_PL_SU.'/'.'100_clean');   
    $suop2			    ->op('diff')
    
  JML 9-1-19 e.g.,
   $suximage 	 	 	 ->curvefile(quotemeta($DATA_SEISMIC_TXT.'/'.'curve1,curve2'));
    
=cut

sub get_a_section {
	my ($self) = @_;

	my $control = control->new();

	my $prog_name = $oop_prog_params->{_prog_name};
	my $j         = 0;

	my @oop_prog_params;
	my $ok = 1;    #_get_exceptions();

	if ($ok) {

		$oop_prog_params[$j] =
		  " \t " . '$' . $prog_name . " \t \t \t \t " . "->clear();";

		# same as for values
		my $length  = scalar @{ $oop_prog_params->{_param_labels_aref} };
		my $version = $oop_prog_params->{_prog_version};

		for (
			my $param_idx = 0, $j = 1 ;
			$param_idx < $length ;
			$j++, $param_idx++
		  )
		{

			my $label = @{ $oop_prog_params->{_param_labels_aref} }[$param_idx];

			#			print(" 1. oop_prog_params, get_a_section, label = $label \n ");

			$label = $control->ors($label);

			#			print(" 2. oop_prog_params, get_a_section, label = $label \n ");

			my $value = @{ $oop_prog_params->{_param_values_aref} }[$param_idx];

			# Only, after the label has been cleaned (just above)
			_set_label_for_a_suffix($label);
			my $suffix = _get_suffix_for_a_label;

		 #			print(" 3. oop_prog_params, get_a_section, suffix=$suffix....\n ");

			_set_label_for_a_prefix($label);
			my $prefix = _get_prefix_for_a_label();

			#			print(" 4. oop_prog_params, get_a_section suffix =$prefix \n ");
			#            $control->set_value($value);
			#            $control->reset_suffix4loop();
			#            $control->set_suffix4oop($suffix);
			#            $value = $control->get_value4oop();

	    # print(" 4. oop_prog_params, get_a_section value =$value\n ");
	    
			if ( length $prefix && length $suffix ) {

#			print(" 1. oop_prog_params, get_a_section CASE #1 Both suffix and prefix are present\n ");
# OUTPUT TEXT is set here
				$oop_prog_params[$j] =
					" \t " . '$'
				  . $prog_name
				  . " \t \t \t \t " . '->'
				  . $label
				  . '(quotemeta('
				  . $prefix
				  . $value . ').'
				  . $suffix . ');';

#				print(" 1. oop_prog_params, get_a_section CASE #1 OUTPUT TEXT: $oop_prog_params[$j] \n");
#				print(
#" 1. oop_prog_params, get_a_section CASE #1 suffix=$suffix---prefix=$prefix---value=$value---\n"
#				);

				#				 					. '.'
			}
			elsif ( !( length($prefix) ) && length($suffix) ) {

# print(" oop_prog_params, get_a_section CASE #2  No prefix but there is a suffix \n ");
# OUTPUT TEXT is set here
				$oop_prog_params[$j] =
					" \t " . '$'
				  . $prog_name
				  . " \t \t \t \t " . '->'
				  . $label
				  . '(quotemeta('
				  . $value
				  . $suffix . '));';

			}
			elsif ( $prefix && !($suffix) ) {

				# CASE 3
				#				print("CASE #3 : oop_prog_params,prefix but no suffix \n");
				# OUTPUT TEXT is set here first
				# First part is:
				$oop_prog_params[$j] =
					" \t " . '$'
				  . $prog_name
				  . " \t \t \t \t " . '->'
				  . $label
				  . '(quotemeta(';

				# check for multiple values
				my $length = scalar $value;

				#				print("2. oop_prog_params,get_a,section,value=$value\n");

				#  detect multiple values, if split by comma
				my @sub_values = split( /,/, $value );

			  # print("oop_prog_params,get_a,section,sub_values:@sub_values\n");
				my $num_values = scalar @sub_values;
				my $last_index = $num_values - 1;

			  # print("oop_prog_params,get_a,section,num_values:$num_values\n");

				if ( defined $num_values
					&& $num_values > 0 )
				{    # one value must exist

					if ( $num_values >= 2 ) {

						my $control = control->new();

						# de-tick sub-values for initial case
						my $i = 0;
						$control->set_infection( $sub_values[$i] );
						$sub_values[$i] = $control->get_ticksBgone();

# print("CASE #3A-1: oop_prog_params,get_a,section,de-ticked value:$sub_values[$i]\n");

						# PREFIX set here
						# Second part is for initial case:
						$oop_prog_params[$j] =
							$oop_prog_params[$j]
						  . $prefix . "'"
						  . $sub_values[$i] . "'" . ".','.";

# print("CASE #3A-1: oop_prog_params,get_a,section, parts 1-2 is $oop_prog_params[$j]\n");

						# de-tick sub-values for up-to penultimate case
						for ( $i = 1 ; $i < ( $num_values - 1 ) ; $i++ ) {

							$control->set_infection( $sub_values[$i] );
							$sub_values[$i] = $control->get_ticksBgone();

							# PREFIX set here
							# Third part is:
							$oop_prog_params[$j] =
								$oop_prog_params[$j]
							  . $prefix . "'"
							  . $sub_values[$i] . "'" . ".','.";

# print("CASE #3A-2: oop_prog_params,get_a,section, parts 1-r is $oop_prog_params[$j]\n");

						}

						# de-tick sub-values for last case
						$control->set_infection( $sub_values[$last_index] );
						$sub_values[$last_index] = $control->get_ticksBgone();

						# Final part has no comma
						$oop_prog_params[$j] =
							$oop_prog_params[$j]
						  . $prefix . "'"
						  . $sub_values[$i] . "'" . '));';

# print("CASE #3A-3: oop_prog_params,get_a,section,Final part is $oop_prog_params[$j]\n");

					}
					elsif ( $num_values == 1 ) {

	  # print(" oop_prog_params, get_a_section CASE #3B, single-value case\n ");

						# OUTPUT TEXT is set here
						# otherwise the prefix is set here , only ONCE
						$oop_prog_params[$j] =
						  $oop_prog_params[$j] . $prefix . $value . '));';

# print("CASE #3B: oop_prog_params,get_a,section,Complete:$oop_prog_params[$j]\n");

					}
					else {

						#						print("oop_prog_params,get_a,section,NADA\n");
					}

				}
				else {
					print(
"oop_prog_params,get_a,section,strange values, WARNING\n"
					);
				}

				# CASE _for_
			}
			elsif ( $suffix && !($prefix) ) {

 #				print(" Case 4 oop_prog_params, get_a_section = suffix but no prefix\n ");
 # OUTPUT TEXT is set here
				$oop_prog_params[$j] =
					" \t " . '$'
				  . $prog_name
				  . " \t \t \t \t " . '->'
				  . $label
				  . '(quotemeta('
				  . $value
				  . $suffix . '));';

			}
			elsif ( !($suffix) && !($prefix) ) {

 # CASE 5
 #				print(" oop_prog_params, get_a_section = CASE 5; neither suffix nor prefix\n ");
 # OUTPUT TEXT is set here
#				$oop_prog_params[$j] =
#					" \t " . '$'
#				  . $prog_name
#				  . " \t \t \t \t " . '->'
#				  . $label
#				  . '("'
#				  . $value . '");';
				  
				$oop_prog_params[$j] =
					" \t " . '$'
				  . $prog_name
				  . " \t \t \t \t " . '->'
				  . $label
				  . '(quotemeta('
				  . $value . '));';
#			    print(" oop_prog_params, get_a_section = CASE 5:  $oop_prog_params[$j]  \n ");
			}
			else {

				# CASE 6
				print(
" oop_prog_params, get_a_section prefix and suffixes are weird \n "
				);
			}

# print(" 2. oop_prog_params, get_a_section, label, value = $oop_prog_params[$j] \n ");
		}

		$oop_prog_params[$j] =
			" \t " . '$'
		  . "$prog_name " . '['
		  . $version . '] '
		  . " \t \t \t " . '= $'
		  . "$prog_name "
		  . '->Step();';
		return ( \@oop_prog_params );

	}
	else {

		# print(" oop_prog_params, get_a_section, data detected \n ");
		$oop_prog_params[0] = " \t " . 'place data here' . " \n ";
		return ( \@oop_prog_params );

	}    # no exceptions
}

sub set_many_param_labels {

	my ( $self, $param_labels_href ) = @_;

	if ($param_labels_href) {
		$oop_prog_params->{_param_labels_aref} =
		  $param_labels_href->{_prog_param_labels_aref};

		#		print(" oop_prog_params, set_param_labels, param_labels,
		#		@{ $oop_prog_params->{_param_labels_aref} } \n ");
	}
	return ();
}

sub set_many_param_values {

	my ( $self, $param_values_href ) = @_;

	if ($param_values_href) {
		$oop_prog_params->{_param_values_aref} =
		  $param_values_href->{_prog_param_values_aref};

		#		print(" oop_prog_params, set_param_values, param_values,
		#		@{ $oop_prog_params->{_param_values_aref} } \n ");
	}
	return ();
}

sub set_a_prog_name {

	my ( $self, $prog_name_href ) = @_;

	if ($prog_name_href) {
		$oop_prog_params->{_prog_name} = $prog_name_href->{_prog_name};

		# print(" 1. oop_prog_params, set_prog_name, prog_name,
		# $oop_prog_params->{_prog_name} \n ");
	}
	return ();
}

sub set_a_prog_version {

	my ( $self, $prog_version_href ) = @_;

	if ($prog_version_href) {
		$oop_prog_params->{_prog_version} = $prog_version_href->{_prog_version};

		# print(" 1. oop_prog_params, set_prog_version, prog_version,
		# $oop_prog_params->{_prog_version} \n ");
	}
	return ();
}

1;
