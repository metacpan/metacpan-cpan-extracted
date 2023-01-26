package App::SeismicUnixGui::misc::whereami2;

=head1 DOCUMENTATION


=head2 SYNOPSIS 

 PERL PACKAGE NAME: whereami.pm 
 AUTHOR: Juan Lorenzo
 DATE: June 22 2017 

 DESCRIPTION 
     
 BASED ON:

=cut

=head2 USE

=head3 NOTES
	only sets values internally
	does not modify values outside the package
	use to locate the user within the gui
	

=head4 Examples


=head2 CHANGES and their DATES

9-25-19 extended into a gui_history


=cut

use Moose;
our $VERSION = '0.0.2';
use Tk;

my $true  = 1;
my $false = 0;

=head2 private hash references

 16 off
 
=cut

my $whereami = {
    _flow_color                 => '',
    _is_Save_button             => $false,
    _is_SaveAs_button           => $false,
    _is_add2flow                => $false,
    _is_add2flow_button         => $false,
    _is_check_code_button       => $false,
    _is_delete_from_flow_button => $false,
    _is_flow_listbox_grey_w     => $false,
    _is_flow_listbox_pink_w     => $false,
    _is_flow_listbox_green_w    => $false,
    _is_flow_listbox_blue_w     => $false,
    _is_moveNdrop_in_flow       => $false,
    _is_sunix_listbox           => $false,
    _is_dragNdrop               => $false,
    _is_flow_select_button      => $false,
    _is_superflow_select_button => $false,
    _is_run_button              => $false,

};

=head2  sub _reset

 16 off
 
=cut

sub _reset {

    my ($self) = @_;

    $whereami = {
        _flow_color                 => '',
        _is_Save_button             => $false,
        _is_SaveAs_button           => $false,
        _is_add2flow                => $false,
        _is_add2flow_button         => $false,
        _is_check_code_button       => $false,
        _is_delete_from_flow_button => $false,
        _is_dragNdrop               => $false,
        _is_flow_listbox_grey_w     => $false,
        _is_flow_listbox_pink_w     => $false,
        _is_flow_listbox_green_w    => $false,
        _is_flow_listbox_blue_w     => $false,
        _is_flow_select_button      => $false,
        _is_moveNdrop_in_flow       => $false,
        _is_sunix_listbox           => $false,
        _is_superflow_select_button => $false,
        _is_run_button              => $false,

    };

# print("whereami,_reset,_is_sunix_listbox,$whereami->{_is_sunix_listbox}\n");
# print("whereami,_reset,_is_superflow_select_button,$whereami->{_is_superflow_select_button}\n");
    return ();
}

=head2 sub get4All 

  foreach my $key (sort keys %$here) {
  		print("1. whereami,get4All,key $key, value: $here->{$key}\n");
 }

=cut

sub get4All {
    my ($self) = @_;
    my $here = $whereami;
    return ($here);
}

=head2 sub reset4All 

  foreach my $key (sort keys %$here) {
  		print("1. whereami,get4All,key $key, value: $here->{$key}\n");
 }

=cut

sub reset4All {
    my ($self) = @_;
    _reset();
    return ();
}

=head2 sub get4add2flow

=cut

sub get4add2flow {
    my ($self) = @_;

    if ( $whereami->{_is_add2flow} ) {

        my $here;
        $here->{_is_add2flow} = $whereami->{_is_add2flow};

        # print("1. whereami,get4add2flow, $here->{_is_add2flow}\n");
        return ($here);

    }
    else {
        print("1. whereami,get4add2flow, missing whereami->{_is_add2flow}\n");
        return ();
    }

    print("1. whereami,get4add2flow, unexpected \n");
    return ();
}

=head2 sub get4add2flow_button

=cut

sub get4add2flow_button {
    my ($self) = @_;
    my $here;
    $here->{_is_add2flow_button} = $whereami->{_is_add2flow_button};

# print("1. whereami,get4add2flow_button, $here->{_is_add2flow_button}= $here->{_is_add2flow_button}\n");
    return ($here);
}

=head2 sub get4check_code_button 

=cut

sub get4check_code_button {
    my ($self) = @_;
    my $here;
    $here->{_is_check_code_button} = $whereami->{_is_check_code_button};

 # print("1. whereami,get4check_code_button, $here->{_is_check_code_button}\n");
    return ($here);
}

