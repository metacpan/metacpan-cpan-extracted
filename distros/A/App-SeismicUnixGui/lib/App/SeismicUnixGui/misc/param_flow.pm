package App::SeismicUnixGui::misc::param_flow;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 Perl package: param_flow.pm 
 AUTHOR: Juan Lorenzo
 DATE: Aug 3 2017 

 DESCRIPTION: 
 V 0.1 Aug 3 2017

 USED FOR: 

 BASED ON:
  param_flow.pm

=cut

use Moose;
our $VERSION = '0.0.1';
use Clone 'clone';

=pod

 private hash_ref
 w  for widgets

=cut

# arrays of arrays
my @program_names;
my @num_good_values;
my @num_good_labels;
my @good_labels;
my @good_values;

my @names;
my @values;
my @checkbuttons;

my $param_flow = {
    _checkbuttons_aref       => '',
    _checkbuttons_aref2      => '',
    _destination_index       => '',
    _end                     => '',
    _first_idx               => 0,    # not a string
    _good_checkbuttons_aref2 => '',
    _good_labels_aref2       => '',
    _good_values_aref2       => '',
    _index2move              => '',
    _index4flow              => -1,
    _index4checkbuttons      => -1,
    _index4names             => -1,
    _index4values            => -1,
    _indices                 => -1,
    _label_boxes_w           => '',
    _length                  => '',
    _names_aref              => '',
    _names_aref2             => '',
    _num_good_values_aref    => 0,
    _num_good_labels_aref    => 0,
    _num_items               => 0,
    _num_items4flow          => 0,
    _num_items4checkbuttons  => 0,
    _num_items4names         => 0,
    _num_items4values        => 0,
    _prog_names_aref         => '',
    _prog_version_aref       => 0,
    _selection_index         => '',
    _start                   => 0,
    _values_aref             => '',
    _values_aref2            => '',
};

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
my $get = L_SU_global_constants->new();
my $var = $get->var();
my $on  = $var->{_on};
my $off = $var->{_off};
my $nu  = $var->{_nu};

=head2 sub first_idx

 first usable index is set to 0

=cut 

sub first_idx {
    my ($self) = @_;

    $param_flow->{_first_idx} = 0;
    return ( $param_flow->{_first_idx} );

}

=head2 sub get_num_good_values_aref

=cut 

sub get_num_good_values_aref {
    my ($self) = @_;

    if ( $param_flow->{_num_good_values_aref} ) {
        my $num_good_values_aref = $param_flow->{_num_good_values_aref};
        return ($num_good_values_aref);
    }
    return ();
}

=head2 sub get_num_good_labels_aref 

=cut 

sub get_num_good_labels_aref {
    my ($self) = @_;

    if ( $param_flow->{_num_good_labels_aref} ) {
        my $num_good_labels_aref = $param_flow->{_num_good_labels_aref};
        return ($num_good_labels_aref);
    }
    return ();
}

=head2 sub insert_selection

 delete parameter names and values
 of on one  selected item

=cut

