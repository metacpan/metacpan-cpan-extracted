package App::SeismicUnixGui::sunix::par::makevel;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PACKAGE NAME:  MAKEVEL - MAKE a VELocity function v(x,y,z)				
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 MAKEVEL - MAKE a VELocity function v(x,y,z)				

 makevel > outfile nx= nz= [optional parameters]			

 Required Parameters:							
 nx=                    number of x samples (3rd dimension)		
 nz=                    number of z samples (1st dimension)		

 Optional Parameters:							
 ny=1                   number of y samples (2nd dimension)		
 dx=1.0                 x sampling interval				
 fx=0.0                 first x sample					
 dy=1.0                 y sampling interval				
 fy=0.0                 first y sample					
 dz=1.0                 z sampling interval				
 fz=0.0                 first z sample					
 v000=2.0               velocity at (x=0,y=0,z=0)			
 dvdx=0.0               velocity gradient with respect to x		
 dvdy=0.0               velocity gradient with respect to y		
 dvdz=0.0               velocity gradient with respect to z		
 vlens=0.0              velocity perturbation in parabolic lens	
 tlens=0.0              thickness of parabolic lens			
 dlens=0.0              diameter of parabolic lens			
 xlens=                 x coordinate of center of parabolic lens	
 ylens=                 y coordinate of center of parabolic lens	
 zlens=                 z coordinate of center of parabolic lens	
 vran=0.0		standard deviation of random perturbation	
 vzfile=                file containing v(z) profile			
 vzran=0.0              standard deviation of random perturbation to v(z)
 vzc=0.0                v(z) chirp amplitude				
 z1c=fz                 z at which to begin chirp			
 z2c=fz+(nz-1)*dz       z at which to end chirp			
 l1c=dz                 wavelength at beginning of chirp		
 l2c=dz                 wavelength at end of chirp			
 exc=1.0                exponent of chirp
 				
