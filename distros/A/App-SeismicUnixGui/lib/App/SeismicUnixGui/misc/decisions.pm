package App::SeismicUnixGui::misc::decisions;

=head1 DOCUMENTATION


=head2 SYNOPSIS 

 PERL PACKAGE NAME: decisions.pm 
 AUTHOR: Juan Lorenzo
 DATE: June 22 2017 

 DESCRIPTION 
     

 BASED ON:
 Version 0.1 April 18 2017  
     Added a simple configuration file readable 
flow
    and writable using Config::Simple (CPAN)

 Version 0.2 
    incorporate more object oriented classes
   
 TODO: Simple (ASCII) local configuration
      file is Project_Variables.config

=cut

=head2 USE

=head3 NOTES
	only sets values internally
	does not modify values that are used outside the package
	used to confirm the suitablility of conditions 
	before proceeding.
	

=head4 Examples


=head2 CHANGES and their DATES

=cut 

=head2 Notes from bash

=cut

use Moose;
our $VERSION = '1.0.0';

=head2 inheritance

=cut

extends 'App::SeismicUnixGui::misc::gui_history' => { -version => 0.0.2 };
use aliased 'App::SeismicUnixGui::misc::gui_history';

=head2 Import modules

=cut

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

=head2 Instantiation

=cut

my $get         = L_SU_global_constants->new();
my $gui_history = gui_history->new();

=head Local variables

=cut

my $flow_type = $get->flow_type_href();

# holds gui_history
my $decisions_href;
my $var          = $get->var();
my $empty_string = $var->{_empty_string};
my $true         = $var->{_true};
my $false        = $var->{_false};

=head2 private hash

27

=cut

my $decisions = {

	_has_used_SaveAs_button                => $false,
	_has_used_Save_button                  => $false,
	_has_used_Save_superflow               => $false,
	_has_used_open_perl_file_button        => $false,
	_is_Delete_file_button                 => $false,
	_is_delete_from_flow_button            => $false,
	_is_delete_whole_flow_button           => $false,
	_is_flow_listbox_grey_w                => $false,
	_is_flow_listbox_pink_w                => $false,
	_is_flow_listbox_green_w               => $false,
	_is_flow_listbox_blue_w                => $false,
	_is_last_flow_index_touched            => $false,
	_is_last_flow_index_touched_grey       => $false,
	_is_last_flow_index_touched_pink       => $false,
	_is_last_flow_index_touched_green      => $false,
	_is_last_flow_index_touched_blue       => $false,
	_is_last_parameter_index_touched_grey  => $false,
	_is_last_parameter_index_touched_pink  => $false,
	_is_last_parameter_index_touched_green => $false,
	_is_last_parameter_index_touched_blue  => $false,
	_is_last_parameter_index_touched_color => $false,
	_is_last_path_touched                  => $false,
	_is_neutral_flow                       => $false,
	_is_open_file_button                   => $false,
	_is_SaveAs_file_button                 => $false,
	_is_select_file_button                 => $false,
	_is_pre_built_superflow                => $false,
	_is_run_select_button                  => $false,
	_is_prog_name                          => $false,
	_is_user_built_flow                    => $false,

};

=head2 sub reset

 
=cut

sub reset {
	my ($self) = @_;

	$decisions = {

		_has_used_SaveAs_button                => $false,
		_has_used_Save_button                  => $false,
		_has_used_Save_superflow               => $false,
		_has_used_open_perl_file_button        => $false,
		_is_Delete_file_button                 => $false,
		_is_delete_from_flow_button            => $false,
		_is_delete_whole_flow_button           => $false,
		_is_flow_listbox_grey_w                => $false,
		_is_flow_listbox_pink_w                => $false,
		_is_flow_listbox_green_w               => $false,
		_is_flow_listbox_blue_w                => $false,
		_is_last_flow_index_touched_grey       => $false,
		_is_last_flow_index_touched_pink       => $false,
		_is_last_flow_index_touched_green      => $false,
		_is_last_flow_index_touched_blue       => $false,
		_is_last_parameter_index_touched_grey  => $false,
		_is_last_parameter_index_touched_pink  => $false,
		_is_last_parameter_index_touched_green => $false,
		_is_last_parameter_index_touched_blue  => $false,
		_is_last_flow_index_touched            => $false,
		_is_last_parameter_index_touched_color => $false,
		_is_last_path_touched                  => $false,
		_is_neutral_flow                       => $false,
		_is_open_file_button                   => $false,
		_is_SaveAs_file_button                 => $false,
		_is_select_file_button                 => $false,
		_is_pre_built_superflow                => $false,
		_is_run_select_button                  => $false,
		_is_prog_name                          => $false,
		_is_user_built_flow                    => $false,

	};
}

