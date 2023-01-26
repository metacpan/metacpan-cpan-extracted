package App::SeismicUnixGui::misc::pod_declare;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PROGRAM NAME: data_in.pm 
 AUTHOR: 	Juan Lorenzo
 DATE: 		June 22 2017
  

 DESCRIPTION 
     

 BASED ON:
 Version 0.0.1 June 22 2017

 Version 0.0.2 July 22 2018


=cut

=head2 USE

=head3 NOTES

=head4 Examples


=head2 CHANGES and their DATES

  Version 0.02 July 22 2018
  added a \t 

=cut 

=head2 Notes from bash
 
=cut 

use Moose;
our $VERSION = '0.0.2';

=head2 Default pod lines for   

 pre-declaration of variables

=cut

my @pod;

$pod[0] = "\n\n" . '=head2 Declare' . "\n\n" .

  "\t" . 'local variables' . "\n\n" .

  '=cut' . "\n";

sub section {
    return ( \@pod );
}

1;