sub insert_selection {
    my ($self)    = @_;
    my $first     = 0;
    my $idx2mv    = $param_flow->{_index2move};
    my $destn_idx = $param_flow->{_destination_index};
    my $end       = $param_flow->{_indices};
    my $num_items = $param_flow->{_num_items};

    # # print("param_flow,insert_selection start is $idx2mv\n");
    # print("param_flow,insert_selection,destn_id is $destn_idx\n");
    # print("param_flow,insert_selection, last index  is $end\n");

    # print("before insertion\n");
    # view_data();
    # STEP 1 arrays for the mobile item
    my ( @tmp_names_aref, @tmp_values_aref, @tmp_checkbuttons_aref );
    my ($tmp_prog_name);
    my ( @swap_names_aref, @swap_values_aref, @swap_checkbuttons_aref );
    my (@swap_prog_names);

    $tmp_prog_name   = @{ $param_flow->{_prog_names_aref} }[$idx2mv];
    @tmp_names_aref  = @{ @{ $param_flow->{_names_aref2} }[$idx2mv] };
    @tmp_values_aref = @{ @{ $param_flow->{_values_aref2} }[$idx2mv] };
    @tmp_checkbuttons_aref =
      @{ @{ $param_flow->{_checkbuttons_aref2} }[$idx2mv] };

   # print(" param_flow,insert_selection,mobile prog name: $tmp_prog_name	 \n");
   # print(" mobile names originally at index $idx2mv is @tmp_names_aref\n");
   # print(" values:	 		@tmp_values_aref   \n");
   # print(" checkbuttons: 	@tmp_checkbuttons_aref \n");

    # STEP 2 intermediate vector containing everything except mobile item
    # swap files have one less item than the original array
    if ( $idx2mv > $first ) {

        for ( my $i = $first, my $j = $first ; $j < $idx2mv ; $i++, $j++ ) {
            $swap_prog_names[$i] = @{ $param_flow->{_prog_names_aref} }[$j];
            $swap_names_aref[$i] =
              clone( \@{ @{ $param_flow->{_names_aref2} }[$j] } );
            $swap_values_aref[$i] =
              clone( \@{ @{ $param_flow->{_values_aref2} }[$j] } );
            $swap_checkbuttons_aref[$i] =
              clone( \@{ @{ $param_flow->{_checkbuttons_aref2} }[$j] } );

# print(" 1. filling  swap vector at index $i with @{$swap_names_aref[$i]}\n");
# print(" 1. filling  swap vector values t index $i with @{$swap_values_aref[$i]}\n");
#print(" 1. filling  swap vector values t index $i with $swap_prog_names[$i]\n");
        }
        for (
            my $i = $idx2mv, my $j = ( $idx2mv + 1 ) ;
            $j <= $end ;
            $i++, $j++
          )
        {
            $swap_prog_names[$i] = @{ $param_flow->{_prog_names_aref} }[$j];
            $swap_names_aref[$i] =
              clone( \@{ @{ $param_flow->{_names_aref2} }[$j] } );
            $swap_values_aref[$i] =
              clone( \@{ @{ $param_flow->{_values_aref2} }[$j] } );
            $swap_checkbuttons_aref[$i] =
              clone( \@{ @{ $param_flow->{_checkbuttons_aref2} }[$j] } );

 # print(" 2. filling  swap vector at index $i with @{$swap_names_aref[$i]}\n");
        }
    }
    else {    # assume $idx2mv=0
        for ( my $i = $first, my $j = ( $first + 1 ) ; $j <= $end ; $i++, $j++ )
        {     # idx2mv=0

            $swap_prog_names[$i] = @{ $param_flow->{_prog_names_aref} }[$j];
            $swap_names_aref[$i] =
              clone( \@{ @{ $param_flow->{_names_aref2} }[$j] } );
            $swap_values_aref[$i] =
              clone( \@{ @{ $param_flow->{_values_aref2} }[$j] } );
            $swap_checkbuttons_aref[$i] =
              clone( \@{ @{ $param_flow->{_checkbuttons_aref2} }[$j] } );

# print(" 3. filling intermediate vector at int. index $i with @{$swap_names_aref[$i]}\n");
        }
    }

    # STEP 3  insert all but mobile item
    #  into the final destination container
    if ( $destn_idx > $first ) {    # assume $destn_idx > 0

        for ( my $i = $first, my $j = $first ; $i < $destn_idx ; $i++, $j++ ) {
            @{ $param_flow->{_prog_names_aref} }[$i] = $swap_prog_names[$j];
            @{ @{ $param_flow->{_names_aref2} }[$i] } =
              @{ $swap_names_aref[$j] };
            @{ @{ $param_flow->{_values_aref2} }[$i] } =
              @{ $swap_values_aref[$j] };
            @{ @{ $param_flow->{_checkbuttons_aref2} }[$i] } =
              @{ $swap_checkbuttons_aref[$j] };

# print(" 1. final vector at new index $i uses swap @{$swap_names_aref[$j]}\n");
# print(" 1. final vector at new index $i is @{@{$param_flow->{_names_aref2}}[$i]}\n");
        }

        for (
            my $i = ( $destn_idx + 1 ), my $j = $destn_idx ;
            $i <= $end ;
            $i++, $j++
          )
        {
            @{ $param_flow->{_prog_names_aref} }[$i] = $swap_prog_names[$j];
            @{ @{ $param_flow->{_names_aref2} }[$i] } =
              @{ $swap_names_aref[$j] };
            @{ @{ $param_flow->{_values_aref2} }[$i] } =
              @{ $swap_values_aref[$j] };
            @{ @{ $param_flow->{_checkbuttons_aref2} }[$i] } =
              @{ $swap_checkbuttons_aref[$j] };

# print(" 2. final vector at new index $i with swap @{$swap_names_aref[$j]}\n");

        }
    }
    else {    # assume $destn_idx = 0
            #  swap files have one less item than the original array
            #   print(" 2A. destn_idx = $destn_idx\n");
            # print(" 4. swap vector index=0 with @{$swap_names_aref[0]}\n");
            # print(" 4. swap vector index=1 with @{$swap_names_aref[1]}\n");
            # print(" 4. swap vector index=2 with @{$swap_names_aref[2]}\n\n");

        for ( my $i = ( $first + 1 ), my $j = $first ; $j < $end ; $i++, $j++ )
        {
            my @swp_nam_tr = @{ $swap_names_aref[$j] };

      # print(" 4. swap vector at swap index j=$j has value of @swp_nam_tr \n");
            @{ $param_flow->{_prog_names_aref} }[$i] = $swap_prog_names[$j];
            @{ @{ $param_flow->{_names_aref2} }[$i] } = @swp_nam_tr;
            @{ @{ $param_flow->{_values_aref2} }[$i] } =
              @{ $swap_values_aref[$j] };
            @{ @{ $param_flow->{_checkbuttons_aref2} }[$i] } =
              @{ $swap_checkbuttons_aref[$j] };

#print(" 3. swap vector at index $j, @{$swap_names_aref[$j]}  names final vector at new index $i \n");
#print(" 3. swap vector at index $j, @{$swap_values_aref[$j]}  values final vector at new index $i \n");
#print(" 3. swap vector at index $j,  $swap_prog_names[$j] prog names final vector at new index $i \n");
        }
    }

    #STEP 4 insert the mobile item
    @{ $param_flow->{_prog_names_aref} }[$destn_idx]   = $tmp_prog_name;
    @{ @{ $param_flow->{_names_aref2} }[$destn_idx] }  = @tmp_names_aref;
    @{ @{ $param_flow->{_values_aref2} }[$destn_idx] } = @tmp_values_aref;
    @{ @{ $param_flow->{_checkbuttons_aref2} }[$destn_idx] } =
      @tmp_checkbuttons_aref;

# print(" 4. final vector at new index $destn_idx with temp vector @tmp_names_aref\n");

    #print("data after insertion\n");
    #view_data();
    return ();
}

