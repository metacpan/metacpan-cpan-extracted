package App::SeismicUnixGui::specs::plot::suximage_spec;
use Moose;
our $VERSION = '1.0.0';

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use aliased 'App::SeismicUnixGui::sunix::plot::suximage';
use App::SeismicUnixGui::misc::SeismicUnix qw($su $suffix_su);

my $get = L_SU_global_constants->new();
my $var = $get->var();

my $empty_string     = $var->{_empty_string};
my $true             = $var->{_true};
my $false            = $var->{_false};
my $file_dialog_type = $get->file_dialog_type_href();
my $flow_type        = $get->flow_type_href();

my $Project  = Project_config->new();
my $suximage = suximage->new();

my $DATA_SEISMIC_SU = $Project->DATA_SEISMIC_SU();    # output data directory
my $PL_SEISMIC      = $Project->PL_SEISMIC(); # default
my $DATA_SEISMIC_TXT= $Project->DATA_SEISMIC_TXT();
my $max_index       = $suximage->get_max_index();

my $is_absclip = $false;
my $is_loclip  = $false;
my $is_hiclip  = $false;

my $suximage_spec = {
	_CONFIG				   => $PL_SEISMIC,
	_DATA_DIR_OUT          => $DATA_SEISMIC_SU,
	_DATA_DIR_IN 			=> $DATA_SEISMIC_TXT,
	_DATA_DIR_OUT          => $PL_SEISMIC,  # DEFAULT
	_binding_index_aref    => '',
	_suffix_type_in        => $su,
	_data_suffix_in        => $suffix_su,
	_suffix_type_out       => $su,
	_data_suffix_out       => $suffix_su,
	_good_labels_aref      => '',            # new
	_file_dialog_type_aref => '',
	_flow_type_aref        => '',
	_has_infile            => $true,
    _has_outpar            => $false,
	_has_pipe_in           => $true,
	_has_pipe_out          => $false,
	_has_redirect_in       => $true,
	_has_redirect_out      => $false,
	_has_subin_in          => $false,
	_has_subin_out         => $false,
	_is_data               => $false,
	_is_first_of_2         => $true,
	
	_is_first_of_3or_more  => $false,
	_is_first_of_4or_more  => $false,
	_is_last_of_2          => $true,
	_is_last_of_3or_more   => $true,
	_is_last_of_4or_more   => $true,
	_is_suprog             => $true,
	_is_superflow          => $false,
	_max_index             => $max_index,
};

# print("suximage_spec, _incompatibles: @{$suximage_spec->{_incompatibles}} \n");

=head2 sub binding_index_aref

curve, item index = 8, bound to $DATA_SEISMIC_TXT
curvefile, item index = 10, bound to $DATA_SEISMIC_TXT
picks/mpicks, item index = 35, bound to PL_SEISMIC by default

=cut

sub binding_index_aref {

	my ($self) = @_;

	my @index;

	$index[0] = 8;
	$index[1] = 10;
	$index[2] = 35;

	$suximage_spec->{_binding_index_aref} = \@index;

	return ();
}

=head2 sub get_max_index

=cut

sub get_max_index {
	my ($self) = @_;

	if ( $suximage_spec->{_max_index} ) {

		my $max_idx = $suximage->get_max_index();
		return ($max_idx);

	}
	else {
		print("suximage_spec, get_max_index, missing max_index\n");
		return ();
	}
}

=head2 sub set_good_labels       
	 
	set value labels that are good

=cut

sub set_good_labels {
	my ( $self, $good_labels_aref ) = @_;

	$suximage_spec->{_good_labels_aref} = $good_labels_aref;

	return ();
}

=head2 sub find_incompatibles
	not_compatible for the following cases
	is_absclip && (is_loclip || is_hiclip)
	     1             1         
	 
	set value labels that are good

=cut

sub set_incompatibles {
	my ($self) = @_;

	my @good_labels_aref = $suximage_spec->{_good_labels_aref};

	my $length = scalar @good_labels_aref;

	for ( my $j = 0; $j < $length; $j++ ) {

		my $good_label = $good_labels_aref[$j];

		if ( $good_label eq 'absclip' ) {
			$is_absclip = $true;

		}
		elsif ( $good_label eq 'hiclip' ) {
			$is_hiclip = $true;

		}
		elsif ( $good_label eq 'loclip' ) {
			$is_loclip = $true;

		}
		else {
			print("suximage_spec, set_incompatibles, NONE \n");
		}
	}

}

#=head2  sub get_incompatible
#
#	parameters
#
#=cut
#
#sub get_incompatibles {
#	my ($self) = @_;
#
#	my (@needed);
#	my @_need_both		= ();
#	my @_need_only_1	= ();
#	my @_none_needed 	= ();
#	my @_all_needed	 	= ();
#
#	my $params = {
#		_need_both		=> \@_need_both,
#		_need_only_1	=> \@_need_only_1,
#		_none_needed	=> \@_none_needed,
#		_all_needed		=> \@_all_needed,
#	};
#
#	#my $number_groups  = 6;
#
#	my @of_two          		= 	('clip','wperc');
#	push @{$params->{_need_only_1}}	,	\@of_two;
#
#
#
##	print("sugain, get_incomatpibles  $length \n");
#
#	my $len_1_needed = scalar @{$params->{_need_only_1}};
#
#	for (my $i=0; $i < $len_1_needed; $i++) {
#
#		print("sugain, get_incompatibles,need_only_1:  @{@{$params->{_need_only_1}}[$i]}\n");
#
#	}
#
##	print("sugain, get_incomatpibles only_one: @only_one\n");
#
#
#	return($params);
#
#}
#
#
# }
#
#=head2 sub get_incompatibles
#	not_compatible for the following cases
#	is_absclip && (is_loclip || is_hiclip)
#	     1             1
#
#	set value labels that are good
#
#=cut
#
#sub get_incompatibles {
#
#	my ($self) 	= @_;
#
#	if ($is_absclip && ($is_loclip || $is_hiclip)) {
#		print("Warning: Can not have absclip and (hiclip or loclip)\n");
#		return();
#	} else {
#		print("No incompatibles\n");
#	}
# }
#