=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $makevel = {
    _dlens  => '',
    _dvdx   => '',
    _dvdy   => '',
    _dvdz   => '',
    _dx     => '',
    _dy     => '',
    _dz     => '',
    _exc    => '',
    _fx     => '',
    _fy     => '',
    _fz     => '',
    _l1c    => '',
    _l2c    => '',
    _nx     => '',
    _ny     => '',
    _nz     => '',
    _tlens  => '',
    _v000   => '',
    _vlens  => '',
    _vran   => '',
    _vzc    => '',
    _vzfile => '',
    _vzran  => '',
    _xlens  => '',
    _ylens  => '',
    _z1c    => '',
    _z2c    => '',
    _zlens  => '',
    _Step   => '',
    _note   => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $makevel->{_Step} = 'makevel' . $makevel->{_Step};
    return ( $makevel->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $makevel->{_note} = 'makevel' . $makevel->{_note};
    return ( $makevel->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $makevel->{_dlens}  = '';
    $makevel->{_dvdx}   = '';
    $makevel->{_dvdy}   = '';
    $makevel->{_dvdz}   = '';
    $makevel->{_dx}     = '';
    $makevel->{_dy}     = '';
    $makevel->{_dz}     = '';
    $makevel->{_exc}    = '';
    $makevel->{_fx}     = '';
    $makevel->{_fy}     = '';
    $makevel->{_fz}     = '';
    $makevel->{_l1c}    = '';
    $makevel->{_l2c}    = '';
    $makevel->{_nx}     = '';
    $makevel->{_ny}     = '';
    $makevel->{_nz}     = '';
    $makevel->{_tlens}  = '';
    $makevel->{_v000}   = '';
    $makevel->{_vlens}  = '';
    $makevel->{_vran}   = '';
    $makevel->{_vzc}    = '';
    $makevel->{_vzfile} = '';
    $makevel->{_vzran}  = '';
    $makevel->{_xlens}  = '';
    $makevel->{_ylens}  = '';
    $makevel->{_z1c}    = '';
    $makevel->{_z2c}    = '';
    $makevel->{_zlens}  = '';
    $makevel->{_Step}   = '';
    $makevel->{_note}   = '';
}

=head2 sub dlens 


=cut

sub dlens {

    my ( $self, $dlens ) = @_;
    if ( $dlens ne $empty_string ) {

        $makevel->{_dlens} = $dlens;
        $makevel->{_note} =
          $makevel->{_note} . ' dlens=' . $makevel->{_dlens};
        $makevel->{_Step} =
          $makevel->{_Step} . ' dlens=' . $makevel->{_dlens};

    }
    else {
        print("makevel, dlens, missing dlens,\n");
    }
}

=head2 sub dvdx 


=cut

sub dvdx {

    my ( $self, $dvdx ) = @_;
    if ( $dvdx ne $empty_string ) {

        $makevel->{_dvdx} = $dvdx;
        $makevel->{_note} = $makevel->{_note} . ' dvdx=' . $makevel->{_dvdx};
        $makevel->{_Step} = $makevel->{_Step} . ' dvdx=' . $makevel->{_dvdx};

    }
    else {
        print("makevel, dvdx, missing dvdx,\n");
    }
}

=head2 sub dvdy 


=cut

sub dvdy {

    my ( $self, $dvdy ) = @_;
    if ( $dvdy ne $empty_string ) {

        $makevel->{_dvdy} = $dvdy;
        $makevel->{_note} = $makevel->{_note} . ' dvdy=' . $makevel->{_dvdy};
        $makevel->{_Step} = $makevel->{_Step} . ' dvdy=' . $makevel->{_dvdy};

    }
    else {
        print("makevel, dvdy, missing dvdy,\n");
    }
}

=head2 sub dvdz 


=cut

sub dvdz {

    my ( $self, $dvdz ) = @_;
    if ( $dvdz ne $empty_string ) {

        $makevel->{_dvdz} = $dvdz;
        $makevel->{_note} = $makevel->{_note} . ' dvdz=' . $makevel->{_dvdz};
        $makevel->{_Step} = $makevel->{_Step} . ' dvdz=' . $makevel->{_dvdz};

    }
    else {
        print("makevel, dvdz, missing dvdz,\n");
    }
}

=head2 sub dx 


=cut

sub dx {

    my ( $self, $dx ) = @_;
    if ( $dx ne $empty_string ) {

        $makevel->{_dx}   = $dx;
        $makevel->{_note} = $makevel->{_note} . ' dx=' . $makevel->{_dx};
        $makevel->{_Step} = $makevel->{_Step} . ' dx=' . $makevel->{_dx};

    }
    else {
        print("makevel, dx, missing dx,\n");
    }
}

=head2 sub dy 


=cut

sub dy {

    my ( $self, $dy ) = @_;
    if ( $dy ne $empty_string ) {

        $makevel->{_dy}   = $dy;
        $makevel->{_note} = $makevel->{_note} . ' dy=' . $makevel->{_dy};
        $makevel->{_Step} = $makevel->{_Step} . ' dy=' . $makevel->{_dy};

    }
    else {
        print("makevel, dy, missing dy,\n");
    }
}

=head2 sub dz 


=cut

sub dz {

    my ( $self, $dz ) = @_;
    if ( $dz ne $empty_string ) {

        $makevel->{_dz}   = $dz;
        $makevel->{_note} = $makevel->{_note} . ' dz=' . $makevel->{_dz};
        $makevel->{_Step} = $makevel->{_Step} . ' dz=' . $makevel->{_dz};

    }
    else {
        print("makevel, dz, missing dz,\n");
    }
}

=head2 sub exc 


=cut

sub exc {

    my ( $self, $exc ) = @_;
    if ( $exc ne $empty_string ) {

        $makevel->{_exc}  = $exc;
        $makevel->{_note} = $makevel->{_note} . ' exc=' . $makevel->{_exc};
        $makevel->{_Step} = $makevel->{_Step} . ' exc=' . $makevel->{_exc};

    }
    else {
        print("makevel, exc, missing exc,\n");
    }
}

=head2 sub fx 


=cut

sub fx {

    my ( $self, $fx ) = @_;
    if ( $fx ne $empty_string ) {

        $makevel->{_fx}   = $fx;
        $makevel->{_note} = $makevel->{_note} . ' fx=' . $makevel->{_fx};
        $makevel->{_Step} = $makevel->{_Step} . ' fx=' . $makevel->{_fx};

    }
    else {
        print("makevel, fx, missing fx,\n");
    }
}

=head2 sub fy 


=cut

sub fy {

    my ( $self, $fy ) = @_;
    if ( $fy ne $empty_string ) {

        $makevel->{_fy}   = $fy;
        $makevel->{_note} = $makevel->{_note} . ' fy=' . $makevel->{_fy};
        $makevel->{_Step} = $makevel->{_Step} . ' fy=' . $makevel->{_fy};

    }
    else {
        print("makevel, fy, missing fy,\n");
    }
}

=head2 sub fz 


=cut

sub fz {

    my ( $self, $fz ) = @_;
    if ( $fz ne $empty_string ) {

        $makevel->{_fz}   = $fz;
        $makevel->{_note} = $makevel->{_note} . ' fz=' . $makevel->{_fz};
        $makevel->{_Step} = $makevel->{_Step} . ' fz=' . $makevel->{_fz};

    }
    else {
        print("makevel, fz, missing fz,\n");
    }
}

=head2 sub l1c 


=cut

sub l1c {

    my ( $self, $l1c ) = @_;
    if ( $l1c ne $empty_string ) {

        $makevel->{_l1c}  = $l1c;
        $makevel->{_note} = $makevel->{_note} . ' l1c=' . $makevel->{_l1c};
        $makevel->{_Step} = $makevel->{_Step} . ' l1c=' . $makevel->{_l1c};

    }
    else {
        print("makevel, l1c, missing l1c,\n");
    }
}

=head2 sub l2c 


=cut

sub l2c {

    my ( $self, $l2c ) = @_;
    if ( $l2c ne $empty_string ) {

        $makevel->{_l2c}  = $l2c;
        $makevel->{_note} = $makevel->{_note} . ' l2c=' . $makevel->{_l2c};
        $makevel->{_Step} = $makevel->{_Step} . ' l2c=' . $makevel->{_l2c};

    }
    else {
        print("makevel, l2c, missing l2c,\n");
    }
}

=head2 sub nx 


=cut

sub nx {

    my ( $self, $nx ) = @_;
    if ( $nx ne $empty_string ) {

        $makevel->{_nx}   = $nx;
        $makevel->{_note} = $makevel->{_note} . ' nx=' . $makevel->{_nx};
        $makevel->{_Step} = $makevel->{_Step} . ' nx=' . $makevel->{_nx};

    }
    else {
        print("makevel, nx, missing nx,\n");
    }
}

=head2 sub ny 


=cut

sub ny {

    my ( $self, $ny ) = @_;
    if ( $ny ne $empty_string ) {

        $makevel->{_ny}   = $ny;
        $makevel->{_note} = $makevel->{_note} . ' ny=' . $makevel->{_ny};
        $makevel->{_Step} = $makevel->{_Step} . ' ny=' . $makevel->{_ny};

    }
    else {
        print("makevel, ny, missing ny,\n");
    }
}

=head2 sub nz 


=cut

sub nz {

    my ( $self, $nz ) = @_;
    if ( $nz ne $empty_string ) {

        $makevel->{_nz}   = $nz;
        $makevel->{_note} = $makevel->{_note} . ' nz=' . $makevel->{_nz};
        $makevel->{_Step} = $makevel->{_Step} . ' nz=' . $makevel->{_nz};

    }
    else {
        print("makevel, nz, missing nz,\n");
    }
}

=head2 sub tlens 


=cut

sub tlens {

    my ( $self, $tlens ) = @_;
    if ( $tlens ne $empty_string ) {

        $makevel->{_tlens} = $tlens;
        $makevel->{_note} =
          $makevel->{_note} . ' tlens=' . $makevel->{_tlens};
        $makevel->{_Step} =
          $makevel->{_Step} . ' tlens=' . $makevel->{_tlens};

    }
    else {
        print("makevel, tlens, missing tlens,\n");
    }
}

=head2 sub v000 


=cut

sub v000 {

    my ( $self, $v000 ) = @_;
    if ( $v000 ne $empty_string ) {

        $makevel->{_v000} = $v000;
        $makevel->{_note} = $makevel->{_note} . ' v000=' . $makevel->{_v000};
        $makevel->{_Step} = $makevel->{_Step} . ' v000=' . $makevel->{_v000};

    }
    else {
        print("makevel, v000, missing v000,\n");
    }
}

=head2 sub vlens 


=cut

sub vlens {

    my ( $self, $vlens ) = @_;
    if ( $vlens ne $empty_string ) {

        $makevel->{_vlens} = $vlens;
        $makevel->{_note} =
          $makevel->{_note} . ' vlens=' . $makevel->{_vlens};
        $makevel->{_Step} =
          $makevel->{_Step} . ' vlens=' . $makevel->{_vlens};

    }
    else {
        print("makevel, vlens, missing vlens,\n");
    }
}

=head2 sub vran 


=cut

sub vran {

    my ( $self, $vran ) = @_;
    if ( $vran ne $empty_string ) {

        $makevel->{_vran} = $vran;
        $makevel->{_note} = $makevel->{_note} . ' vran=' . $makevel->{_vran};
        $makevel->{_Step} = $makevel->{_Step} . ' vran=' . $makevel->{_vran};

    }
    else {
        print("makevel, vran, missing vran,\n");
    }
}

=head2 sub vzc 


=cut

sub vzc {

    my ( $self, $vzc ) = @_;
    if ( $vzc ne $empty_string ) {

        $makevel->{_vzc}  = $vzc;
        $makevel->{_note} = $makevel->{_note} . ' vzc=' . $makevel->{_vzc};
        $makevel->{_Step} = $makevel->{_Step} . ' vzc=' . $makevel->{_vzc};

    }
    else {
        print("makevel, vzc, missing vzc,\n");
    }
}

=head2 sub vzfile 


=cut

sub vzfile {

    my ( $self, $vzfile ) = @_;
    if ( $vzfile ne $empty_string ) {

        $makevel->{_vzfile} = $vzfile;
        $makevel->{_note} =
          $makevel->{_note} . ' vzfile=' . $makevel->{_vzfile};
        $makevel->{_Step} =
          $makevel->{_Step} . ' vzfile=' . $makevel->{_vzfile};

    }
    else {
        print("makevel, vzfile, missing vzfile,\n");
    }
}

=head2 sub vzran 


=cut

sub vzran {

    my ( $self, $vzran ) = @_;
    if ( $vzran ne $empty_string ) {

        $makevel->{_vzran} = $vzran;
        $makevel->{_note} =
          $makevel->{_note} . ' vzran=' . $makevel->{_vzran};
        $makevel->{_Step} =
          $makevel->{_Step} . ' vzran=' . $makevel->{_vzran};

    }
    else {
        print("makevel, vzran, missing vzran,\n");
    }
}

=head2 sub xlens 


=cut

sub xlens {

    my ( $self, $xlens ) = @_;
    if ( $xlens ne $empty_string ) {

        $makevel->{_xlens} = $xlens;
        $makevel->{_note} =
          $makevel->{_note} . ' xlens=' . $makevel->{_xlens};
        $makevel->{_Step} =
          $makevel->{_Step} . ' xlens=' . $makevel->{_xlens};

    }
    else {
        print("makevel, xlens, missing xlens,\n");
    }
}

=head2 sub ylens 


=cut

sub ylens {

    my ( $self, $ylens ) = @_;
    if ( $ylens ne $empty_string ) {

        $makevel->{_ylens} = $ylens;
        $makevel->{_note} =
          $makevel->{_note} . ' ylens=' . $makevel->{_ylens};
        $makevel->{_Step} =
          $makevel->{_Step} . ' ylens=' . $makevel->{_ylens};

    }
    else {
        print("makevel, ylens, missing ylens,\n");
    }
}

=head2 sub z1c 


=cut

sub z1c {

    my ( $self, $z1c ) = @_;
    if ( $z1c ne $empty_string ) {

        $makevel->{_z1c}  = $z1c;
        $makevel->{_note} = $makevel->{_note} . ' z1c=' . $makevel->{_z1c};
        $makevel->{_Step} = $makevel->{_Step} . ' z1c=' . $makevel->{_z1c};

    }
    else {
        print("makevel, z1c, missing z1c,\n");
    }
}

=head2 sub z2c 


=cut

sub z2c {

    my ( $self, $z2c ) = @_;
    if ( $z2c ne $empty_string ) {

        $makevel->{_z2c}  = $z2c;
        $makevel->{_note} = $makevel->{_note} . ' z2c=' . $makevel->{_z2c};
        $makevel->{_Step} = $makevel->{_Step} . ' z2c=' . $makevel->{_z2c};

    }
    else {
        print("makevel, z2c, missing z2c,\n");
    }
}

=head2 sub zlens 


=cut

sub zlens {

    my ( $self, $zlens ) = @_;
    if ( $zlens ne $empty_string ) {

        $makevel->{_zlens} = $zlens;
        $makevel->{_note} =
          $makevel->{_note} . ' zlens=' . $makevel->{_zlens};
        $makevel->{_Step} =
          $makevel->{_Step} . ' zlens=' . $makevel->{_zlens};

    }
    else {
        print("makevel, zlens, missing zlens,\n");
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;
    my $max_index = 27;

    return ($max_index);
}

1;
