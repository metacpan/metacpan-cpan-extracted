package App::SeismicUnixGui::big_streams::iPick;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PROGRAM NAME: iPick.pm 
 AUTHOR: Juan Lorenzo
 DATE:  Sept. 14 2015 
         

 DESCRIPTION: 
 Version: 0.0.1
 Package used for interactive picking of points

=head2 USE

=head3 NOTES 

 "purpose" is now exclusively 'geopsy', in which case the processing
 is slightly different and
 the output directories and files have a unique format
 
 ep is an appropriated gather header. 
 If you do not want to have ep
 defined as a gather header variable, then the following is allowed:
 p=0
ep max=0 a
ep min=0  
 

=head4

 Examples:

     base_file_name  	= 30Hz_All_geom_geom;
     gather_header  	= fldr;   (single gather type for picking)
     offset_type  		= tracl;  (or, e.g., offset but only affects the label *)
     first_gather   	= 1;
     gather_inc    		= 1;
     last_gather    	= 100;
     freq    		    = 0,3,100,200;  or freq = (can be left empty without any values as well)
     **gather_type    	= fldr;
     min_amplitude      = .0;
     max_amplitude      = .75;
     min_x1             = 15.873015           (Hz, for geopsy)
     max_x1             = 999.999             (Hz, for geopsy)
     purpose            = geopsy
      
      * if you want offset to be considered when plotting data
      then modify the d2 and f2 values prior to picking.
      
      ** Define family of interactive user messages to use
          SP or CDP

=head3 SEISMIC UNIX NOTES  

=head4 CHANGES and their DATES


=cut

=head2 STEPS


=cut

=head2 Import 

  packages
  directory definitions

=cut 

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';

use App::SeismicUnixGui::misc::control '0.0.3';
use aliased 'App::SeismicUnixGui::misc::control';

use aliased 'App::SeismicUnixGui::misc::message';
use aliased 'App::SeismicUnixGui::sunix::shell::cp';
use aliased 'App::SeismicUnixGui::misc::flow';

use aliased 'App::SeismicUnixGui::big_streams::iPicks2par';
use aliased 'App::SeismicUnixGui::big_streams::iPicks2sort';
use aliased 'App::SeismicUnixGui::big_streams::iSave_picks';

use aliased 'App::SeismicUnixGui::specs::big_streams::iPick_specB';
use aliased 'App::SeismicUnixGui::big_streams::iShowNselect_picks';
use aliased 'App::SeismicUnixGui::big_streams::iSelect_xt';

use aliased 'App::SeismicUnixGui::misc::manage_files_by2';
use aliased 'App::SeismicUnixGui::misc::old_data';

use aliased 'App::SeismicUnixGui::messages::SuMessages';
use App::SeismicUnixGui::misc::SeismicUnix qw($on $off $in $to $go $ipicks_par_
	$ipick_check_pickfile_ $false $true
	$itemp_picks_ $itemp_picks_sorted_);

my $Project            = Project_config->new();
my ($DATA_SEISMIC_SU)  = $Project->DATA_SEISMIC_SU();
my ($DATA_SEISMIC_TXT) = $Project->DATA_SEISMIC_TXT();
my ($date)             = $Project->date();

=head2 instantiate 

 programs

=cut

my $control            = control->new();
my $cp                 = cp->new();
my $test               = manage_files_by2->new();
my $log                = message->new();
my $run                = flow->new();
my $iPick_specB        = iPick_specB->new();
my $iShowNselect_picks = iShowNselect_picks->new();
my $iSelect_xt         = iSelect_xt->new();
my $iPicks2par         = iPicks2par->new();
my $iPicks2sort        = iPicks2sort->new();
my $check4old_data     = old_data->new();
my $iSave_picks        = iSave_picks->new();
my $SuMessages         = SuMessages->new();
my $get                = L_SU_global_constants->new();

my $variables       = $iPick_specB->variables();
my $DATA_DIR_IN     = $variables->{_DATA_DIR_IN};
my $DATA_DIR_OUT    = $variables->{_DATA_DIR_OUT};
my $data_suffix_in  = $variables->{_data_suffix_in};
my $data_suffix_out = $variables->{_data_suffix_out};
my $var             = $get->var();
my $empty_string    = $var->{_empty_string};

=head2 private hash
 
=cut

