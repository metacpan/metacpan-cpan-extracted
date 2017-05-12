
package App::Guiio ;
$|++ ;

use strict;
use warnings;

use Data::TreeDumper ;
use Data::TreeDumper::Renderer::GTK ;
use Module::Util qw(find_installed) ;
use File::Basename ;
#-----------------------------------------------------------------------------

sub get_color_from_user
{
my ($self, $previous_color) = @_ ;

my $color = Gtk2::Gdk::Color->new (@{$previous_color});
my $dialog = Gtk2::ColorSelectionDialog->new ("Changing color");

my $colorsel = $dialog->colorsel;

$colorsel->set_previous_color ($color);
$colorsel->set_current_color ($color);
$colorsel->set_has_palette (TRUE);

my $response = $dialog->run;

if ($response eq 'ok') 
	{
	$color = $colorsel->get_current_color;
	}

$dialog->destroy;

return [$color->red, $color->green , $color->blue]  ;
}

#-----------------------------------------------------------------------------

sub show_dump_window
{
my ($self, $data, $title, @dumper_setup) = @_ ;

my $treedumper = Data::TreeDumper::Renderer::GTK->new
				(
				data => $data,
				title => $title,
				dumper_setup => {@dumper_setup}
				);
		
$treedumper->modify_font(Gtk2::Pango::FontDescription->from_string ('monospace'));
$treedumper->collapse_all;

# some boilerplate to get the widget onto the screen...
my $window = Gtk2::Window->new;

my $scroller = Gtk2::ScrolledWindow->new;
$scroller->add ($treedumper);

$window->add ($scroller);
$window->set_default_size(640, 1000) ;
$window->show_all;
}

#-----------------------------------------------------------------------------

sub display_message_modal
{
my ($self, $message) = @_ ;

my $window = new Gtk2::Window() ;

my $dialog = Gtk2::MessageDialog->new 
	(
	$window,
	'destroy-with-parent' ,
	'info' ,
	'close' ,
	$message ,
	) ;

$dialog->signal_connect(response => sub { $dialog->destroy ; 1 }) ;
$dialog->run() ;
}

#-----------------------------------------------------------------------------

sub display_yes_no_cancel_dialog
{
my ($self, $title, $text) = @_ ;

my $window = new Gtk2::Window() ;

my $dialog = Gtk2::Dialog->new($title, $window, 'destroy-with-parent')  ;
$dialog->set_default_size (300, 150);
$dialog->add_button ('gtk-yes' => 'yes');
$dialog->add_button ('gtk-no' => 'no');
$dialog->add_button ('gtk-cancel' => 'cancel');

my $lable = Gtk2::Label->new($text);
$dialog->vbox->add ($lable);
$lable->show;

my $result = $dialog->run() ;

$dialog->destroy ;

return $result ;
}

#-----------------------------------------------------------------------------

sub display_quit_dialog
{
my ($self, $title, $text) = @_ ;

my $window = new Gtk2::Window() ;

my $dialog = Gtk2::Dialog->new($title, $window, 'destroy-with-parent')  ;
$dialog->set_default_size (300, 150);

add_button_with_icon ($dialog, 'Continue editing', 'gtk-cancel' => 'cancel');
add_button_with_icon ($dialog, 'Save and Quit', 'gtk-save' => 999);
add_button_with_icon ($dialog, 'Quit and loose changes', 'gtk-ok' => 'ok');

my $lable = Gtk2::Label->new($text);
$dialog->vbox->add ($lable);
$lable->show;

my $result = $dialog->run() ;
$result = 'save_and_quit' if "$result" eq "999" ;

$dialog->destroy ;

return $result ;
}

sub add_button_with_icon {
	# code by Muppet
        my ($dialog, $text, $stock_id, $response_id,$is_file) = @_;

        my $button = create_button ($text, $stock_id,$is_file);
        $button->show;

        $dialog->add_action_widget ($button, $response_id);
}

#
# Create a button with a stock icon but with non-stock text.
#
sub create_button {
	# code by Muppet, j2simpso
        my ($text, $stock_id,$is_file) = @_;

        my $button = Gtk2::Button->new ();
        my $image = Gtk2::Image->new();
        #
        # This setup is cribbed from gtk_button_construct_child()
        # in gtkbutton.c.  It does not handle all the details like
        # left-to-right ordering and alignment and such, as in the
        # real button code.
        #
		# the if_file parameter specifies whether whether to treat $stock_id as a image_ID of a path to an image file (TRUE if path for image file)
		$is_file = FALSE unless defined $is_file;
		
		if (!$is_file){
		    $image = Gtk2::Image->new_from_stock ($stock_id, 'button');
			}
        else{
			$image = Gtk2::Image->new_from_file($stock_id);
			}
			
		my $label = Gtk2::Label->new ($text); # accepts mnemonics
        $label->set_mnemonic_widget ($button);

        my $hbox = Gtk2::HBox->new ();
        $hbox->pack_start ($image, FALSE, FALSE, 0);
        $hbox->pack_start ($label, FALSE, FALSE, 0);

        $hbox->show_all ();

        $button->add ($hbox);

        return $button;
}


