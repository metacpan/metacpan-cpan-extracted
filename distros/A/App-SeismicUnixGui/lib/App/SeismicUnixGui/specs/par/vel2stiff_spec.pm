package App::SeismicUnixGui::specs::par::vel2stiff_spec;
use Moose;
our $VERSION = '0.0.1';

use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use App::SeismicUnixGui::misc::SeismicUnix qw($su $suffix_su $bin $suffix_bin);
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get       = L_SU_global_constants->new();
my $Project   = Project_config->new();

my $var = $get->var();

my $empty_string     = $var->{_empty_string};
my $true             = $var->{_true};
my $false            = $var->{_false};
my $file_dialog_type = $get->file_dialog_type_href();
my $flow_type        = $get->flow_type_href();

my $DATA_SEISMIC_BIN= $Project->DATA_SEISMIC_BIN();    # output data directory
my $DATA_SEISMIC_SU = $Project->DATA_SEISMIC_SU();    # output data directory
my $PL_SEISMIC      = $Project->PL_SEISMIC();
my $max_index       = 17; 

my $vel2stiff_spec = {
	_CONFIG                => $PL_SEISMIC,
	_DATA_DIR_IN           => $DATA_SEISMIC_BIN,
	_DATA_DIR_OUT          => $DATA_SEISMIC_BIN,
	_binding_index_aref    => '',
	_suffix_type_in        => $bin,
	_data_suffix_in        => $suffix_bin,
	_suffix_type_out       => $bin,
	_data_suffix_out       => $suffix_bin,
	_file_dialog_type_aref => '',
	_flow_type_aref        => '',
	_has_infile            => $true,
	_has_outpar            => $false,
	_has_pipe_in           => $true,
	_has_pipe_out          => $true,
	_has_redirect_in       => $true,
	_has_redirect_out      => $true,
	_has_subin_in          => $false,
	_has_subin_out         => $false,
	_is_data               => $false,
	_is_first_of_2         => $true,
	_is_first_of_3or_more  => $true,
	_is_first_of_4or_more  => $true,
	_is_last_of_2          => $false,
	_is_last_of_3or_more   => $false,
	_is_last_of_4or_more   => $false,
	_is_suprog             => $true,
	_is_superflow          => $false,
	_max_index             => $max_index,
	 _prefix_aref          => '',
     _suffix_aref          => '',
};

=head2  sub binding_index_aref

=cut

sub binding_index_aref {

	my $self = @_;

	my @index;

	$index[0] = 0;       # item is  bound to DATA_DIR_IN
	$index[1] = 1;       # item is bound to DATA_DIR_IN
	$index[2] = 2;       # item is bound to DATA_DIR_IN
	$index[3] = 3;       # item is bound to DATA_DIR_IN
	$index[4] = 4;       # item is  bound to DATA_DIR_IN
	$index[5] = 5;       # item is bound to DATA_DIR_IN
	$index[6] = 6;       # item is bound to DATA_DIR_IN
	$index[7] = 7;       # item is bound to DATA_DIR_IN
	$index[8] = 8;       # item is  bound to DATA_DIR_IN
	$index[9] = 9;       # item is bound to DATA_DIR_IN
	$index[10] = 10;       # item is bound to DATA_DIR_IN
	$index[11]= 14;       # item is bound to DATA_DIR_IN
	$index[12]= 15;       # item is  bound to DATA_DIR_IN
	$index[13] = 16;       # item is bound to DATA_DIR_IN
	$index[14] = 17;       # item is bound to DATA_DIR_IN

	$vel2stiff_spec->{_binding_index_aref} = \@index;
	return ();

}

=head2  sub file_dialog_type_aref

type of dialog (Data, Flow, SaveAs) is needed by binding
one type of dialog for each index
=cut

sub file_dialog_type_aref {

	my $self = @_;

	my @type;
	
	my $index_aref = get_binding_index_aref();
	my @index      = @$index_aref;

	$type[$index[0]]  = $file_dialog_type->{_Data};
	$type[$index[1]] = $file_dialog_type->{_Data};
	$type[$index[2]]   = $file_dialog_type->{_Data};
	$type[$index[3]]  = $file_dialog_type->{_Data};
	$type[$index[4]]  = $file_dialog_type->{_Data};
	$type[$index[5]]  = $file_dialog_type->{_Data};
	$type[$index[6]]  = $file_dialog_type->{_Data};
	$type[$index[7]]  = $file_dialog_type->{_Data};
	$type[$index[8]]  = $file_dialog_type->{_Data};
	$type[$index[9]]  = $file_dialog_type->{_Data};
	$type[$index[10]] = $file_dialog_type->{_Data};
	$type[$index[11]] = $file_dialog_type->{_Data};
	$type[$index[12]] = $file_dialog_type->{_Data};
	$type[$index[13]] = $file_dialog_type->{_Data};
	$type[$index[14]] = $file_dialog_type->{_Data};

	$vel2stiff_spec->{_file_dialog_type_aref} = \@type;
	return ();

}

=head2  sub flow_type_aref

=cut