my $iPick = {
	_gather_header     => '',
	_offset_type       => '',
	_gather_num        => '',
	_gather_num_suffix => '',
	_exists            => '',
	_file_in           => '',
	_freq              => '',
	_gather_type       => '',
	_inbound           => '',
	_inbound_curve     => '',
	_max_amplitude     => '',
	_max_x1        => '',
	_min_amplitude     => '',
	_min_x1        => '',
	_next_step         => '',
	_number_of_tries   => '',
	_purpose           => '',
	_textfile_in       => '',
	_textfile_out      => ''
};

=head2
 
 declare variables types
 establish just the locally scoped variables

=cut

my ( @flow, @cp, @items );

=head2 sub clear

  sets all variable strings to '' 

=cut

sub clear {
	$iPick->{_gather_num}        = '';
	$iPick->{_gather_type}       = '';
	$iPick->{_gather_header}     = '';
	$iPick->{_offset_type}       = '';
	$iPick->{_gather_num_suffix} = '';
	$iPick->{_exists}            = '';
	$iPick->{_file_in}           = '';
	$iPick->{_freq}              = '';
	$iPick->{_inbound}           = '';
	$iPick->{_inbound_curve}     = '';
	$iPick->{_max_amplitude}     = '';
	$iPick->{_max_x1}        = '';
	$iPick->{_min_amplitude}     = '';
	$iPick->{_min_x1}        = '';
	$iPick->{_next_step}         = '';
	$iPick->{_number_of_tries}   = '';
	$iPick->{_purpose}           = '';
	$iPick->{_textfile_in}       = '';
	$iPick->{_textfile_out}      = '';

}

=head2 sub icp_sorted_2_old_picks

 When user wants to rreview old data 
 this sub allows the user to 
use a prior sorted file
 Juan M. Lorenzo
 Jan 10 2010

  ted_inbound	= $DATA_DIR_OUT.'/'.$iPick->{_inbound_curve_file};
  my $outbound			= $DATA_DIR_OUT.'/'.$itemp_picks_.$iPick->{_file_in};

 	$cp    ->from($inbound);
 	$cp    ->to($outbound);
 	$cp[1] = $cp->Step();
    input file is ipicks_sorted
    output pick file 
    text file out: ipicks_old 


=cut 

sub _icp_sorted2temp_picks {

	my ( $inbound_sorted, $outbound );
	my ($writefile_out);
	my ($flow);
	my ( $XTpicks_out, $XTpicks_in );

	&_inbound_curve();

	$inbound_sorted = $iPick->{_inbound_curve};
	$outbound       = $DATA_DIR_OUT . '/' . $itemp_picks_ . $iPick->{_file_in};

	$cp->clear();
	$cp->from($inbound_sorted);
	$cp->to($outbound);
	$cp[1] = $cp->Step();

=head2

  DEFINE FLOW(S)

=cut 

	@items = ( $cp[1] );
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

	#end of copy of XT old picks sorted to iXTpicks_old
}

=head2  sub _inbound_curve

 Required text file with x,t pairs
 
=cut

sub _inbound_curve {

	my ($self) = @_;

	if ( defined $iPick->{_file_in} ) {

		my $file_in = $iPick->{_file_in};
		$iPick->{_inbound_curve} = $DATA_DIR_OUT . '/' . $itemp_picks_sorted_ . $file_in;

		# print("iPick, _inbound_curve: $iPick->{_inbound_curve} \n\n");

	} else {
		print("iPick, _inbound_curve: unexpected file_in \n\n");
	}
}

=head2 sub gather_header

  define header on which to search or run suwindow
  For example, when you have a string of shotpoint
  gathers in a single file and you want to examine
  one at a time. In this case the binheader type can
  be ep

=cut

sub gather_header {
	my ( $self, $gather_header ) = @_;

	if ( defined($gather_header)
		|| $gather_header eq $empty_string ) {

		$iPick->{_gather_header} = $gather_header;

	} else {
		print("iPick,gather_header, unexpected gather_header");
	}
	return ();
}

=head2 sub data_scale

 Required data plotting scale 

=cut

sub data_scale {
	my ( $self, $data_scale ) = @_;

	if ( defined($data_scale)
		|| $data_scale eq $empty_string ) {

		$iPick->{_data_scale} = $data_scale;

	} else {
		print("iPick,data_scale, unexpected data_scale");
	}
	return ();
}