=head2 sub get_binding_index_aref

=cut

sub get_binding_index_aref {
	my ($self) = @_;
	my @index;

	if ( $suximage_spec->{_binding_index_aref} ) {
		my $index_aref = $suximage_spec->{_binding_index_aref};
		return ($index_aref);

	}
	else {
		print(
			"suximage_spec, get_binding_index_aref, missing binding_index_aref\n"
		);
		return ();
	}

	my $index_aref = $suximage_spec->{_binding_index_aref};

}

=head2 sub file_dialog_type_aref

  type of dialog (Data, Flow, SaveAs) is needed by binding
  one type of dialog for each index

=cut 

sub file_dialog_type_aref {
	my ($self) = @_;

	my @type;

	$type[0] = $file_dialog_type->{_Data};
	$type[1] = $file_dialog_type->{_Data};
	$type[2] = $file_dialog_type->{_Data};    # mpicks bound to PL_SEISMIC directory

	$suximage_spec->{_file_dialog_type_aref} = \@type;

	return ();

}

=head2 sub get_file_dialog_type_aref

=cut 

sub get_file_dialog_type_aref {
	my ($self) = @_;

	if ( $suximage_spec->{_file_dialog_type_aref} ) {
		my @type = @{ $suximage_spec->{_file_dialog_type_aref} };
		return ( \@type );
	}
	else {
		print(
			"suximage_spec,get_file_dialog_type_aref, missing file_dialog_type_aref\n"
		);
		return ();
	}
}

=head2 sub flow_type_aref

=cut 

sub flow_type_aref {
	my ($self) = @_;

	my @type;

	$type[0] = $flow_type->{_user_built};

	$suximage_spec->{_flow_type_aref} = \@type;

	return ();

}

=head2 sub get_binding_length

=cut 

sub get_binding_length {
	my ($self) = @_;

	if ( $suximage_spec->{_binding_index_aref} ) {
		my $length;
		$length = scalar @{ $suximage_spec->{_binding_index_aref} };
		return ($length);

	}
	else {

		print("suximage_spec, get_binding_length, missing length \n");
		return ();
	}

}

=head2 sub get_flow_type_aref

=cut 

sub get_flow_type_aref {
	my ($self) = @_;

	if ( $suximage_spec->{_flow_type_aref} ) {
		my $type_aref = $suximage_spec->{_flow_type_aref};
		return ($type_aref);
	}
	else {

		print("suximage_spec, get_flow_type_aref, missing flow_type_aref \n");
		return ();
	}
}

#
#=head2 incompatible parameters
#	whose product is 1
#
#=cut
#	my @compatible_clips  = ('hiclip','loclip');
#	my @incomp_clips = ('hiclip','loclip','perc','abs');
#
#	my $incompatibles = {
#		_clips  	 	=> \@incomp_clips,
#	};

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
				"suximage, get_incompatibles,need_only_1:  @{@{$params->{_need_only_1}}[$i]}\n"
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

	if ( $suximage_spec->{_prefix_aref} ) {

		my $prefix_aref = $suximage_spec->{_prefix_aref};
		return ($prefix_aref);

	}
	else {
		print("suximage_spec, get_prefix_aref, missing prefix_aref\n");
		return ();
	}

	return ();
}

=head2 sub get_suffix_aref

=cut

sub get_suffix_aref {

	my ($self) = @_;

	if ( $suximage_spec->{_suffix_aref} ) {

		my $suffix_aref = $suximage_spec->{_suffix_aref};
		return ($suffix_aref);

	}
	else {
		print("suximage_spec, get_suffix_aref, missing suffix_aref\n");
		return ();
	}

	return ();
}

=head2  sub prefix_aref

Include in the Set up
sections of an output Poop flow.

prefixes and suffixes to parameter labels
are filtered by sunix_pl

getparstring can not parse 2 complex urve file names
1 curve file name with a PATH prefix will work but not 2
e.g., PREFIX/curve1  PREFIX/curve2

=cut

sub prefix_aref {

	my ($self) = @_;

	my @prefix;

	for ( my $i = 0; $i < $max_index; $i++ ) {

		$prefix[$i] = $empty_string;

	}
	
	my $index_aref = get_binding_index_aref();
	my @index      = @$index_aref;
	$prefix[ $index[0] ] = '$DATA_SEISMIC_TXT' . ".'/'.";
	$prefix[ $index[1] ] = '$DATA_SEISMIC_TXT' . ".'/'.";
	$prefix[ $index[2] ] = "";	
	
	$suximage_spec->{_prefix_aref} = \@prefix;
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

	for ( my $i = 0; $i < $max_index; $i++ ) {

		$suffix[$i] = $empty_string;

	}
	$suximage_spec->{_suffix_aref} = \@suffix;
	return ();

}

=head2 sub variables

	return a hash array 
	with definitions

=cut

sub variables {
	my ($self) = @_;

	# print("suximage_spec,variables,
	# first_of_2,$suximage_spec->{_is_first_of_2}\n");
	my $hash_ref = $suximage_spec;
	return ($hash_ref);
}

1;