=head2 sub _reset


=cut

sub _reset {
	my ($self) = @_;

	$decisions = {

		_has_used_SaveAs_button                => $false,
		_has_used_Save_button                  => $false,
		_has_used_Save_superflow               => $false,
		_has_used_open_perl_file_button        => $false,
		_is_Delete_file_button                 => $false,
		_is_delete_from_flow_button            => $false,
		_is_delete_whole_flow_button           => $false,
		_is_flow_listbox_grey_w                => $false,
		_is_flow_listbox_pink_w                => $false,
		_is_flow_listbox_green_w               => $false,
		_is_flow_listbox_blue_w                => $false,
		_is_last_flow_index_touched            => $false,
		_is_last_flow_index_touched_grey       => $false,
		_is_last_flow_index_touched_pink       => $false,
		_is_last_flow_index_touched_green      => $false,
		_is_last_flow_index_touched_blue       => $false,
		_is_last_parameter_index_touched_grey  => $false,
		_is_last_parameter_index_touched_pink  => $false,
		_is_last_parameter_index_touched_green => $false,
		_is_last_parameter_index_touched_blue  => $false,
		_is_last_parameter_index_touched_color => $false,
		_is_last_path_touched                  => $false,
		_is_open_file_button                   => $false,
		_is_SaveAs_file_button                 => $false,
		_is_select_file_button                 => $false,
		_is_pre_built_superflow                => $false,
		_is_run_select_button                  => $false,
		_is_prog_name                          => $false,
		_is_user_built_flow                    => $false,

	};

}

=head2 sub get4_FileDialog_Delete


=cut

sub get4FileDialog_Delete {
	my ( $self, $hash_ref ) = @_;

	if (
		(
			   $decisions->{_is_flow_listbox_grey_w}
			|| $decisions->{_is_flow_listbox_pink_w}
			|| $decisions->{_is_flow_listbox_green_w}
			|| $decisions->{_is_flow_listbox_blue_w}
			&& $decisions->{_is_Delete_file_button}
		)
	  or ( $decisions->{_is_neutral_flow}
		&& $decisions->{_is_Delete_file_button} )
		)
	{
		return ($true);
	}
	else {
		print(
"decisions,get4FileDialog_Delete,grey: $decisions->{_is_flow_listbox_grey_w}, and pink  listbox: $decisions->{_is_flow_listbox_pink_w}\n"
		);
		print(
"decisions,get4FileDialog_Delete,green: $decisions->{_is_flow_listbox_green_w}, and blue listbox: $decisions->{_is_flow_listbox_blue_w}\n"
		);
		print(
"decisions,get4FileDialog_Delete: decisions->{_is_Delete_file_button}: $decisions->{_is_Delete_file_button}\n"
		);
		return ($false);
	}
}

=head2 sub get4_FileDialog_select


=cut

sub get4FileDialog_select {
	my ( $self, $hash_ref ) = @_;

# print ("decisions,get4FileDialog_select,grey: $decisions->{_is_flow_listbox_grey_w}, and pink  listbox: $decisions->{_is_flow_listbox_pink_w}\n");
# print ("decisions,get4FileDialog_select,green: $decisions->{_is_flow_listbox_green_w}, and blue listbox: $decisions->{_is_flow_listbox_blue_w}\n");
# print ("decisions,get4FileDialog_select,left: decisions->{_is_last_path_touched}: $decisions->{_is_last_path_touched}\n");
# print ("decisions,get4FileDialog_select,left: decisions->{_is_pre_built_superflow}: $decisions->{_is_selected_file_name}\n");
# print ("decisions,get4FileDialog_select,left: decisions->{_is_pre_built_superflow}: $decisions->{_is_selected_path}\n");

	if (
		(
			   $decisions->{_is_flow_listbox_grey_w}
			|| $decisions->{_is_flow_listbox_pink_w}
			|| $decisions->{_is_flow_listbox_green_w}
			|| $decisions->{_is_flow_listbox_blue_w}
			|| $decisions->{_is_pre_built_superflow}
			|| $decisions->{_is_last_path_touched}
		)
		&& (   $decisions->{_is_selected_file_name}
			|| $decisions->{_is_selected_path}
		)    # for data file name, not pl file name

	  )
	{
		return ($true);
	}
	else {
		return ($false);
	}
}

=head2 sub get4FileDialog_open_perl

=cut