=head2  sub file_in

 Required file name
 on which to pick top mute values

=cut

sub file_in {
	my ( $self, $file_in ) = @_;

	if ( $file_in && $file_in ne $empty_string ) {

		# e.g. 'sp1' becomes sp1
		$control->set_infection($file_in);
		$file_in = $control->get_ticksBgone();
		$iPick->{_file_in} = $file_in;

		# print("iPick,file_in,file is $iPick->{_file_in} \n");

	} else {
		print("iPick,file_in,file does not exist\n");
	}
	return ();
}

=head2 sub freq
Bandpass filter frequencies before
 conducting amplitude analysis
 e.g., "3,6,40,50"
 
=cut

sub freq {
	my ( $self, $freq ) = @_;

	$iPick->{_freq} = $freq if defined($freq);

	# print("iPick,freq,freq is$iPick->{_freq}\n\n");
}

=head2 sub gather_num

  sets gather number to consider  

=cut

sub gather_num {
	my ( $self, $gather_num ) = @_;

	if ( defined $gather_num && $gather_num ne $empty_string ) {
		$iPick->{_gather_num}        = $gather_num;
		$iPick->{_gather_num_suffix} = '_gather' . $iPick->{_gather_num};

		# print("iPick,gather_num: $gather_num\n");

	} else {
		print("iPick,gather_num, unexpected gather_num\n");
	}

}

=head2 sub  gather_type
Define which family of 
interactive user messages to use
SP or CDP

=cut

sub gather_type {
	my ( $self, $gather_type ) = @_;

	if ( defined($gather_type)
		|| $gather_type eq $empty_string ) {

		$iPick->{_gather_type} = $gather_type;

		# print("iPick,gather_type: $gather_type\n");

	} else {
		print("iPick,gather_type, unexpected gather_type");
	}
	return ();
}

=head2 sub get4data_type

look for old data

  Are there old picks to read?
  These old picks are of a type e.g.,
  velan,
  gather
  general Pick_xt
  
=cut

sub get4data_type {

	my ($self) = @_;

	if (   defined( $iPick->{_type} )
		&& defined( $iPick->{_gather_num} )
		&& defined( $iPick->{_file_in} )
		&& $iPick->{_file_in} ne $empty_string
		&& $iPick->{_type} ne $empty_string
		&& $iPick->{_gather_num} ne $empty_string ) {

		$check4old_data->gather_num( $iPick->{_gather_num} );
		$check4old_data->file_in( $iPick->{_file_in} );
		$iPick->{_exists} = $check4old_data->type( $iPick->{_type} );
		my $result = $iPick->{_exists};

		return ($result);

	} else {
		print("iPick,type,missing type or gather_num\n");
	}

}

=head2 sub iPicks_par
Convert format of pick files for use later
 into "par" format 
 
=cut

sub iPicks_par {

	my ($self) = @_;
	my $ans;

	if ( defined $iPick->{_file_in}
		&& $iPick->{_file_in} ne $empty_string ) {

		$iPick->{_inbound} = $DATA_DIR_IN . '/' . $iPick->{_file_in} . $data_suffix_in;
		$ans = $test->does_file_exist( \$iPick->{_inbound} );

		# print("iPick, iPicks_par, Does file exist? $ans \n");
		# print("iPick, iPicks_par, file: $iPick->{_inbound}\n");
	}

	if ($ans) {

		$iPicks2par->file_in( $iPick->{_file_in} );
		$iPicks2par->calc();

	} else {
		print("iPick, iPicks_par, file does not exist\n");
	}

	return ();
}

=head2 sub iPicks_sort

 convert format of pick files for use later
 into "par" format 
 
=cut

sub iPicks_sort {

	my ($self) = @_;
	my $ans;

	if ( defined $iPick->{_file_in}
		&& $iPick->{_file_in} ne $empty_string ) {

		# print("iPick, iPicks_sort, file :$iPick->{_file_in}\n");
		$iPick->{_inbound} = $DATA_DIR_OUT . '/' . $itemp_picks_ . $iPick->{_file_in};

		# print("iPick, iPicks_sort, file :$iPick->{_inbound}\n");
		$ans = $test->does_file_exist( \$iPick->{_inbound} );
	}

	if ($ans) {

		if ( $iPick->{_number_of_tries} > 0 ) {

			# print("iPick,iPicks_sort,file, file_in: $iPick->{_file_in}\n");
			$iPicks2sort->file_in( $iPick->{_file_in} );
			$iPicks2sort->calc();

		} else {

			# print("iPick,iPicks_sort,NADA\n");
		}

	} else {
		print("iPick, iPicks_sort, file does not exist\n");
	}

	return ();
}

