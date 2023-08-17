package App::SeismicUnixGui::sunix::header::surange;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PERL PROGRAM NAME:  SURANGE - get max and min values for non-zero header entries	
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SURANGE - get max and min values for non-zero header entries	

 surange <stdin	 					

 Optional parameters:						
	key=		Header key(s) to range (default=all)	

 Note: Gives partial results if interrupted			

 Output is: 							
 number of traces 						
 keyword min max (first - last) 				
 north-south-east-west limits of shot, receiver and midpoint   


 Credits:
      Stanford: Stewart A. Levin
              Added print of eastmost, northmost, westmost,
              southmost coordinates of shots, receivers, and 
              midpoints.  These coordinates have had any
              nonzero coscal header value applied.
	Geocon: Garry Perratt (output one header per line;
		option to specify headers to range;
		added first & last values where min<max)
	Based upon original by:
		SEP: Stew Levin
		CWP: Jack K. Cohen

 Note: the use of "signal" is inherited from BSD days and may
       break on some UNIXs.  It is dicey in that the responsibility
	 for program termination is lateraled back to the main.


=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';

my $surange = {
    _key  => '',
    _Step => '',
    _note => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $surange->{_Step} = 'surange' . $surange->{_Step};
    return ( $surange->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $surange->{_note} = 'surange' . $surange->{_note};
    return ( $surange->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $surange->{_key}  = '';
    $surange->{_Step} = '';
    $surange->{_note} = '';
}

=head2 sub key 


=cut

sub key {

    my ( $self, $key ) = @_;
    if ($key) {

        $surange->{_key}  = $key;
        $surange->{_note} = $surange->{_note} . ' key=' . $surange->{_key};
        $surange->{_Step} = $surange->{_Step} . ' key=' . $surange->{_key};

    }
    else {
        print("surange, key, missing key,\n");
    }
}

=head2 sub get_max_index
   max index = number of input variables - 1
 
=cut

sub get_max_index {
    my ($self) = @_;
    my $max_index = 0;

    return ($max_index);
}

1;