sub get4FileDialog_open_perl {
	my ($self) = @_;

	if (
		   $decisions->{_is_open_file_button}
		|| $decisions->{_is_selected_file_name}
		|| !( $decisions->{_is_selected_path}
		)    # for data file name, not pl file name
	  )
	{
		return ($true);
	}
	else {
		return ($false);
	}

	#	if (   $decisions->{_is_flow_listbox_grey_w}
	#		|| $decisions->{_is_flow_listbox_pink_w}
	#		|| $decisions->{_is_flow_listbox_green_w}
	#		|| $decisions->{_is_flow_listbox_blue_w}
	#		|| $decisions->{_is_pre_built_superflow}
	#		|| $decisions->{_is_selected_file_name}
	#		|| !(
	#			$decisions->{_is_selected_path} ) # for data file name, not pl file name
	#		)
	#	{
	#		return ($true);
	#	}
	#	else {
	#		if ( $decisions->{_is_open_file_button} ) {
	#			return ($true);
	#		}
	#	}
}

=head2 sub get4_FileDialog_SaveAs


=cut

sub get4FileDialog_SaveAs {
	my ($self) = @_;

	# can not save a pre-built superflows under arbitrary name
	if ( $decisions->{_is_pre_built_superflow} ) {
		return ($false);

	}
	elsif (
		(
			   $decisions->{_is_flow_listbox_grey_w}
			|| $decisions->{_is_flow_listbox_pink_w}
			|| $decisions->{_is_flow_listbox_green_w}
			|| $decisions->{_is_flow_listbox_blue_w}
			|| $decisions->{_is_flow_listbox_color_w}
		)
		&& $decisions->{_is_SaveAs_file_button}
	  )
	{
		# print("decisions,get4FileDialog_SaveAs: $true\n");

		# print("decisions: \n
		# _is_flow_listbox_grey_ 		= $decisions->{_is_flow_listbox_grey_w}\n
		# _is_flow_listbox_pink_w		= $decisions->{_is_flow_listbox_pink_w}\n
		# _is_flow_listbox_green_w	= $decisions->{_is_flow_listbox_green_w}\n
		# _is_flow_listbox_blue_w		= $decisions->{_is_flow_listbox_blue_w}\n
		# _is_flow_listbox_color_w	= $decisions->{_is_flow_listbox_color_w}\n
		# _is_SaveAs_file_button		= $decisions->{_is_SaveAs_file_button}\n");
		return ($true);

	}
	else {
		print("decisions,get4FileDialog_SaveAs,exception to rules \n");
	}

	return (0);
}

=head2 sub get4flow_select
OK if we are selecting a user-built flow box


=cut

sub get4flow_select {
	my ($self) = @_;

	my $result;

	# print("decisions, get4flow_select, write gui_history.txt\n");
	# $gui_history->view();

	my $most_recent_flow_type =
	  ( ( $gui_history->get_defaults() )->{_flow_type_href} )->{_most_recent};

	if ( $most_recent_flow_type eq $flow_type->{_user_built} ) {

	#		print(
	#			"decisions get4flow_select, prior_flow_type = $most_recent_flow_type \n"
	#		);

		$result = $true;

	}
	elsif ( $most_recent_flow_type eq $flow_type->{_pre_built_superflow} ) {

		$result = $false;
	}
	else {
		print(
			"decisions, get4flow_select, most_recent_flow_type is unknown \n");
	}

	return ($result);

}

