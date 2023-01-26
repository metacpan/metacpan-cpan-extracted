package App::SeismicUnixGui::specs::par::b2a_spec;
use Moose;
our $VERSION = '0.0.1';

use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use App::SeismicUnixGui::misc::SeismicUnix qw($bin $txt $su $suffix_txt $suffix_bin);
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::sunix::par::b2a';

my $get     = L_SU_global_constants->new();
my $Project = Project_config->new();
my $b2a     = b2a->new();

my $var = $get->var();

my $empty_string     = $var->{_empty_string};
my $true             = $var->{_true};
my $false            = $var->{_false};
my $file_dialog_type = $get->file_dialog_type_href();
my $flow_type        = $get->flow_type_href();

my $DATA_SEISMIC_BIN = $Project->DATA_SEISMIC_BIN();    # input data directory
my $DATA_SEISMIC_SU  = $Project->DATA_SEISMIC_SU();
my $DATA_SEISMIC_TXT = $Project->DATA_SEISMIC_TXT();    # output
my $PL_SEISMIC       = $Project->PL_SEISMIC();
my $max_index        = $b2a->get_max_index();

my $b2a_spec = {
	_CONFIG                => $PL_SEISMIC,
	_DATA_DIR_IN           => $DATA_SEISMIC_BIN,
	_DATA_DIR_OUT          => $DATA_SEISMIC_TXT,
	_binding_index_aref    => '',
	_suffix_type_in        => $bin,
	_data_suffix_in        => $suffix_bin,
	_suffix_type_out       => $txt,
	_data_suffix_out       => $suffix_txt,
	_file_dialog_type_aref => '',
	_flow_type_aref        => '',
	_has_infile            => $true,
	_has_outpar            => $true,
	_has_outpar            => $false,
	_has_pipe_in           => $true,
	_has_pipe_out          => $true,
	_has_redirect_in       => $true,
	_has_redirect_out      => $true,
	_has_subin_in          => $true,
	_has_subin_out         => $false,
	_is_data               => $false,
	_is_first_of_2         => $true,
	_is_first_of_3or_more  => $true,
	_is_first_of_4or_more  => $false,
	_is_last_of_2          => $false,
	_is_last_of_3or_more   => $true,
	_is_last_of_4or_more   => $true,
	_is_suprog             => $true,
	_is_superflow          => $false,
	_max_index             => $max_index,
};

my $incompatibles = { clip => [ 'mbal', 'pbal' ], };

=head2  sub _sub_binding_index_aref

=cut

sub binding_index_aref {

	my ($self) = @_;

	my @index;

	# first binding index (index=0)
	# connects to second item (index=1)
	# in the parameter list
	$index[0] = 2;    # inbound item is  bound

	$b2a_spec->{_binding_index_aref} = \@index;
	return ();

}

=head2 sub file_dialog_type_aref

=cut

sub file_dialog_type_aref {
	my ($self) = @_;

	my @type;
	
	my $index_aref = get_binding_index_aref();
	my @index      = @$index_aref;

	# bound index will look for data

	$type[ $index[0] ] = $file_dialog_type->{_Data};
	
	$type[0] = '';

	$b2a_spec->{_file_dialog_type_aref} = \@type;

	return ();

}

=head2 sub flow_type_aref

=cut

sub flow_type_aref {

	my ($self) = @_;

	my @type;

	my $index_aref = get_binding_index_aref();
	my @index      = @$index_aref;

	# bound index will look for data

	$type[ $index[0] ] = $file_dialog_type->{_Data};

	$b2a_spec->{_flow_type_aref} = \@type;

	return ();

}

=head2 sub get_binding_index_aref

=cut

sub get_binding_index_aref {

	my ($self) = @_;
	my @index;

	if ( $b2a_spec->{_binding_index_aref} ) {

		my $index_aref = $b2a_spec->{_binding_index_aref};
		return ($index_aref);

	}
	else {
		print("b2a_spec, get_binding_index_aref, missing binding_index_aref\n");
		return ();
	}

	my $index_aref = $b2a_spec->{_binding_index_aref};

}

