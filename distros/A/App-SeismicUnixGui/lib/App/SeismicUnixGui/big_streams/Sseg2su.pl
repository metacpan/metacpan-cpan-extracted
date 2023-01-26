
=head1 DOCUMENTATION

=head2 SYNOPSIS


 PROGRAM NAME:  Sseg2su
 AUTHOR:  Juan Lorenzo

=head2 CHANGES and their DATES

 DATE:    Aug 9, 2011
 Version  1.1 July 29 2016
          Introduced pure textual configuration files

=head2 DESCRIPTION

 File format conversiuon
 Data format change from Seg2 ("DAT")
 or geometrics format to su

=head2 REQUIRES 

 sioseis  
 lcoal configuration file called Sseg2su_config

=head2 Examples

For example, total number of files =74  first file is "1000.su"

=head2 STEPS

 1.  use the local library of the user
 1.1 bring is user variables from a local file
 2.  create instances of the needed subroutines

=head2 NOTES 

 We are using Moose.
 Moose already declares that you need debuggers turned on
 so you don't need a line like the following:
 use warnings;
 

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use aliased 'App::SeismicUnixGui::misc::readfiles';
use aliased 'App::SeismicUnixGui::configs::big_streams::Sseg2su_config';

=head2 Instantiate classes:

 Create a new version of the package 
 with a unique name

=cut

my $read           = readfiles->new();
my $Project        = Project_config->new();
my $Sseg2su_config = Sseg2su_config->new();

=head2 Get directory definitions


=cut

my ($DATA_SEISMIC_SU)   = $Project->DATA_SEISMIC_SU();
my ($DATA_SEISMIC_SEG2) = $Project->DATA_SEISMIC_SEG2();

=head2 Get variable values from local configuration file

=cut

my ( $CFG_h, $CFG_aref ) = $Sseg2su_config->get_values();

my $number_of_files   = $CFG_h->{seg2su}{1}{number_of_files};
my $first_file_number = $CFG_h->{seg2su}{1}{first_file_number};

#print("values are $number_of_files, $first_file_number\n\n");

=head2  Convert *dat

file names to DAT file names for
conversion by sioseis

=cut

my ( $i,         $j,          $j_char );
my ( @file_name, @cp_dat2DAT, @segyclean );
my ( @sioseis,   @flow );

for (
	$i = 1, $j = $first_file_number ;
	$i <= $number_of_files ;
	$i += 1, $j += 1
  )
{
	$j_char = sprintf( "%u", $j );
	$file_name[$i] = $j_char;

	#	print $j_char . "\n";

}

for ( $i = 1 ; $i <= $number_of_files ; $i++ ) {

	$cp_dat2DAT[$i] = (
		" cp $DATA_SEISMIC_SEG2/$file_name[$i].dat \\
	$DATA_SEISMIC_SEG2/$file_name[$i].DAT
		"
	);

	#	print $cp_dat2DAT[$i] . "\n";

=pod INPUT FILE NAMES

convert seg2 files to su files

=cut

	$sioseis[$i] = ( "
cd $DATA_SEISMIC_SEG2;
echo 'moving to' `pwd`;
sioseis << eof
procs seg2in diskoa end
seg2in
    ffilen $file_name[$i] 	lfilen $file_name[$i]  end
end
diskoa
opath $DATA_SEISMIC_SU/$file_name[$i].su
ofmt 5
format su end
end
end
eof" );

=pod Clean 

su output

=cut

	$segyclean[$i] = (
		" segyclean					\\
			<$DATA_SEISMIC_SU/$file_name[$i].su			\\
			>$DATA_SEISMIC_SU/$file_name[$i]_clean.su	\\
		"
	);

}    # END FOR LOOP

=head2 DEFINE and Run

	FLOW(S)

=cut

for ( $i = 1 ; $i <= $number_of_files ; $i += 1 ) {

	$flow[1][$i] = $cp_dat2DAT[$i];
	$flow[2][$i] = $sioseis[$i];

	$flow[3][$i] = $segyclean[$i];
	
	system $flow[1][$i];
	system 'echo', $flow[1][$i];

	system $flow[2][$i];
	system 'echo', $flow[2][$i];

	system $flow[3][$i];
	system 'echo', $flow[3][$i];

}