=head2 sub delete_selection

 delete parameter names and values
 of on one  selected item

=cut

sub delete_selection {

    my ( $self, $index2delete ) = @_;
    my $end       = $param_flow->{_indices};
    my $num_items = $param_flow->{_num_items};
    my $first     = 0;
    $param_flow->{_index2delete} = $index2delete;

# print("\nparam_flow,delete_selection B4 deletion,idx2delete=$index2delete\n");
# view_data($index2delete);

    # CASE 1: delete end item but not the last one
    if ( $index2delete == $end && $num_items > 1 )
    {    # final item but more than one item
            # print("index2delete = end, idx $index2delete\n");
            # empty end index of array
        pop @{ $param_flow->{_checkbuttons_aref2} };
        pop @{ $param_flow->{_names_aref2} };
        pop @{ $param_flow->{_values_aref2} };
        pop @{ $param_flow->{_prog_names_aref} };

        # no $index_after;
    }

    # CASE 2: GENERAL CASE
    #         listbox has 3 items or more
    #         I can delete any but final
    if ( $index2delete >= 0 && $index2delete < $end ) {
        my $index_after = $index2delete + 1;

        # print("index2delete >= 0 , idx2delete=$index2delete end=$end \n");
        # print("index_after $index_after \n");

        for (
            my $i = $index_after, my $j = $index2delete ;
            $i <= $end ;
            $i++, $j++
          )
        {
         # print("Prog names B4 delete  @{$param_flow->{_prog_names_aref}}	\n");

            @{ @{ $param_flow->{_checkbuttons_aref2} }[$j] } =
              @{ @{ $param_flow->{_checkbuttons_aref2} }[$i] };
            @{ @{ $param_flow->{_names_aref2} }[$j] } =
              @{ @{ $param_flow->{_names_aref2} }[$i] };
            @{ @{ $param_flow->{_values_aref2} }[$j] } =
              @{ @{ $param_flow->{_values_aref2} }[$i] };
            @{ $param_flow->{_prog_names_aref} }[$j] =
              @{ $param_flow->{_prog_names_aref} }[$i];
        }

        # empty end index of array
        # - OK JL
        pop @{ $param_flow->{_checkbuttons_aref2} };
        pop @{ $param_flow->{_names_aref2} };
        pop @{ $param_flow->{_values_aref2} };
        pop @{ $param_flow->{_prog_names_aref} };

       # print("Prog names After delete @{$param_flow->{_prog_names_aref}}	\n");
    }

    # CASE 3: listbox has only 1 and final item left
    if ( $index2delete == 0 && $num_items == 1 ) {

        # print("index2delete = 0 and num_items=1, idx $index2delete\n");
        # empty end index of array
        pop @{ $param_flow->{_checkbuttons_aref2} };
        pop @{ $param_flow->{_names_aref2} };
        pop @{ $param_flow->{_values_aref2} };
        pop @{ $param_flow->{_prog_names_aref} };

        # no $index_after;
    }

    $param_flow->{_num_items}--;
    $param_flow->{_num_items4flow}--;
    $param_flow->{_num_items4values}--;
    $param_flow->{_num_items4names}--;
    $param_flow->{_num_items4checkbuttons}--;

    $param_flow->{_indices}--;
    $param_flow->{_index4values}--;
    $param_flow->{_index4names}--;
    $param_flow->{_index4checkbuttons}--;

    $param_flow->{_index4flow}--;

    # print("\nAfter delete_selection, index2delete was $index2delete\n");
    #view_data($index2delete);

    return ();
}

=head2 sub get_check_buttons_settings 

