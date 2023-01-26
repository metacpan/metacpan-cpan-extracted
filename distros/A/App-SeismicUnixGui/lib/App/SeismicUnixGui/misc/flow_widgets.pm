package App::SeismicUnixGui::misc::flow_widgets;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PACKAGE NAME: 

 AUTHOR: Juan Lorenzo

 DATE:

 DESCRIPTION:
 Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES

=head2 CHANGES and their DATES
   V0.1.2 refactoring superflows and user-built flows
   August 3 2018
   V0.1.3 Dec 2 2018 reordered methods alphabetically
   added get_num_indices

=cut 

use Moose;
our $VERSION = '0.1.3';
use Tk;
use Tk::DragDrop;
use Tk::DropSite;
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get                 = L_SU_global_constants->new();
my $default_param_specs = $get->param();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

=head2 private hash references

	16

=cut

my $flow_widgets = {
	_current_get_flow_selection_index => '',
	_first_index                      => '',
	_first_item                       => '',
	_flow_listbox_wref                => '',
	_index                            => '',
	_index2delete                     => '',
	_labels_aref                      => '',
	_labels_w_aref                    => '',
	_last_index                       => '',
	_last_item                        => '',
	_num_items                        => '',
	_all_items_aref                   => '',
};

my $true  = 1;
my $false = 0;

=head2 p sub _reset

	16

=cut

 sub _reset {
 	
 	my ($self) = @_;
 	
	$flow_widgets->{_current_get_flow_selection_index} =  ''; 
	$flow_widgets->{_first_index} =  ''; 
	$flow_widgets->{_first_item } =  ''; 
	$flow_widgets->{_flow_listbox_wref} =  ''; 
	$flow_widgets->{_index} =  ''; 
	$flow_widgets->{_index2delete} =  ''; 
	$flow_widgets->{_labels_aref} =  ''; 
	$flow_widgets->{_labels_w_aref} =  ''; 
	$flow_widgets->{_last_index} =  ''; 
	$flow_widgets->{_last_item} =  ''; 
	$flow_widgets->{_num_items} =  ''; 
	$flow_widgets->{_all_items_aref} =  ''; 
	
	return();
};

=head2 sub clear

 delete ALL items
 from the listbox

=cut

sub clear {

	my ( $self, $flow_listbox_w ) = @_;

	if ($flow_listbox_w) {
		
		my $first_index  = 0;	
		$flow_listbox_w->delete( $first_index, 'end');
	  _reset();

	} else {
		print("2. flow_widgets, clear, missing flow_listbox_w\n");
	}
	return ();
}

=head2 sub clear_flow_item 

 empty flow item hash

=cut

sub clear_flow_item {

	my ( $self, $flow_listbox_w ) = @_;

	if ($flow_listbox_w) {

		my $flow_listbox = $flow_listbox_w;
		my $num_items    = $flow_listbox->size();
		my $first_index  = 0;

		$flow_widgets->{_first_index}       = $first_index;
		$flow_widgets->{_flow_listbox_wref} = $flow_listbox;
		$flow_widgets->{_num_items}         = $num_items;

		# must become an empty listbox
		if ( $num_items == 1 ) {

			my $last_item = $flow_listbox->get('end');
			$flow_widgets->{_last_item} = $last_item;
			my $first_item     = $flow_listbox->get($first_index);
			my $last_index     = $num_items - 1;
			my $all_items_aref = $flow_listbox->get( $first_index, 'end' );
			
			$flow_listbox_w->delete( $first_index, $last_index );
			$flow_widgets->{_all_items_aref} = $all_items_aref;
			$flow_widgets->{_last_index}     = $last_index;
			$flow_widgets->{_first_item}     = $first_item;

			print("flow_widgets,clear_flow_items,last item: is $last_item\n");
			print("flow_widgets,clear_flow_items,num_items: is $num_items\n");
			print("flow_widgets,clear_flow_items,first_item: is $first_item\n");

			return ();

		} else {

			# print ("flow_widgets,clear_flow_items, $num_items is unexpected--NADA\n");
			return ();
		}
	} else {
		print("flow_widgets,clear_flow_items, missing flow_listbox_w\n");
		return ();
	}
}