=head2 sub get4delete_from_flow_button

=cut

sub get4delete_from_flow_button {
    my ($self) = @_;
    my $here;
    $here->{_is_delete_from_flow_button} =
      $whereami->{_is_delete_from_flow_button};

#print("1. whereami,get4delete_from_flow_button, $here->{_is_delete_from_flow_button}\n");
    return ($here);
}

=head2 sub get4dragNdrop

=cut

sub get4dragNdrop {
    my ($self) = @_;
    my $here;
    $here->{_is_dragNdrop} = $whereami->{_is_dragNdrop};

# print("1. whereami,get4dragNdrop_from_flow_button, $here->{_is_dragNdrop}\n");
    return ($here);
}

=head2 sub _get_flow_color


=cut

sub _get_flow_color {
    my ($self) = @_;

    if ( $whereami->{_flow_color} ) {

        my $flow_color = $whereami->{_flow_color};
        return ($flow_color);

    }
    else {

        print("whereamin,_get_flow_color, missing color \n ");
        return ();
    }

}

=head2 sub get4flow_listbox 

 	TODO: distinguihs between listboxes --grey,pink,green and blue... 4 off

=cut

sub get4flow_listbox {

    my ($self) = @_;
    my $here;
    my $color = _get_flow_color();

    # print("whereami,get4flow_listbox, color: $color \n");

    if ($color) {

        my $is_flow_listbox_color_w_text = '_is_flow_listbox_' . $color . '_w';
        $here->{_is_flow_listbox_color_w_text} =
          $whereami->{$is_flow_listbox_color_w_text};
        $here->{_is_flow_listbox_color_w} =
          $whereami->{_is_flow_listbox_color_w};

# print("1. whereami,get4flow_listbox, is_flow_listbox_color_w_text: $here->{_is_flow_listbox_color_w_text}\n");
# print("1. whereami,get4flow_listbox, _is_flow_listbox_color_w: $here->{_is_flow_listbox_color_w}\n");
        return ($here);

    }
    else {

        print(" whereami,get4flow_listbox, missing color \n");
    }

    print("1. whereami,get4flow_listbox, unexpected \n");
    return ();
}

=head2 sub get4moveNdrop_in_flow 


=cut

sub get4moveNdrop_in_flow {
    my ($self) = @_;
    my $here;
    $here->{_is_moveNdrop_in_flow} = $whereami->{_is_moveNdrop_in_flow};

# print("1. whereami,get4moveNdrop_flow, $here->{_is_get4moveNdrop_in_flow}\n");
    return ($here);
}

=head2 sub get4run_button 

=cut

sub get4run_button {
    my ($self) = @_;
    my $here;
    $here->{_is_run_button} = $whereami->{_is_run_button};

    # print("1. whereami,get4run_button, $here->{_is_run_button}\n");
    return ($here);
}

=head2 sub get4flow_select_button 

=cut

sub get4flow_select_button {
    my ($self) = @_;
    my $here;
    $here->{_is_flow_select_button} = $whereami->{_is_flow_select_button};

    # print("1. whereami,get4flow_select, $here->{_is_flow_select_button}\n");
    return ($here);
}

=head2 sub get4Save_button 

=cut

sub get4Save_button {
    my ($self) = @_;
    my $here;
    $here->{_is_Save_button} = $whereami->{_is_Save_button};

    # print("1. whereami,get4Save_button, $here->{_is_Save_button}\n");
    return ($here);
}

=head2 sub get4SaveAs_button 

=cut

sub get4SaveAs_button {
    my ($self) = @_;
    my $here;
    $here->{_is_SaveAs_button} = $whereami->{_is_SaveAs_button};

    # print("1. whereami,get4SaveAs_button, $here->{_is_SaveAs_button}\n");
    return ($here);
}

=head2 sub get4superflow_select_button 

=cut

sub get4superflow_select_button {
    my ($self) = @_;
    my $here;
    $here->{_is_superflow_select_button} =
      $whereami->{_is_superflow_select_button};

# print("1. whereami,get4superflow_select_button, $here->{_is_sunix_listbox}\n");
    return ($here);
}

=head2 sub get4sunix_listbox 

=cut

sub get4sunix_listbox {
    my ($self) = @_;
    my $here;
    $here->{_is_sunix_listbox} = $whereami->{_is_sunix_listbox};

    # print("1. whereami,get4sunix_listbox, $here->{_is_sunix_listbox}\n");
    return ($here);
}