=head2 sub get_binding_length

=cut

sub get_binding_length {
	my ($self) = @_;

	if ( $b2a_spec->{_binding_index_aref} ) {

		my $length;

		$length = scalar @{ $b2a_spec->{_binding_index_aref} };

		return ($length);

	}
	else {
		print("b2a_spec, get_binding_length, missing length \n");
		return ();
	}

}

=head2 sub get_file_dialog_type_aref

=cut

sub get_file_dialog_type_aref {

	my ($self) = @_;
	if ( $b2a_spec->{_file_dialog_type_aref} ) {

		my @type = @{ $b2a_spec->{_file_dialog_type_aref} };

		return ( \@type );

	}
	else {
		print(
"b2a_spec,get_file_dialog_type_aref, missing file_dialog_type_aref\n"
		);
		return ();
	}

}

=head2 sub get_flow_type_aref

=cut 

sub get_flow_type_aref {
	my ($self) = @_;
	if ( $b2a_spec->{_flow_type_aref} ) {

		my $type_aref = $b2a_spec->{_flow_type_aref};

		return ($type_aref);

	}
	else {
		print("b2a_spec, get_flow_type_aref, missing flow_type_aref \n");
		return ();
	}
}

=head2 sub get_max_index

=cut

sub get_max_index {

	my ($self) = @_;

	if ( $b2a_spec->{_max_index} ) {

		my $max_idx = $b2a->get_max_index();
		return ($max_idx);

	}
	else {
		print("b2a_spec, get_max_index, missing max_index\n");
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

		for ( my $i = 0 ; $i < $len_1_needed ; $i++ ) {

			print(
"b2a, get_incompatibles,need_only_1:  @{@{$params->{_need_only_1}}[$i]}\n"
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

	if ( $b2a_spec->{_prefix_aref} ) {

		my $prefix_aref = $b2a_spec->{_prefix_aref};
		return ($prefix_aref);

	}
	else {
		print("b2a_spec, get_prefix_aref, missing prefix_aref\n");
		return ();
	}

	return ();
}

=head2 sub get_suffix_aref

=cut

sub get_suffix_aref {

	my ($self) = @_;

	if ( $b2a_spec->{_suffix_aref} ) {

		my $suffix_aref = $b2a_spec->{_suffix_aref};
		return ($suffix_aref);

	}
	else {
		print("b2a_spec, get_suffix_aref, missing suffix_aref\n");
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

	my ($self) = @_;

	my @prefix;

	for ( my $i = 0 ; $i < $max_index ; $i++ ) {

		$prefix[$i] = $empty_string;

	}

	my $index_aref = get_binding_index_aref();
	my @index      = @$index_aref;

	# label 1 in GUI is output xx_file and needs a home directory
	$prefix[ $index[0] ] = '$DATA_SEISMIC_TXT' . ".'/'.";

	$b2a_spec->{_prefix_aref} = \@prefix;
	return ();

}

=head2  sub suffix_aref

Initialize suffixes as empty
Assign specific suffixes to parameter
values

=cut

sub suffix_aref {

	my ($self) = @_;

	my @suffix;

	for ( my $i = 0 ; $i < $max_index ; $i++ ) {

		$suffix[$i] = $empty_string;

	}

	my $index_aref = get_binding_index_aref();
	my @index      = @$index_aref;

	# label 1 in GUI is output xx_file and needs a home directory
	$suffix[ $index[0] ] = '' . '' . '$suffix_txt';

	$b2a_spec->{_suffix_aref} = \@suffix;
	return ();

}

=head2 sub variables

return a hash array
with definitions

=cut

sub variables {

	my ($self) = @_;

	my $hash_ref = $b2a_spec;

	return ($hash_ref);

}

1;
