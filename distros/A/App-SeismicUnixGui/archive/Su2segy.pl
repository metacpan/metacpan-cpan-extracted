=head1 DOCUMENTATION

=head2 SYNOPSIS To convert su data to segy data

 PROGRAM NAME: Su2segy
 AUTHOR:  Juan Lorenzo

=head2 CHANGES and their DATES

 DATE: Oct. 15, 2011   
 Version  1.0 

=head2 DESCRIPTION

   

=head2 USE

=head2 Examples

=head2 SEISMIC UNIX NOTES

=head2 STEPS


=head2 NOTES 
file names and locations are automatically found

=cut

use Moose;
our $VERSION = '0.0.1';

# define library of system subroutines
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';

# import system variables
use App::SeismicUnixGui::misc::SeismicUnix qw($suffix_sgy $suffix_su $suffix_usp);

# instantiation new local package
my $Project = Project_config->new();

# import system variables
my ($DATA_SEISMIC_SEGY) = $Project->DATA_SEISMIC_SEGY();
my ($DATA_SEISMIC_SU)   = $Project->DATA_SEISMIC_SU();

my $data_in;
$sufile_in[1] = $data_in;

$inbound_segyhdrs[1] = $DATA_SEISMIC_SU . '/' . $sufile_in[1] . $suffix_su;
$outbound_segywrite[1] =
     $DATA_SEISMIC_SEGY . '/' . $sufile_in[1] . $suffix_sgy;

# DEFINE SU MODULES
$segywrite[1] = (
    " segywrite			\\
			bfile=$DATA_SEISMIC_SU/binary	\\
			hfile=$DATA_SEISMIC_SU/header	\\
			"
);

# create segy binary and ascii header using seismic unix file
$segyhdrs[1] = (
    "  segyhdrs  		\\
			bfile=$DATA_SEISMIC_SU/binary	\\
			hfile=$DATA_SEISMIC_SU/header	\\
			"
);

# DEFINE FLOW(S)
$flow[1] = (
    " $segyhdrs[1] 		\\
			< $inbound_segyhdrs[1]  |	\\
			$segywrite[1]			\\		
			tape=$outbound_segywrite[1]	\\
		"
);

# RUN FLOW(S)
#system $flow[1];
system 'echo', $flow[1];