#-----------------------------------------------------------------------------

sub display_edit_dialog
{
my ($self, $title, $text) = @_ ;

$text ='' unless defined $text ;

my $window = new Gtk2::Window() ;

my $dialog = Gtk2::Dialog->new($title, $window, 'destroy-with-parent')  ;
$dialog->set_default_size (300, 150);
$dialog->add_button ('gtk-ok' => 'ok');

my $textview = Gtk2::TextView->new;
$textview->modify_font (Gtk2::Pango::FontDescription->from_string ('monospace 10'));

my $buffer = $textview->get_buffer;
 $buffer->insert ($buffer->get_end_iter, $text);

$dialog->vbox->add ($textview);
$textview->show;

#
# Set up the dialog such that Ctrl+Return will activate the "ok"  response. Muppet
#
#~ my $accel = Gtk2::AccelGroup->new;
#~ $accel->connect
		#~ (
		#~ Gtk2::Gdk->keyval_from_name ('Return'), ['control-mask'], [],
                #~ sub { $dialog->response ('ok'); }
		#~ );
		
#~ $dialog->add_accel_group ($accel);

$dialog->run() ;

my $new_text =  $textview->get_buffer->get_text($buffer->get_start_iter, $buffer->get_end_iter, TRUE) ;

$dialog->destroy ;

return $new_text
}

#-----------------------------------------------------------------------------

sub get_file_name
{
my ($self, $type) = @_ ;

my $file_name = '' ;

my $file_chooser = Gtk2::FileChooserDialog->new 
				(
				$type, undef, $type,
				'gtk-cancel' => 'cancel', 'gtk-ok' => 'ok'
				);

$file_name = $file_chooser->get_filename if ('ok' eq $file_chooser->run) ;
	
$file_chooser->destroy;

return $file_name ;
}

#-----------------------------------------------------------------------------

sub display_box_edit_dialog
{
my ($rows, $title, $text) = @_ ;

my $window = new Gtk2::Window() ;

my $dialog = Gtk2::Dialog->new('Box attributes', $window, 'destroy-with-parent')  ;
$dialog->set_default_size (450, 305);
$dialog->add_button ('gtk-ok' => 'ok');

#~ my $vbox = $dialog->vbox ;
my $dialog_vbox = $dialog->vbox ;

my $vbox = Gtk2::VBox->new (FALSE, 5);
$dialog_vbox->pack_start ($vbox, TRUE, TRUE, 0);

$vbox->pack_start (Gtk2::Label->new (""),
		 FALSE, FALSE, 0);

my $sw = Gtk2::ScrolledWindow->new;
$sw->set_shadow_type ('etched-in');
$sw->set_policy ('automatic', 'automatic');
$vbox->pack_start ($sw, TRUE, TRUE, 0);

# create model
my $model = create_model ($rows);

# create tree view
my $treeview = Gtk2::TreeView->new_with_model ($model);
$treeview->set_rules_hint (TRUE);
$treeview->get_selection->set_mode ('single');

add_columns($treeview, $rows);

$sw->add($treeview);

# title
my $titleview = Gtk2::TextView->new;
$titleview->modify_font (Gtk2::Pango::FontDescription->from_string ('monospace 10'));
my $title_buffer = $titleview->get_buffer ;
$title_buffer->insert ($title_buffer->get_end_iter, $title);

$vbox->add ($titleview);
$titleview->show;

# text 
my $textview = Gtk2::TextView->new;
$textview->modify_font (Gtk2::Pango::FontDescription->from_string ('monospace 10'));

my $text_buffer = $textview->get_buffer;
$text_buffer->insert ($text_buffer->get_end_iter, $text);

$vbox->add ($textview) ;
$textview->show() ;

# Focus and select, code by Tian
$text_buffer->select_range($text_buffer->get_start_iter, $text_buffer->get_end_iter);
$textview->grab_focus() ;


# some buttons
#~ my $hbox = Gtk2::HBox->new (TRUE, 4);
#~ $vbox->pack_start ($hbox, FALSE, FALSE, 0);

#~ my $button = Gtk2::Button->new ("Add item");
#~ $button->show() ;
#~ $button->signal_connect (clicked => \&add_item, $model);
#~ $hbox->pack_start ($button, TRUE, TRUE, 0);

#~ $button = Gtk2::Button->new ("Remove item");
#~ $button->signal_connect (clicked => \&remove_item, $treeview);
#~ $hbox->pack_start ($button, TRUE, TRUE, 0);

#~ $hbox->show() ;

$treeview->show() ;
$vbox->show() ;
$sw->show() ;

$dialog->run() ;

my $new_text =  $textview->get_buffer->get_text($text_buffer->get_start_iter, $text_buffer->get_end_iter, TRUE) ;
my $new_title =  $titleview->get_buffer->get_text($title_buffer->get_start_iter, $title_buffer->get_end_iter, TRUE) ;

$dialog->destroy ;

return($new_text, $new_title) ;
}

