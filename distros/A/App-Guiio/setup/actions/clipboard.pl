
use List::Util qw(min max) ;

#----------------------------------------------------------------------------------------------

register_action_handlers
	(
	'Copy to clipboard' => 
		[
		['C00-c', 'C00-Insert']
		, \&export_to_clipboard_as_ascii
		],
		
	'Insert from clipboard' => 
		[
		['C00-v', '00S-Insert']
		, \&insert_from_clipboard
		],
		
	#'Export to clipboard & primary as ascii'=> ['C00-e', \&export_to_clipboard_as_ascii] ,
	#'Import from clipboard to box'=> ['C0S-E', \&import_from_clipboard_to_box] ,
	#'Import from primary to box'=> ['0A0-e', \&import_from_primary_to_box] ,
	) ;

#----------------------------------------------------------------------------------------------

sub export_to_clipboard_as_ascii
{
my ($self) = @_ ;

my $ascii = $self->transform_elements_to_ascii_buffer($self->get_selected_elements(1)) ;

Gtk2::Clipboard->get (Gtk2::Gdk->SELECTION_CLIPBOARD)->set_text($ascii);

# also put in selection  --  DH
Gtk2::Clipboard->get (Gtk2::Gdk->SELECTION_PRIMARY)->set_text($ascii);
}

#----------------------------------------------------------------------------------------------

sub import_from_clipboard_to_box
{
my ($self) = @_ ;

my $ascii = Gtk2::Clipboard->get (Gtk2::Gdk->SELECTION_CLIPBOARD)->wait_for_text();

my $element = $self->add_new_element_named('stencils/guiio/box', $self->{MOUSE_X}, $self->{MOUSE_Y}) ;

$element->set_text('', $ascii) ;

$self->select_elements(1, $element) ;

$self->update_display() ;

}

#----------------------------------------------------------------------------------------------

sub import_from_primary_to_box
{
my ($self) = @_ ;

my $ascii = Gtk2::Clipboard->get (Gtk2::Gdk->SELECTION_PRIMARY)->wait_for_text();

my $element = $self->add_new_element_named('stencils/guiio/box', $self->{MOUSE_X}, $self->{MOUSE_Y}) ;

$element->set_text('', $ascii) ;

$self->select_elements(1, $element) ;

$self->update_display() ;

}

#----------------------------------------------------------------------------------------------

sub copy_to_clipboard
{
my ($self) = @_ ;

my @selected_elements = $self->get_selected_elements(1) ;
return unless @selected_elements ;

my %selected_elements = map { $_ => 1} @selected_elements ;

my @connections =
	grep 
		{
		exists $selected_elements{$_->{CONNECTED}} && exists $selected_elements{$_->{CONNECTEE}}
		} 
		$self->get_connections_containing(@selected_elements)  ;

my $elements_and_connections =
	{
	ELEMENTS =>  \@selected_elements,
	CONNECTIONS => \@connections ,
	};
	
# print Data::TreeDumper::DumpTree $elements_and_connections, '$elements_and_connections:', MAX_DEPTH => 2 ;
#~ print Data::Dumper::Dumper $elements_and_connections ;#, '$elements_and_connections:', MAX_DEPTH => 2 ;

$self->{CLIPBOARD} =  Clone::clone($elements_and_connections) ;
} ;	
	
#----------------------------------------------------------------------------------------------

sub insert_from_clipboard
{
my ($self) = @_ ;

$self->create_undo_snapshot() ;
my $ascii = Gtk2::Clipboard->get (Gtk2::Gdk->SELECTION_CLIPBOARD)->wait_for_text();
$self->transform_ascii_string_to_elements($ascii);
# $self->select_elements(0, @{$self->{ELEMENTS}}) ;
	
# unless(defined $x_offset)
	# {
	# my $min_x = min(map {$_->{X}} @{$self->{CLIPBOARD}{ELEMENTS}}) ;
	# $x_offset = $min_x - $self->{MOUSE_X} ;
	# }

# unless(defined $y_offset)
	# {
	# my $min_y = min(map {$_->{Y}} @{$self->{CLIPBOARD}{ELEMENTS}}) ;
	# $y_offset = $min_y  - $self->{MOUSE_Y} ;
	# }

# my %new_group ;

# for my $element (@{$self->{CLIPBOARD}{ELEMENTS}})
	# {
	# @$element{'X', 'Y'}= ($element->{X} - $x_offset, $element->{Y} - $y_offset) ;
				
	# if(exists $element->{GROUP} && scalar(@{$element->{GROUP}}) > 0)
		# {
		# my $group = $element->{GROUP}[-1] ;
		
		# unless(exists $new_group{$group})
			# {
			# $new_group{$group} = {'GROUP_COLOR' => $self->get_group_color()} ;
			# }
			
		# pop @{$element->{GROUP}} ;
		# push @{$element->{GROUP}}, $new_group{$group} ;
		# }
	# else
		# {
		# delete $element->{GROUP} ;
		# }
	# }

# my $clipboard = Clone::clone($self->{CLIPBOARD}) ;

# $self->add_elements(@{$clipboard->{ELEMENTS}}) ;
# $self->add_connections(@{$clipboard->{CONNECTIONS}}) ;

$self->update_display() ;
} ;	
	
