package App::SeismicUnixGui::sunix::statsMath::suop;

=head2 SYNOPSIS

PERL PROGRAM NAME: 

AUTHOR: Juan Lorenzo (Perl module only)

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES
 SUOP - do unary arithmetic operation on segys 		



 suop <stdin >stdout op=abs					



 Required parameters:						

	none							



 Optional parameter:						

	op=abs		operation flag				

			abs   : absolute value			

			avg   : remove average value		

			ssqrt : signed square root		

			sqr   : square				

			ssqr  : signed square			

			sgn   : signum function			

			exp   : exponentiate			

			sexp  : signed exponentiate		

			slog  : signed natural log		

			slog2 : signed log base 2		

			slog10: signed common log		

			cos   : cosine				

			sin   : sine				

			tan   : tangent				

			cosh  : hyperbolic cosine		

			sinh  : hyperbolic sine			

			tanh  : hyperbolic tangent		

			cnorm : norm complex samples by modulus ", 

			norm  : divide trace by Max. Value	

			db    : 20 * slog10 (data)		

			neg   : negate value			

			posonly : pass only positive values	

			negonly : pass only negative values	

                       sum   : running sum trace integration   

                       diff  : running diff trace differentiation

                       refl  : (v[i+1] - v[i])/(v[i+1] + v[i]) 

			mod2pi : modulo 2 pi			

			inv   : inverse				

			rmsamp : rms amplitude			

                       s2v   : sonic to velocity (ft/s) conversion     

                       s2vm  : sonic to velocity (m/s) conversion     

                       d2m   : density (g/cc) to metric (kg/m^3) conversion 

                       drv2  : 2nd order vertical derivative 

                       drv4  : 4th order vertical derivative 

                       integ : top-down integration            

                       spike : local extrema to spikes         

                       saf   : spike and fill to next spike    

                       freq  : local dominant freqeuncy        

                       lnza  : preserve least non-zero amps    

                       --------- window operations ----------- 

                       mean  : arithmetic mean                 

                       despike  : despiking based on median filter

                       std   : standard deviation              

                       var   : variance                        

       nw=21           number of time samples in window        

                       --------------------------------------- 

			nop   : no operation			



 Note:	Binary ops are provided by suop2.			

 Operations inv, slog, slog2, and slog10 are "punctuated",	", 

 meaning that if, the input contains 0 values,			

 0 values are returned.					",	



 For file operations on non-SU format binary files use:  farith



 Credits:



 CWP: Shuki Ronen, Jack K Cohen (c. 1987)

  Toralf Foerster: norm and db operations, 10/95.

  Additions by Reg Beardsley, Chris Liner, and others.



 Notes:

	If efficiency becomes important consider inverting main loop

      and repeating operation code within the branches of the switch.



	Note on db option.  The following are equivalent:

	... | sufft | suamp | suop op=norm | suop op=slog10 |\

		sugain scale equals 20| suxgraph style=normal



	... | sufft | suamp | suop op=db | suxgraph style=normal



=head2 User's notes (Juan Lorenzo)

 An additional parameter called "list"  allows the operation
 to be repeated among multiple files.

 The base file names of the su files are in the list, which
 means that they are missing their suffix or extension,
 
 e.g., file1_neg

 The list is found in $DATA_SEISMIC_TXT.
 Output file names carry a suffix equal to the operation
 variable. For example,

    file1_neg.su

=cut

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';

=head2 Import packages

=cut

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

use App::SeismicUnixGui::misc::SeismicUnix
  qw($go $in $off $on $out $ps $to $suffix_ascii $suffix_bin $suffix_ps $suffix_segy $suffix_su);
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use aliased 'App::SeismicUnixGui::misc::control';
use aliased 'App::SeismicUnixGui::misc::readfiles';

=head2 instantiation of packages

=cut

my $get              = L_SU_global_constants->new();
my $Project          = Project_config->new();
my $control          = control->new();
my $readfiles        = readfiles->new();
my $DATA_SEISMIC_SU  = $Project->DATA_SEISMIC_SU();
my $DATA_SEISMIC_BIN = $Project->DATA_SEISMIC_BIN();
my $DATA_SEISMIC_TXT = $Project->DATA_SEISMIC_TXT();

my $PS_SEISMIC = $Project->PS_SEISMIC();

my $var          = $get->var();
my $on           = $var->{_on};
my $off          = $var->{_off};
my $true         = $var->{_true};
my $false        = $var->{_false};
my $empty_string = $var->{_empty_string};

=head2 Encapsulated
hash of private variables

=cut