sub flow_type_aref {

	my $self = @_;

	my @type;

	$type[0] = $flow_type->{_user_built};
    $type[1] = $flow_type->{_user_built};
 	$type[2] = $flow_type->{_user_built};
    $type[3] = $flow_type->{_user_built}; 
    $type[4] = $flow_type->{_user_built};
    $type[5] = $flow_type->{_user_built};
 	$type[6] = $flow_type->{_user_built};
    $type[7] = $flow_type->{_user_built}; 
   	$type[8] = $flow_type->{_user_built};
    $type[9] = $flow_type->{_user_built};
 	$type[10] = $flow_type->{_user_built};
    $type[11] = $flow_type->{_user_built}; 
    $type[12] = $flow_type->{_user_built};
    $type[13] = $flow_type->{_user_built};
 	$type[14] = $flow_type->{_user_built};

	$vel2stiff_spec->{_flow_type_aref} = \@type;
	return ();

}

=head2 sub get_binding_index_aref

=cut

sub get_binding_index_aref {

	my $self = @_;
	my @index;

	if ( $vel2stiff_spec->{_binding_index_aref} ) {

		my $index_aref = $vel2stiff_spec->{_binding_index_aref};
		return ($index_aref);

	} else {
		print("vel2stiff_spec, get_binding_index_aref, missing binding_index_aref\n");
		return ();
	}

	my $index_aref = $vel2stiff_spec->{_binding_index_aref};
}

=head2 sub get_binding_length

=cut

sub get_binding_length {

	my $self = @_;

	if ( $vel2stiff_spec->{_binding_index_aref} ) {

		my $binding_length = scalar @{ $vel2stiff_spec->{_binding_index_aref} };
		return ($binding_length);

	} else {
		print("vel2stiff_spec, get_binding_length, missing binding_length\n");
		return ();
	}

	return ();
}

=head2 sub get_file_dialog_type_aref

=cut

sub get_file_dialog_type_aref {

	my $self = @_;
	if ( $vel2stiff_spec->{_file_dialog_type_aref} ) {

		my $index_aref = $vel2stiff_spec->{_file_dialog_type_aref};
		return ($index_aref);

	} else {
		print("vel2stiff_spec, get_file_dialog_type_aref, missing get_file_dialog_type_aref\n");
		return ();
	}

	return ();
}

=head2 sub get_flow_type_aref

=cut

sub get_flow_type_aref {

	my $self = @_;

	if ( $vel2stiff_spec->{_flow_type_aref} ) {

		my $index_aref = $vel2stiff_spec->{_flow_type_aref};
		return ($index_aref);

	} else {
		print("vel2stiff_spec, get_flow_type_aref, missing flow_type_aref\n");
		return ();
	}

}

=head2 sub get_incompatibles

=cut

sub get_incompatibles {

	my $self = @_;
	my @needed;

	my @_need_both;

	my @_need_only_1;

	my @_none_needed;

	my @_all_needed;

	my $params = {

		_need_both   => \@_need_both,
		_need_only_1 => \@_need_only_1,
		_none_needed => \@_none_needed,
		_all_needed  => \@_all_needed,

	};

	my @of_two = ( 'xx', 'yy' );
	push @{ $params->{_need_only_1} }, \@of_two;

	my $len_1_needed = scalar @{ $params->{_need_only_1} };

	if ( $len_1_needed >= 1 ) {

		for ( my $i = 0; $i < $len_1_needed; $i++ ) {

			print("vel2stiff, get_incompatibles,need_only_1:  @{@{$params->{_need_only_1}}[$i]}\n");

		}

	} else {
		print("get_incompatibles, no incompatibles\n");
	}

	return ($params);

}

=head2 sub get_prefix_aref

=cut

sub get_prefix_aref {

	my $self = @_;

	if ( $vel2stiff_spec->{_prefix_aref} ) {

		my $prefix_aref = $vel2stiff_spec->{_prefix_aref};
		return ($prefix_aref);

	} else {
		print("vel2stiff_spec, get_prefix_aref, missing prefix_aref\n");
		return ();
	}

	return ();
}

=head2 sub get_suffix_aref

=cut

sub get_suffix_aref {

	my $self = @_;

	if ( $vel2stiff_spec->{_suffix_aref} ) {

		my $suffix_aref = $vel2stiff_spec->{_suffix_aref};
		return ($suffix_aref);

	} else {
		print("$vel2stiff_spec, get_suffix_aref, missing suffix_aref\n");
		return ();
	}

	return ();
}

=head2  sub prefix_aref

Include in the Set up
sections of an output Poop flow.

prefixes and suffixes to parameter labels
are filtered by sunix_pl

=cut

