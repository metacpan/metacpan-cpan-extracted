package App::SeismicUnixGui::sunix::statsMath::sumax;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PERL PROGRAM NAME:  SUMAX - get trace by trace local/global maxima, minima, or absolute maximum
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SUMAX - get trace by trace local/global maxima, minima, or absolute maximum

 sumax <stdin >stdout [optional parameters] 			

 Required parameters:						
	none								

 Optional parameters: 						
	output=ascii 		write ascii data to outpar		
				=binary for binary floats to stdout	
				=segy for SEGY traces to stdout		

	mode=maxmin		output both minima and maxima		
				=max maxima only			
				=min minima only			
				=abs absolute maxima only      		
				=rms RMS 		      		
				=thd search first max above threshold	

	threshamp=0		threshold amplitude value		
	threshtime=0		tmin to start search for threshold 	

	verbose=0 		writes global quantities to outpar	
				=1 trace number, values, sample location
				=2 key1 & key2 instead of trace number  
	key1=fldr		key for verbose=2                       
	key2=ep			key for verbose=2                       

	outpar=/dev/tty		output parameter file; contains output	
					from verbose			

 Examples: 								
 For global max and min values:  sumax < segy_data			
 For local and global max and min values:  sumax < segy_data verbose=1	
 To plot values specified by mode:					
    sumax < segy_data output=binary mode=modeval | xgraph n=npairs	
 To plot seismic data with the only values nonzero being those specified
 by mode=modeval:							
    sumax < segy_data output=segy mode=modeval | suxwigb		

 Note:	while traces are counted from 1, sample values are counted from 0.
	Also, if multiple min, max, or abs max values exist on a trace,	
       only the first one is captured.					

 See also: suxmax, supsmax						

 Credits:
	CWP : John Stockwell (total rewrite)
	Geocon : Garry Perratt (all ASCII output changed from 0.000000e+00 to 0.000000e+00)
	                       (added mode=rms).
      ESCI: Reginald Beardsley (added header key option)
	based on an original program by:
	SEP: Shuki Ronen
	CWP: Jack K. Cohen
      IFM-GEOMAR: Gerald Klein (added threshold option) 

 Trace header fields accessed: ns dt & user specified keys


=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';