sub show_whereami {
	my ($self) = @_;
	
	# print("I am wheream2\n");
	&set4add2flow_button();
	my $ans=1;
	# print(" whereaim2,show_whereami ans= $ans\n");
	
	return();
}

=head2 sub set4add2flow

=cut

sub set4add2flow {
    my ( $self, $color ) = @_;
    _reset();

    # print(" whereami, set4add2flow\n");
    $whereami->{_is_add2flow} = $true;

    return ();
}

=head2 sub set4add2flow_button

=cut

sub set4add2flow_button {
    my ($self) = @_;
    _reset();
    $whereami->{_is_add2flow_button} = $true;

 	# print("1. whereami2,set4add2flow_button,_is_add2flow_button= $whereami->{_is_add2flow_button}\n");
    return ();
}

=head2 sub set4check_code_button 

=cut

sub set4check_code_button {
    my ($self) = @_;
    _reset();
    $whereami->{_is_check_code_button} = $true;
    print(
"1. whereami,set4check_code_button, $whereami->{_is_check_code_button}\n"
    );
    return ();
}

=head2 sub set4delete_from_flow_button

=cut

sub set4delete_from_flow_button {
    my ($self) = @_;
    _reset();
    $whereami->{_is_delete_from_flow_button} = $true;

# print("1. whereami,set4delete_from_flow_button, $whereami->{_is_delete_from_flow_button}\n");
    return ();
}

=head2 sub set4dragNdrop 

=cut

sub set4dragNdrop {
    my ($self) = @_;
    _reset();
    $whereami->{_is_dragNdrop} = $true;

    #  print("1. whereami,set4dragNdrop, $whereami->{_is_dragNdrop}\n");
    return ();
}

=head2 sub _set_flow_color


=cut

sub _set_flow_color {
    my $color = @_;

    if ($color) {

        $whereami->{_flow_color} = $color;

    }
    else {

        print("whereamin,_set_flow_color, missing color \n ");
    }

    return ();
}

=head2 sub set4flow_listbox 

 	TODO: distinguish between listboxes grey,pink,green or blue
    	foreach my $key (sort keys %$whereami) {
   			print (" grey_flow key is $key, value is $whereami->{$key}\n");
  		}
=cut

sub set4flow_listbox {
    my ( $self, $color ) = @_;

    # print(" whereami, set4flow_listbox, color: $color\n");

    if ($color) {
        _reset();
        my $is_flow_listbox_color_w_text = '_is_flow_listbox_' . $color . '_w';
        $whereami->{$is_flow_listbox_color_w_text} = $true;
        $whereami->{_is_flow_listbox_color_w}      = $true;
        $whereami->{_flow_color}                   = $color;

        my $out = $whereami->{$is_flow_listbox_color_w_text};

# print("1. whereami,set4flow_listbox, is_flow_listbox_color_w_text: $is_flow_listbox_color_w_text\n");
# print("1. whereami,set4flow_listbox, whereami->{\$is_flow_listbox_color_w_text}: whereami->{$is_flow_listbox_color_w_text}: $out\n");

    }
    else {
        print("whereami,set4flow_listbox, missing color\n");
    }

    return ();
}

=head2 sub set4flow_select 

=cut

sub set4flow_select {
    my ($self) = @_;
    _reset();
    $whereami->{_is_flow_select_button} = $true;

  # print("1. whereami,set4flow_select, $whereami->{_is_flow_select_button}\n");
    return ();
}

=head2 sub set4moveNdrop_in_flow 

=cut

sub set4moveNdrop_in_flow {
    my ($self) = @_;
    _reset();
    $whereami->{_is_moveNdrop_in_flow} = $true;

# print("1. whereami,set4moveNdrop_in_flow, $whereami->{_is_moveNdrop_in_flow}\n");
    return ();
}

=head2 sub set4run_button 

=cut

sub set4run_button {
    my ($self) = @_;
    _reset();
    $whereami->{_is_run_button} = $true;
    print("1. whereami,set4run_button, $whereami->{_is_flow_select_button}\n");
    return ();
}

=head2 sub set4Save_button 

=cut

sub set4Save_button {
    my ($self) = @_;
    _reset();
    $whereami->{_is_Save_button} = $true;
    print("1. whereami,set4Save_button, $whereami->{_is_Save_button}\n");
    return ();
}

