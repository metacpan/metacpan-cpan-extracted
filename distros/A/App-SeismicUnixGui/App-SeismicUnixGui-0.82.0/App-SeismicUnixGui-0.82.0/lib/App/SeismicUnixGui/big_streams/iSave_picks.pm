package App::SeismicUnixGui::big_streams::iSave_picks;

use Moose;
our $VERSION = '0.0.1';

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PROGRAM NAME:iSave_picks.pm
 AUTHOR:  Juan Lorenzo
 DATE:    iSave_picks 
 Version: 1.0 

 DESCRIPTION: Save final version of
  muted picks for any type of muting

=head2 USE

=head4 

 Examples

=head2 SEISMIC UNIX NOTES

=head4 CHANGES and their DATES

 Base on iTop_mute_picks3.pm V 3.0 
	Sept. 2015
 Originally to Save final Top Mute of Data

=head2 STEPS

  use the local library of the user
  bring is user variables from a local file
  create instances of the needed subroutines

=cut

=head2

 instantiate classes

=cut

use aliased 'App::SeismicUnixGui::misc::message';
use aliased 'App::SeismicUnixGui::misc::flow';
use aliased 'App::SeismicUnixGui::sunix::shell::cp';
use App::SeismicUnixGui::misc::SeismicUnix qw($go $in $on $to);
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

use App::SeismicUnixGui::misc::control '0.0.3';
use aliased 'App::SeismicUnixGui::misc::control';

my $control = control->new();
my $get     = L_SU_global_constants->new();
my $log     = message->new();
my $run     = flow->new();
my $cp      = cp->new();
my $Project = Project_config->new();

my $purpose      = $get->purpose();
my $var          = $get->var();
my $empty_string = $var->{_empty_string};

=head2

 Import file-name  and directory definitions

=cut 

use App::SeismicUnixGui::misc::SeismicUnix qw($itemp_picks_sorted_par_ $ipicks_par_);
my ($DATA_SEISMIC_TXT) = $Project->DATA_SEISMIC_TXT();

=head2
 
 declare variables types
 establish just the locally scoped variables

=cut

my ( @flow, @cp, @items );

=head2

 create hash with important variables

=cut

my $iSave_picks = {
    _gather_num    => '',
    _gather_type   => '',
    _gather_header => '',
    _file_in       => '',
    _inbound       => '',
    _outbound      => '',
    _purpose       => '',
};

=head2 subroutine clear

  sets all variable strings to '' 

=cut 

sub clear {
    $iSave_picks->{_gather_num}    = '';
    $iSave_picks->{_gather_type}   = '';
    $iSave_picks->{_gather_header} = '';
    $iSave_picks->{_inbound}       = '';
    $iSave_picks->{_outbound}      = '';
    $iSave_picks->{_purpose}       = '';
}

=head2 subroutine gather_header

  sets gather_header number to consider  

=cut

sub gather_header {
    my ( $variable, $gather_header ) = @_;
    $iSave_picks->{_gather_header} = $gather_header
      if defined($gather_header);
}

=head2 sub calc

 rewrite sorted picks into a permanent file

=cut

sub calc {

    my ($self) = @_;

    #  my $suffix = '_'.$iSave_picks->{_gather_header}.
    #		$iSave_picks->{_gather_num};

    # CASE 1 - geopsy
    if ( defined $iSave_picks->{_purpose}
        && $iSave_picks->{_purpose} eq $purpose->{_geopsy} )
    {

        my ($GEOPSY_PICKS_RAW) = $Project->GEOPSY_PICKS_RAW();

        if ( -d $GEOPSY_PICKS_RAW ) {

            $iSave_picks->{_inbound} =
                $DATA_SEISMIC_TXT . '/'
              . '.itemp'
              . '_picks_sorted_'
              . $iSave_picks->{_file_in};

            $iSave_picks->{_outbound} =
                $GEOPSY_PICKS_RAW . '/' . 'xt_'
              . $iSave_picks->{_file_in} . '_'
              . $iSave_picks->{_gather_type}
              . $iSave_picks->{_gather_num};

            $cp->from( $iSave_picks->{_inbound} );
            $cp->to( $iSave_picks->{_outbound} );
            $cp[1] = $cp->Step();

        }
        else {

            use Tk;
            use strict;
            use App::SeismicUnixGui::misc::L_SU_global_constants;

            my $get = L_SU_global_constants->new();
            my $var = $get->var();

            # Main Window
            my $mw = MainWindow->new();

            my $arial_14 = $mw->fontCreate(
                'arial_14',
                -family => 'arial',
                -weight => 'bold',
                -size   => -14
            );

            $mw->configure( -background => $var->{_my_purple} );

            use App::SeismicUnixGui::messages::message_director;
            my $iPick_message = message_director->new();
            my $message       = $iPick_message->iPick(0);

            $mw->messageBox(
                -title      => "iPick geopsy",
                -font       => $arial_14,
                -message    => $message,
                -background => $var->{_my_yellow},
                -default    => 'oK',
            );
            print("iSave_picks,calc, $message\n");
        }

        # CASE 2 - normal case
    }
    elsif ( not defined $iSave_picks->{_purpose}
        || $iSave_picks->{_purpose} eq $empty_string )
    {

        $iSave_picks->{_inbound} =
            $DATA_SEISMIC_TXT . '/'
          . '.itemp'
          . '_picks_sorted_par_'
          . $iSave_picks->{_file_in};

        $iSave_picks->{_outbound} =
            $DATA_SEISMIC_TXT . '/'
          . 'xt_par_'
          . $iSave_picks->{_file_in} . '_'
          . $iSave_picks->{_gather_type}
          . $iSave_picks->{_gather_num};

        $cp->from( $iSave_picks->{_inbound} );
        $cp->to( $iSave_picks->{_outbound} );
        $cp[1] = $cp->Step();

    }
    else {
        print("1. iSave_picks, purpose:---$iSave_picks->{_purpose}---\n");
    }

=head2

  DEFINE FLOW(S)

=cut 

    @items = ( $cp[1], $go );
    $flow[1] = $run->modules( \@items );

=head2

  RUN FLOW(S)

=cut 

    $run->flow( \$flow[1] );

=head2

  LOG FLOW(S)TO SCREEN AND FILE

=cut

    # print  "$flow[1]\n";
    # $log->file($flow[1]);

}    # end calc subroutine

