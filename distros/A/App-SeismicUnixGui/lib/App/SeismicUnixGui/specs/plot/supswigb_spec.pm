package App::SeismicUnixGui::specs::plot::supswigb_spec;
use Moose;
our $VERSION = '0.0.1';

use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use App::SeismicUnixGui::misc::SeismicUnix qw($su $suffix_su $ps $suffix_ps);
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get      = L_SU_global_constants->new();
my $Project  = Project_config->new();

my $var = $get->var();

my $empty_string     = $var->{_empty_string};
my $true             = $var->{_true};
my $false            = $var->{_false};
my $file_dialog_type = $get->file_dialog_type_href();
my $flow_type        = $get->flow_type_href();

my $PS_SEISMIC        = $Project->PS_SEISMIC();    # output data directory
my $DATA_SEISMIC_SU   = $Project->DATA_SEISMIC_SU();    # output data directory
my $PL_SEISMIC        = $Project->PL_SEISMIC();
my $max_index         = 60;

my $supswigb_spec = {
    _CONFIG	 			   => $PL_SEISMIC,
    _DATA_DIR_IN           => $DATA_SEISMIC_SU,
	_DATA_DIR_OUT          => $PS_SEISMIC,
	_binding_index_aref    => '',
	_suffix_type_in        => $su,
	_data_suffix_in        => $suffix_su,
	_suffix_type_out       => $ps,
	_data_suffix_out       => $suffix_ps,
	_good_labels_aref      => '',            # new
	_file_dialog_type_aref => '',
	_flow_type_aref        => '',
	_has_infile            => $true,
    _has_outpar            => $false,
	_has_pipe_in           => $true,
	_has_pipe_out          => $false,
	_has_redirect_in       => $true,
	_has_redirect_out      => $true,
	_has_subin_in          => $false,
	_has_subin_out         => $false,
	_is_data               => $false,
	_is_first_of_2         => $true,
	_is_first_of_3or_more  => $true,
	_is_first_of_4or_more  => $false,
	_is_last_of_2          => $false,
	_is_last_of_3or_more   => $false,
	_is_last_of_4or_more   => $false,
	_is_suprog             => $true,
	_is_superflow          => $false,
	_max_index             => $max_index,
	_prefix_aref           => '',
	_suffix_aref           => '',
};

=head2  sub binding_index_aref

=cut

sub binding_index_aref {

	my $self = @_;

	my @index;

	$index[0] = 0;

	$supswigb_spec->{_binding_index_aref} = \@index;
	return ();

}

=head2  sub file_dialog_type_aref

type of dialog (Data, Flow, SaveAs) is needed by binding
one type of dialog for each index
=cut

sub file_dialog_type_aref {

	my $self = @_;

	my @type;

	$type[0] = '';

	$supswigb_spec->{_file_dialog_type_aref} = \@type;
	return ();

}

=head2  sub flow_type_aref

=cut

sub flow_type_aref {

	my $self = @_;

	my @type;

	$type[0] = $flow_type->{_user_built};

	$supswigb_spec->{_flow_type_aref} = \@type;
	return ();

}

=head2 sub get_binding_index_aref

=cut

sub get_binding_index_aref {

	my $self = @_;
	my @index;

	if ( $supswigb_spec->{_binding_index_aref} ) {

		my $index_aref = $supswigb_spec->{_binding_index_aref};
		return ($index_aref);

	}
	else {
		print(
			"supswigb_spec, get_binding_index_aref, missing binding_index_aref\n"
		);
		return ();
	}

	my $index_aref = $supswigb_spec->{_binding_index_aref};
}

=head2 sub get_binding_length

=cut

sub get_binding_length {

	my $self = @_;

	if ( $supswigb_spec->{_binding_index_aref} ) {

		my $binding_length = scalar @{ $supswigb_spec->{_binding_index_aref} };
		return ($binding_length);

	}
	else {
		print("supswigb_spec, get_binding_length, missing binding_length\n");
		return ();
	}

	return ();
}

=head2 sub get_file_dialog_type_aref

=cut

sub get_file_dialog_type_aref {

	my $self = @_;
	if ( $supswigb_spec->{_file_dialog_type_aref} ) {

		my $index_aref = $supswigb_spec->{_file_dialog_type_aref};
		return ($index_aref);

	}
	else {
		print(
			"supswigb_spec, get_file_dialog_type_aref, missing get_file_dialog_type_aref\n"
		);
		return ();
	}

	return ();
}

=head2 sub get_flow_type_aref

=cut

sub get_flow_type_aref {

	my $self = @_;

	if ( $supswigb_spec->{_flow_type_aref} ) {

		my $index_aref = $supswigb_spec->{_flow_type_aref};
		return ($index_aref);

	}
	else {
		print("supswigb_spec, get_flow_type_aref, missing flow_type_aref\n");
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
				"supswigb, get_incompatibles,need_only_1:  @{@{$params->{_need_only_1}}[$i]}\n"
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

	if ( $supswigb_spec->{_prefix_aref} ) {

		my $prefix_aref = $supswigb_spec->{_prefix_aref};
		return ($prefix_aref);

	}
	else {
		print("supswigb_spec, get_prefix_aref, missing prefix_aref\n");
		return ();
	}

	return ();
}

=head2 sub get_suffix_aref

=cut

sub get_suffix_aref {

	my $self = @_;

	if ( $supswigb_spec->{_suffix_aref} ) {

		my $suffix_aref = $supswigb_spec->{_suffix_aref};
		return ($suffix_aref);

	}
	else {
		print("$supswigb_spec, get_suffix_aref, missing suffix_aref\n");
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
	$supswigb_spec->{_prefix_aref} = \@prefix;
	return ();

}

=head2  sub suffix_aref

Initialize suffixes as empty
values

=cut

sub suffix_aref {

	my $self = @_;

	my @suffix;

	for ( my $i = 0; $i < $max_index; $i++ ) {

		$suffix[$i] = $empty_string;

	}
	$supswigb_spec->{_suffix_aref} = \@suffix;
	return ();

}

=head2 sub variables


return a hash array 
with definitions
 
=cut

sub variables {

	my ($self) = @_;
	my $hash_ref = $supswigb_spec;
	return ($hash_ref);
}

1;