=head2 sub clear_items_versions_aref

=cut

sub clear_items_versions_aref {

	my ($self) = @_;

	my @version;
	my ( $length, $clear_items_versions_aref );
	my (@items_aref);

	# print("flow_widgets,clear_items_versions_aref,flow_widgets->{_all_items_aref} }= @{ $flow_widgets->{_all_items_aref} }\n");

	@items_aref = @{ $flow_widgets->{_all_items_aref} };
	$length     = $flow_widgets->{_last_index} + 1;


	# initialize an array of zeroes
	for ( my $i = 0; $i < $length; $i++ ) {

		$version[$i] = 0;
	}

	# print("flow_widgets,clear_items_versions_aref:versions= @version\n");

	#loop through all items in the flow listbox
	for ( my $current = 0; $current < $length; $current++ ) {

		$version[$current] = $version[$current] + 1;

		# print("flow_widgets,clear_items_versions_aref,current: @{$flow_widgets->{_all_items_aref}}[$current]\n");

		#loop from current to last item
		for ( my $next = $current + 1; $next < $length; $next++ ) {

			my $instances = 1;

			if ( $items_aref[$current] eq $items_aref[$next] ) {
				$version[$next] = $version[$next] + 1;
			}

			# print("flow_widgets,clear_items_versions_aref,next: @{$flow_widgets->{_all_items_aref}}[$next]\n");
		}

	}    # end loop over all items in flow listbox

	# print("flow_widgets,clear_items_versions_aref:versions @version\n");
	# print("flow_widgets,clear_items_versions_aref,next: @{$flow_widgets->{_all_items_aref}}\n");

	return ( \@version );
}

#=head2
#
#   silly limits because of weird drag and drop behavior
#   counter can increase ( impleis deleting) but can not
#   decrease .. imy arbitrary limit
#
#=cut
#
#sub dec_vigil_on_delete_counter {
#	my ( $self, $value ) = @_;
#	my $new_counter = $flow_widgets->{_leave_dropsite} - $value;
#	$flow_widgets->{_leave_dropsite} = $new_counter;
#
#	# print("flow_widgets, dec_vigil_on_delete_counter, count=$flow_widgets->{_leave_dropsite}\n");
#	return ();
#}

sub delete_selection {
	my ( $self, $flow_listbox_w ) = @_;

	# print("flow_widgets, delete_selection, delete is active\n");
	# print("Before deletion flow_widgets, delete_selection, \n last item: $flow_widgets->{_last_item}\n num_items:$flow_widgets->{_num_items}\n last_index:$flow_widgets->{_last_index}\n");

	# for index to delete
	$flow_widgets->{_index2delete} = $flow_widgets->{_current_get_flow_selection_index};

	# print("flow_widgets,delete_selection,index2delete:$flow_widgets->{_index2delete}\n");
	my $index2delete = $flow_widgets->{_index2delete};

	# move selection one up
	if ( $index2delete >= 0 ) {    # move selection one up
		if ( $index2delete > 0 ) {

			# print("1. flow_widgets, delete_selection deleted index is $index2delete\n");
			$flow_listbox_w->delete($index2delete);

			;                      # last item to delete
								   # update private variables
			$flow_widgets->{_last_item}  = $flow_listbox_w->get('end');
			$flow_widgets->{_num_items}  = $flow_widgets->{_num_items} - 1;
			$flow_widgets->{_last_index} = $flow_widgets->{_last_index} - 1;

		}    # index to delete is 0 but not the last item
		elsif ( $flow_widgets->{_last_index} > $index2delete ) {
			$flow_listbox_w->delete($index2delete);
			$flow_listbox_w->selectionSet($index2delete);    # at index=0
															 # update private variables
			$flow_widgets->{_last_item}  = $flow_listbox_w->get('end');
			$flow_widgets->{_num_items}  = $flow_widgets->{_num_items} - 1;
			$flow_widgets->{_last_index} = $flow_widgets->{_last_index} - 1;

		}    # index to delete is 0 and it is the last item
		else {
			$flow_listbox_w->delete($index2delete);
			$flow_widgets->{_last_item}  = 'nu';
			$flow_widgets->{_num_items}  = $flow_widgets->{_num_items} - 1;     #=0
			$flow_widgets->{_last_index} = $flow_widgets->{_last_index} - 1;    #=-1
				# print("2. flow_widgets, delete_selection, deleted index: is $index2delete..\n");
		}
	}

	# print("3.After deletion flow_widgets,delete_selection,\nlast item: $flow_widgets->{_last_item}\n num_items,$flow_widgets->{_num_items}\n last_index $flow_widgets->{_last_index}\n");

	return ();
}