#-----------------------------------------------------------------------------

sub create_model 
{
my ($rows) = @_ ;

my $model = Gtk2::ListStore->new(qw/Glib::Boolean Glib::String  Glib::String Glib::String Glib::String Glib::Boolean/);

foreach my $row (@{$rows}) 
	{
	my $iter = $model->append;

	my $column = 0 ;
	$model->set ($iter, map {$column++, $_} @{$row}) ;
	}

return $model;
}

#-----------------------------------------------------------------------------

sub add_columns 
{
my ($treeview, $rows) = @_ ;
my $model = $treeview->get_model;

# column for fixed toggles
my $renderer = Gtk2::CellRendererToggle->new;
$renderer->signal_connect (toggled => \&display_toggled, [$model, $rows]) ;

my $column = Gtk2::TreeViewColumn->new_with_attributes 
			(
			'show',
			$renderer,
			active => 0
			) ;
			
$column->set_sizing('fixed') ;
$column->set_fixed_width(70) ;
$treeview->append_column($column) ;

# column for row titles
my $row_renderer = Gtk2::CellRendererText->new;
$row_renderer->set_data (column => 1);

$treeview->insert_column_with_attributes(-1, '', $row_renderer, text => 1) ;

#~ $column->set_sort_column_id (COLUMN_NUMBER);

my $current_column = 2 ;
for my $column_title('left', 'body', 'right')
	{
	my $renderer = Gtk2::CellRendererText->new;
	$renderer->signal_connect (edited => \&cell_edited, [$model, $rows]);
	$renderer->set_data (column => $current_column );

	$treeview->insert_column_with_attributes 
				(
				-1, $column_title, $renderer,
				text => $current_column,
				editable => 5, 
				);
				
	$current_column++ ;
	}
}

#-----------------------------------------------------------------------------

sub cell_edited 
{
my ($cell, $path_string, $new_text, $model_and_rows) = @_;

my ($model, $rows) = @{$model_and_rows} ;

my $path = Gtk2::TreePath->new_from_string ($path_string);
my $column = $cell->get_data ("column");
my $iter = $model->get_iter($path);
my $row = ($path->get_indices)[0];

$rows->[$row][$column] = $new_text ;

$model->set($iter, $column, $new_text);
}

#-----------------------------------------------------------------------------

sub display_toggled 
{
my ($cell, $path_string, $model_and_rows) = @_;

my ($model, $rows) = @{$model_and_rows} ;

my $column = $cell->get_data ('column');
my $path = Gtk2::TreePath->new ($path_string) ;
my $iter = $model->get_iter ($path);
my $display = $model->get($iter, 0);

$rows->[$path_string][$column] = $display ^ 1 ;

$model->set ($iter, 0, $display ^ 1);
}

#-----------------------------------------------------------------------------

#~ sub add_item {
  #~ my ($button, $model) = @_;

  #~ push @articles, {
	#~ number => 0,
	#~ product => "Description here",
	#~ editable => TRUE,
  #~ };

  #~ my $iter = $model->append;
  #~ $model->set ($iter,
               #~ COLUMN_NUMBER, $articles[-1]{number},
               #~ COLUMN_PRODUCT, $articles[-1]{product},
               #~ COLUMN_EDITABLE, $articles[-1]{editable});
#~ }

#~ sub remove_item {
  #~ my ($widget, $treeview) = @_;
  #~ my $model = $treeview->get_model;
  #~ my $selection = $treeview->get_selection;

  #~ my $iter = $selection->get_selected;
  #~ if ($iter) {
      #~ my $path = $model->get_path ($iter);
      #~ my $i = ($path->get_indices)[0];
      #~ $model->remove ($iter);

      #~ splice @articles, $i;
  #~ }
#~ }

#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------
# GUIIO Dialog Code Begins Here...:
# This procedure will create a VBox containing all of the controls that GUIIO can control
# to allow users to select which UI component they want to have placed on the GUIIO surface

