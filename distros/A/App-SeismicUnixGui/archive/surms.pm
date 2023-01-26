package App::SeismicUnixGui::sunix::statsMath::surms;
use Moose;
our $VERSION = '0.0.1';

=pod 

 surms inherits from sumax

=cut

use aliased 'App::SeismicUnixGui::sunix::statsMath::sumax';

my $surms = sumax->new();

=pod

 import system variables

=cut

use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
my $Project = Project_config->new();
use App::SeismicUnixGui::misc::SeismicUnix qw($rms_amp $rms $ascii $to_outpar_file 
$suffix_hyphen $suffix_ascii $suffix_su);
my ($TEMP_DATA_SEISMIC_SU) = $Project->TEMP_DATA_SEISMIC_SU();

sub note {
    my ($note) = @_;

=pod

 default mode= 'rms';
 default key = 'rms_amp'
 default output is 'asc'
 default is to output to output file: verbose=0

=cut

    my $key     = $rms_amp;
    my $output  = $ascii;
    my $verbose = $to_outpar_file;

    $surms->mode($rms);
    $surms->verbose($verbose);
    $p = $surms->note();
    print ' note=' . $p . "\n\n";
    $a = 1;
    return $a;

    #return $surms->{_mode};
}

sub Step {
    my ($surms) = @_;
    my $key = $rms_amp;

=pod

 default outpar is ~.temp/

=cut

    my $outpar =
      $TEMP_DATA_SEISMIC_SU . '/' . $suffix_hyphen . $key . $suffix_ascii;
    $surms->{_outpar} = $outpar;
    $surms->{_Step}   = ' outpar=' . $surms->{_outpar};

    my $mode = $rms;
    $surms->{_mode} = $mode;
    $surms->{_Step} = $surms->{_Step} . ' mode=' . $surms->{_mode};

    $surms->{_key}  = $key;
    $surms->{_Step} = $surms->{_Step} . ' key=' . $surms->{_key};

    my $output = $ascii;
    $surms->{_output} = $output;
    $surms->{_Step}   = $surms->{_Step} . ' output=' . $surms->{_output};

    my $verbose = $to_outpar_file;
    $surms->{_verbose} = $verbose;
    $surms->{_Step}    = $surms->{_Step} . ' verbose=' . $surms->{_verbose};

    $surms->{_Step} = 'sumax ' . $surms->{_Step};

    return $surms->{_Step};

}

=pod

 Juan's option
 is to put an option for the number of panels
 that will be evaluated

=cut

sub panel_max {
    my ( $surms, $panel_max ) = @_;
    $surms->{_panel_max} = $panel_max if defined($panel_max);
}

=head2 sub get_max_index

max index = number of input variables -1

=cut

sub get_max_index {
    my ($self) = @_;

    # only file_name : index=6
    my $max_index = 6;

    return ($max_index);
}

1;
