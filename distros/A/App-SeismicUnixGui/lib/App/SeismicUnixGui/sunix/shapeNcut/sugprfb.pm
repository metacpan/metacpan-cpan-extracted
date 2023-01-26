package App::SeismicUnixGui::sunix::shapeNcut::sugprfb;

=head1 DOCUMENTATION

=head2 SYNOPSIS

PACKAGE NAME: SUGPRFB - SU program to remove First Breaks from GPR data		
AUTHOR: Juan Lorenzo
DATE:   
DESCRIPTION:
Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

SUGPRFB - SU program to remove First Breaks from GPR data		

  sugprfb < radar traces >outfile			  		

 nx=51		number of traces to sum to create pilot trace (odd)	
 fbt=60	length of first break in number of samples		

 Notes:								
 The first fbt samples from nx traces are stacked to form a pilot	
 first break trace, this is fitted to the actual traces by shifting	
 and scaling.		 The nx traces long spatial window is		
 slided along the section and a new pilot traces is formed for each	
 position. The scalers in percent and the time shifts are stored in	
 header words trwf and grnors.
=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $sugprfb = {
	_fbt  => '',
	_nx   => '',
	_Step => '',
	_note => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

	$sugprfb->{_Step} = 'sugprfb' . $sugprfb->{_Step};
	return ( $sugprfb->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

	$sugprfb->{_note} = 'sugprfb' . $sugprfb->{_note};
	return ( $sugprfb->{_note} );

}

=head2 sub clear

=cut

sub clear {

	$sugprfb->{_fbt}  = '';
	$sugprfb->{_nx}   = '';
	$sugprfb->{_Step} = '';
	$sugprfb->{_note} = '';
}

=head2 sub fbt 


=cut

sub fbt {

	my ( $self, $fbt ) = @_;
	if ( $fbt ne $empty_string ) {

		$sugprfb->{_fbt}  = $fbt;
		$sugprfb->{_note} = $sugprfb->{_note} . ' fbt=' . $sugprfb->{_fbt};
		$sugprfb->{_Step} = $sugprfb->{_Step} . ' fbt=' . $sugprfb->{_fbt};

	}
	else {
		print("sugprfb, fbt, missing fbt,\n");
	}
}

=head2 sub nx 


=cut

sub nx {

	my ( $self, $nx ) = @_;
	if ( $nx ne $empty_string ) {

		$sugprfb->{_nx}   = $nx;
		$sugprfb->{_note} = $sugprfb->{_note} . ' nx=' . $sugprfb->{_nx};
		$sugprfb->{_Step} = $sugprfb->{_Step} . ' nx=' . $sugprfb->{_nx};

	}
	else {
		print("sugprfb, nx, missing nx,\n");
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
