package App::SeismicUnixGui::misc::param_sunix;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 Perl package: param_sunix.pm 
 AUTHOR: Juan Lorenzo
 DATE: June 22 2017 

 DESCRIPTION: 
 V 0.1 June 22 2017
 V 0.2 June 23 2017
   change class name from sunix.pm  
   
  V 0.0.2 made in June 2022   

 USED FOR: 

 BASED ON:

=cut

use Moose;
our $VERSION = '0.0.2';

=pod

 private hash_ref
 w  for widgets

=cut

my $param_sunix = {
	_flow_type       => '',
	_program_name    => '',
	_label_boxes_w   => '',
	_entry_boxes_w   => '',
	_check_buttons_w => '',
	_all_aref        => '',
	_first_idx       => 0,
	_last            => '',
	_length          => '',
	_size            => '',
};

#has 'program_name' => (
#    is        => 'rw',
#    isa       => 'HashRef',
#    clearer   => 'clear_program_name',
#    predicate => 'has_program_name',
#    reader    => 'get_program_name',
##    writer	  => 'set_program_name',
#	trigger   => \&set_program_name,
#);

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

use App::SeismicUnixGui::misc::su_param '0.0.3';
use aliased 'App::SeismicUnixGui::misc::su_param';

my $get          = L_SU_global_constants->new();
my $var          = $get->var();
my $on           = $var->{_on};
my $off          = $var->{_off};
my $nu           = $var->{_nu};
my $yes          = $var->{_yes};
my $no           = $var->{_no};
my $empty_string = $var->{_empty_string};

=head2 sub set_program_name

 i/p is scalar ref
 o/p is scalar ref

=cut 

sub set_program_name {
	my ( $self, $program_name_sref ) = @_;
	# print("1. param_sunix, set_program_name,is $$program_name_sref\n");

	if (
		defined $program_name_sref
		&& $program_name_sref ne $empty_string
		&& $param_sunix->{_flow_type} ne $empty_string
	) {

#		print("2. param_sunix, set_program_name,is $$program_name_sref\n");
		$param_sunix->{_program_name} = $program_name_sref;

		_defaults( $param_sunix->{_program_name} );

	} else {
		print("param_sunix, set_program_name, name or flow_type is missing \n");
	}
}

=pod

 export all the private hash references

=cut

sub get_all {
	my ($self) = @_;

	_defaults( $param_sunix->{_program_name} );

	return ();
}

=head2 sub defaults

 Read a default specification file 
 Debug with
    print ("self is $self,program is $program_name\n");
 print("params are @$ref_CFG\n");
 program name is a hash
    print("params are @$ref_cfg\n");
    print ("param_sunix,defaults:program is $$program_name_sref\n");

=cut

sub defaults {
	my ($program_name_sref) = @_;

	print("param_sunix,defaults,program_name is $$program_name_sref\n");

	if ( defined $program_name_sref ) {

		my $su_param = su_param->new();
		my ( $cfg_aref, $size );

		$cfg_aref                 = $su_param->get($program_name_sref);
		$param_sunix->{_all_aref} = $cfg_aref;
		$param_sunix->{_length}   = $su_param->my_length($program_name_sref);

		print("param_sunix,defaults, length:$param_sunix->{_length}\n");
		return ();
	}
}

=head2 sub _defaults

 accessible to only methods within this file
 and from within the pacakge
 
=cut

sub _defaults {
	my ($program_name_sref) = @_;

#	print("param_sunix,_defaults,program_name is $$program_name_sref\n");
#	print("param_sunix,_defaults,param_sunix->{_flow_type} is $param_sunix->{_flow_type}\n");

	if ( defined $program_name_sref
		&& $param_sunix->{_flow_type} ne $empty_string ) {

		my $su_param = su_param->new();
		my ( $cfg_aref, $size );

		$su_param->set_flow_type( $param_sunix->{_flow_type} );

		$cfg_aref                 = $su_param->get($program_name_sref);
#		print("param_sunix,_defaults,cfg_aref = @{$cfg_aref}\n");
		$param_sunix->{_all_aref} = $cfg_aref;
		$param_sunix->{_length}   = $su_param->my_length($program_name_sref);

		# print("param_sunix,_defaults, length:$param_sunix->{_length}\n");
		return ();

	} else {
		print("param_sunix,_defaults, missing program_name_sref\n");
	}
}

=cut 

=head2 sub first_idx

 first usable index is set to 0

=cut 

sub first_idx {

	my ($self) = @_;

	$param_sunix->{_first_idx} = 0;

	my $result = $param_sunix->{_first_idx};
	return ($result);

}

=head2 sub get_check_buttons_settings 


=cut

