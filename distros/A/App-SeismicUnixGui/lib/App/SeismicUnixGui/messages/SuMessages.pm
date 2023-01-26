package App::SeismicUnixGui::messages::SuMessages;

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

=head1 DOCUMENTATION

=head2 SYNOPSIS 
PACKAGE NAME: SuMessages 
 AUTHOR: Juan Lorenzo
         July 29 2015

 DESCRIPTION: 
 Version: 1.1
 Version: 1.11 : June 12 2007 
   Include messages for interactive bottom mute
 Messages to users in Seismic unix programs

=head2 USE

=head3 NOTES 

=head4 
 Examples

=head3 SEISMIC UNIX NOTES  

=head4 CHANGES and their DATES

=cut

=head2

=head3 STEPS

 1. define the types of variables you are using
    these would be the values you enter into 
    each of the Seismic Unix programs  each of the 
    Seismic Unix programs

 2. build a list or hash with all the possible variable
    names you may use and you can even change them

=cut

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};
my $NaN			= $var->{_NaN};

=head2

set defaults

VELAN DATA 
 m/s

 
=cut

my $SuMessages = {
	_cdp_num       => '',
	_gather_num    => '',
	_gather_type   => '',
	_gather_header => '',
	_type          => '',
	_instructions  => ''
};

=head2 subroutine clear

  sets all variable strings to '' 

=cut

sub clear {

	$SuMessages->{_cdp_num}       = '';
	$SuMessages->{_gather_num}    = '';
	$SuMessages->{_gather_type}   = '';
	$SuMessages->{_gather_header} = '';
	$SuMessages->{_type}          = '';
	$SuMessages->{_instructions}  = '';
}

=head2 subroutine cdp_num

  sets cdp number to consider  

=cut

sub cdp_num {
	my ( $self, $cdp_num ) = @_;

	if ( defined $cdp_num ) {
		
		$SuMessages->{_cdp_num}    = $cdp_num;
		$SuMessages->{_gather_num} = $cdp_num;
		# print("\ncdp num is $SuMessages->{_cdp_num}\n");
		
	}
	else {

		print("\nSuMessages, cdp num, missing cdp_num\n");
	}

}

=head2 subroutine gather_header

  sets binheader type to consider  

=cut

sub gather_header {
	my ( $self, $gather_header ) = @_;
	$SuMessages->{_gather_header} = $gather_header if defined($gather_header);

	#print("\ngather_header is $SuMessages->{_gather_header}\n");
}

=head2 subroutine gather_type

  sets gather type to consider  

=cut

sub gather_type {
	my ( $self, $gather_type ) = @_;
	$SuMessages->{_gather_type} = $gather_type if defined($gather_type);

	#print("\n_gather_type is $SuMessages->{_gather_type}\n");
}

=head2 subroutine gather_num

  sets gather number to consider  

=cut

sub gather_num {
	my ( $self, $gather_num ) = @_;
	$SuMessages->{_gather_num} = $gather_num if defined($gather_num);

	# print("\ngather num is $SuMessages->{_gather_num}\n");
}

=head2

 sub set
   establishes the family type of messages

   e.g., velocity analysis
         sutaup,
         bottom mute
         top mute
         interactive velocity analysis
         general picking
         
=cut

sub set {
	my ( $self, $message_type ) = @_;

	if ( defined($message_type) && $message_type ne $empty_string ) {

		$SuMessages->{_type} = $message_type;

#		print("SuMessages, set, type is $SuMessages->{_type}\n\n");

	}
	else {
		print("SuMessages,set,unexpected message type");
	}
}

=head2

 sub instructions 
   print instructions for a given family type of message 
   e.g., velocity analysis
         sutaup  etc.

=cut

