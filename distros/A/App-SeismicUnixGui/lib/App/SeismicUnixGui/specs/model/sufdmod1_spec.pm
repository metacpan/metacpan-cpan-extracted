package App::SeismicUnixGui::specs::model::sufdmod1_spec;
use Moose;
our $VERSION = '0.0.1';

use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use App::SeismicUnixGui::misc::SeismicUnix qw($su $suffix_su $suffix_bin);
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';


my $get     = L_SU_global_constants->new();
my $Project = Project_config->new();


my $var = $get->var();

my $empty_string     = $var->{_empty_string};
my $true             = $var->{_true};
my $false            = $var->{_false};
my $file_dialog_type = $get->file_dialog_type_href();
my $flow_type        = $get->flow_type_href();

my $DATA_SEISMIC_BIN = $Project->DATA_SEISMIC_BIN();    # input data directory
my $DATA_SEISMIC_SU  = $Project->DATA_SEISMIC_SU();     # output data directory
my $PL_SEISMIC        = $Project->PL_SEISMIC();
my $max_index = 17;    #$sufdmod1->get_max_index() mystery error

my $sufdmod1_spec =  {
	_CONFIG						  => $PL_SEISMIC,
	_DATA_DIR_IN           => $DATA_SEISMIC_BIN,
	_DATA_DIR_OUT          => $DATA_SEISMIC_SU,
	_binding_index_aref    => '',
	_suffix_type_in        => $su, # TODO should be bin ???
	_data_suffix_in        => $suffix_bin,
	_suffix_type_out       => $su,
	_data_suffix_out       => $suffix_su,
	_file_dialog_type_aref => '',
	_flow_type_aref        => '',
	_has_infile            => $true,
    _has_outpar          => $false,
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
	 _prefix_aref               => '',
     _suffix_aref               => '',	
};

=head2  sub binding_index_aref

dfile, sfile,vfile (item indices =1,9,14)
is bound to binary directory DATA_SEISMIC_BIN

=cut

sub binding_index_aref {

	my ($self) = @_;

	my @index;

	$index[0] = 1;
	$index[1] = 9;
	$index[2] = 14;

	$sufdmod1_spec->{_binding_index_aref} = \@index;
	return ();

}

=head2  sub flow_type_aref

=cut

sub flow_type_aref {

	my ($self) = @_;

	my @type;

	$type[0] = $flow_type->{_user_built};

	$sufdmod1_spec->{_flow_type_aref} = \@type;
	return ();

}

=head2 sub get_binding_index_aref

=cut

sub get_binding_index_aref {

	my ($self) = @_;
	my @index;

	if ( $sufdmod1_spec->{_binding_index_aref} ) {

		my $index_aref = $sufdmod1_spec->{_binding_index_aref};
		return ($index_aref);

	}
	else {
		print(
			"sufdmod1_spec, get_binding_index_aref, missing binding_index_aref\n"
		);
		return ();
	}

	my $index_aref = $sufdmod1_spec->{_binding_index_aref};
}

=head2  sub file_dialog_type_aref

type of dialog (Data, Flow, SaveAs) is needed by binding
one type of dialog for each index

=cut

sub file_dialog_type_aref {

	my ($self) = @_;

	my @type;
	
    my $index_aref = get_binding_index_aref();
	my @index      = @$index_aref;

	$type[$index[0]] = $file_dialog_type->{_Data};
	$type[$index[1]] = $file_dialog_type->{_Data};
	$type[$index[2]] = $file_dialog_type->{_Data};

	$sufdmod1_spec->{_file_dialog_type_aref} = \@type;
	return ();

}

=head2 sub get_binding_length

=cut

sub get_binding_length {

	my ($self) = @_;

	if ( $sufdmod1_spec->{_binding_index_aref} ) {

		my $binding_length = scalar @{ $sufdmod1_spec->{_binding_index_aref} };

		# print("sufdmod1_spec, get_binding_length: $binding_length\n");
		return ($binding_length);

	}
	else {
		print("sufdmod1_spec, get_binding_length, missing binding_length\n");
		return ();
	}

	return ();
}