my ($i,$j, $length);
 		my @on_off;
 		my @values_aref;

 		@values_aref 	= @{@{$param_flow->{_checkbuttons_aref2}}[$index]};
 		$length			= scalar @values_aref;

   		print("param_flow,get_check_buttons_settings: is @values_aref\n");

  		#for ($i=1,$j=0; $i < $length; $i=$i+2,$j++ ) {
  		for ($i=0; $i < $length; $i++ ) {
    		#$values[$j]  = $values_aref[$i]; 
    			#print("param_flow, get_check_buttons_settings :index $j values: $values[$j]\n");
     	if($values_aref[$i] eq $nu || ) {
     	  	$on_off[$i]     = $off;
		  	# print(" 1. param_flow, get_check_buttons_settings,$on_off[$i]\n");
     	}
     	else {
       		$on_off[$i]     = $on;
		    # print(" 2. param_flow, get_check_buttons_settings,$on_off[$i]\n");
     	}
     	# print("param_flow: get_check_buttons_settings :index $i setting $nu is: $on_off[$i]\n");
   		}

=cut

sub get_check_buttons_settings {
    my $self  = @_;
    my $index = $param_flow->{_selection_index};
    my @on_off;

    if ( $index >= 0 ) {
        my @on_off = @{ @{ $param_flow->{_checkbuttons_aref2} }[$index] };
        print("param_flow,get_check_buttons_settings: is @on_off\n");

        return ( \@on_off );
    }
    return ();
}

=head2 sub get_flow_index 

 get current program index 
  
=cut 

sub get_flow_index {
    my ($self) = @_;
    my $current_idx = $param_flow->{_index4flow};

    # print("param_flow, get flow_index,
    # current_idx is $param_flow->{_index4flow}\n");
    return ($current_idx);
}

=head2 sub get_flow_prog_names_aref 

  extract sequential program names in flow 
  
=cut 

sub get_flow_prog_names_aref {
    my ($self) = @_;

    # print("param_flow, get_flow_prog_names_aref,
    # @{$param_flow->{_prog_names_aref}}\n");
    my $hash->{_prog_names_aref} = $param_flow->{_prog_names_aref};
    return ( $hash->{_prog_names_aref} );
}

=head2 sub get_good_labels_aref2

=cut

sub get_good_labels_aref2 {
    my ($self) = @_;

    if ( $param_flow->{_good_labels_aref2} ) {
        my $good_labels_aref2 = $param_flow->{_good_labels_aref2};

        # print(" param_flow,get_good_labels_aref2,
        # good_labels for index 0=
        # @{@{$param_flow->{_good_labels_aref2}}[0]}\n");
        return ($good_labels_aref2);
    }
    return ();
}

=head2  sub get_good_values_aref2

=cut

sub get_good_values_aref2 {
    my ($self) = @_;

    if ( $param_flow->{_good_values_aref2} ) {
        my $good_values_aref2 = $param_flow->{_good_values_aref2};

        # print(" param_flow,get_good_values_aref2,
        # good_values for index 0= :
        # @{@{$param_flow->{_good_values_aref2}}[0]}\n");
        return ($good_values_aref2);
    }
    return ();
}

=head2 sub get_names_aref


=cut

sub get_names_aref {
    my ($self) = @_;
    my $index = $param_flow->{_selection_index};

    if ( $index >= 0 ) {
        my @names_aref;
        my ($length);

        @names_aref = @{ @{ $param_flow->{_names_aref2} }[$index] };
        $length     = scalar @names_aref;

       # print(" param_flow, get_names names:  @names_aref, index is $index\n");
        return ( \@names_aref );
    }
}

=head2 sub get_num_items


=cut

sub get_num_items {
    my ($self) = @_;
    return ( $param_flow->{_num_items} );
}

=head2 sub get_values_aref


=cut

sub get_values_aref {
    my ($self) = @_;
    my $index = $param_flow->{_selection_index};

    if ( $index >= 0 ) {
        my ( $i, $j, $length );
        my ( @values_aref, @values );

        @values_aref = @{ @{ $param_flow->{_values_aref2} }[$index] };
        $length      = scalar @values_aref;

        # print("param_flow,get_values :values_aref is @values_aref\n");

        #		for ($i=1,$j=0; $i < $length; $i=$i+2,$j++ ) {
        # 		$values[$j]  = $values_aref[$i];
        #		#print("param_flow, get_values :index $j values: $values[$j]\n");
        #	}
        return ( \@values_aref );
    }
}

=head2 sub get_flow_items_version_aref 

 o/p is array ref of the version of each program name

=cut 

sub get_flow_items_version_aref {
    my ($self) = @_;
    my $program_version_aref = $param_flow->{_prog_version_aref};

    # print("param_flow, get_flow_items_version_aref
    # @{$param_flow->{_prog_version_aref}}\n");

    return ($program_version_aref);
}

=head2 sub length 

 last item number (not last index) 
 last item numberis equivalent to length

=cut 

sub length {
    my ($self) = @_;

    my ( $length, $index );
    my @values_aref;

    $index = $param_flow->{_selection_index};
    if ( $index >= 0 ) {
        @values_aref = @{ @{ $param_flow->{_values_aref2} }[$index] };
        $length      = scalar @values_aref;

        # print("param_flow, length, num values: $length\n");
        # print("param_flow, index: $index\n");
        return ($length);
    }
    else {
        print("param_flow,length,  index does not exist\n");
        print("param_flow, length, num values: $length\n");
        return ();
    }
}

