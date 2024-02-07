package App::SeismicUnixGui::sunix::shapeNcut::suresamp;
use Moose;
our $VERSION = '0.0.1';

=pod

=head1 NOTES from SEISMIC UNIX MAN PAGES

SURESAMP - Resample in time                                       
                                                                   
 suresamp <stdin >stdout  [optional parameters]                    
                                                                   
 Required parameters:                                              
     none                                                          
                                                                   
 Optional Parameters:                                              
    nt=tr.ns    number of time samples on output                   
    dt=         time sampling interval on output                   
                default is:                                        
                tr.dt/10^6     seismic data                        
                tr.d1          non-seismic data                    
    tmin=       time of first sample in output                     
                default is:                                        
                tr.delrt/10^3  seismic data  `                      
                tr.f1          non-seismic data                    
    rf=         resampling factor;                                 
                if defined, set nt=nt_in*rf and dt=dt_in/rf        
    verbose=0   =1 for advisory messages                           
                                                                   
                                                                   
 Example 1: (assume original data had dt=.004 nt=256)              
    sufilter <data f=40,50 amps=1.,0. |                            
    suresamp nt=128 dt=.008 | ...                                  
 Using the resampling factor rf, this example translates to:       
    sufilter <data f=40,50 amps=1.,0. | suresamp rf=0.5 | ...      
                                                                   
 Note the typical anti-alias filtering before sub-sampling!        
                                                                   
 Example 2: (assume original data had dt=.004 nt=256)              
    suresamp <data nt=512 dt=.002 | ...                            
 or use:                                                           
    suresamp <data rf=2 | ...

                                                                  
 Example 3: (assume original data had d1=.1524 nt=8192)            
    sufilter <data f=0,1,3,3.28 amps=1,1,1,0 |                     
    suresamp <data nt=4096 dt=.3048 | ...                          
                                                                   
 Example 4: (assume original data had d1=.5 nt=4096)               
    suresamp <data nt=8192 dt=.25 | ...                            
                
=cut

=pod

=head2

   1. Use packages:

     (for variable definitions)
     SeismicUnix (Seismic Unix modules)

=cut

=head2  Create

  hash of important variables
  and sub clear to clean them
  from memory

=cut

use App::SeismicUnixGui::misc::SeismicUnix qw($on);

my $suresamp = {
    _nt      => '',
    _tmin    => '',
    _dt      => '',
    _rf      => '',
    _verbose => '',
    _Step    => '',
    _note    => ''
};

=pod

 sub clear 
     clear global variables from the memory

=cut

sub clear {
    $suresamp->{_nt} = '', $suresamp->{_tmin} = '';
    $suresamp->{_dt} = '';
    $suresamp->{_rf} = '';
    $suresamp->{_verbose} = '';
    $suresamp->{_Step}    = '';
    $suresamp->{_note}    = '';

}

=head2 sub tmin

 time of the first sample to create

=cut 

sub tmin {
    my ( $variable, $tmin ) = @_;
    if ($tmin) {
        $suresamp->{_tmin} = $tmin;
        $suresamp->{_Step} =
          $suresamp->{_Step} . ' tmin=' . $suresamp->{_tmin};
        $suresamp->{_note} =
          $suresamp->{_note} . ' tmin=' . $suresamp->{_tmin};
    }
}

=head2 sub nt

 output number of samples

=cut 

sub nt {
    my ( $variable, $nt ) = @_;
    if ($nt) {
        $suresamp->{_nt}   = $nt;
        $suresamp->{_Step} = $suresamp->{_Step} . ' nt=' . $suresamp->{_nt};
        $suresamp->{_note} = $suresamp->{_note} . ' nt=' . $suresamp->{_nt};
    }
}

=head2 sub dt

 output sampling interval (s)

=cut 

sub dt {
    my ( $variable, $dt ) = @_;
    if ($dt) {
        $suresamp->{_dt}   = $dt;
        $suresamp->{_Step} = $suresamp->{_Step} . ' dt=' . $suresamp->{_dt};
        $suresamp->{_note} = $suresamp->{_note} . ' dt=' . $suresamp->{_dt};
    }
}

=head2 sub rf

 resampling factor instead of
 using dt and nt
 An rf < 1 increases dt output
 and decreases ns output

=cut 

sub rf {
    my ( $variable, $rf ) = @_;
    if ($rf) {
        $suresamp->{_rf}   = $rf;
        $suresamp->{_Step} = $suresamp->{_Step} . ' rf=' . $suresamp->{_rf};
        $suresamp->{_note} = $suresamp->{_note} . ' rf=' . $suresamp->{_rf};
    }
}

=head2 sub note 

 independent log of sunix sripts 

=cut 

sub note {
    my ($variable) = @_;
    $suresamp->{_note} = $suresamp->{_note};
    return $suresamp->{_note};
}

=head2 sub note 

 sunix sripts in bash format 

=cut 

sub Step {
    my ($variable) = @_;
    $suresamp->{_Step} = 'suresamp ' . $suresamp->{_Step};
    return $suresamp->{_Step};
}

=head2 sub  verbose

 advisory program output 
 to screen

=cut 

sub verbose {
    my ( $variable, $verbose ) = @_;
    if ($verbose) {
        $suresamp->{_verbose} = $verbose;
        $suresamp->{_Step} =
          $suresamp->{_Step} . ' verbose=' . $suresamp->{_verbose};
        $suresamp->{_note} =
          $suresamp->{_note} . ' verbose=' . $suresamp->{_verbose};
    }
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