use App::SeismicUnixGui::misc::L_SU_global_constants;
use App::SeismicUnixGui::misc::control '0.0.3';
my $get = App::SeismicUnixGui::misc::L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $sumax = {
    _key1       => '',
    _key2       => '',
    _mode       => '',
    _outpar     => '',
    _output     => '',
    _threshamp  => '',
    _threshtime => '',
    _verbose    => '',
    _Step       => '',
    _note       => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $sumax->{_Step} = 'sumax' . $sumax->{_Step};
    return ( $sumax->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $sumax->{_note} = 'sumax' . $sumax->{_note};
    return ( $sumax->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $sumax->{_key1}       = '';
    $sumax->{_key2}       = '';
    $sumax->{_mode}       = '';
    $sumax->{_outpar}     = '';
    $sumax->{_output}     = '';
    $sumax->{_threshamp}  = '';
    $sumax->{_threshtime} = '';
    $sumax->{_verbose}    = '';
    $sumax->{_Step}       = '';
    $sumax->{_note}       = '';
}

=head2 sub key1 


=cut

sub key1 {

    my ( $self, $key1 ) = @_;
    if ( $key1 ne $empty_string ) {

        $sumax->{_key1} = $key1;
        $sumax->{_note} = $sumax->{_note} . ' key1=' . $sumax->{_key1};
        $sumax->{_Step} = $sumax->{_Step} . ' key1=' . $sumax->{_key1};

    }
    else {
        print("sumax, key1, missing key1,\n");
    }
}

=head2 sub key2 


=cut

sub key2 {

    my ( $self, $key2 ) = @_;
    if ( $key2 ne $empty_string ) {

        $sumax->{_key2} = $key2;
        $sumax->{_note} = $sumax->{_note} . ' key2=' . $sumax->{_key2};
        $sumax->{_Step} = $sumax->{_Step} . ' key2=' . $sumax->{_key2};

    }
    else {
        print("sumax, key2, missing key2,\n");
    }
}

=head2 sub mode 


=cut

sub mode {

    my ( $self, $mode ) = @_;
    if ( $mode ne $empty_string ) {

        $sumax->{_mode} = $mode;
        $sumax->{_note} = $sumax->{_note} . ' mode=' . $sumax->{_mode};
        $sumax->{_Step} = $sumax->{_Step} . ' mode=' . $sumax->{_mode};

    }
    else {
        print("sumax, mode, missing mode,\n");
    }
}

=head2 sub outpar 


=cut

sub outpar {

    my ( $self, $outpar ) = @_;
    if ( defined $outpar
        && $outpar ne $empty_string )
    {

        use Scalar::Util qw(looks_like_number);

        my $control = App::SeismicUnixGui::misc::control->new();

        # we should have a string and not a number
        my $fmt = 0;
        $fmt = looks_like_number($outpar);

        if ($fmt) {

# print("sumax,outpar, outpar_value looks like a number BUT should be a string\n");

        }
        else {
            # print("sumax,outpar, looks like a string: $outpar\n");

            $control->set_back_slashBgone($outpar);
            $outpar = $control->get_back_slashBgone();

            # print("sumax,outpar without back_slashes looks like $outpar \n");
        }

        $sumax->{_outpar} = $outpar;

        # print("sumax,outpar, $outpar\n");

        if (   defined $sumax->{_output}
            && $sumax->{_output} ne $empty_string
            && $sumax->{_outpar} ne '/dev/tty' )
        {

            my $Project = Project_config->new();

            my $base_file_name = $outpar;
            my $output         = $sumax->{_output};

            if ( $output eq 'segy' ) {

                my $DATA_SEISMIC_SEGY = $Project->DATA_SEISMIC_SEGY();
                $sumax->{_outpar} = $DATA_SEISMIC_SEGY . '/' . $base_file_name;

            }
            elsif ( $output eq 'ascii' ) {

                my $DATA_SEISMIC_TXT = $Project->DATA_SEISMIC_TXT();
                $sumax->{_outpar} = $DATA_SEISMIC_TXT . '/' . $base_file_name;

            }
            elsif ( $output eq 'binary' ) {

                my $DATA_SEISMIC_BIN = $Project->DATA_SEISMIC_BIN();
                $sumax->{_outpar} = $DATA_SEISMIC_BIN . '/' . $base_file_name;

            }
            else {
                print("sumax,outpar, unexpected output parameter\n");
            }

        }
        else {
            # print("sumax,outpar,missing output or output is /dev/tty \n");
        }

        $sumax->{_note} = $sumax->{_note} . ' outpar=' . $sumax->{_outpar};
        $sumax->{_Step} = $sumax->{_Step} . ' outpar=' . $sumax->{_outpar};

    }
    else {
        print("sumax, outpar, missing outpar,\n");
    }
}

=head2 sub output 


=cut

sub output {

    my ( $self, $output ) = @_;
    if ( $output ne $empty_string ) {

        $sumax->{_output} = $output;
        $sumax->{_note}   = $sumax->{_note} . ' output=' . $sumax->{_output};
        $sumax->{_Step}   = $sumax->{_Step} . ' output=' . $sumax->{_output};

    }
    else {
        print("sumax, output, missing output,\n");
    }
}

=head2 sub threshamp 


=cut

sub threshamp {

    my ( $self, $threshamp ) = @_;
    if ( $threshamp ne $empty_string ) {

        $sumax->{_threshamp} = $threshamp;
        $sumax->{_note} =
          $sumax->{_note} . ' threshamp=' . $sumax->{_threshamp};
        $sumax->{_Step} =
          $sumax->{_Step} . ' threshamp=' . $sumax->{_threshamp};

    }
    else {
        print("sumax, threshamp, missing threshamp,\n");
    }
}

=head2 sub threshtime 


=cut

sub threshtime {

    my ( $self, $threshtime ) = @_;
    if ( $threshtime ne $empty_string ) {

        $sumax->{_threshtime} = $threshtime;
        $sumax->{_note} =
          $sumax->{_note} . ' threshtime=' . $sumax->{_threshtime};
        $sumax->{_Step} =
          $sumax->{_Step} . ' threshtime=' . $sumax->{_threshtime};

    }
    else {
        print("sumax, threshtime, missing threshtime,\n");
    }
}

=head2 sub verbose 


=cut

sub verbose {

    my ( $self, $verbose ) = @_;
    if ( $verbose ne $empty_string ) {

        $sumax->{_verbose} = $verbose;
        $sumax->{_note}    = $sumax->{_note} . ' verbose=' . $sumax->{_verbose};
        $sumax->{_Step}    = $sumax->{_Step} . ' verbose=' . $sumax->{_verbose};

    }
    else {
        print("sumax, verbose, missing verbose,\n");
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;
    my $max_index = 7;

    return ($max_index);
}

1;