=head2 sub private_get_good_length4item 

=cut

sub private_get_good_length4item {
    my ( $self, $index4flow ) = @_;
    my $idx    = $index4flow;
    my $length = scalar @{ $param_flow->{_good_values_aref2}[$idx] };
    return ($length);
}

=head2 sub private_get_names_aref


=cut

sub private_get_names_aref {
    my ($item_index) = @_;

    if ( $item_index >= 0 ) {
        my ( $i, $j, $length );
        my ( @names_aref, @names );
        @names_aref = @{ @{ $param_flow->{_names_aref2} }[$item_index] };

        # print("param_flow, private_get_names_aref,
        #@names_aref, index=$item_index\n");
        return ( \@names_aref );
    }
}

=head2 sub private_get_values_aref


=cut

sub private_get_values_aref {
    my ($item_index) = @_;

    if ( $item_index >= 0 ) {
        my ( $i, $j, $length );
        my ( @values_aref, @values );
        @values_aref = @{ @{ $param_flow->{_values_aref2} }[$item_index] };

        # print("param_flow, private_get_values_aref,
        # @values_aref, index=$item_index\n");
        return ( \@values_aref );
    }
}

=head2 sub private_set_good_labels4item 

 	my $num_items4flow = $param_flow->{_num_items4flow}; 

=cut

sub private_set_good_labels4item {
    my ($index4flow) = @_;

    # print("param_flow,set_good_indices4item,
    # self,index4flow: $self,$index4flow\n");

    my $idx = $index4flow;
    my (@good);
    my ($j);

    # print("1. param_flow,private_set_good_labels4item,
    # flow index:$idx, prog name:
    # @{$param_flow->{_prog_names_aref}}[$idx] \n");

    # good values determine names and checkbuttons
    my $values_aref = private_get_values_aref($idx);
    my $length      = scalar @$values_aref;

    for ( my $i = 0, $j = 0 ; $i < $length ; $i++ ) {

        # print("param_flow, private_set_good_labels4item:
        # values_aref is @$values_aref[$i]\n");

        # don't use the following values: 'nu' , empty
        if (   @$values_aref[$i] ne "'nu'"
            && @$values_aref[$i] ne '' )
        {

            my $name = ${ @{ $param_flow->{_names_aref2} }[$idx] }[$i];

            # print("2. param_flow,private_set_good_labels4item,
            # good index #$i, name:$name \n");

            $good[$j] = $name;
            $j++;
        }
    }

    $num_good_labels[$idx] = $j;

    # print("param_flow,private_set_good_labels4item,
    # good_labels=@good \n");

    $param_flow->{_num_good_labels_aref} = \@num_good_labels;
    $good_labels[$idx]                   = \@good;
    $param_flow->{_good_labels_aref2}    = \@good_labels;

    # print("	3. param_flow,private_set_good_labels4item,
    # num_good_labels= $num_good_labels[$idx] ,
    # names are:	@{@{$param_flow->{_good_labels_aref2}}[$idx]}\n");

}

=head2 sub private_set_good_values4item 

	Set good values privately for a single item (program name)
	within a flow

 	my $num_items4flow = $param_flow->{_num_items4flow}; 

=cut

sub private_set_good_values4item {
    my ($index4flow) = @_;

    # print("param_flow,set_good_indices4item,
    # self,index4flow: $self,$index4flow\n");

    my $idx = $index4flow;    # program sequence in flow
    my (@good);
    my ($j);

    # print("1. param_flow,private_set_good_values4item,
    # flow index:$idx,
    # prog name:@{$param_flow->{_prog_names_aref}}[$idx] \n");

    my $values_aref = private_get_values_aref($idx);
    my $length      = scalar @$values_aref;

    for ( my $i = 0, $j = 0 ; $i < $length ; $i++ ) {

        #print("param_flow, private_set_good_values_4item:
        #values_aref is @$values_aref[$i]\n");

        if (   @$values_aref[$i] ne "'nu'"
            && @$values_aref[$i] ne '' )
        {

            my $value = ${ @{ $param_flow->{_values_aref2} }[$idx] }[$i];

            # print("2. param_flow,private_set_good_values4item,
            # good index #$i, value:$value \n");

            $good[$j] = $value;
            $j++;
        }
    }

    $num_good_values[$idx] = $j;

    #print("param_flow,private_set_good_values4item,
    #good_values=@good \n");

    $param_flow->{_num_good_values_aref} = \@num_good_values;

    $good_values[$idx] = \@good;
    $param_flow->{_good_values_aref2} = \@good_values;

    #print("	3. param_flow,private_set_good_values4item,
    #num_good_values= $num_good_values[$idx] ,
    #values are:	@{@{$param_flow->{_good_values_aref2}}[$idx]}\n");

}

