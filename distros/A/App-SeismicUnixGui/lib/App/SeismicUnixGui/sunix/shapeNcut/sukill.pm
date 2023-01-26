package App::SeismicUnixGui::sunix::shapeNcut::sukill;

=head2 SYNOPSIS

PACKAGE NAME: 

AUTHOR:  

DATE:

DESCRIPTION:

Version:

=head2 USE

Usage 1:
To kill an array of trace numbers

Example:
       $sukill->tracl(\@array);
       $sukill->Steps()

Usage 1:
To kill a single of trace number
count=1 (default if omitted)

Example:
       $sukill->min('2');
       $sukill->Step()

If you read the file directly into sukill then also
us sukill->file('name')


=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES
 SUKILL - zero out traces					

 sukill <stdin >stdout [optional parameters]			

 Optional parameters:						

	key=trid	header name to select traces to kill	

	a=2		header value identifying traces to kill

 or

 	min= 		first trace to kill (one-based)		

 	count=1		number of traces to kill 		


 Notes:							

	If min= is set it overrides selecting traces by header.	


 Credits:

	CWP: Chris Liner, Jack K. Cohen

	header-based trace selection: Florian Bleibinhaus


 Trace header fields accessed: ns

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';

=head2 Import packages

=cut

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to $suffix_ascii $off $suffix_su $suffix_bin);
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';

=head2 instantiation of packages

=cut

my $get              = L_SU_global_constants->new();
my $Project          = Project_config->new();
my $DATA_SEISMIC_SU  = $Project->DATA_SEISMIC_SU();
my $DATA_SEISMIC_BIN = $Project->DATA_SEISMIC_BIN();
my $DATA_SEISMIC_TXT = $Project->DATA_SEISMIC_TXT();

my $var          = $get->var();
my $on           = $var->{_on};
my $off          = $var->{_off};
my $true         = $var->{_true};
my $false        = $var->{_false};
my $empty_string = $var->{_empty_string};

=head2 Encapsulated
hash of private variables

=cut

my $sukill = {
	_a     => '',
	_count => '',
	_key   => '',
	_min   => '',
	_Step  => '',
	_note  => '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

	$sukill->{_Step} = 'sukill' . $sukill->{_Step};
	return ( $sukill->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

	$sukill->{_note} = 'sukill' . $sukill->{_note};
	return ( $sukill->{_note} );

}

=head2 sub clear

=cut

sub clear {

	$sukill->{_a}     = '';
	$sukill->{_count} = '';
	$sukill->{_key}   = '';
	$sukill->{_min}   = '';
	$sukill->{_Step}  = '';
	$sukill->{_note}  = '';
}

=head2 sub a 


=cut

sub a {

	my ( $self, $a ) = @_;
	if ( $a ne $empty_string ) {

		$sukill->{_a}    = $a;
		$sukill->{_note} = $sukill->{_note} . ' a=' . $sukill->{_a};
		$sukill->{_Step} = $sukill->{_Step} . ' a=' . $sukill->{_a};

	}
	else {
		print("sukill, a, missing a,\n");
	}
}

=head2 sub count 


=cut

sub count {

	my ( $self, $count ) = @_;
	if ( $count ne $empty_string ) {

		$sukill->{_count} = $count;
		$sukill->{_note}  = $sukill->{_note} . ' count=' . $sukill->{_count};
		$sukill->{_Step}  = $sukill->{_Step} . ' count=' . $sukill->{_count};

	}
	else {
		print("sukill, count, missing count,\n");
	}
}

=head2 sub key 


=cut

sub key {

	my ( $self, $key ) = @_;
	if ( $key ne $empty_string ) {

		$sukill->{_key}  = $key;
		$sukill->{_note} = $sukill->{_note} . ' key=' . $sukill->{_key};
		$sukill->{_Step} = $sukill->{_Step} . ' key=' . $sukill->{_key};

	}
	else {
		print("sukill, key, missing key,\n");
	}
}

=head2 sub min 


=cut

sub min {

	my ( $self, $min ) = @_;
	if ( $min ne $empty_string ) {

		$sukill->{_min}  = $min;
		$sukill->{_note} = $sukill->{_note} . ' min=' . $sukill->{_min};
		$sukill->{_Step} = $sukill->{_Step} . ' min=' . $sukill->{_min};

	}
	else {
		print("sukill, min, missing min,\n");
	}
}

=head2 sub get_max_index

max index = number of input variables -1
 
=cut

sub get_max_index {
	my ($self) = @_;
	my $max_index = 3;

	return ($max_index);
}

1;