sub prefix_aref {

	my $self = @_;

	my @prefix;

	for ( my $i = 0; $i < $max_index; $i++ ) {

		$prefix[$i] = $empty_string;

	}
	
	my $index_aref = get_binding_index_aref();
	my @index      = @$index_aref;

	# label i1 n GUI is input c11_file and needs a home directory
	$prefix[ $index[0] ] = '$DATA_SEISMIC_BIN' . ".'/'.";
	# label 2 in GUI is input c13_file and needs a home directory
	$prefix[ $index[1] ] = '$DATA_SEISMIC_BIN' . ".'/'.";
	# label 3 in GUI is input c15_file and needs a home directory
	$prefix[ $index[2] ] = '$DATA_SEISMIC_BIN' . ".'/'.";
	# label 4 in GUI is input c33_file and needs a home directory
	$prefix[ $index[3] ] = '$DATA_SEISMIC_BIN' . ".'/'.";
	# label 5 in GUI is input c35_file and needs a home directory
	$prefix[ $index[4] ] = '$DATA_SEISMIC_BIN' . ".'/'.";
	# label 6 in GUI is input c44_file and needs a home directory
	$prefix[ $index[5] ] = '$DATA_SEISMIC_BIN' . ".'/'.";
	# label 7 in GUI is input c55_file and needs a home directory
	$prefix[ $index[6] ] = '$DATA_SEISMIC_BIN' . ".'/'.";
	# label 8  in GUI is input c66_file and needs a home directory
	$prefix[ $index[7] ] = '$DATA_SEISMIC_BIN' . ".'/'.";
	# label 9 in GUI is input deltafile and needs a home directory
	$prefix[ $index[8] ] = '$DATA_SEISMIC_BIN' . ".'/'.";
	# label 10 in GUI is input epsfile and needs a home directory
	$prefix[ $index[9] ] = '$DATA_SEISMIC_BIN' . ".'/'.";
	# label 11 in GUI is input gammafile and needs a home directory
	$prefix[ $index[10] ] = '$DATA_SEISMIC_BIN' . ".'/'.";
	# label 15 in GUI is input phi_file and needs a home directory
	$prefix[ $index[11] ] = '$DATA_SEISMIC_BIN' . ".'/'.";
	# label 16 in GUI is input rhofile and needs a home directory
	$prefix[ $index[12] ] = '$DATA_SEISMIC_BIN' . ".'/'.";
	# label 17 in GUI is input vpfile and needs a home directory
	$prefix[ $index[13] ] = '$DATA_SEISMIC_BIN' . ".'/'.";
	# label 18 in GUI is input vsfile and needs a home directory
	$prefix[ $index[14] ] = '$DATA_SEISMIC_BIN' . ".'/'.";
	
	$vel2stiff_spec->{_prefix_aref} = \@prefix;
	return ();

}

=head2  sub suffix_aref

Initialize suffixes as empty
Assign specific suffixes to parameter
values
Used to create output perl flows 
(using "oop_x" modules)

=cut

sub suffix_aref {

	my $self = @_;

	my @suffix;

	for ( my $i = 0; $i < $max_index; $i++ ) {

		$suffix[$i] = $empty_string;

	}
	
	my $index_aref = get_binding_index_aref();
	my @index      = @$index_aref;

	# label 1 in GUI is input c11_file and needs a home directory
	$suffix[ $index[0] ] = "" . '$suffix_bin';
	# label 2 in GUI is input c13_file and needs a home directory
	$suffix[ $index[1] ] = "" . '$suffix_bin';
	# label 3 n GUI is input c15_file and needs a home directory
	$suffix[ $index[2] ] = "" . '$suffix_bin';
	# label 4 in GUI is input c33_file and needs a home directory
	$suffix[ $index[3] ] = "" . '$suffix_bin';	
    # label 5 in GUI is input c35_file and needs a home directory
	$suffix[ $index[4] ] = "" . '$suffix_bin';
	# label 6 in GUI is input c44_file and needs a home directory
	$suffix[ $index[5] ] = "" . '$suffix_bin';
	# label 7 in GUI is input c55_file and needs a home directory
	$suffix[ $index[6] ] = "" . '$suffix_bin';
	# label 8 in GUI is input c66_file and needs a home directory
	$suffix[ $index[7] ] = "" . '$suffix_bin';
	# label 9 in GUI is input deltafile and needs a home directory
	$suffix[ $index[8] ] = "" . '$suffix_bin';
	# label 10 in GUI is input epsfile and needs a home directory
	$suffix[ $index[9] ] = "" . '$suffix_bin';
	# label 11 in GUI is input gammafile and needs a home directory
	$suffix[ $index[10] ] = "" . '$suffix_bin';
	# label 15 in GUI is input phi_file and needs a home directory
	$suffix[ $index[11] ] = "" . '$suffix_bin';	
	# label 16 in GUI is input rhofile and needs a home directory
	$suffix[ $index[12] ] = "" . '$suffix_bin';
	# label 17 in GUI is input vpfile and needs a home directory
	$suffix[ $index[13] ] = "" . '$suffix_bin';
	# label 18 in GUI is input vsfile and needs a home directory
	$suffix[ $index[14] ] =  "" . '$suffix_bin';

			
	$vel2stiff_spec->{_suffix_aref} = \@suffix;
	
	return ();

}

=head2 sub variables


return a hash array 
with definitions
 
=cut

sub variables {

	my ($self) = @_;
	my $hash_ref = $vel2stiff_spec;
	return ($hash_ref);
}

1;