=head2 sub set_flow_items_version_aref 

 i/p is array ref of the version of each program name

=cut 

sub set_flow_items_version_aref {
    my ( $self, $program_version_aref ) = @_;
    if ($program_version_aref) {
        $param_flow->{_prog_version_aref} = $program_version_aref;

#print("param_flow, set_flow_items_version_aref @{$param_flow->{_prog_version_aref}}\n");
    }
}

=head2 sub  set_insert_start 

 move paramter names and values
 of one selected item into another
 space

=cut

sub set_insert_start {
    my ( $self, $start ) = @_;
    $param_flow->{_index2move} = $start;

    # print("param_flow,set_insert_start is $start\n");

    return ();
}

=head2 sub set_insert_end

 move paramter names and values
 of one selected item into another
 space

=cut

sub set_insert_end {
    my ( $self, $end ) = @_;
    $param_flow->{_destination_index} = $end;

    # print("param_flow,set_insert_end  $end \n");

    return ();
}

=head2 sub set_flow_index 

 select an item for which to extract data
      			print("param_flow, set flow_index, prog name is @{$param_flow->{_prog_names_aref}}[$index]\n");
  
=cut 

sub set_flow_index {
    my ( $self, $index ) = @_;

    # print("param_flow, set_flow_index,index, $index\n");
    if ( $index >= 0 ) {

        $param_flow->{_selection_index} = $index;
    }
    else {
        print(
            "param_flow, set_flow_index,index does not exist, index:$index\n");
    }
    return ();
}

=head2 sub set_names_aref


=cut

sub set_names_aref {
    my ( $self, $names_aref ) = @_;
    my $index = $param_flow->{_selection_index};

    # print(" param_flow, set_names:  @{$names_aref}, index is $index\n");

    if ( $index >= 0 ) {
        my @names_aref;
        my ($length);

        @{ $param_flow->{_names_aref2} }[$index] = $names_aref;

        # $length 		= scalar @names_aref;

        return ();
    }
}

=head2 sub set_good_labels 

	select names with values

=cut

sub set_good_labels {

    my ($self) = @_;
    my $length = $param_flow->{_num_items4flow};

    # print("param_flow,set_good_labels
    # num_items4flow:	$param_flow->{_num_items4flow}\n");

    for ( my $i = 0 ; $i < $length ; $i++ ) {
        private_set_good_labels4item($i);
    }

    return ();

}

=head2 sub set_good_values

	find good values for ALL programs in flow

=cut

sub set_good_values {

    my ($self) = @_;
    my $length = $param_flow->{_num_items4flow};

    # print("param_flow,set_good_values
    # num_items4flow:	$param_flow->{_num_items4flow}\n");

    for ( my $i = 0 ; $i < $length ; $i++ ) {
        private_set_good_values4item($i);
    }

    return ();
}

=head2 sub set_good_labels4item 

 	my $num_items4flow = $param_flow->{_num_items4flow}; 

=cut

sub set_good_labels4item {
    my ( $self, $index4flow ) = @_;

    # print("param_flow,set_good_labels4item,
    # self,index4flow: $self,$index4flow\n");

    my $idx = $index4flow;
    my ( @good,            @good_labels );
    my ( $num_good_labels, $j );

    # print("1. param_flow,set_good_labels4item,
    #flow index:$idx, prog name:
    # @{$param_flow->{_prog_names_aref}}[$idx] \n");

    # good values (not names) determine good names
    my $values_aref = private_get_values_aref($idx);
    my $length      = scalar @$values_aref;

    for ( my $i = 0, $j = 0 ; $i < $length ; $i++ ) {

        # print("param_flow, set_good_labels4item:
        # values_aref is @$values_aref[$i]\n");

        if ( @$values_aref[$i] ne "'nu'" ) {
            my $name = ${ @{ $param_flow->{_names_aref2} }[$idx] }[$i];

            #print("2. param_flow,set_good_labels4item,
            #good index #$i, name:$name \n");

            $good[$j] = $name;
            $j++;
        }
    }

    $num_good_labels = $j;

    # print("param_flow,set_good_labels4item,
    # good_labels=@good \n");

    $good_labels[$idx] = \@good;
    $param_flow->{_good_labels_aref2} = \@good_labels;

    # print("	3. param_flow,set_good_,names4item,
    # num_good_labels= $num_good_labels , names are:
    # @{@{$param_flow->{_good_labels_aref2}}[$idx]}\n");
    return ();
}

=head2 sub set_good_values4item 

 	my $num_items4flow = $param_flow->{_num_items4flow}; 
	work on finding good values for one item

=cut