#=head2 sub get4flow_select
#
#
#=cut
#
#sub get4flow_select {
#    my ($self) = @_;
#    my @state;
#
#    $state[0] = $decisions->{_is_flow_listbox_grey_w};
#    $state[1] = $decisions->{_is_flow_listbox_pink_w};
#    $state[2] = $decisions->{_is_flow_listbox_green_w};
#    $state[3] = $decisions->{_is_flow_listbox_blue_w};
#
#    #$state[4] = $decisions->{_is_last_flow_index_touched};
#    #$state[5] = $decisions->{_is_last_parameter_index_touched_color};
#    # $state[12] = $decisions->{_is_prog_name};
#
#    $state[4] = $decisions->{_is_last_flow_index_touched_grey};
#    $state[5] = $decisions->{_is_last_flow_index_touched_pink};
#    $state[6] = $decisions->{_is_last_flow_index_touched_green};
#    $state[7] = $decisions->{_is_last_flow_index_touched_blue};
#
#    $state[8]  = $decisions->{_is_last_parameter_index_touched_grey};
#    $state[9]  = $decisions->{_is_last_parameter_index_touched_pink};
#    $state[10] = $decisions->{_is_last_parameter_index_touched_green};
#    $state[11] = $decisions->{_is_last_parameter_index_touched_blue};
#
#    my $condition1 = ( $state[0] || $state[1] || $state[2]  || $state[3] );
#    my $condition2 = ( $state[4] || $state[5] || $state[6]  || $state[7] );
#    my $condition3 = ( $state[8] || $state[9] || $state[10] || $state[11] );
#
#    if ( $condition1 && $condition2 && $condition3 && $state[12] ) {
#
##    if ( ($state[0] || $state[1] || $state[2] || $state[3]) &&
##    	($state[4] && $state[5] && $state[12])  ) {
# print(" decisions,get4flow_select, state is true: $true\n");
##  print(" decisions,get4flow_select, TRUE states:
##  0:$state[0],1:$state[1],02:$state[2],3:$state[3]
##  ,4:$state[4],05:$state[5],06:$state[6],07:$state[7],08:$state[8],09:$state[9],
##  10:$state[10],11:$state[11],12:$state[12]\n");
#
#        return ($true);
#
#    }
#    else {
# print("decisions,get4flow_select, state is false: $false\n");
# print(" decisions,get4flow_select, FALSE states:
#   0:$state[0],1:$state[1],02:$state[2],3:$state[3]
#   ,4:$state[4],05:$state[5],06:$state[6],07:$state[7],08:$state[8],09:$state[9],
#   10:$state[10],11:$state[11],12:$state[12]\n");
#        return ($false);
#    }
#}

=head2 sub get4delete_from_flow_button

foreach my $key (sort keys %$decisions) {
     print ("decisions,get4delete_from_flow_button4,key is $key, value is $decisions->{$key}\n");
   }
   
=cut

sub get4delete_from_flow_button {
	my ($self) = @_;
	my @state;

	$state[1] = $decisions->{_is_flow_listbox_grey_w};
	$state[2] = $decisions->{_is_flow_listbox_pink_w};
	$state[3] = $decisions->{_is_flow_listbox_green_w};
	$state[4] = $decisions->{_is_flow_listbox_blue_w};
	$state[5] = $decisions->{_is_flow_listbox_color_w};
	$state[6] = $decisions->{_is_delete_from_flow_button};

	if ( ( $state[1] || $state[2] || $state[3] || $state[4] || $state[5] )
		&& $state[6] )
	{
		# print(" decisions,get4delete_from_flow_button, state is $true\n");
		return ($true);
	}
	else {
		print(" decisions,get4delete_from_flow_button, state is $false\n");
		return ($false);
	}
}

=head2 sub get4delete_whole_flow_button

=cut

sub get4delete_whole_flow_button {
	my ($self) = @_;
	my @state;

	$state[1] = $decisions->{_is_flow_listbox_grey_w};
	$state[2] = $decisions->{_is_flow_listbox_pink_w};
	$state[3] = $decisions->{_is_flow_listbox_green_w};
	$state[4] = $decisions->{_is_flow_listbox_blue_w};
	$state[5] = $decisions->{_is_flow_listbox_color_w};
	$state[6] = $decisions->{_is_delete_whole_flow_button};

	if ( ( $state[1] || $state[2] || $state[3] || $state[4] || $state[5] )
		&& $state[6] )
	{
		# print(" decisions,get4delete_whole_flow_button, state is $true\n");
		return ($true);
	}
	else {
		print(" decisions,get4delete_whole_flow_button, state is $false\n");
		print(
			" decisions,get4delete_whole_flow_button, \n
		state[1]=$state[1],state[2]=$state[2],state[3]=$state[3]],state[4]=$state[4]\n
		],state[5]=$state[5],state[6]=$state[6]\n"
		);
		return ($false);
	}
}

=head2 sub get4help


=cut

