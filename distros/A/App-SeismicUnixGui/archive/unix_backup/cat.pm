package cat;

=head1 DOCUMENTATION

=head2 SYNOPSIS 


 PROGRAM NAME: cat
 AUTHOR: Juan Lorenzo
 DATE: Oct 10 2012
 DESCRIPTION concatenates lists of file names
 Version 0.1

 DESCRIPTION: 
     
 USED FOR: 

 BASED ON:
 CHANGES:  0.0.2

=cut

use Moose;
our $VERSION = '0.0.2';
use App::SeismicUnixGui::misc::L_SU_global_constants;
my $get = L_SU_global_constants->new();
my $var = $get->var();

=head2 private hash

=cut

my $binding = {
	_prog_name_sref => '',
	_sub_ref        => '',
	_values_w_aref  => '',
};

my $newline = '
';

=head2 private hash

=cut

my $cat = {
	_list  => '',
	_note  => '',
	_start => '',
	_end   => '',
	_Step  => '',
};

sub clear {
	my ($self) = @_;
	$cat->{_list}  = '';
	$cat->{_note}  = '';
	$cat->{_start} = '';
	$cat->{_end}   = '';
	$cat->{_Step}  = '';
	return ();
}
sub end {
	my ( $self, $end ) = @_;
	$cat->{_note} = ' to # ' . $end;
	$cat->{_end} = $end if defined($end);
	return ();
}

sub first {
	my ( $self, $start ) = @_;
	$cat->{_note} = ' from file # ' . $start;
	$cat->{_start} = $start if defined($start);
	return ();
}

sub last {
	my ( $self, $end ) = @_;
	$cat->{_note} = ' to # ' . $end;
	$cat->{_end} = $end if defined($end);
	return ();
}


sub list {
	my ( $self, $DIR, $ref_array ) = @_;
	my @list = @$ref_array if defined($ref_array);
	$cat->{_DIR} = $DIR if defined($DIR);
	$cat->{_Step} = $cat->{_Step};

	my $start = $cat->{_start};
	my $end   = $cat->{_end};

	for ( my $i = $start; $i <= $end; $i++ ) {

		#print("i=$i\n\n");
		$cat->{_Step} =
			$cat->{_Step} . $cat->{_DIR} . '/' . $list[$i] . ' \\' . $newline;
	}
	return ();
}

=head2 sub cat_outbound

=cut

sub set_cat_outbound {
	my ( $self, $outbound ) = @_;

	if ( length $outbound ) {

		print("cccmp, set_cat_outbound, outbound = $outbound\n");
	}
	else {
		print("cccmp, set_cat_outbound, missing variable\n");
	}

	my $result;

	# $ccmco->set_file2cat();
	# $cccmp->set_cat();

	return ($result);

}



sub start {
	my ( $self, $start ) = @_;
	$cat->{_note} = ' to # ' . $start;
	$cat->{_start} = $start if defined($start);
	return ();
}
sub Step {
	my ($Step) = @_;
	$cat->{_Step} = $cat->{_step};
	return $cat->{_Step};
}

1;