=head2 sub set4SaveAs_button 

=cut

sub set4SaveAs_button {
    my ($self) = @_;
    _reset();
    $whereami->{_is_SaveAs_button} = $true;
    print("1. whereami,set4saveAs_button, $whereami->{_is_SaveAs_button}\n");
    return ();
}

=head2 sub set4sunix_listbox 

=cut

sub set4sunix_listbox {
    my ($self) = @_;

    _reset();
    $whereami->{_is_sunix_listbox} = $true;

    #print("1. whereami,set4sunix_listbox, $whereami->{_is_sunix_listbox}\n");

    return ();
}

=head2 sub set4superflow_select_button 

=cut

sub set4superflow_select_button {
    my ($self) = @_;
    _reset();
    $whereami->{_is_superflow_select_button} = $true;

#  print("1. whereami,set4superflow_select_button, $whereami->{_is_superflow_select_button}\n");
    return ();
}

=head2 sub widget_type 

  # print(" self:$self widget: $widget\n");
    my @fields         = split (/\./,$widget->PathName());    
    my $widget_name    = $fields[-1];
    print ( "whereami, widget_type, widget name is $fields[-1]\n");
    print(" reference: $reference\n");


=cut

sub widget_type {
    my ( $self, $widget ) = @_;

    my $type = 'nu';

    my $reference = $widget->focusCurrent;
    my @fields = split( '=', $widget->focusCurrent );

    #   			  foreach my $i (@fields) {
    #    		 print(" whereami,widget_type is $fields[$i]\n");
    #   			 }
    # print(" 1. whereamin,widget_type widget is $fields[0]\n");
    if ( $fields[0] eq 'Tk::Entry' )    { $type = 'Entry' }
    if ( $fields[0] eq 'MainWindow' )   { $type = 'MainWindow' }
    if ( $fields[0] eq 'Tk::DragDrop' ) { $type = 'DragDrop' }
    if ( $fields[0] eq 'Tk::Text' )     { $type = 'Text' }

    return ($type);
}

=head2  sub in_gui

 screen location by using part of the widget name
    print(" currently  focus lies in: $screen_location\n");
    print(" 2. widget is $i\n");
    my $screen_location = $widget->focusCurrent;
    my $reference       = ref $screen_location;
    name is in the last element of the split array 

  if widget_name= frame then we have flow
              $var->{_flow}
  if widget_name= menubutton we have superflow 
              $var->{_tool}

}

=cut

sub in_gui {
    my ($self) = @_;

    #    print ( "widget is $fields[-1]\n");
    #

    if ( $whereami->{_is_add2flow_button} ) {

        # print ("whereami,in_gui: _is_add2flow_button\n");
    }

    if ( $whereami->{_is_check_code_button} ) {

        # print ("whereami,in_gui:_is_check_code_button \n");
    }

    if ( $whereami->{_is_delete_from_flow_button} ) {

        # print ("whereami,in_gui: _is_delete_from_flow_button\n" );
    }

    if ( $whereami->{_is_dragNdrop} ) {

        # print ("whereami,in_gui: _is_dragNdrop\n" );
    }

    if ( $whereami->{_is_flow_listbox_grey_w} ) {

        # print ("whereami,in_gui: _is_flow_listbox_grey_w\n");
    }

    if ( $whereami->{_is_flow_listbox_green_w} ) {

        # print ("whereami,in_gui:_is_flow_listbox_green_w \n");
    }

    if ( $whereami->{_is_sunix_listbox} ) {

# print ("whereami,in_gui: _is_sunix_listbox=$whereami->{_is_sunix_listbox}\n");
    }

    if ( $whereami->{_is_sunix_module} ) {

        # print ("whereami,in_gui:_is_sunix_module \n");
    }

    if ( $whereami->{_is_run_button} ) {

        # print ("whereami,in_gui:_is_run_button \n");
    }

    if ( $whereami->{_is_Save_button} ) {

        # print ("whereami,in_gui:_is_Save_button \n");
    }

    if ( $whereami->{_is_SaveAs_button} ) {

        # print ("whereami,in_gui:_is_SaveAs_button \n");
    }

    if ( $whereami->{_is_superflow_select_button} ) {

        # print ("whereami,in_gui: _is_superflow_select_button\n");
    }

    #print (" \n");
    #return($widget_name);
    return ();
}

1;