sub get4help {
	my ($self) = @_;
	my @state;

	$state[0] = $decisions->{_is_flow_listbox_grey_w};
	$state[1] = $decisions->{_is_flow_listbox_pink_w};
	$state[2] = $decisions->{_is_flow_listbox_green_w};
	$state[3] = $decisions->{_is_flow_listbox_blue_w};

	$state[4] = $decisions->{_is_last_flow_index_touched_grey};
	$state[5] = $decisions->{_is_last_flow_index_touched_pink};
	$state[6] = $decisions->{_is_last_flow_index_touched_green};
	$state[7] = $decisions->{_is_last_flow_index_touched_blue};

	$state[8]  = $decisions->{_is_last_parameter_index_touched_grey};
	$state[9]  = $decisions->{_is_last_parameter_index_touched_pink};
	$state[10] = $decisions->{_is_last_parameter_index_touched_green};
	$state[11] = $decisions->{_is_last_parameter_index_touched_blue};

	$state[12] = $decisions->{_is_prog_name};

	$state[13] = $decisions->{_is_sunix_listbox};
	$state[14] = $decisions->{_is_pre_built_superflow};
	$state[15] = $decisions->{_is_sunix_listbox};

	#	$state[4] = $decisions->{_is_last_flow_index_touched};
	#	$state[5] = $decisions->{_is_last_parameter_index_touched_color};
	#	$state[6] = $decisions->{_is_prog_name};
	#	$state[7] = $decisions->{_is_sunix_listbox};
	#	$state[8] = $decisions->{_is_pre_built_superflow};

# print("decisions,get4help,states:$state[0],$state[1],$state[2],$state[3],$state[4],$state[5],$state[6],$state[7],$state[8]\n");
# print("decisions,get4help,states:$state[9],$state[10],$state[11],$state[12],$state[13],$state[14],$state[15]\n");

	my $condition1 = ( $state[0] || $state[1] || $state[2]  || $state[3] );
	my $condition2 = ( $state[4] || $state[5] || $state[6]  || $state[7] );
	my $condition3 = ( $state[8] || $state[9] || $state[10] || $state[11] );
	my $condition4 = ( $condition2 && $condition3 && $state[12] );
	my $condition5 = $condition1 && $condition4;

	#	my $condition 	=  ( ($state[0] || $state[1] || $state[2] || $state[3])
	#					 && ($state[4] && $state[5] && $state[6]) );

	if ( $condition5 || $state[13] || $state[14] || $state[15] ) {

		# if ( $condition || $state[7] ||$state[8] ) {
		# print(" decisions,get4help, state is true: $true\n");

		return ($true);

	}
	else {
		# print("decisions,get4help, state is false: $false\n");
		print("decisions,get4help, state is false: $false\n");
		print(
			" decisions,get4flow_select, states: 
		0:$state[0],1:$state[1],02:$state[2],3:$state[3]
		,4:$state[4],05:$state[5],06:$state[6],07:$state[7]
		,8:$state[8],09:$state[9],10:$state[10],11:$state[11],12:$state[12]
		,13:$state[13],14:$state[14],15:$state[15]\n"
		);

		return ($false);
	}
}

=head2 sub get4run_select


=cut

sub get4run_select {
	my ($self) = @_;
	my @state;
	$state[1] = $decisions->{_has_used_SaveAs_button};
	$state[2] = $decisions->{_has_used_Save_button};
	$state[3] = $decisions->{_has_used_Save_superflow};
	$state[4] = $decisions->{_has_used_open_perl_file_button};

	if ( $state[1] || $state[2] || $state[3] || $state[3] ) {

		# print(" decisions,get4run_select, state is $true\n");
		return ($true);
	}
	else {
		# print(" decisions,get4run_select, state is $false\n");
		return ($false);
	}
}

=head2 sub set4_FileDialog_Delete


=cut

sub set4FileDialog_Delete {
	my ( $self, $hash_ref ) = @_;
	_reset();

	$decisions->{_is_Delete_file_button} = $hash_ref->{_is_Delete_file_button};
	$decisions->{_is_neutral_flow}       = $hash_ref->{_is_neutral_flow};
	$decisions->{_is_flow_listbox_grey_w} =
	  $hash_ref->{_is_flow_listbox_grey_w};
	$decisions->{_is_flow_listbox_pink_w} =
	  $hash_ref->{_is_flow_listbox_pink_w};
	$decisions->{_is_flow_listbox_green_w} =
	  $hash_ref->{_is_flow_listbox_green_w};
	$decisions->{_is_flow_listbox_blue_w} =
	  $hash_ref->{_is_flow_listbox_blue_w};
	$decisions->{_is_pre_built_superflow} =
	  $hash_ref->{_is_pre_built_superflow};
	$decisions->{_is_user_built_superflow} =
	  $hash_ref->{_is_user_built_superflow};

# print("decisions, set4FileDialog_Delete, decisions->{_is_Delete_file_button}: $decisions->{_is_Delete_file_button}\n");
# print("decisions, set4FileDialog_Delete, decisions->{_is_flow_listbox_grey_w}: $decisions->{_is_flow_listbox_grey_w}\n");
# print("decisions, set4FileDialog_Delete, decisions->{_is_flow_listbox_green_w}: $decisions->{_is_flow_listbox_green_w} \n");
# print("decisions, set4FileDialog_Delete, decisions->{_is_pre_built_superflow}: $decisions->{_is_pre_built_superflow}\n");
# print("decisions, set4FileDialog_Delete, decisions->{_is_user_built_flow}: $decisions->{_is_user_built_flow}\n");

	return ($empty_string);

}