my $suop = {
	_inbound_list => '',
	_nw           => '',
	_op           => '',
	_Step         => '',
	_note         => '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

	my ($self) = @_;

	if ( length $suop->{_inbound_list} ) {
		my $file_num;
		my @Step;

		my ( $file_name_aref, $num_files ) = _get_file_names();
		my ($inbound_aref) = _get_inbound();
		my @inbound        = @$inbound_aref;
		my @file_name      = @$file_name_aref;
		my $num_of_files   = scalar @file_name;

		# print("_get_inbound: @inbound\n");
		my $outbound;
		my $step;

		my $last_idx        = $num_of_files - 1;

		# All cases when num_traces >=0
		# for first file
		$outbound = $DATA_SEISMIC_SU.'/'.$file_name[0] . '_' . $suop->{_op} . $suffix_su;
		$step     = " suop $suop->{_Step} < $inbound[0] > $outbound ";
#		print ("outbound=$outbound\n");

		if ( $last_idx >= 2 ) {

			# CASE: >= 3 operations
			for ( my $i = 1 ; $i < $last_idx ; $i++ ) {

				$outbound =
					$DATA_SEISMIC_SU . '/'
				  . $file_name[$i] . '_'
				  . $suop->{_op}
				  . $suffix_su;
				$step =
				  $step . "&  suop $suop->{_Step} < $inbound[$i] > $outbound ";

			}

			# for last file
			$outbound = $DATA_SEISMIC_SU.'/'.$file_name[$last_idx] . '_' . $suop->{_op} . $suffix_su;
			$suop->{_Step} =
			  $step . "&  suop $suop->{_Step} < $inbound[$last_idx] > $outbound ";

		}
		elsif ( $last_idx == 1 ) {

			# for last file
			$outbound = $DATA_SEISMIC_SU.'/'.$file_name[$last_idx] . '_' . $suop->{_op} . $suffix_su;
			$suop->{_Step} =
			  $step . "&  suop $suop->{_Step} < $inbound[$last_idx] > $outbound ";

		}
		elsif ( $last_idx == 0 ) {

			$suop->{_Step} = $step;

		}
		else {
			print("suop,Step,unexpected case\n");
			return();
		}

		return ($suop->{_Step});
	}
	elsif ( not length $suop->{_inbound_list} ) {

		$suop->{_Step} = 'suop' . $suop->{_Step};
		return ( $suop->{_Step} );

	}
	else {
		print("suop, Step, incorrect parameters\n");
	}

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

	$suop->{_note} = 'suop' . $suop->{_note};
	return ( $suop->{_note} );

}

=head2 sub clear

=cut

sub clear {
	$suop->{_inbound_list} = '';
	$suop->{_nw}           = '';
	$suop->{_op}           = '';
	$suop->{_Step}         = '';
	$suop->{_note}         = '';
}

=head2 sub _get_file_names

=cut

sub _get_file_names {
	my ($self) = @_;

	if ( length $suop->{_inbound_list} ) {

#		_set_inbound_list(); 

		my $inbound_list = $suop->{_inbound_list};

		my ( $file_names_ref, $num_files ) = $readfiles->cols_1p($inbound_list);
		my $result_a = $file_names_ref;
		my $result_b = $num_files;

		#		print("_get_file_names, values=@$file_names_ref\n");
		return ( $result_a, $result_b );

	}
	else {
		print("_get_file_names, missing inbound\n");
		return ();
	}

}

=head2 sub _get_inbound

=cut

sub _get_inbound {
	my ($self) = @_;

	my ( $array_ref, $num_files ) = _get_file_names();

	if ( length $array_ref ) {

		my @file_name = @$array_ref;
		my @inbound;

		for ( my $i = 0 ; $i < $num_files ; $i++ ) {

			$inbound[$i] = $DATA_SEISMIC_SU . '/' . $file_name[$i] . $suffix_su;

		}

		return ( \@inbound );

	}
	else {
		print("suop,_get_inbound, missing file names\n");
		return ();
	}

}

=head2 sub _set_inbound_list

=cut

sub _set_inbound_list {
	my ($self) = @_;

	if ( length $suop->{_inbound_list} ) {

		my $inbound_list = $suop->{_inbound_list};
		$control->set_back_slashBgone($inbound_list);
		$inbound_list = $control->get_back_slashBgone();
		$suop->{_inbound_list} = $inbound_list;

	}
	else {
		print("_set_inbound_list, missing list\n");
		return ();
	}

}

=head2 sub list

 list array

=cut

sub list {
	my ( $self, $list ) = @_;

	if ( length $list ) {

		$suop->{_inbound_list} = $list;
		_set_inbound_list();

		#		print("suop,list is $suop->{_inbound_list}\n\n");

	}
	else {
		print("suop, list, missing list,\n");
	}
	return ();
}

#=head2 sub neg 
#
#
#=cut
#
#sub neg {
#
#	my ( $self, $neg ) = @_;
#	if ( $neg ne $empty_string ) {
#
#		$suop->{_neg}   = $neg;
#		$suop->{_note} = $suop->{_note} . ' neg=' . $suop->{_neg};
#		$suop->{_Step} = $suop->{_Step} . ' neg=' . $suop->{_neg};
#
#	}
#	else {
#		print("suop, neg, missing neg,\n");
#	}
#}

=head2 sub nw 


=cut

sub nw {

	my ( $self, $nw ) = @_;
	if ( $nw ne $empty_string ) {

		$suop->{_nw}   = $nw;
		$suop->{_note} = $suop->{_note} . ' nw=' . $suop->{_nw};
		$suop->{_Step} = $suop->{_Step} . ' nw=' . $suop->{_nw};

	}
	else {
		print("suop, nw, missing nw,\n");
	}
}

=head2 sub op 


=cut

sub op {

	my ( $self, $op ) = @_;
	if ( $op ne $empty_string ) {

		$suop->{_op}   = $op;
		$suop->{_note} = $suop->{_note} . ' op=' . $suop->{_op};
		$suop->{_Step} = $suop->{_Step} . ' op=' . $suop->{_op};

	}
	else {
		print("suop, op, missing op,\n");
	}
}

=head2 sub get_max_index

max index = number of input variables -1
 
=cut

sub get_max_index {
	my ($self) = @_;
	my $max_index = 2;

	return ($max_index);
}

1;