=head2 sub iPicks_save

 save pick files for later use
 
=cut

sub iPicks_save {
	my ($self) = @_;
	$iSave_picks->gather_num( $iPick->{_gather_num} );
	$iSave_picks->gather_header( $iPick->{_gather_header} );
	$iSave_picks->gather_type( $iPick->{_gather_type} );
	$iSave_picks->file_in( $iPick->{_file_in} );
	$iSave_picks->set_purpose( $iPick->{_purpose} );
	$iSave_picks->calc();
	return ();
}

=head2 sub  iPicks_select_xt

 Select point co-ordinates from traces
 provide file name
 
=cut

sub iPicks_select_xt {

	my ($self) = @_;

	if ( defined $iPick->{_file_in}
		&& $iPick->{_file_in} ne $empty_string ) {

		$iPick->{_inbound} = $DATA_DIR_IN . '/' . $iPick->{_file_in} . $data_suffix_in;
		my $ans = $test->does_file_exist( \$iPick->{_inbound} );

		# print("iPick,iPicks_select_xt, file: $iPick->{_file_in} exists?:$ans\n");

		if ($ans) {

			# update a possible previous pick and save to a new file name for
			# later use in ShowNselect
			if ( $iPick->{_number_of_tries} >= 2 ) {

				&iPicks_sort();

				# will not wait for sunix programs to stop so must be done here
				# and at the start of picking

			} else {

				# print("iPick, iPicks_select_xt, NADA\n");
			}

			$iSelect_xt->gather_type( $iPick->{_gather_type} );
			$iSelect_xt->offset_type( $iPick->{_offset_type} );
			$iSelect_xt->gather_header( $iPick->{_gather_header} );
			$iSelect_xt->file_in( $iPick->{_file_in} );
			$iSelect_xt->freq( $iPick->{_freq} );
			$iSelect_xt->gather_num( $iPick->{_gather_num} );
			$iSelect_xt->max_amplitude( $iPick->{_max_amplitude} );
			$iSelect_xt->max_x1( $iPick->{_max_x1} );
			$iSelect_xt->min_amplitude( $iPick->{_min_amplitude} );
			$iSelect_xt->min_x1( $iPick->{_min_x1} );
			$iSelect_xt->number_of_tries( $iPick->{_number_of_tries} );
			$iSelect_xt->set_purpose( $iPick->{_purpose} );
			$iSelect_xt->calcNdisplay();

		} else {
			print("iPick,iPicks_select_xt, file does not exist. ans=$ans\n");
		}

	}

}

=head2 sub  iPicks_shownNselect

	Update a possible previous pick and save to a new file name for	
	later use in ShowNselect
	num_tries >1, is a condition already imposed in Pick.pl
 
=cut

sub iPicks_shownNselect {
	my (@self) = @_;

	&_icp_sorted2temp_picks;
	$iShowNselect_picks->file_in( $iPick->{_file_in} );
	$iShowNselect_picks->gather_header( $iPick->{_gather_header} );
	$iShowNselect_picks->offset_type( $iPick->{_offset_type} );
	$iShowNselect_picks->freq( $iPick->{_freq} );
	$iShowNselect_picks->gather_num( $iPick->{_gather_num} );
	$iShowNselect_picks->max_amplitude( $iPick->{_max_amplitude} );
	$iShowNselect_picks->min_x1( $iPick->{_min_x1} );
	$iShowNselect_picks->max_x1( $iPick->{_max_x1} );
	$iShowNselect_picks->min_amplitude( $iPick->{_min_amplitude} );
	$iShowNselect_picks->number_of_tries( $iPick->{_number_of_tries} );
	$iShowNselect_picks->set_purpose( $iPick->{_purpose} );
	$iShowNselect_picks->calcNdisplay();
	return ();
}

=head2

 sub maximum amplitude to plot 

=cut