sub destination_index {
	my $self              = @_;
	my $destination_index = $flow_widgets->{_chosen_index2drop};
	return ($destination_index);
}

=head2 sub get_index2delete


=cut

sub get_index2delete {

	my ($self) = @_;
	return ( $flow_widgets->{_index2delete} );

}

=head2 sub get_current_program

 from the current listbox
 returns a scalar reference to the element selected
 fromt the list box

=cut

sub get_current_program {

	my ( $self, $widget_ref ) = @_;

	my @selection_index = $$widget_ref->curselection;

	# print("flow_widgets,get_current_program, selection index is @selection_index \n");

	if (@selection_index) {    # if defined

		if ( @selection_index >= 0 ) {

			my $prog_name = $$widget_ref->get( $selection_index[0] );

			# print("1. flow_widgets  get_current_program program name is $prog_name\n");
			return ( \$prog_name );

		} else {
			print("flow_widgets,get_current_program, unexpected selection index:@selection_index \n");
			return ();
		}

	} else {    # no item selected or no items exist

		# make sure that the first flow item exists,
		# (TODO) and that you have not changed color
		my $flow_listbox_color_w = $$widget_ref;
		my $flow_num_items       = $flow_listbox_color_w->size();

		# print("2. flow_widgets,get_current_program, flow_num_items=$flow_num_items\n");

		if ( $flow_num_items > 0 ) {
			my $index        = $flow_num_items - 1;                  # unfounded assumption.. possible future error
			my $program_name = $flow_listbox_color_w->get($index);
			my $result       = $program_name;
			return ( \$result );

		} else {

			# print("flow_widgets,get_current_program, unexpected num_items=$flow_num_items\n");

			# print("flow_widgets,get_current_program, Perhaps null selection index\n");
			return ();
		}

	}

}

=head2 sub get_flow_selection

  estimates the index lselected in the listbox
  the first item has an index=0
  


=cut

sub get_flow_selection {
	my ( $self, $flow_listbox_w ) = @_;

	if ( $flow_listbox_w ne $empty_string ) {

		# print("flow_widgets,get_flow_selection, flow_listbox_w: $flow_listbox_w\n");

		my @selection_index = $flow_listbox_w->curselection;

		if (@selection_index) {

			# print("flow_widgets,get_flow_selection,selection_index= @selection_index\n");
			$flow_widgets->{_flow_listbox_wref} = $flow_listbox_w;
			my $current_selected_index = $selection_index[0];

			$flow_widgets->{_current_get_flow_selection_index} = $current_selected_index;

			# print("flow_widgets,get_flow_selection--is integer: $current_selected_index\n");

			return ($current_selected_index);

		} else {

			# print("flow_widgets,get_flow_selection,selection_index is missing, need to select an item again NADA\n");
			return ();
		}

	} else {

		# print("flow_widgets,get_flow_selection, missing flow_listbox widget returns -1\n");
		my $result = -1;
		return ($result);
	}

}

=head2 get_num_indices

 how many (items-1) are there in a listbox
 input is a widget 
 output is a scalar

=cut

sub get_num_indices {

	my ( $self, $flow_listbox_w ) = @_;

	if ($flow_listbox_w) {

		my $num_indices = ( $$flow_listbox_w->size() - 1 );

		# print("2. flow_widgets,get_num_indices,num_indices=$num_indices\n");
		return ($num_indices);

	} else {
		print("2. flow_widgets,get_num_indices,missing flow_listbox_w\n");
		return ();
	}

}

=head2 get_num_items

 how many items are there in a listbox
 input is a widget from the main flow

=cut

