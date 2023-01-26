use Moose;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PROGRAM NAME: Segdread 
 AUTHOR: Juan Lorenzo
 DESCRIPTION: script to read segd files
 DATE Version 1 June 22, 2016

=cut 

=head2 Simple pseudo code
   
  Segdread

=cut

=head2 Import 

 perl classes container and system variables
 take variables and packages directly from
 the path to the library, so as to minimize memory use

=cut

=head2  Requires

  package from a local subdirectory (libAll) 
  to define input file names and their number
  For example, total number of files =74  first file is "1000.segd"

=cut

use lib './libAll';
use Segdread qw($number_of_files $first_file_number);
print("number of files is $number_of_files\n\n");

use SU;
my ($DATA_SEISMIC_SU)   = $Project->DATA_SEISMIC_SU();
my ($DATA_SEISMIC_SEGD) = $Project->DATA_SEISMIC_SEGD();
use App::SeismicUnixGui::misc::SeismicUnix
     qw($suffix_geom $suffix_segd $suffix_su $go $in $on $to $out);

=head2 Instantiate classes

  message,flow,segdread 

=cut

my $log      = message->new();
my $run      = flow->new();
my $segdread = segdread->new();

=head2 Declare variables

  Make them local 

=cut

my ( @file_in,          @segdfile_in );
my ( @segdread_inbound, @segdread_outbound );
my (@sufile_outbound);
my (@segdread);
my ( @flow, @items );
my ( $i, $j, $j_char, $nf, $ffn );


=head2 Protect global numeric values
      
       from change in this program 
       
=cut

$nf  = 1;
$ffn = 1;
if ($number_of_files)   { $nf  = $number_of_files }
if ($first_file_number) { $ffn = $first_file_number }

=head2 Establish

 file names and directories
 inbound and outbound refer to complete paths 
 
 Create file names in a loop

=cut


for ( $i = 1, $j = $ffn; $i <= $nf; $i += 1, $j += 1 ) {
    $j_char = sprintf( "0", $j );
    $file_in[$i] = $j_char;
}

=head2 Convert segd to su-formatted files


=cut

for ( $i = 1; $i <= $nf; $i++ ) {

    $segdfile_in[$i]      = $file_in[$i] . $suffix_segd;
    $segdread_inbound[$i] = $DATA_SEISMIC_SEGD . '/' . $segdfile_in[$i];
    $sufile_outbound[$i] = $DATA_SEISMIC_SU . '/' . $file_in[$i] . $suffix_su;
    $segdread_outbound[$i] = $sufile_outbound[$i];

=head2 Information about data files

 input files come from Sercel SN388 system

=cut


=head2 segdread settings


=cut

    $segdread->clear();
    $segdread->tape( $segdread_inbound[$i] );

# $segdread->$verbose(1);
    $segdread->ptmax(1);
    $segdread->aux(0);
    $segdread->use_stdio(1);
    $segdread[$i] = $segdread->Step();


=head2 DEFINE FLOW(S)
 

=cut

    @items = ( $segdread[$i], $out, $segdread_outbound[$i], $go );
    $flow[1] = $run->modules( \@items );

=head2 RUN FLOW(S)
 

=cut

    $run->flow( \$flow[1] );

=head2 LOG FLOW(S)


=cut

    print $flow[1] . "\n\n";

# $log->file($flow[1]);

}   # end of for loop