sub max_amplitude {

	my ( $self, $max_amplitude ) = @_;

	if ( defined($max_amplitude) ) {

		$iPick->{_max_amplitude} = $max_amplitude;

		# print("max_amplitude is $iPick->{_max_amplitude}\n\n");

	} else {
		print("iPick,max_amplitude, unexpected max amplitude\n");
	}
}

=head2

 sub maximum time/Hz to plot 

=cut

sub max_x1 {
	my ( $self, $max_x1 ) = @_;

	if ( length $max_x1 ) {

		$iPick->{_max_x1} = $max_x1;

		# print("max_x1 is $iPick->{_max_x1}\n\n");

	} else {
		print("iPick,max_x1, unexpected max time-s\n");
	}
}

=head2 sub  iPicks_message

  instructions 

=cut

sub iPicks_message {

	my ( $self, $message ) = @_;

	if ( defined($message) ) {
		$iPick->{_message} = $message;

		# print("message is $iPick->{_message}\n\n");

	} else {
		print("iPick,iPicks_message, unexpected message\n");
	}
}

=head2

 sub minumum amplitude to plot 

=cut

sub min_amplitude {
	my ( $self, $min_amplitude ) = @_;

	if ( defined $min_amplitude && $min_amplitude ne $empty_string ) {
		$iPick->{_min_amplitude} = $min_amplitude;

		# print("min_amplitude is $iPick->{_min_amplitude}\n\n");
	} else {
		print("iPick,min_amplitude, unexpected min amplitude\n");
	}
}

=head2

 sub minimum time/Hzto plot 

=cut

sub min_x1 {
	my ( $self, $min_x1 ) = @_;

	if ( length $min_x1 ) {

		$iPick->{_min_x1} = $min_x1;

		# print("min_x1 is $iPick->{_min_x1}\n\n");

	} else {
		print("iPick,min_x1, unexpected min time-s\n");
	}
}

=head2

 sub number_of_tries 
 required count of the number of attempts
 at estimating the velocity

=cut

sub number_of_tries {

	my ( $self, $number_of_tries ) = @_;

	if ( $number_of_tries ne $empty_string ) {

		$iPick->{_number_of_tries} = $number_of_tries
			if defined($number_of_tries);

		# print("iPick, number_of_tries,$iPick->{_number_of_tries} \n\n");

	} else {
		print("iPick, number_of_tries, unexpected number_of_tries} \n\n");
	}
}

=head2 sub  offset_type

  define which values to use in the x axis 

=cut

sub offset_type {

	my ( $self, $offset_type ) = @_;
	$iPick->{_offset_type} = $offset_type if defined($offset_type);

	# print("offset type -2 $offset_type\n\n");
}

=head2 sub  set_message

  define the message family (type) to use
  also set the gather number (TODO: move option elsewhere)

=cut

sub set_message_type {

	my ( $self, $type ) = @_;

	if ( $type ne $empty_string ) {

		$iPick->{_message_type} = $type;
		$SuMessages->set( $iPick->{_message_type} );

		# print("iPick, type,$iPick->{_type} \n\n");

		#=head3
		#
		#    update gather number for messages
		#
		#=cut

		#		$SuMessages->gather_num($iPick->{_gather_num});
		#		$SuMessages->instructions($iPick->{_instructions});
		#		$SuMessages->gather_header($iPick->{_gather_header});
		#		$SuMessages->gather_type($iPick->{_gather_type});

	} else {
		print("iPick, type, unexpected type} \n\n");
	}
}

=head2 sub  set_data_type

	set what type of old data
	we are looking for
	velan,
	gather
	general Pick_xt
  
=cut

sub set_data_type {
	my ( $self, $type ) = @_;

	if ( $type && $type ne $empty_string ) {

		$iPick->{_type} = $type;

	} else {
		print("iPick,set_data_type,missing data type\n");
	}
	return ();
}

=head2  sub set_purpose 

  define where the data will need to go
  define the type of behavior
  
=cut

sub set_purpose {

	my ( $self, $type ) = @_;

	if ( defined $type
		&& $type ne $empty_string ) {

		$iPick->{_purpose} = $type;

		# print("iPick,set_purpose: $iPick->{_purpose}\n");

	} else {

		# print("iPick,set_purpose is unavailable, NADA\n");
	}
}

1;
