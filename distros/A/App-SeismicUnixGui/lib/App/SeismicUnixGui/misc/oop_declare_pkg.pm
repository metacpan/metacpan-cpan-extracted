package App::SeismicUnixGui::misc::oop_declare_pkg;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PROGRAM NAME: data_in.pm 
 AUTHOR: 	Juan Lorenzo
 DATE: 		June 22 2017
  

 DESCRIPTION 
     

 BASED ON:
 Version 0.0.1 June 22 2017


=cut

=head2 USE

=head3 NOTES

=head4 Examples


=head2 CHANGES and their DATES


=cut 

=head2 Notes from bash
 
=cut 

use Moose;
our $VERSION = '0.0.1';

=head2 Default perl lines for

     declaring required packages

=cut

my @oop_declare_pkg;

$oop_declare_pkg[0] = "\t" . 'my (@flow);' . "\n\t" . 'my (@items);';

sub section {
    my ($self) = @_;

    return ( \@oop_declare_pkg );

}

1;