sub get_num_items {

	my ( $self, $flow_listbox_w ) = @_;

	if ($flow_listbox_w) {

		my $num_items = $flow_listbox_w->size();

		# print("2. flow_widgets,get_num_items,num_items=$num_items\n");
		return ($num_items);

	} else {
		print("2. flow_widgets,get_num_items,missing flow_listbox_w\n");
		return ();
	}

}

sub inc_vigil_on_delete_counter {
	my ($self) = @_;
	$flow_widgets->{_leave_dropsite}++;

	# print("flow_widgets, inc_vigil_on_delete_counter, count=$flow_widgets->{_leave_dropsite}\n");
}

sub local_get_chosen_index2drag {
	my ($self) = @_;

	#	print("flow_widgets,local_get_chosen_index2drag  is $flow_widgets->{_chosen_index2drag}\n");
	return ( $flow_widgets->{_chosen_index2drag} );
}

sub local_get_vigil_on_delete {
	my ($self) = @_;

	# print("flow_widgets,local_get_vigil_on_delete, count=$flow_widgets->{_leave_dropsite}\n");
	return ( $flow_widgets->{_leave_dropsite} );
}

sub get_vigil_on_delete {
	my ($self) = @_;

	# print("flow_widgets,get_vigil_on_delete, count=$flow_widgets->{_leave_dropsite}\n");
	return ( $flow_widgets->{_leave_dropsite} );
}

sub index2move {
	my $self       = @_;
	my $index2move = $flow_widgets->{_chosen_index2drag};
	return ($index2move);
}

=head2 sub is_drag_deleted

=cut

sub is_drag_deleted {

	my ( $self, $flow_listbox_grey_w_w ) = @_;

	# print("flow_widgets, is_drag_deleted,flow_listbox_grey_w=$flow_listbox_grey_w_w  \n");
	my $num_items;
	my $check;
	my $true       = 1;
	my $false      = 0;
	my $is_deleted = 0;

	$num_items = local_get_num_items($flow_listbox_grey_w_w);
	$check     = local_get_vigil_on_delete();

	# print("1.flow_widgets, is_drag_deleted, #num_items=$num_items\n ");
	# print("1.flow_widgets, is_drag_deleted vigil_on_delete count is $check\n ");
	if ( $num_items >= 1 ) {
		if ( $check > -1 && $check <= 3 ) {
			$is_deleted = $true;

			# print("2.flow_widgets, is_drag_deleted vigil_on_delete count is $check\n ");
			# print("2.flow_widgets, is_drag_deleted?, yes, deletion occurred\n");
			local_set_vigil_on_delete();
		}
		return ($is_deleted);
	}
}

=head2 sub local_set_vigil_on_delete 

 If $leave_dropsite >-1 , < 2 then we have deleted an item
 TODO consider when (1) new flow item is selected or
 (2)new sunix box item is selected

 leave_dropsite will increment once when item is moved (=0)
 and two more times (=2)if it is dropeed withint he listbox
 however it is only incremented twice (=1) if drop FAILS

 leave_dropsite is a counter that is used to see if 
 during DnD the mouse left the listbox window

=cut

sub local_set_vigil_on_delete {
	my ($self) = @_;
	$flow_widgets->{_leave_dropsite} = -1;

	# print("flow_widgets, local_set_vigil_on_delete, RESTART (=-1)\n");
	return ();
}

sub set_vigil_on_delete {
	my ($self) = @_;
	$flow_widgets->{_leave_dropsite} = -1;

	# print("flow_widgets, set_vigil_on_delete, RESTART (=-1)\n");
	return ();
}

=head2 sub items_aref

=cut

sub items_aref {

	my ($self) = @_;

	my $items_aref = $flow_widgets->{_all_items_aref};

	#print("flow_widgets,items_aref: all items @$items_aref\n");

	return ($items_aref);
}

=head2 sub items_versions_aref

=cut