=head2 subroutine file_in

 Required file name
 on which to pick x,t values

=cut

sub file_in {

    my ( $self, $file_in ) = @_;

    if ( defined $file_in && $file_in ne $empty_string ) {

        # e.g. 'sp1' becomes sp1
        $control->set_infection($file_in);
        $file_in = control->get_ticksBgone();
        $iSave_picks->{_file_in} = $file_in;

        # print("iSave_picks, file_in: $iSave_picks->{_file_in} \n");

    }
    else {
        print("iSave_picks, file_in: unexpected file_in \n");
    }
}

=head2 subroutine gather

  sets gather number to consider  

=cut

sub gather_num {
    my ( $variable, $gather_num ) = @_;
    $iSave_picks->{_gather_num} = $gather_num if defined($gather_num);
}

=head2 sub gather_type

  define which family of messages to use
  
  e.g., SP or CDP

=cut

sub gather_type {
    my ( $self, $gather_type ) = @_;

    if ( defined($gather_type)
        || $gather_type eq $empty_string )
    {

        control->set_infection($gather_type);
        $gather_type = control->get_ticksBgone();
        $iSave_picks->{_gather_type} = $gather_type;

        # print("iSave_picks,gather_type: $gather_type\n");

    }
    else {
        print("iSave_picks,gather_type, unexpected gather_type");
    }
    return ();
}

#sub icp {
#
# 	my ($self) = @_;
#
#	use Shell qw(echo);
#
#    my  $home_directory = ` echo \$HOME`;
#    chomp $home_directory;
#
#	my $HOME 			= $home_directory;
#
#	use File::Copy;
#	use App::SeismicUnixGui::misc::control '0.0.3';
#use aliased 'App::SeismicUnixGui::misc::control';
#	use dirs;
#	use App::SeismicUnixGui::misc::readfiles;
#
#	my $ACTIVE_CONFIGURATION 		= $HOME.'/.L_SU/configuration/active';
#	my $inbound						= $ACTIVE_CONFIGURATION.'/Project.config';
#
#	my $readfiles					= readfiles	->new();
#	my $dirs						= dirs		->new();
#	my $control						= control	->new();
#
#	my $project = {
#		_names_aref   				=>	'',
#		_values_aref   				=> 	'',
#		_check_buttons_aref  		=>	'',
#	};
#
#	my ($names_aref,$values_aref)  	= $readfiles->configs($inbound);
#
#	$project->{_names_aref} 		= $names_aref;
#	$project->{_values_aref} 		= $values_aref;
#	my $PROJECT_NAME				= @{$project->{_values_aref}}[2];
#	# my $PROJECT_PATH				= @{$project->{_values_aref}}[1];
#	$dirs							-> set_path($PROJECT_NAME);
#	my $Project_name 				= $dirs-> get_last_dirInpath();
#	$control						-> set_infection($Project_name );
#	$Project_name 					= $control->get_ticksBgone();
#
#	# print("Project_config,update_configuration_file, PROJECT_PATH: $PROJECT_PATH\n");
#
#	# print("Project_config,update_configuration_file, Project_name: $Project_name \n");
#
#	my $FROM_project_config		= $inbound;
#	my $TO_project_config		= $HOME.'/.L_SU/configuration/'.$Project_name.'/Project.config';
#	# print("Project_config,update_configuration_files copying from $FROM_project_config to $TO_project_config\n");
#	copy($FROM_project_config,$TO_project_config);
#
#
# }

=head2  sub set_purpose 

  define where the data will need to go
  define the type of behavior
  
=cut

sub set_purpose {

    my ( $self, $type ) = @_;

    if ( defined $type
        && $type ne $empty_string )
    {

        my $control = control->new();
        $control->set_infection($type);
        $type = control->get_ticksBgone();

        # print("iSave_picks,set_purpose: $type\n");
        # print("iSave_picks,set_purpose: $purpose->{_geopsy}\n");

        if ( $type eq $purpose->{_geopsy} ) {

            $iSave_picks->{_purpose} = $type;

            # print("iSave_picks,set_purpose: $iSave_picks->{_purpose}\n");

        }
        else {
            # print("iSave_picks,set_purpose is unavailable, NADA\n");
        }

    }
    else {
        # print("iSave_picks,set_purpose value is empty NADA\n");
    }
}

1;
