package App::SeismicUnixGui::specs::par::unisam_spec;
use Moose;
our $VERSION = '0.0.1';

use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use App::SeismicUnixGui::misc::SeismicUnix qw($su $bin $suffix_su $suffix_bin);
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::sunix::par::unisam';

my $get     = L_SU_global_constants->new();
my $Project = Project_config->new();
my $unisam  = unisam->new();

my $var = $get->var();

my $empty_string     = $var->{_empty_string};
my $true             = $var->{_true};
my $false            = $var->{_false};
my $file_dialog_type = $get->file_dialog_type_href();
my $flow_type        = $get->flow_type_href();

my $DATA_SEISMIC_BIN = $Project->DATA_SEISMIC_BIN();    # input data directory
my $DATA_SEISMIC_SU  = $Project->DATA_SEISMIC_SU();     # output data directory
my $PL_SEISMIC        = $Project->PL_SEISMIC();
my $max_index        = $unisam->get_max_index();

my $unisam_spec = {
	_CONFIG						  => $PL_SEISMIC,
	_DATA_DIR_OUT          => $DATA_SEISMIC_SU,
	_DATA_DIR_IN           => $DATA_SEISMIC_BIN,
	_DATA_DIR_OUT          => $DATA_SEISMIC_BIN,
	_binding_index_aref    => '',
	_suffix_type_in        => $bin,
	_data_suffix_in        => $suffix_bin,
	_suffix_type_out       => $su,
	_data_suffix_out       => $suffix_bin,
	_file_dialog_type_aref => '',
	_flow_type_aref        => '',
	_has_infile            => $true,
	_has_pipe_in           => $false,
	_has_pipe_out          => $true,
	_has_redirect_in       => $false,
	_has_redirect_out      => $true,
	_has_subin_in          => $true,               # DATA_SEISMIC_BIN
	_has_subin_out         => $true,               # DATA_SEISMIC_BIN
	_is_data               => $false,
	_is_first_of_2         => $true,
	_is_first_of_3or_more  => $true,
	_is_first_of_4or_more  => $true,
	_is_last_of_2          => $false,
	_is_last_of_3or_more   => $false,
	_is_last_of_4or_more   => $false,
	_is_suprog             => $true,               # SeismicUnix module
	_is_superflow          => $false,
	_max_index             => $max_index,
};

=head2  sub binding_index_aref

xfile (item index =13)
is bound to binary directory DATA_SEISMIC_BIN

=cut

sub binding_index_aref {

	my $self = @_;

	my @index;

	$index[0] = 13;
	$index[0] = 15;
	$index[0] = 17;

	$unisam_spec->{_binding_index_aref} = \@index;
	return ();

}

=head2  sub file_dialog_type_aref

type of dialog (Data, Flow, SaveAs) is needed by binding
one type of dialog for each index

=cut

sub file_dialog_type_aref {

	my $self = @_;

	my @type;

	$type[0] = $file_dialog_type->{_Data};
	$type[1] = $file_dialog_type->{_Data};
	$type[2] = $file_dialog_type->{_Data};

	$unisam_spec->{_file_dialog_type_aref} = \@type;
	return ();

}

=head2  sub flow_type_aref

=cut

sub flow_type_aref {

	my $self = @_;

	my @type;

	$type[0] = $flow_type->{_user_built};

	$unisam_spec->{_flow_type_aref} = \@type;
	return ();

}

=head2 sub get_binding_index_aref

=cut

sub get_binding_index_aref {

	my $self = @_;
	my @index;

	if ( $unisam_spec->{_binding_index_aref} ) {

		my $index_aref = $unisam_spec->{_binding_index_aref};
		return ($index_aref);

	}
	else {
		print(
			"unisam_spec, get_binding_index_aref, missing binding_index_aref\n"
		);
		return ();
	}

	my $index_aref = $unisam_spec->{_binding_index_aref};
}

=head2 sub get_binding_length

=cut

sub get_binding_length {

	my $self = @_;

	if ( $unisam_spec->{_binding_index_aref} ) {

		my $binding_length = scalar @{ $unisam_spec->{_binding_index_aref} };
		return ($binding_length);

	}
	else {
		print("unisam_spec, get_binding_length, missing binding_length\n");
		return ();
	}

	return ();
}

=head2 sub get_file_dialog_type_aref

=cut

sub get_file_dialog_type_aref {

	my $self = @_;
	if ( $unisam_spec->{_file_dialog_type_aref} ) {

		my $index_aref = $unisam_spec->{_file_dialog_type_aref};
		return ($index_aref);

	}
	else {
		print(
			"unisam_spec, get_file_dialog_type_aref, missing get_file_dialog_type_aref\n"
		);
		return ();
	}

	return ();
}

=head2 sub get_flow_type_aref

=cut

sub get_flow_type_aref {

	my $self = @_;

	if ( $unisam_spec->{_flow_type_aref} ) {

		my $index_aref = $unisam_spec->{_flow_type_aref};
		return ($index_aref);

	}
	else {
		print("unisam_spec, get_flow_type_aref, missing flow_type_aref\n");
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

			print(
				"unisam, get_incompatibles,need_only_1:  @{@{$params->{_need_only_1}}[$i]}\n"
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

	my $self = @_;

	if ( $unisam_spec->{_prefix_aref} ) {

		my $prefix_aref = $unisam_spec->{_prefix_aref};
		return ($prefix_aref);

	}
	else {
		print("unisam_spec, get_prefix_aref, missing prefix_aref\n");
		return ();
	}

	return ();
}

=head2 sub get_suffix_aref

=cut

sub get_suffix_aref {

	my $self = @_;

	if ( $unisam_spec->{_suffix_aref} ) {

		my $suffix_aref = $unisam_spec->{_suffix_aref};
		return ($suffix_aref);

	}
	else {
		print("$unisam_spec, get_suffix_aref, missing suffix_aref\n");
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
	$unisam_spec->{_prefix_aref} = \@prefix;
	return ();

}

=head2  sub suffix_aref

Initialize suffixes as empty
Assign specific suffixes to parameter
values

=cut

sub suffix_aref {

	my $self = @_;

	my @suffix;

	for ( my $i = 0; $i < $max_index; $i++ ) {

		$suffix[$i] = $empty_string;

	}
	$unisam_spec->{_suffix_aref} = \@suffix;
	return ();

}

=head2 sub variables

return a hash array 
with definitions
 
=cut

sub variables {
	my ($self) = @_;
	my $hash_ref = $unisam_spec;
	return ($hash_ref);
}

1;