sub get_check_buttons_settings {
	my ($self)   = @_;
	my $cfg_aref = $param_sunix->{_all_aref};
	my $length   = $param_sunix->{_length};
	my ( $i, $j );
	my @on_off;
	my @values;

	for ( $i = 1, $j = 0; $i < $length; $i = $i + 2, $j++ ) {
		$values[$j] = @$cfg_aref[$i];

		# print("param_sunix, get_check_buttons_settings :index..$j..values:$values[$j]\n");
		if (   $values[$j] eq $nu
			|| $values[$j] eq "'nu'"
			|| $values[$j] eq ''
			|| $values[$j] eq "''" ) {
			$on_off[$j] = $off;
		} else {
			$on_off[$j] = $on;
		}

		# print("param_sunix: get_check_buttons_settings :index $j setting: $on_off[$j]\n");
	}
	return ( \@on_off );
}

=head2 sub get_half_length 

 return the # values or labels which is half
 the "length" used by param_sunix internally

=cut 

sub get_half_length {

	my ($self) = @_;

	if ( $param_sunix->{_length} ) {

		my $half_length = ( $param_sunix->{_length} ) / 2;

		# print("param_sunix, get_length, length is $length\n");

		return ($half_length);
	} else {
		print("param_sunix,get_length. Warning Juan,CHECK THIS CASE\n");
	}

}

=head2 sub get_length4perl_flow 

 return the # values or labels which is half
 the "length" used by param_sunix internally

=cut 

sub get_length4perl_flow {

	my ($self) = @_;

	if ( $param_sunix->{_length} ) {

		my $length = ( $param_sunix->{_length} ) / 2;

		# print("param_sunix, get_length4perl_flow , length is $length\n");

		return ($length);
	} else {
		print("param_sunix,get_length4perl_flow . Warning Juan,CHECK THIS CASE\n");
	}

}

=head2 sub get_length 

 return the # values or labels which is half
 the "length" used by param_sunix internally

=cut 

sub get_length {

	my ($self) = @_;

	if ( $param_sunix->{_length} ) {

		my $length = $param_sunix->{_length};

		# print("param_sunix, get_length, length is $length\n");

		return ($length);
	} else {
		print("param_sunix,get_length. Warning Juan,CHECK THIS CASE\n");
	}

}

=head2 sub names


=cut

sub get_names {
	my ($self)   = @_;
	my $cfg_aref = $param_sunix->{_all_aref};
	my $length   = $param_sunix->{_length};
	my ( $i, $j );
	my @names;

	# print("1. param_sunix, get_names: we have length = $length\n\n");
	for ( $i = 0, $j = 0; $i < $length; $i = $i + 2, $j++ ) {
		$names[$j] = @$cfg_aref[$i];

		# print(" param_sunix, get_names :index $j names:  $names[$j]\n");
	}
	return ( \@names );
}

=head2 sub values


=cut

sub get_values {
	my ($self)   = @_;
	my $cfg_aref = $param_sunix->{_all_aref};
	my $length   = $param_sunix->{_length};
	my ( $i, $j );
	my @values;

	# print("cfg_aref is @$cfg_aref\n");

	for ( $i = 1, $j = 0; $i < $length; $i = $i + 2, $j++ ) {
		$values[$j] = @$cfg_aref[$i];

		# print("param_sunix, get_values :index $j values: $values[$j]\n");
		# print("param_sunix, get_values :index $i values:  @$cfg_aref[$i]\n");        print("param_sunix, get_values :index $j values: $values[$j]\n");
	}
	return ( \@values );
}

sub set_flow_type {

	my ( $self, $flow_type ) = @_;

	# print("param_sunix,  set_flow_type ,flow_type=$flow_type\n");
	if ( defined $flow_type
		&& $flow_type ne $empty_string ) {

		$param_sunix->{_flow_type} = $flow_type;

		# print("param_sunix,  set_flow_type ,flow_type=$param_sunix->{_flow_type}\n");

	} else {
		print("param_sunix,  set_flow_type , missing value\n");
	}

	return ();
}

=head2 sub set_half_length 

 length is not the last index but one beyond
 this subroutine will FAIL if sub defaults IS NOT called first

=cut 

sub set_half_length {

	my @self = @_;

	if ( $param_sunix->{_length} ) {

		$param_sunix->{_length} = ( $param_sunix->{_length} ) / 2;

		# print("param_sunix, set_length, length: $param_sunix->{_length}\n");

		return ();
	} else {
		print("param_sunix,set_length. Warning Juan,CHECK THIS CASE\n");
	}

}

=head2 sub set_length 

 length is not the last index but one beyond
 this subroutine will FAIL if sub defaults IS NOT called first

=cut 

sub set_length {

	my @self = @_;

	if ( $param_sunix->{_length} ) {

		$param_sunix->{_length} = ( $param_sunix->{_length} ) / 2;

		print("param_sunix, set_length, length: $param_sunix->{_length}\n");

		return ();
	} else {
		print("param_sunix,set_length. Warning Juan,CHECK THIS CASE\n");
	}

}

# removes Moose exports
#no Moose;
# 	# increases speed
#__PACKAGE__->meta->make_immutable;
1;
