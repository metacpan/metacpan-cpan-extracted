
#----------------------------------------------------------------------------------------------

register_action_handlers
	(
	'Add button' => ['000-b', \&add_element, ['stencils/guiio/Button',0]],
	'Add button Upper' => ['000-B', \&add_element, ['stencils/guiio/Button', 0]],
	'Add checkbox' => ['000-c', \&add_element, ['stencils/guiio/Checkbox',0]],
	'Add checkbox upper' => ['000-C', \&add_element, ['stencils/guiio/Checkbox',0]],
	'Add radio button' => ['000-r', \&add_element, ['stencils/guiio/Radio Button',0]],
	'Add radio button upper' => ['000-R', \&add_element, ['stencils/guiio/Radio Button',0]],
	'Add label' => ['000-l', \&add_element, ['stencils/guiio/Label',0]],
	'Add label upper' => ['000-L', \&add_element, ['stencils/guiio/Label',0]],
	'Add textbox' => ['000-t', \&add_element, ['stencils/guiio/Textbox',0]],
	'Add textbox upper' => ['000-T', \&add_element, ['stencils/guiio/Textbox',0]],
	'Add window' => ['000-w', \&add_element, ['stencils/guiio/Window',0]],
	'Add window uppper' => ['000-W', \&add_element, ['stencils/guiio/Window',0]],
	'Add listbox' => ['000-h', \&add_element, ['stencils/guiio/Listbox',0]],
	'Add listbox uppper' => ['000-H', \&add_element, ['stencils/guiio/Listbox',0]],
	'Add dropdown' => ['000-d', \&add_element, ['stencils/guiio/Combobox',0]],
	'Add dropdown uppper' => ['000-D', \&add_element, ['stencils/guiio/Combobox',0]],
	'Add scrollbar' => ['000-s', \&add_element, ['stencils/guiio/Scrollbar',0]],
	'Add scrollbar uppper' => ['000-S', \&add_element, ['stencils/guiio/Scrollbar',0]],
	'Add progressbar' => ['000-p', \&add_element, ['stencils/guiio/Progress Bar',0]],
	'Add progressbar uppper' => ['000-P', \&add_element, ['stencils/guiio/Progress Bar',0]],
	'Add slider' => ['000-i', \&add_element, ['stencils/guiio/Slider',0]],
	'Add slider uppper' => ['000-I', \&add_element, ['stencils/guiio/Slider',0]],
	'Add calendar' => ['000-f', \&add_element, ['stencils/guiio/Calendar',0]],
	'Add calendar uppper' => ['000-F', \&add_element, ['stencils/guiio/Calendar',0]],
	
	) ;
	
#----------------------------------------------------------------------------------------------

sub add_element
{
my ($self, $name_and_edit) = @_ ;

$self->create_undo_snapshot() ;

$self->select_elements(0, @{$self->{ELEMENTS}}) ;

my ($name, $edit) = @{$name_and_edit} ;

my $element = $self->add_new_element_named($name, $self->{MOUSE_X}, $self->{MOUSE_Y}) ;

$element->edit() if $edit;

$self->select_elements(1, $element) ;

$self->update_display() ;
} ;