sub set_good_values4item {
    my ( $self, $index4flow ) = @_;

    # print("param_flow,set_good_indices4item,
    # self,index4flow: $self,$index4flow\n");

    my $idx = $index4flow;
    my ( @good,            @good_values );
    my ( $num_good_values, $j );

    # print("1. param_flow,set_good_values4item,
    # flow index:$idx, prog name:
    # @{$param_flow->{_prog_names_aref}}[$idx] \n");

    my $values_aref = private_get_values_aref($idx);
    my $length      = scalar @$values_aref;

    for ( my $i = 0, $j = 0 ; $i < $length ; $i++ ) {

        # print("param_flow, set_good_values4item:
        # values_aref is @$values_aref[$i]\n");

        if ( @$values_aref[$i] ne "'nu'" ) {
            my $value = ${ @{ $param_flow->{_values_aref2} }[$idx] }[$i];

            # print("2. param_flow,set_good_indices4item,
            # good index #$i, value:$value \n");

            $good[$j] = $value;
            $j++;
        }
    }

    $num_good_values = $j;

    # print("param_flow,set_good_values4item,
    # good_values=@good \n");

    $good_values[$idx] = \@good;
    $param_flow->{_good_values_aref2} = \@good_values;

    # print("	3. param_flow,set_good_,values4item,
    # num_good_values= $num_good_values , values are:
    # @{@{$param_flow->{_good_values_aref2}}[$idx]}\n");
    return ();
}

=head2 sub set_values_aref


=cut

sub set_values_aref {
    my ( $self, $values_aref ) = @_;
    my $index = $param_flow->{_selection_index};

    if ( $index >= 0 ) {
        my ( $i, $j, $length );
        my ( @values_aref, @values );

        @{ $param_flow->{_values_aref2} }[$index] = $values_aref;
        $length = scalar @values_aref;

        # print("param_flow,set_values :values_aref is @$values_aref\n");

        #		for ($i=1,$j=0; $i < $length; $i=$i+2,$j++ ) {
        # 		$values[$j]  = $values_aref[$i];
        #		#print("param_flow, set_values :index $j values: $values[$j]\n");
        #	}
        return ();
    }
}

=head2 sub set_check_buttons_settings 

set check_buttons by user from outside

=cut

sub set_check_buttons_settings_aref {
    my ( $self, $check_buttons_settings_aref ) = @_;
    my $index       = $param_flow->{_selection_index};
    my $chkbut_aref = $check_buttons_settings_aref;

    if ( $index >= 0 ) {
        my ( $i, $j, $length );
        my @on_off;
        my @values_aref;

        @{ $param_flow->{_checkbuttons_aref2} }[$index] = $chkbut_aref;

        # $length			= scalar @$chkbut_aref;

        # print("param_flow,set_check_buttons_settings: is @$chkbut_aref\n");

#for ($i=1,$j=0; $i < $length; $i=$i+2,$j++ ) {
#for ($i=0; $i < $length; $i++ ) {
#$values[$j]  = $values_aref[$i];
#print("param_flow, set_check_buttons_settings :index $j values: $values[$j]\n");
#if(@$values_aref[$i] eq $nu) {
#  	$on_off[$i]     = $off;
# print(" 1. param_flow, set_check_buttons_settings,$on_off[$i]\n");
#}
#else {
#		$on_off[$i]     = $on;
# print(" 2. param_flow, set_check_buttons_settings,$on_off[$i]\n");
#}
# print("param_flow: set_check_buttons_settings :index $i setting $nu is: $on_off[$i]\n");
#}
#return();
    }
    return ();
}

=head2 sub stack_checkbuttons_aref2

  array of arrays
  One array if checkbuttons for each item
  DB
  #for (my $i=0; $i<=$index;$i++) {
    #print("param_flow,checkbuttons_aref,@{@{$param_flow->{_checkbuttons_aref2}}[$i]} index $i\n");
  #}
     #print("param_flow, checkbuttons_aref2, num_items4checkbuttons $param_flow->{_num_items4checkbuttons}\n");

=cut

sub stack_checkbuttons_aref2 {

    my ( $self, $checkbuttons_aref ) = @_;
    my $index = $param_flow->{_index4checkbuttons} + 1;

    $checkbuttons[$index] = $checkbuttons_aref;
    $param_flow->{_checkbuttons_aref2} = \@checkbuttons;

    $param_flow->{_indices} = $index;
    $param_flow->{_index4checkbuttons}++;
    $param_flow->{_num_items4checkbuttons}++;
    $param_flow->{_num_items} = $param_flow->{_num_items4checkbuttons};

# print("param_flow,stack_checkbuttons_aref2,  @{$checkbuttons[$index]},idx $index num_items $param_flow->{_num_items}\n");
# print("param_flow,stack_checkbuttons_aref2,  @{@{$param_flow->{_checkbuttons_aref2}}[$index]},idx $index num_items $param_flow->{_num_items}\n");

    return ();
}

=head2 sub stack_flow_item 

 i/p is scalar ref to a program name
 keep count and increment the number of items
 encapsulate internal counters and array
 from the array shared among the package subroutines 

 count items at start in case we don't return to the subroutine
 later
     print("param_flow, stack_flow_item @{$param_flow->{_prog_names_aref}}, num_items $param_flow->{_num_items}\n");
 	 print("param_flow, stack_flow_item, index: $index\n");

