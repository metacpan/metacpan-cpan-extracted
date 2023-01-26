package App::SeismicUnixGui::sunix::model::suplane;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PACKAGE NAME: SUPLANE - create common offset data file with up to 3 planes	
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES
  SUPLANE - create common offset data file suplane
with up to 3 planes	


suplane [optional parameters] >stdout	 			


Optional Parameters:
					
 npl=3			number of planes
 			
 nt=64 		number of time samples
 		
 ntr=32		number of traces	
 	
 taper=0		no end-of-plane taper			
			= 1 taper planes to zero at the end	
			
 offset=400 		offset	
 				
 dt=0.004	 	time sample interval in seconds	
 	
...plane 1 ...							

	dip1=0		dip of plane #1 (ms/trace)	
		
 	len1= 3*ntr/4	HORIZONTAL extent of plane (traces)	
 	
	ct1= nt/2	time sample for center pivot	 	
	
	cx1= ntr/2	trace for center pivot			
	
...plane 2 ...							

	dip2=4		dip of plane #2 (ms/trace)	
		
	len2= 3*ntr/4	HORIZONTAL extent of plane (traces)

	ct2= nt/2	time sample for center pivot 	
		
	cx2= ntr/2	trace for center pivot		
		
...plane 3 ...							

	dip3=8		dip of plane #3 (ms/trace)		
	
	len3= 3*ntr/4	HORIZONTAL extent of plane (traces)	
	
	ct3= nt/2	time sample for center pivot		
	
	cx3= ntr/2	trace for center pivot			

 liner=0	use parameters					
 
			= 1 parameters set for 64x64 data set   
			
			with separated dipping planes.		

 Credits:
	CWP: Chris Liner

 Trace header fields set: ns, dt, offset, tracl

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $suplane = {
    _ct1    => '',
    _ct2    => '',
    _ct3    => '',
    _cx1    => '',
    _cx2    => '',
    _cx3    => '',
    _dip1   => '',
    _dip2   => '',
    _dip3   => '',
    _dt     => '',
    _len1   => '',
    _len2   => '',
    _len3   => '',
    _liner  => '',
    _npl    => '',
    _nt     => '',
    _ntr    => '',
    _offset => '',
    _taper  => '',
    _Step   => '',
    _note   => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $suplane->{_Step} = 'suplane' . $suplane->{_Step};
    return ( $suplane->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $suplane->{_note} = 'suplane' . $suplane->{_note};
    return ( $suplane->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $suplane->{_ct1}    = '';
    $suplane->{_ct2}    = '';
    $suplane->{_ct3}    = '';
    $suplane->{_cx1}    = '';
    $suplane->{_cx2}    = '';
    $suplane->{_cx3}    = '';
    $suplane->{_dip1}   = '';
    $suplane->{_dip2}   = '';
    $suplane->{_dip3}   = '';
    $suplane->{_dt}     = '';
    $suplane->{_len1}   = '';
    $suplane->{_len2}   = '';
    $suplane->{_len3}   = '';
    $suplane->{_liner}  = '';
    $suplane->{_npl}    = '';
    $suplane->{_nt}     = '';
    $suplane->{_ntr}    = '';
    $suplane->{_offset} = '';
    $suplane->{_taper}  = '';
    $suplane->{_Step}   = '';
    $suplane->{_note}   = '';
}

=head2 sub ct1 


=cut

sub ct1 {

    my ( $self, $ct1 ) = @_;
    if ( $ct1 ne $empty_string ) {

        $suplane->{_ct1}  = $ct1;
        $suplane->{_note} = $suplane->{_note} . ' ct1=' . $suplane->{_ct1};
        $suplane->{_Step} = $suplane->{_Step} . ' ct1=' . $suplane->{_ct1};

    }
    else {
        print("suplane, ct1, missing ct1,\n");
    }
}

=head2 sub ct2 


=cut

sub ct2 {

    my ( $self, $ct2 ) = @_;
    if ( $ct2 ne $empty_string ) {

        $suplane->{_ct2}  = $ct2;
        $suplane->{_note} = $suplane->{_note} . ' ct2=' . $suplane->{_ct2};
        $suplane->{_Step} = $suplane->{_Step} . ' ct2=' . $suplane->{_ct2};

    }
    else {
        print("suplane, ct2, missing ct2,\n");
    }
}

=head2 sub ct3 


=cut

sub ct3 {

    my ( $self, $ct3 ) = @_;
    if ( $ct3 ne $empty_string ) {

        $suplane->{_ct3}  = $ct3;
        $suplane->{_note} = $suplane->{_note} . ' ct3=' . $suplane->{_ct3};
        $suplane->{_Step} = $suplane->{_Step} . ' ct3=' . $suplane->{_ct3};

    }
    else {
        print("suplane, ct3, missing ct3,\n");
    }
}

=head2 sub cx1 


=cut

sub cx1 {

    my ( $self, $cx1 ) = @_;
    if ( $cx1 ne $empty_string ) {

        $suplane->{_cx1}  = $cx1;
        $suplane->{_note} = $suplane->{_note} . ' cx1=' . $suplane->{_cx1};
        $suplane->{_Step} = $suplane->{_Step} . ' cx1=' . $suplane->{_cx1};

    }
    else {
        print("suplane, cx1, missing cx1,\n");
    }
}

=head2 sub cx2 


=cut

sub cx2 {

    my ( $self, $cx2 ) = @_;
    if ( $cx2 ne $empty_string ) {

        $suplane->{_cx2}  = $cx2;
        $suplane->{_note} = $suplane->{_note} . ' cx2=' . $suplane->{_cx2};
        $suplane->{_Step} = $suplane->{_Step} . ' cx2=' . $suplane->{_cx2};

    }
    else {
        print("suplane, cx2, missing cx2,\n");
    }
}

=head2 sub cx3 


=cut

sub cx3 {

    my ( $self, $cx3 ) = @_;
    if ( $cx3 ne $empty_string ) {

        $suplane->{_cx3}  = $cx3;
        $suplane->{_note} = $suplane->{_note} . ' cx3=' . $suplane->{_cx3};
        $suplane->{_Step} = $suplane->{_Step} . ' cx3=' . $suplane->{_cx3};

    }
    else {
        print("suplane, cx3, missing cx3,\n");
    }
}

=head2 sub dip1 


=cut

sub dip1 {

    my ( $self, $dip1 ) = @_;
    if ( $dip1 ne $empty_string ) {

        $suplane->{_dip1} = $dip1;
        $suplane->{_note} = $suplane->{_note} . ' dip1=' . $suplane->{_dip1};
        $suplane->{_Step} = $suplane->{_Step} . ' dip1=' . $suplane->{_dip1};

    }
    else {
        print("suplane, dip1, missing dip1,\n");
    }
}

=head2 sub dip2 


=cut

sub dip2 {

    my ( $self, $dip2 ) = @_;
    if ( $dip2 ne $empty_string ) {

        $suplane->{_dip2} = $dip2;
        $suplane->{_note} = $suplane->{_note} . ' dip2=' . $suplane->{_dip2};
        $suplane->{_Step} = $suplane->{_Step} . ' dip2=' . $suplane->{_dip2};

    }
    else {
        print("suplane, dip2, missing dip2,\n");
    }
}

=head2 sub dip3 


=cut

sub dip3 {

    my ( $self, $dip3 ) = @_;
    if ( $dip3 ne $empty_string ) {

        $suplane->{_dip3} = $dip3;
        $suplane->{_note} = $suplane->{_note} . ' dip3=' . $suplane->{_dip3};
        $suplane->{_Step} = $suplane->{_Step} . ' dip3=' . $suplane->{_dip3};

    }
    else {
        print("suplane, dip3, missing dip3,\n");
    }
}

=head2 sub dt 


=cut

sub dt {

    my ( $self, $dt ) = @_;
    if ( $dt ne $empty_string ) {

        $suplane->{_dt}   = $dt;
        $suplane->{_note} = $suplane->{_note} . ' dt=' . $suplane->{_dt};
        $suplane->{_Step} = $suplane->{_Step} . ' dt=' . $suplane->{_dt};

    }
    else {
        print("suplane, dt, missing dt,\n");
    }
}

=head2 sub len1 


=cut

sub len1 {

    my ( $self, $len1 ) = @_;
    if ( $len1 ne $empty_string ) {

        $suplane->{_len1} = $len1;
        $suplane->{_note} = $suplane->{_note} . ' len1=' . $suplane->{_len1};
        $suplane->{_Step} = $suplane->{_Step} . ' len1=' . $suplane->{_len1};

    }
    else {
        print("suplane, len1, missing len1,\n");
    }
}

=head2 sub len2 


=cut

sub len2 {

    my ( $self, $len2 ) = @_;
    if ( $len2 ne $empty_string ) {

        $suplane->{_len2} = $len2;
        $suplane->{_note} = $suplane->{_note} . ' len2=' . $suplane->{_len2};
        $suplane->{_Step} = $suplane->{_Step} . ' len2=' . $suplane->{_len2};

    }
    else {
        print("suplane, len2, missing len2,\n");
    }
}

=head2 sub len3 


=cut

sub len3 {

    my ( $self, $len3 ) = @_;
    if ( $len3 ne $empty_string ) {

        $suplane->{_len3} = $len3;
        $suplane->{_note} = $suplane->{_note} . ' len3=' . $suplane->{_len3};
        $suplane->{_Step} = $suplane->{_Step} . ' len3=' . $suplane->{_len3};

    }
    else {
        print("suplane, len3, missing len3,\n");
    }
}

=head2 sub liner 


=cut

sub liner {

    my ( $self, $liner ) = @_;
    if ( $liner ne $empty_string ) {

        $suplane->{_liner} = $liner;
        $suplane->{_note} =
          $suplane->{_note} . ' liner=' . $suplane->{_liner};
        $suplane->{_Step} =
          $suplane->{_Step} . ' liner=' . $suplane->{_liner};

    }
    else {
        print("suplane, liner, missing liner,\n");
    }
}

=head2 sub npl 


=cut

sub npl {

    my ( $self, $npl ) = @_;
    if ( $npl ne $empty_string ) {

        $suplane->{_npl}  = $npl;
        $suplane->{_note} = $suplane->{_note} . ' npl=' . $suplane->{_npl};
        $suplane->{_Step} = $suplane->{_Step} . ' npl=' . $suplane->{_npl};

    }
    else {
        print("suplane, npl, missing npl,\n");
    }
}

=head2 sub nt 


=cut

sub nt {

    my ( $self, $nt ) = @_;
    if ( $nt ne $empty_string ) {

        $suplane->{_nt}   = $nt;
        $suplane->{_note} = $suplane->{_note} . ' nt=' . $suplane->{_nt};
        $suplane->{_Step} = $suplane->{_Step} . ' nt=' . $suplane->{_nt};

    }
    else {
        print("suplane, nt, missing nt,\n");
    }
}

=head2 sub ntr 


=cut

sub ntr {

    my ( $self, $ntr ) = @_;
    if ( $ntr ne $empty_string ) {

        $suplane->{_ntr}  = $ntr;
        $suplane->{_note} = $suplane->{_note} . ' ntr=' . $suplane->{_ntr};
        $suplane->{_Step} = $suplane->{_Step} . ' ntr=' . $suplane->{_ntr};

    }
    else {
        print("suplane, ntr, missing ntr,\n");
    }
}

=head2 sub offset 


=cut

sub offset {

    my ( $self, $offset ) = @_;
    if ( $offset ne $empty_string ) {

        $suplane->{_offset} = $offset;
        $suplane->{_note} =
          $suplane->{_note} . ' offset=' . $suplane->{_offset};
        $suplane->{_Step} =
          $suplane->{_Step} . ' offset=' . $suplane->{_offset};

    }
    else {
        print("suplane, offset, missing offset,\n");
    }
}

=head2 sub taper 


=cut

sub taper {

    my ( $self, $taper ) = @_;
    if ( $taper ne $empty_string ) {

        $suplane->{_taper} = $taper;
        $suplane->{_note} =
          $suplane->{_note} . ' taper=' . $suplane->{_taper};
        $suplane->{_Step} =
          $suplane->{_Step} . ' taper=' . $suplane->{_taper};

    }
    else {
        print("suplane, taper, missing taper,\n");
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;
    my $max_index = 18;

    return ($max_index);
}

1;