sub activate_guiio_component{
my ($self,$element_name,$x_pos,$y_pos) = @_;
$x_pos = 0 unless defined $x_pos;
$y_pos = 0 unless defined $y_pos;
	
my $control = $self->add_new_element_named($element_name, $x_pos,$y_pos) ;

if (index($element_name,'Radio Button') >= 0 or index($element_name,'Checkbox') >= 0)
{
	$control->SetChecked(TRUE);
} 
$self->update_display();
}
sub display_component_palette
{
my ($self) = @_;
my $root_dir = find_installed('App::Guiio');

	my ($basename, $path, $ext) = File::Basename::fileparse(find_installed('App::Guiio'), ('\..*')) ;
	$path = $path . $basename . '/';
	my $vbox = Gtk2::VBox->new (TRUE,4);
my $btnWindow = create_button('Window',$path . 'images/widget-gtk-dialog.png',TRUE);
my $btnButton = create_button('Button',$path . 'images/widget-gtk-button.png', TRUE);
my $btnTextbox = create_button('Textbox',$path . 'images/widget-gtk-entry.png', TRUE);
my $btnProgressBar = create_button('Progress Bar',$path .'images/widget-gtk-progressbar.png',TRUE);
my $btnScrollBar = create_button('Scroll Bar',$path .'images/widget-gtk-vscrollbar.png', TRUE);
my $btnSlider = create_button('Slider', $path .'images/widget-gtk-hscale.png', TRUE);
my $btnListbox = create_button('Listbox', $path .'images/widget-gtk-list.png',TRUE);
my $btnCombobox = create_button('Dropdown List', $path .'images/widget-gtk-combo.png',TRUE);
my $btnCalendar = create_button('Calendar',$path .'images/widget-gtk-calendar.png',TRUE);
my $btnRadioButton = create_button('Radio Button',$path . 'images/widget-gtk-radiobutton.png',TRUE);
my $btnCheckBox = create_button('Checkbox', $path .'images/widget-gtk-checkbutton.png',TRUE);
my $btnLabel = create_button('Label',$path . 'images/widget-gtk-label.png',TRUE);

$btnButton->signal_connect("clicked", sub { $self->activate_guiio_component('stencils/guiio/Button'); });
$btnWindow->signal_connect("clicked", sub { $self->activate_guiio_component('stencils/guiio/Window');});
$btnLabel->signal_connect("clicked", sub { $self->activate_guiio_component('stencils/guiio/Label');});
$btnListbox->signal_connect("clicked", sub { $self->activate_guiio_component('stencils/guiio/Listbox'); });
$btnRadioButton->signal_connect("clicked", sub { $self->activate_guiio_component('stencils/guiio/Radio Button');});
$btnCheckBox->signal_connect("clicked", sub { $self->activate_guiio_component('stencils/guiio/Checkbox');});
$btnProgressBar->signal_connect("clicked", sub { $self->activate_guiio_component('stencils/guiio/Progress Bar');});
$btnScrollBar->signal_connect("clicked", sub { $self->activate_guiio_component('stencils/guiio/Scroll Bar');});
$btnSlider->signal_connect("clicked", sub { $self->activate_guiio_component('stencils/guiio/Slider');});
$btnCalendar->signal_connect("clicked", sub{$self->activate_guiio_component('stencils/guiio/Calendar');});
$btnTextbox->signal_connect("clicked", sub{$self->activate_guiio_component('stencils/guiio/Textbox');});
$btnCombobox->signal_connect("clicked", sub{$self->activate_guiio_component('stencils/guiio/Combobox');});

$vbox->pack_start ($btnWindow, FALSE, FALSE, 0);
$vbox->pack_start ($btnLabel,FALSE, FALSE, 0);
$vbox->pack_start ($btnTextbox,FALSE, FALSE, 0);
$vbox->pack_start ($btnButton, FALSE, FALSE, 0);
$vbox->pack_start ($btnListbox,FALSE, FALSE, 0);
$vbox->pack_start ($btnCombobox,FALSE, FALSE, 0);
$vbox->pack_start ($btnRadioButton,FALSE, FALSE, 0);
$vbox->pack_start ($btnCheckBox,FALSE, FALSE, 0);
$vbox->pack_start ($btnScrollBar,FALSE, FALSE, 0);
$vbox->pack_start ($btnProgressBar,FALSE, FALSE, 0);
$vbox->pack_start ($btnSlider,FALSE, FALSE, 0);
$vbox->pack_start ($btnCalendar,FALSE, FALSE, 0);

$vbox->show_all();         

$btnWindow->set_focus_on_click(FALSE);
$btnButton->set_focus_on_click(FALSE);
$btnTextbox->set_focus_on_click(FALSE);
$btnProgressBar->set_focus_on_click(FALSE);
$btnScrollBar->set_focus_on_click(FALSE);
$btnSlider->set_focus_on_click(FALSE);
$btnListbox->set_focus_on_click(FALSE);
$btnCombobox->set_focus_on_click(FALSE);
$btnCalendar->set_focus_on_click(FALSE);
$btnRadioButton->set_focus_on_click(FALSE);
$btnCheckBox->set_focus_on_click(FALSE);
$btnLabel->set_focus_on_click(FALSE);

return $vbox;
}
1 ;