=cut 

sub stack_flow_item {
    my ( $self, $program_name_sref ) = @_;
    if ($program_name_sref) {
        my $index = $param_flow->{_index4flow} + 1;

        # print("param_flow, stack_flow_item, index: $index\n");

        $program_names[$index] = $$program_name_sref;
        $param_flow->{_prog_names_aref} = \@program_names;

        $param_flow->{_indices}    = $index;
        $param_flow->{_index4flow} = $index;
        $param_flow->{_num_items4flow}++;
        $param_flow->{_num_items}++;

    }
    return ();
}

=head2 sub stack_names_aref2 

 i/p array ref for values in a program
 an array of arrays is created, one array for each item
 DrBN
#  for (my $i=0; $i<=$index;$i++) {
    #print("param_flow,names_aref,@{@{$param_flow->{_names_aref2}}[$i]} item $i\n");
#  }
     #print("param_flow, names_aref2, num_items4names $param_flow->{_num_items4names}\n");

 #print("param_flow,names_aref,$names[$index],item $index\n");
=cut

sub stack_names_aref2 {

    my ( $self, $names_aref ) = @_;
    my $index = $param_flow->{_index4names} + 1;

    $names[$index] = $names_aref;
    $param_flow->{_names_aref2} = \@names;

    $param_flow->{_indices} = $index;
    $param_flow->{_index4names}++;
    $param_flow->{_num_items4names}++;
    $param_flow->{_num_items} = $param_flow->{_num_items4names};

# print("param_flow,names_aref2, names @{$names[$index]},idx $index num_items $param_flow->{_num_items}\n");
    for ( my $i = 0 ; $i <= $index ; $i++ ) {

# print("param_flow,stack_names_aref2, cumulative names @{$names[$i]},idx $index num_items $param_flow->{_num_items}\n");
    }

    return ();
}

=head2 sub stack_values_aref2 

 i/p array ref for values in a program
 an array of arrays is created, one array for each item

DB
  #for (my $i=0; $i<=$index;$i++) {
   # print("param_flow,values_aref2,@{@{$param_flow->{_values_aref2}}[$i]} index $i\n");
  #}
  #print("param_flow,values_aref2,num_items=$param_flow->{_num_items}\n");
  # print("param_flow,values_aref2, index $index\n");

=cut

sub stack_values_aref2 {

    my ( $self, $values_aref ) = @_;
    my $index = $param_flow->{_index4values} + 1;

    $values[$index] = $values_aref;
    $param_flow->{_values_aref2} = \@values;

    $param_flow->{_indices} = $index;
    $param_flow->{_index4values}++;
    $param_flow->{_num_items4values}++;
    $param_flow->{_num_items} = $param_flow->{_num_items4values};

# print("param_flow,stack_values_aref2, values @{$values[$index]},idx $index num_items $param_flow->{_num_items}\n");
    return ();
}

=head2 sub view_data

 Data viewer for debugging
   print("B4  delete: names are  $param_flow->{_names_aref2}\n");    # ref_Array
   print("B4  delete: names are  @{$param_flow->{_names_aref2}}\n");     # [ref_array0 ref_array1 .... 
   print("B4  delete: names are  @{$param_flow->{_names_aref2}}[0]\n");  # ref_array0

   print("B4  delete: names are  @{$param_flow->{_names_aref2}}[1]\n"); #ref_array1
     
   print("B4  delete: names are  @{@{$param_flow->{_names_aref2}}[0]}\n"); # all names in ref_array 0 
   print("B4  delete: names are  @{@{$param_flow->{_names_aref2}}[1]}[0]\n"); # first name  in ref_array 
   print("param_flow,view_data: list for each item\n");

=cut

sub view_data {
    my ( $self, $index2delete ) = @_;
    my @num_progs;

    my $indices = $param_flow->{_indices};
    $num_progs[0] = $param_flow->{_num_items};

    $num_progs[1] = scalar( @{ $param_flow->{_names_aref2} } );
    $num_progs[3] = scalar( @{ $param_flow->{_values_aref2} } );
    $num_progs[4] = scalar( @{ $param_flow->{_checkbuttons_aref2} } );
    $num_progs[5] = scalar( @{ $param_flow->{_prog_names_aref} } );

# print("\nparam_flow,view_data:number of items in list in 4-5 different ways  @num_progs \n");
# print("param_flow,view_data:max index = $indices  \n\n");

    print(
"param_flow,view_data:  prog_names:   @{$param_flow->{_prog_names_aref}}\n"
    );
    for ( my $i = 0 ; $i <= $indices ; $i++ ) {
        print(
"param_flow,view_data: names:        @{@{$param_flow->{_names_aref2}}[$i]}\n"
        );

# print("param_flow,view_data: values:       @{@{$param_flow->{_values_aref2}}[$i]}\n");
# print("param_flow,view_data: checkbuttons: @{@{$param_flow->{_checkbuttons_aref2}}[$i]}\n\n");
    }
}

1;