sub items_versions_aref {

	my ($self) = @_;

	my @version;
	my ( $length, $items_versions_aref );
	my (@items_aref);

	@items_aref = @{ $flow_widgets->{_all_items_aref} };
	$length     = $flow_widgets->{_last_index} + 1;

	# print("flow_widgets,items_versions_aref,length is  $length\n");
	# initialize an array of zeroes
	for ( my $i = 0; $i < $length; $i++ ) {
		$version[$i] = 0;
	}

	#print("flow_widgets,items_versions_aref:versions @version\n");

	#loop through all items in the flow listbox
	for ( my $current = 0; $current < $length; $current++ ) {
		$version[$current] = $version[$current] + 1;

		#print("flow_widgets,items_versions_aref,current: @{$flow_widgets->{_all_items_aref}}[$current]\n");

		#loop from current to last item
		for ( my $next = $current + 1; $next < $length; $next++ ) {
			my $instances = 1;

			if ( $items_aref[$current] eq $items_aref[$next] ) {
				$version[$next] = $version[$next] + 1;
			}

			#print("flow_widgets,items_versions_aref,next: @{$flow_widgets->{_all_items_aref}}[$next]\n");
		}

	}    # end loop over all items in flow listbox

	# print("flow_widgets,items_versions_aref:versions @version\n");
	# print("flow_widgets,items_versions_aref,next: @{$flow_widgets->{_all_items_aref}}\n");

	return ( \@version );
}

=head2 sub set_flow_items 

 collect listbox widget reference

=cut

sub set_flow_items {

	my ( $self, $widget_ref ) = @_;
	if ($widget_ref) {
		my $flow_listbox = $widget_ref;
		my $num_items    = $flow_listbox->size();
		my $first_index  = 0;
		$flow_widgets->{_first_index}       = $first_index;
		$flow_widgets->{_flow_listbox_wref} = $flow_listbox;
		$flow_widgets->{_num_items}         = $num_items;

		# not an empty listbox
		if ( $num_items > 0 ) {
			my $last_item = $flow_listbox->get('end');
			$flow_widgets->{_last_item} = $last_item;
			my $first_item     = $flow_listbox->get($first_index);
			my $last_index     = $num_items - 1;
			my $all_items_aref = $flow_listbox->get( $first_index, 'end' );
			$flow_widgets->{_all_items_aref} = $all_items_aref;
			$flow_widgets->{_last_index}     = $last_index;
			$flow_widgets->{_first_item}     = $first_item;

			# print("flow_widgets,set_flow_items,last item: is $last_item\n");
			# print("flow_widgets,set_flow_items,num_items: is $num_items\n");
			# print("flow_widgets,set_flow_items,first_item: is $first_item\n");
		}
		return ();
	}
}

=head2 local_get_num_items

 how many items are there in a listbox
 input is a widget 
 output is a scalar 

=cut

sub local_get_num_items {

	my ($flow_listbox_w) = @_;

	my $num_items = $flow_listbox_w->size();

	# print("flow_widgets,local_get_num_items,num_items=$num_items\n");

	return ($num_items);

}

=head2 sub  num_items 

 collect listbox widget reference
     print("flow_widgets,flow_times: last_item $last_item\n");
     print("flow_widgets,flow_times: first_item $first_item\n");
     print("flow_widgets,flow_times: size $num_items\n");

=cut

sub num_items {

	my ( $self, $widget_ref ) = @_;
	if ($widget_ref) {
		my $flow_listbox = $widget_ref;
		my $num_items    = $flow_listbox->size();
		$flow_widgets->{_num_items} = $num_items;

		return ($num_items);
	}
}

=head2 sub  set_num_items 

=cut

sub set_num_items {
	my ( $self, $widget_ref ) = @_;
	if ($widget_ref) {
		my $flow_listbox = $widget_ref;
		my $num_items    = $flow_listbox->size();
		$flow_widgets->{_num_items} = $num_items;
		return ();
	}
	return ();
}

#
#
#=head2
#
#   $TkPl_SU->{_listbox_size}  	= $flow_listbox->size;
#   print("main,delete_from_flow_commands,listbox size before ->delete is $TkPl_SU->{_listbox_size}\n\n\n");
#   $TkPl_SU->{_listbox_size}  	= $flow_listbox->size;
#   print("main,delete_from_flow_select_commands,listbox size after ->delete is $TkPl_SU->{_listbox_size}\n\n\n");
#
#=cut

1;
