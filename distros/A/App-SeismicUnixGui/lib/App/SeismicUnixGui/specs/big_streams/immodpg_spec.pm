package App::SeismicUnixGui::specs::big_streams::immodpg_spec;

use Moose;
our $VERSION = '0.0.1';

use App::SeismicUnixGui::misc::SeismicUnix qw($su $suffix_su);
require App::SeismicUnixGui::misc::L_SU_global_constants;
require App::SeismicUnixGui::configs::big_streams::Project_config;

my $L_SU_global_constants  = App::SeismicUnixGui::misc::L_SU_global_constants->new();
my $var                     = $L_SU_global_constants->var();

my $empty_string     = $var->{_empty_string};
my $file_dialog_type = $L_SU_global_constants->file_dialog_type_href();
my $flow_type        = $L_SU_global_constants->flow_type_href();

my $true  			= $var->{_true};
my $false 			= $var->{_false};

my $Project          	= App::SeismicUnixGui::configs::big_streams::Project_config->new();
my $DATA_SEISMIC_SU  	= $Project->DATA_SEISMIC_SU();   # output data directory
my $IMMODPG  			= $Project->IMMODPG();

my $max_index    		= 19;

my $immodpg_spec =  {
    _CONFIG	 				=> $IMMODPG,
    _DATA_DIR_IN           => $DATA_SEISMIC_SU,
	_DATA_DIR_OUT          => $DATA_SEISMIC_SU,
	_binding_index_aref    => '',
    _suffix_type_in        => $su,
    _data_suffix_in        => $suffix_su,
    _suffix_type_out       => $su,
    _data_suffix_out       => $suffix_su,
    _file_dialog_type_aref => '',
    _flow_type_aref        => '',
    _has_infile            => $false,
    _has_pipe_in           => $false,
    _has_pipe_out          => $false,
    _has_redirect_in       => $false,
    _has_redirect_out      => $false,
    _has_subin_in          => $false,
    _has_subin_out         => $false,
    _is_data               => $false,
    _is_first_of_2         => $false,
    _is_first_of_3or_more  => $false,
    _is_first_of_4or_more  => $false,
    _is_last_of_2          => $false,
    _is_last_of_3or_more   => $false,
    _is_last_of_4or_more   => $false,
    _is_suprog             => $false,
    _is_superflow          => $true,
    _max_index             => $max_index,
	_prefix_aref           => '',
    _suffix_aref			=> '',
};

=head2 sub binding_index_aref

out

=cut

sub binding_index_aref {
    my ($self) = @_;
    my @index;

    $index[0] = 0;     # item is  bound to _DATA_DIR_IN

    $immodpg_spec->{_binding_index_aref} = \@index;

    return ();
}

=head2 sub get_binding_index_aref


=cut 

sub get_binding_index_aref {
    my ($self) = @_;
    my @index;

    if ( $immodpg_spec->{_binding_index_aref} ) {
        my $index_aref = $immodpg_spec->{_binding_index_aref};
        return ($index_aref);

    }
    else {
        print(
            "immodpg_spec, get_binding_index_aref, missing binding_index_aref\n"
        );
        return ();
    }

    my $index_aref = $immodpg_spec->{_binding_index_aref};

}

=head2 sub get_max_index

=cut

sub get_max_index {
    my ($self) = @_;

    if ( $immodpg_spec->{_max_index} ) {

        my $max_idx = $immodpg_spec->{_max_index};
        return ($max_idx);

    }
    else {
        print("immodpg_spec, get_max_index, missing max_index\n");
        return ();
    }
}


=head2 sub file_dialog_type_aref

=cut 

sub file_dialog_type_aref {
    my ($self) = @_;

    my @type;

    $type[0] = $file_dialog_type->{_Data};

    $immodpg_spec->{_file_dialog_type_aref} = \@type;

    return ();

}

=head2 sub get_file_dialog_type_aref

=cut 

sub get_file_dialog_type_aref {
    my ($self) = @_;

    if ( $immodpg_spec->{_file_dialog_type_aref} ) {
        my @type = @{ $immodpg_spec->{_file_dialog_type_aref} };
        return ( \@type );
    }
    else {
        print(
"immodpg_spec,get_file_dialog_type_aref, missing file_dialog_type_aref\n"
        );
        return ();
    }
}

=head2 sub flow_type_aref

=cut 

sub flow_type_aref {
    my ($self) = @_;

    my @type;

    $type[0] = $flow_type->{_pre_built_superflow};

    $immodpg_spec->{_flow_type_aref} = \@type;

    return ();

}

=head2 sub get_flow_type_aref

=cut 

sub get_flow_type_aref {
    my ($self) = @_;

    if ( $immodpg_spec->{_flow_type_aref} ) {
        my $type_aref = $immodpg_spec->{_flow_type_aref};
        return ($type_aref);
    }
    else {

        print("immodpg_spec, get_flow_type_aref, missing flow_type_aref \n");
        return ();
    }
}

=head2 sub get_prefix_aref

=cut

 sub get_prefix_aref {

	my $self 	= @_;

	if ( defined $immodpg_spec->{_prefix_aref} ) {

		my $prefix_aref= $immodpg_spec->{_prefix_aref};
		return($prefix_aref);

	} else {
		print("immodpg_spec, get_prefix_aref, missing prefix_aref\n");
		return();
	}

	return();
 }

=head2 sub get_suffix_aref

=cut

 sub get_suffix_aref {

	my $self 	= @_;

	if ($immodpg_spec->{_suffix_aref} ) {

			my $suffix_aref= $immodpg_spec->{_suffix_aref};
			return($suffix_aref);

	} else {
			print("immodpg_spec, get_suffix_aref, missing suffix_aref\n");
			return();
	}

	return();
 }


=head2  sub prefix_aref

=cut

 sub prefix_aref {

	my $self 	= @_;

	my @prefix;

	for (my $i=0; $i < $max_index; $i++) {

		$prefix[$i]	= $empty_string;

	}
	$immodpg_spec ->{_prefix_aref} = \@prefix;
	return();

 }


=head2  sub suffix_aref

=cut

 sub suffix_aref {

	my $self 	= @_;

	my @suffix;

	for (my $i=0; $i < $max_index; $i++) {

		$suffix[$i]	= $empty_string;

	}
	$immodpg_spec ->{_suffix_aref} = \@suffix;
	return();

 }


=head2 sub get_binding_length

=cut 

sub get_binding_length {
    my ($self) = @_;

    if ( $immodpg_spec->{_binding_index_aref} ) {
        my $length;
        $length = scalar @{ $immodpg_spec->{_binding_index_aref} };
        return ($length);

    }
    else {

        print("immodpg_spec, get_binding_length, missing length \n");
        return ();
    }

}

=head2 sub variables

	return a hash array 
	with definitions

=cut

sub variables {
    my ($self) = @_;

    # print("immodpg_spec,variables,
    # first_of_2,$immodpg_spec->{_is_first_of_2}\n");
    my $hash_ref = $immodpg_spec;
    return ($hash_ref);
}

1;