sub instructions {

	my ( $self, $instructions ) = @_;

#print(
#		"SuMessages,instructions:$instructions,gather_num: $SuMessages->{_gather_num}\n\n"
#	);

	if (   defined($instructions)
		&& ( length( $SuMessages->{_gather_num} ) or
		        $SuMessages->{_gather_num} eq $NaN )
		&& $instructions ne $empty_string )
	{

		$SuMessages->{_instructions} = $instructions;

=item CASE:

  interactive spectral analysis 

=cut 

		if ( $SuMessages->{_type} eq 'iSpectralAnalysis' ) {

			if ( $SuMessages->{_instructions} eq 'firstSpectralAnalysis' ) {

				print("\n   GATHER = $SuMessages->{_gather_num}\n\n");
				print("  1. PICK two(2) X-T pairs\n");
				print("  2. Quit window*\n");
				print("  3. Click CALC \n\n\n");
				print("  (*To FINISH picking in window, enter: q \n");
				print("    while mouse lies over image)\n");
				print("LSULSULSULSULSULSULSULSULSULSULSULSULSULSU\n");
				return ();
			}    # end first spectral analysis instructions
		}

=item CASE:

  interactive velocity analysis 

=cut 

		if ( $SuMessages->{_type} eq 'iva' ) {

			if ( $SuMessages->{_instructions} eq 'first_velan' ) {

				print("\n   CDP = $SuMessages->{_cdp_num}\n\n");
				print("   Click PICK  (if you want to pick V-T pairs) \n");
				print("   or Click NEXT  (next CDP)\n\n");
				print("LSULSULSULSULSULSULSULSULSULSULSULSULSULSU\n");
				return ();

			}    # end first-velan instructions

			if ( $SuMessages->{_instructions} eq 'pre_pick_velan' ) {

				print("  1. PICK V-T pairs\n");
				print("  2. Quit window*\n");
				print("  3. Click CALC \n\n\n");
				print("  (*To FINISH picking in window, enter: q \n");
				print("    while mouse lies over image)\n");
				print("LSULSULSULSULSULSULSULSULSULSULSULSULSULSU\n");
				return ();

			}    # end 'pre_pick_velan' instructions

			if ( $SuMessages->{_instructions} eq 'post_pick_velan' ) {

				print("\tCDP = $SuMessages->{_cdp_num}\n\n");
				print(" Are you HAPPY with these picks? \n");
				print("\n");
				print(" If NOT:  \n");
				print("  1. RE-PICK the V-T pairs  \n");
				print("  2. Quit window*, and \n");
				print("  3. Click CALC\n\n");
				print(" If SATISFIED:\n");
				print("  1. Quit window*,\n");
				print("  2. Click NEXT to go to next CDP  \n");
				print("  or Click EXIT    \n\n\n");
				print("  (*To FINISH picking in window, enter: q \n");
				print("    while mouse lies over image)\n");
				print("LSULSULSULSULSULSULSULSULSULSULSULSULSULSU\n");
				return ();

			}    # end post-pick velan
		}    # end iva-type instructions

=item CASE

  Interactive top-mute picking 

=cut 

		if ( $SuMessages->{_type} eq 'iTopMute' ) {

			if ( $SuMessages->{_instructions} eq 'first_top_mute' ) {

				print(
					"\n  $SuMessages->{_gather_type}  GATHER  = $SuMessages->{_gather_num}\n\n"
				);
				print("   Click PICK  (if you want to pick X-T pairs) \n");
				print("   or Click NEXT  (next GATHER)\n\n");
				print("LSULSULSULSULSULSULSULSULSULSULSULSULSULSU\n");
				return ();
			}

			if ( $SuMessages->{_instructions} eq 'pre_pick_mute' ) {

				print("  1. PICK X-T pairs\n");
				print("  2. Quit window*\n");
				print("  3. Click CALC \n\n\n");
				print("  (*To FINISH picking in window, enter: q \n");
				print("    while mouse lies over image)\n");
				print("LSULSULSULSULSULSULSULSULSULSULSULSULSULSU\n");
				return ();
			}

			if ( $SuMessages->{_instructions} eq 'post_pick_mute' ) {

				print(
					"\t $SuMessages->{_gather_type} GATHER = $SuMessages->{_gather_num}\n\n"
				);
				print(" Are you HAPPY with these picks? \n");
				print("\n");
				print(" If NOT:  \n");
				print("  1. PICK the X-T pairs  \n");
				print("  2. Quit window*, and \n");
				print("  3. Click CALC\n\n");
				print(" If SATISFIED:\n");
				print("  1. Quit window*,\n");
				print("  2. Click NEXT to go to next CDP  \n");
				print("  or Click EXIT    \n\n");
				print("LSULSULSULSULSULSULSULSULSULSULSULSULSULSU\n");
				return ();

			}    # end post-pick mute

		}    # end top mute instructions

=item CASE

  Interactive bottom-mute picking 

=cut 

		if ( $SuMessages->{_type} eq 'iBottomMute' ) {

			if ( $SuMessages->{_instructions} eq 'first_bottom_mute' ) {

				print(
					"\n  $SuMessages->{_gather_type}  GATHER  = $SuMessages->{_gather_num}\n\n"
				);
				print("   Click PICK  (if you want to pick X-T pairs) \n");
				print("   or Click NEXT  (next GATHER)\n\n");
				print("LSULSULSULSULSULSULSULSULSULSULSULSULSULSU\n");
				return ();
			}

			if ( $SuMessages->{_instructions} eq 'pre_pick_mute' ) {

				print("  1. PICK X-T pairs\n");
				print("  2. Quit window*\n");
				print("  3. Click CALC \n\n\n");
				print("  (*To FINISH picking in window, enter: q \n");
				print("    while mouse lies over image)\n");
				print("LSULSULSULSULSULSULSULSULSULSULSULSULSULSU\n");
				return ();
			}

			if ( $SuMessages->{_instructions} eq 'post_pick_mute' ) {

				print(
					"\t $SuMessages->{_gather_type} GATHER = $SuMessages->{_gather_num}\n\n"
				);
				print(" Are you HAPPY with these picks? \n");
				print("\n");
				print(" If NOT:  \n");
				print("  1. PICK the X-T pairs  \n");
				print("  2. Quit window*, and \n");
				print("  3. Click CALC\n\n");
				print(" If SATISFIED:\n");
				print("  1. Quit window*,\n");
				print("  2. Click NEXT to go to next CDP  \n");
				print("  or Click EXIT    \n\n");
				print("LSULSULSULSULSULSULSULSULSULSULSULSULSULSU\n");
				return ();

			}    # end post-pick mute

		}    # end bottom mute instructions

=item CASE

  Interactive general x-t picking 

=cut 

		if ( $SuMessages->{_type} eq 'iPick_xt' ) {

			if ( $SuMessages->{_instructions} eq 'first_pick_xt' ) {

				print(
					"\n  $SuMessages->{_gather_type}  GATHER  = $SuMessages->{_gather_num}\n\n"
				);
				print("   Click PICK  (if you want to pick X-T pairs) \n");
				print("   or Click NEXT  (next GATHER)\n\n");
				print("LSULSULSULSULSULSULSULSULSULSULSULSULSULSU\n");
				return ();
			}

			if ( $SuMessages->{_instructions} eq 'pre_pick_xt' ) {

				print("  1. PICK X-T pairs\n");
				print("  2. Quit window*\n");
				print("  3. Click CALC \n\n\n");
				print("  (*To FINISH picking in window, enter: q \n");
				print("    while mouse lies over image)\n");
				print("LSULSULSULSULSULSULSULSULSULSULSULSULSULSU\n");
				return ();
			}

			if ( $SuMessages->{_instructions} eq 'post_pick_xt' ) {

				print(
					"\t $SuMessages->{_gather_type} GATHER = $SuMessages->{_gather_num}\n\n"
				);
				print(" Are you HAPPY with these picks? \n");
				print("\n");
				print(" If NOT:  \n");
				print("  1. PICK the X-T pairs  \n");
				print("  2. Quit window*, and \n");
				print("  3. Click CALC\n\n");
				print(" If SATISFIED:\n");
				print("  1. Quit window*,\n");
				print("  2. Click NEXT to go to next CDP  \n");
				print("  or Click EXIT    \n\n");
				print("LSULSULSULSULSULSULSULSULSULSULSULSULSULSU\n");
				return ();

			}    # end post-pick

		}    # end pick instructions

	}
	else {
		print(
			"SuMessages, instructions, missing instructions or gather_num \n\n"
		);
	}

}    # end sub instructions

1;