=head2 sub set4_FileDialog_select

	my $selected_file_name = $hash_ref->{_selected_file_name};
	print("decisions,selected_file_name:$selected_file_name\n"); 

	if ( $selected_file_name ne '') {
		$decisions->{_is_selected_file_name}  = $true; 
	}

=cut

sub set4FileDialog_select {
	my ( $self, $hash_ref ) = @_;
	_reset();

	$decisions->{_is_flow_listbox_grey_w} =
	  $hash_ref->{_is_flow_listbox_grey_w};
	$decisions->{_is_flow_listbox_pink_w} =
	  $hash_ref->{_is_flow_listbox_pink_w};
	$decisions->{_is_flow_listbox_green_w} =
	  $hash_ref->{_is_flow_listbox_green_w};
	$decisions->{_is_flow_listbox_blue_w} =
	  $hash_ref->{_is_flow_listbox_blue_w};
	$decisions->{_is_flow_listbox_color_w} =
	  $hash_ref->{_is_flow_listbox_color_w};
	$decisions->{_is_pre_built_superflow} =
	  $hash_ref->{_is_pre_built_superflow};
	$decisions->{_is_selected_file_name} = $hash_ref->{_is_selected_file_name};
	$decisions->{_is_selected_path}      = $hash_ref->{_is_selected_path};

	if ( $hash_ref->{_last_path_touched} ne '' ) {
		$decisions->{_is_last_path_touched} = $true;

# print ("decisions, set4FileDialog_select,last_path_touched:$hash_ref->{_last_path_touched}\n");
	}

# print ("decisions, set4FileDialog_select,left and right listbox:$decisions->{_is_flow_listbox_grey_w} , $decisions->{_is_flow_listbox_green_w} superflow is $decisions->{_is_pre_built_superflow}	selected_file_name= $decisions->{_is_selected_file_name}\n");

	return ($empty_string);

}

=head2 sub set4FileDialog_open_perl

=cut

sub set4FileDialog_open_perl {
	my ( $self, $hash_ref ) = @_;

	_reset();
	$decisions->{_is_open_file_button} = $hash_ref->{_is_open_file_button};
	$decisions->{_is_flow_listbox_grey_w} =
	  $hash_ref->{_is_flow_listbox_grey_w};
	$decisions->{_is_flow_listbox_pink_w} =
	  $hash_ref->{_is_flow_listbox_pink_w};
	$decisions->{_is_flow_listbox_green_w} =
	  $hash_ref->{_is_flow_listbox_green_w};
	$decisions->{_is_flow_listbox_blue_w} =
	  $hash_ref->{_is_flow_listbox_blue_w};

	#	$decisions->{_is_pre_built_superflow} =
	#		$hash_ref->{_is_pre_built_superflow};
	$decisions->{_is_selected_file_name} = $hash_ref->{_is_selected_file_name};
	$decisions->{_is_selected_path}      = $hash_ref->{_is_selected_path};

	#	print("decisions, set4FileDialog_open_perl\n");
	#	foreach my $key (sort keys %$decisions) {
	#   		print (" decisions key is $key, value is $decisions->{$key}\n");
	#   }

	return ($empty_string);

}

=head2 sub set4_FileDialog_SaveAs


=cut

sub set4FileDialog_SaveAs {
	my ( $self, $hash_ref ) = @_;
	_reset();

	$decisions->{_is_SaveAs_file_button} = $hash_ref->{_is_SaveAs_file_button};
	$decisions->{_is_flow_listbox_grey_w} =
	  $hash_ref->{_is_flow_listbox_grey_w};
	$decisions->{_is_flow_listbox_pink_w} =
	  $hash_ref->{_is_flow_listbox_pink_w};
	$decisions->{_is_flow_listbox_green_w} =
	  $hash_ref->{_is_flow_listbox_green_w};
	$decisions->{_is_flow_listbox_blue_w} =
	  $hash_ref->{_is_flow_listbox_blue_w};
	$decisions->{_is_pre_built_superflow} =
	  $hash_ref->{_is_pre_built_superflow};
	$decisions->{_is_user_built_superflow} =
	  $hash_ref->{_is_user_built_superflow};

# print("decisions, set4FileDialog_SaveAs, decisions->{_is_SaveAs_file_button}: $decisions->{_is_SaveAs_file_button}\n");
# print("decisions, set4FileDialog_SaveAs, decisions->{_is_flow_listbox_grey_w}: $decisions->{_is_flow_listbox_grey_w}\n");
# print("decisions, set4FileDialog_SaveAs, decisions->{_is_flow_listbox_green_w}: $decisions->{_is_flow_listbox_green_w} \n");
# print("decisions, set4FileDialog_SaveAs, decisions->{_is_pre_built_superflow}: $decisions->{_is_pre_built_superflow}\n");
# print("decisions, set4FileDialog_SaveAs, decisions->{_is_user_built_flow}: $decisions->{_is_user_built_flow}\n");

	return ($empty_string);

}

