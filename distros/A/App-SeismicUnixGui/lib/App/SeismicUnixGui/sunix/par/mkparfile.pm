package App::SeismicUnixGui::sunix::par::mkparfile;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PERL PROGRAM NAME:  MKPARFILE - convert ascii to par file format 				
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 MKPARFILE - convert ascii to par file format 				

 mkparfile <stdin >stdout 						

 Optional parameters:							
 	string1="par1"	first par string			
 	string2="par2"	second par string			

 This is a tool to convert values written line by line to parameter 	
 vectors in the form expected by getpar.  For example, if the input	
 file looks like:							
 	t0 v0								
 	t1 v1								
	...								
 then									
	mkparfile <input >output string1=tnmo string2=vnmo		
 yields:								
	tnmo=t0,t1,...							
	vnmo=v0,v1,...							

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $mkparfile = {
    _string1 => '',
    _string2 => '',
    _tnmo    => '',
    _vnmo    => '',
    _Step    => '',
    _note    => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $mkparfile->{_Step} = 'mkparfile' . $mkparfile->{_Step};
    return ( $mkparfile->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $mkparfile->{_note} = 'mkparfile' . $mkparfile->{_note};
    return ( $mkparfile->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $mkparfile->{_string1} = '';
    $mkparfile->{_string2} = '';
    $mkparfile->{_tnmo}    = '';
    $mkparfile->{_vnmo}    = '';
    $mkparfile->{_Step}    = '';
    $mkparfile->{_note}    = '';
}

=head2 sub string1 


=cut

sub string1 {

    my ( $self, $string1 ) = @_;
    if ( $string1 ne $empty_string ) {

        $mkparfile->{_string1} = $string1;
        $mkparfile->{_note} =
          $mkparfile->{_note} . ' string1=' . $mkparfile->{_string1};
        $mkparfile->{_Step} =
          $mkparfile->{_Step} . ' string1=' . $mkparfile->{_string1};

    }
    else {
        print("mkparfile, string1, missing string1,\n");
    }
}

=head2 sub string2 


=cut

sub string2 {

    my ( $self, $string2 ) = @_;
    if ( $string2 ne $empty_string ) {

        $mkparfile->{_string2} = $string2;
        $mkparfile->{_note} =
          $mkparfile->{_note} . ' string2=' . $mkparfile->{_string2};
        $mkparfile->{_Step} =
          $mkparfile->{_Step} . ' string2=' . $mkparfile->{_string2};

    }
    else {
        print("mkparfile, string2, missing string2,\n");
    }
}

=head2 sub tnmo 


=cut

sub tnmo {

    my ( $self, $tnmo ) = @_;
    if ( $tnmo ne $empty_string ) {

        $mkparfile->{_tnmo} = $tnmo;
        $mkparfile->{_note} =
          $mkparfile->{_note} . ' tnmo=' . $mkparfile->{_tnmo};
        $mkparfile->{_Step} =
          $mkparfile->{_Step} . ' tnmo=' . $mkparfile->{_tnmo};

    }
    else {
        print("mkparfile, tnmo, missing tnmo,\n");
    }
}

=head2 sub vnmo 


=cut

sub vnmo {

    my ( $self, $vnmo ) = @_;
    if ( $vnmo ne $empty_string ) {

        $mkparfile->{_vnmo} = $vnmo;
        $mkparfile->{_note} =
          $mkparfile->{_note} . ' vnmo=' . $mkparfile->{_vnmo};
        $mkparfile->{_Step} =
          $mkparfile->{_Step} . ' vnmo=' . $mkparfile->{_vnmo};

    }
    else {
        print("mkparfile, vnmo, missing vnmo,\n");
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;
    my $max_index = 1;

    return ($max_index);
}

1;