=head2 sub get_file_dialog_type_aref

=cut

sub get_file_dialog_type_aref {

	my ($self) = @_;
	if ( $sufdmod1_spec->{_file_dialog_type_aref} ) {

		my $index_aref = $sufdmod1_spec->{_file_dialog_type_aref};
		return ($index_aref);

	}
	else {
		print(
			"sufdmod1_spec, get_file_dialog_type_aref, missing get_file_dialog_type_aref\n"
		);
		return ();
	}

	return ();
}

=head2 sub get_flow_type_aref

=cut

sub get_flow_type_aref {

	my ($self) = @_;

	if ( $sufdmod1_spec->{_flow_type_aref} ) {

		my $index_aref = $sufdmod1_spec->{_flow_type_aref};
		return ($index_aref);

	}
	else {
		print("sufdmod1_spec, get_flow_type_aref, missing flow_type_aref\n");
		return ();
	}

}

=head2 sub get_incompatibles

=cut

sub get_incompatibles {

	my ($self) = @_;
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

			print(
				"sufdmod1, get_incompatibles,need_only_1:  @{@{$params->{_need_only_1}}[$i]}\n"
			);

		}

	}
	else {
		print("get_incompatibles, no incompatibles\n");
	}

	return ($params);

}

=head2 sub get_prefix_aref

=cut

sub get_prefix_aref {

	my ($self) = @_;

	if ( $sufdmod1_spec->{_prefix_aref} ) {

		my $prefix_aref = $sufdmod1_spec->{_prefix_aref};
		return ($prefix_aref);

	}
	else {
		print("sufdmod1_spec, get_prefix_aref, missing prefix_aref\n");
		return ();
	}

	return ();
}

=head2 sub get_suffix_aref

=cut

sub get_suffix_aref {

	my ($self) = @_;

	if ( $sufdmod1_spec->{_suffix_aref} ) {

		my $suffix_aref = $sufdmod1_spec->{_suffix_aref};
		return ($suffix_aref);

	}
	else {
		print("$sufdmod1_spec, get_suffix_aref, missing suffix_aref\n");
		return ();
	}

	return ();
}

=head2  sub prefix_aref

Include in the set-up
sections of an output Poop flow.

Prefixes and suffixes to parameter labels
are filtered by sunix_pl on writing out.

=cut

sub prefix_aref {

	my ($self) = @_;

	my @prefix;

	for ( my $i = 0; $i < $max_index; $i++ ) {

		$prefix[$i] = $empty_string;

	}

	my $index_aref = get_binding_index_aref();
	my @index      = @$index_aref;
	$prefix[ $index[0] ] =  '$DATA_SEISMIC_BIN' . ".'/'.";
	$prefix[ $index[1] ] =  '$DATA_SEISMIC_SU' . ".'/'.";
	$prefix[ $index[2] ] =  '$DATA_SEISMIC_BIN' . ".'/'.";

	$sufdmod1_spec->{_prefix_aref} = \@prefix;
	return ();

}

=head2  sub suffix_aref

Initialize suffixes as empty
Assign specific suffixes to parameter
values

set data type in to binary
set data type out to su
for writing out to perl script

=cut

sub suffix_aref {

	my ($self) = @_;

	my @suffix;

	for ( my $i = 0; $i < $max_index; $i++ ) {

		$suffix[$i] = $empty_string;

	}

	my $index_aref = get_binding_index_aref();
	my @index      = @$index_aref;
	$suffix[ $index[0] ] = ''.'' . '$suffix_bin';
	$suffix[ $index[1] ] = ''.''. '$suffix_su';
	$suffix[ $index[2] ] = ''.''. '$suffix_bin';

	$sufdmod1_spec->{_suffix_aref} = \@suffix;
	return ();

}

=head2 sub variables

return a hash array 
with definitions
 
=cut

sub variables {
	my $self     = @_;
	my $hash_ref = $sufdmod1_spec;
	return ($hash_ref);
}

1;