=head2 sub set4delete_from_flow_button


=cut

sub set4delete_from_flow_button {
	my ( $self, $hash_ref ) = @_;
	_reset();

	$decisions->{_is_flow_listbox_grey_w} =
	  $hash_ref->{_is_flow_listbox_grey_w};
	$decisions->{_is_flow_listbox_pink_w} =
	  $hash_ref->{_is_flow_listbox_pink_w};
	$decisions->{_is_flow_listbox_green_w} =
	  $hash_ref->{_is_flow_listbox_green_w};
	$decisions->{_is_flow_listbox_blue_w} =
	  $hash_ref->{_is_flow_listbox_blue_w};
	$decisions->{_is_flow_listbox_color_w} =
	  $hash_ref->{_is_flow_listbox_color_w};
	$decisions->{_is_delete_from_flow_button} =
	  $hash_ref->{_is_delete_from_flow_button};

	return ($empty_string);
}

=head2 sub set4delete_whole_flow_button

=cut

sub set4delete_whole_flow_button {
	my ( $self, $hash_ref ) = @_;
	_reset();

	$decisions->{_is_flow_listbox_grey_w} =
	  $hash_ref->{_is_flow_listbox_grey_w};
	$decisions->{_is_flow_listbox_pink_w} =
	  $hash_ref->{_is_flow_listbox_pink_w};
	$decisions->{_is_flow_listbox_green_w} =
	  $hash_ref->{_is_flow_listbox_green_w};
	$decisions->{_is_flow_listbox_blue_w} =
	  $hash_ref->{_is_flow_listbox_blue_w};
	$decisions->{_is_flow_listbox_color_w} =
	  $hash_ref->{_is_flow_listbox_color_w};
	$decisions->{_is_delete_whole_flow_button} =
	  $hash_ref->{_is_delete_whole_flow_button};

	return ($empty_string);
}

=head2 sub set4flow_select
Account for null prog_name case

=cut

sub set4flow_select {
	my ( $self, $hash_ref ) = @_;

	if ($hash_ref) {

		$decisions->{_is_flow_listbox_grey_w} =
		  $hash_ref->{_is_flow_listbox_grey_w};
		$decisions->{_is_flow_listbox_pink_w} =
		  $hash_ref->{_is_flow_listbox_pink_w};
		$decisions->{_is_flow_listbox_green_w} =
		  $hash_ref->{_is_flow_listbox_green_w};
		$decisions->{_is_flow_listbox_blue_w} =
		  $hash_ref->{_is_flow_listbox_blue_w};
		$decisions->{_is_last_flow_index_touched} =
		  $hash_ref->{_is_last_flow_index_touched};
		$decisions->{_is_last_flow_index_touched_grey} =
		  $hash_ref->{_is_last_flow_index_touched_grey};
		$decisions->{_is_last_flow_index_touched_pink} =
		  $hash_ref->{_is_last_flow_index_touched_pink};
		$decisions->{_is_last_flow_index_touched_green} =
		  $hash_ref->{_is_last_flow_index_touched_green};
		$decisions->{_is_last_flow_index_touched_blue} =
		  $hash_ref->{_is_last_flow_index_touched_blue};
		$decisions->{_is_last_parameter_index_touched_grey} =
		  $hash_ref->{_is_last_parameter_index_touched_grey};
		$decisions->{_is_last_parameter_index_touched_pink} =
		  $hash_ref->{_is_last_parameter_index_touched_pink};
		$decisions->{_is_last_parameter_index_touched_green} =
		  $hash_ref->{_is_last_parameter_index_touched_green};
		$decisions->{_is_last_parameter_index_touched_blue} =
		  $hash_ref->{_is_last_parameter_index_touched_blue};
		$decisions->{_is_last_parameter_index_touched_color} =
		  $hash_ref->{_is_last_parameter_index_touched_color};

		if ( defined $hash_ref->{_prog_name_sref} )
		{    # does it have *_spec.pm and regular *.pm
			$decisions->{_is_prog_name} = $true;
		}
		else {
			print(
"\n1. decisions, set4flow_select, program does not have spec.pm:---$decisions->{_is_prog_name}---\n"
			);
			$decisions->{_is_prog_name} = $false;
		}

# print("\n1. decisions, set4flow_select, program name is---$decisions->{_is_prog_name}---\n");
# print(" decisions,set4flow_select, left and right listbox are $decisions->{_is_flow_listbox_grey_w}$decisions->{_is_flow_listbox_green_w}\n");
	}

	return ($empty_string);
}

sub set_hash_ref {
	my ( $self, $hash_ref ) = @_;

	$gui_history->set_defaults($hash_ref);
	$decisions_href = $gui_history->get_defaults();

	return ($empty_string);
}

=head2 sub set4help


=cut

sub set4help {
	my ( $self, $hash_ref ) = @_;

	if ($hash_ref) {

		$decisions->{_is_flow_listbox_grey_w} =
		  $hash_ref->{_is_flow_listbox_grey_w};
		$decisions->{_is_flow_listbox_pink_w} =
		  $hash_ref->{_is_flow_listbox_pink_w};
		$decisions->{_is_flow_listbox_green_w} =
		  $hash_ref->{_is_flow_listbox_green_w};
		$decisions->{_is_flow_listbox_blue_w} =
		  $hash_ref->{_is_flow_listbox_blue_w};
		$decisions->{_is_last_flow_index_touched_grey} =
		  $hash_ref->{_is_last_flow_index_touched_grey};
		$decisions->{_is_last_flow_index_touched_pink} =
		  $hash_ref->{_is_last_flow_index_touched_pink};
		$decisions->{_is_last_flow_index_touched_green} =
		  $hash_ref->{_is_last_flow_index_touched_green};
		$decisions->{_is_last_flow_index_touched_blue} =
		  $hash_ref->{_is_last_flow_index_touched_blue};
		$decisions->{_is_last_parameter_index_touched_grey} =
		  $hash_ref->{_is_last_parameter_index_touched_grey};
		$decisions->{_is_last_parameter_index_touched_pink} =
		  $hash_ref->{_is_last_parameter_index_touched_pink};
		$decisions->{_is_last_parameter_index_touched_green} =
		  $hash_ref->{_is_last_parameter_index_touched_green};

		$decisions->{_is_last_flow_index_touched} =
		  $hash_ref->{_is_last_flow_index_touched};
		$decisions->{_is_last_parameter_index_touched_color} =
		  $hash_ref->{_is_last_parameter_index_touched_color};
		$decisions->{_is_sunix_listbox} = $hash_ref->{_is_sunix_listbox};
		$decisions->{_is_pre_built_superflow} =
		  $hash_ref->{_is_pre_built_superflow};

		if ( $hash_ref->{_prog_name_sref} ) {
			$decisions->{_is_prog_name} = $true;
		}
		else {
# print("\n1. decisions, set4help, program name is---$decisions->{_is_prog_name}---\n");
			$decisions->{_is_prog_name} = $false;
		}

# print("\n1. decisions, set4help program name is---$decisions->{_is_prog_name}---\n");
# print(" decisions,set4help, left and right listbox are $decisions->{_is_flow_listbox_grey_w}$decisions->{_is_flow_listbox_green_w}\n");
	}

	return ($empty_string);
}

=head2 sub set4run_select

	used by both pre-built superflows and user-built flows

=cut

sub set4run_select {
	my ( $self, $hash_ref ) = @_;
	_reset();    #OK JML

	$decisions->{_has_used_SaveAs_button} =
	  $hash_ref->{_has_used_SaveAs_button};
	$decisions->{_has_used_Save_button} = $hash_ref->{_has_used_Save_button};
	$decisions->{_has_used_Save_superflow} =
	  $hash_ref->{_has_used_Save_superflow};
	$decisions->{_has_used_open_perl_file_button} =
	  $hash_ref->{_has_used_open_perl_file_button};
	$decisions->{_is_Save_button} = $hash_ref->{_is_Save_button};

# print("decisions,set4run_select, _has_used_SaveAs_button= $decisions->{_has_used_SaveAs_button} \n");
# print("decisions,set4run_select, _has_used_Save_button= $decisions->{_has_used_Save_button} \n");
# print("decisions,set4run_select, _is_Save_button= $decisions->{_is_Save_button} \n");
	return ($empty_string);

}

1;
