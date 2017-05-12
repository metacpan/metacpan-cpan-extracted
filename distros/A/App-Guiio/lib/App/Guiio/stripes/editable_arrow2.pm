
package App::Guiio::stripes::editable_arrow2 ;

use base App::Guiio::stripes::stripes ;

use strict;
use warnings;

use List::Util qw(min max) ;
use Readonly ;
use Clone ;

#-----------------------------------------------------------------------------

Readonly my $DEFAULT_ARROW_TYPE => 
	[
	['Up', '|', '|', '^', 1, ],
	['45', '/', '/', '^', 1, ],
	['Right', '-', '-', '>', 1, ],
	['135', '\\', '\\', 'v', 1, ],
	['Down', '|', '|', 'v', 1, ],
	['225', '/', '/', 'v', 1, ],
	['Left', '-', '-', '<', 1, ],
	['315', '\\', '\\', '^', 1, ],
	] ;

sub new
{
my ($class, $element_definition) = @_ ;

my $self = bless  {}, __PACKAGE__ ;
	
$self->setup
	(
	$element_definition->{ARROW_TYPE} || Clone::clone($DEFAULT_ARROW_TYPE),
	$element_definition->{END_X}, 	$element_definition->{END_Y},
	$element_definition->{EDITABLE},
	) ;

return $self ;
}

#-----------------------------------------------------------------------------

sub setup
{
my ($self, $arrow_type, $end_x, $end_y, $editable) = @_ ;

my ($stripes, $real_end_x, $real_end_y) = $self->get_arrow($arrow_type, $end_x, $end_y) ;

$self->set
	(
	STRIPES => $stripes,
	END_X => $real_end_x,
	END_Y => $real_end_y,
	ARROW_TYPE => $arrow_type,
	) ;
}

#-----------------------------------------------------------------------------

sub get_arrow
{
my ($self,$arrow_type, $end_x, $end_y) = @_ ;
my ($stripes, $real_end_x, $real_end_y, $height, $width) = ([]) ;

$end_y *= 2 ; # compensate for aspect ratio

my $direction = $end_x >= 0
			? $end_y <= 0
				? -$end_y > $end_x
					? -$end_y / 4 > $end_x
						? 'up'
						:'up'
					: -$end_y > $end_x / 2
						? 'right'
						: 'right'
				: $end_y < $end_x
					? $end_y < $end_x / 2
						? 'right'
						:'right'
					: $end_y  / 4 < $end_x
						? 'down'
						: 'down'
			: $end_y < 0
				? $end_y < $end_x
					? $end_y / 4 < $end_x
						? 'up'
						: 'up'
					: $end_y < $end_x / 2
						? 'left'
						: 'left'
				: $end_y > -$end_x
					? $end_y / 4 > -$end_x
						? 'down'
						: 'down'
					: $end_y > -$end_x / 2
						? 'left'
						: 'left' ;

$end_y /= 2 ; # done compensating for aspect ratio

my $arrow ;

for ($direction)
	{
	$_ eq 'up' and do
		{
		my ($start, $body, $end) = @{$arrow_type->[0]}[1 .. 3] ;
		
		$height = -$end_y + 1 ;
		$real_end_y = $end_y ;
		$real_end_x = 0 ;
		
		$arrow = $height == 2
				? $start . "\n" . $end
				: index($self->{NAME},'Slider') >= 0 ? $height % 2 == 1 ? ("$start\n" x (($height-1)/2)) . $body . "\n" . ("$end\n" x (($height-1)/2)) :
														"$start\n" x (1+($height-1)/2) . $body . "\n" . "$end\n" x (($height-1)/2) :
														$start . "\n" . ("$body\n" x ($height -2)) . $end ;
				
		push @{$stripes},
			{
			'HEIGHT' => $height,
			'TEXT' => $arrow,
			'WIDTH' => 1,
			'X_OFFSET' => 0,
			'Y_OFFSET' => $end_y,
			};
			
		last ;
		} ;
		
		
	$_ eq 'right' and do
		{
		my ($start, $body, $end) = @{$arrow_type->[1]}[1 .. 3] ;
		
		$width = $end_x + 1 ;
		$real_end_x = $end_x ;
		$real_end_y = 0 ;
	
	
		$arrow = $width == 1
				? $end
				: $width == 2
					? $start . $end
					: index($self->{NAME},'Slider') >= 0 ? $width % 2 == 0 ? ($start x (($width-2)/2)) . $body . ($end x (($width-2)/2)) :
														$start x (1+($width-2)/2) . $body . $end x (($width-2)/2)
					: $start . ($body x ($width -2)) . $end ;
					
		push @{$stripes},
			{
			'HEIGHT' => 1,
			'TEXT' => $arrow,
			'WIDTH' => $width,
			'X_OFFSET' => 0,
			'Y_OFFSET' => 0,
			};
			
		last ;
		} ;
	$_ eq 'down' and do
		{
		my ($start, $body, $end) = @{$arrow_type->[2]}[1 .. 3] ;
		$height = $end_y + 1 ;
		$real_end_y = $end_y ;
		$real_end_x  = 0 ;
		
		$arrow = $height == 2
				? $start . "\n" . $end
				: index($self->{NAME},'Slider') >= 0 ? $height % 2 == 1 ? ("$start\n" x (($height-1)/2)) . $body . "\n" . ("$end\n" x (($height-1)/2)) :
														"$start\n" x (1+($height-1)/2) . $body . "\n" . "$end\n" x (($height-1)/2) :
														$start . "\n" . ("$body\n" x ($height -2)) . $end ;
				
		push @{$stripes},
			{
			'HEIGHT' => $height,
			'TEXT' => $arrow,
			'WIDTH' => 1,
			'X_OFFSET' => 0,
			'Y_OFFSET' => 0,
			};
		last ;
		} ;
	$_ eq 'left' and do
		{
		my ($start, $body, $end) = @{$arrow_type->[3]}[1 .. 3] ;
		
		$width = -$end_x + 1 ;
		
		$real_end_y = 0 ;
		$real_end_x = $end_x ;
		
		$arrow = $width == 2
				? $start . $end
				: index($self->{NAME},'Slider') >= 0 ? $width % 2 == 0 ? ($start x (($width-2)/2)) . $body . ($end x (($width-2)/2)) :
														$start x (1+($width-2)/2) . $body . $end x (($width-2)/2) 
														: $start . ($body x ($width -2)) . $end ;
				
		push @{$stripes},
			{
			'HEIGHT' => 1,
			'TEXT' => $arrow,
			'WIDTH' => $width,
			'X_OFFSET' => $end_x,
			'Y_OFFSET' => 0,
			};
			
		last ;
		} ;
	}

return($stripes, $real_end_x, $real_end_y) ;
}

#-----------------------------------------------------------------------------

sub get_extra_points
{
my ($self) = @_ ;

return
	(
	{X =>  $self->{START_X}, Y => $self->{START_Y}, NAME => 'resize'},
	) ;
}

#-----------------------------------------------------------------------------

sub get_selection_action
{
my ($self, $x, $y) = @_ ;

if ($x == $self->{END_X} && $y == $self->{END_Y})
	{
	'resize' ;
	}
else
	{
	'move' ;
	}
}

#-----------------------------------------------------------------------------

sub resize
{
my ($self, $reference_x, $reference_y, $new_x, $new_y) = @_ ;

my $new_end_x = $new_x ;
my $new_end_y = $new_y ;

$self->setup($self->{ARROW_TYPE}, $new_end_x, $new_end_y, $self->{EDITABLE}) ;

return(0, 0, $self->{END_X} + 1, $self->{END_X} + 1) ;
}

#-----------------------------------------------------------------------------

sub get_text
{
my ($self) = @_ ;
}

#-----------------------------------------------------------------------------

sub set_text
{
my ($self) = @_ ;
}

#-----------------------------------------------------------------------------

sub edit
{
my ($self) = @_ ;

return unless $self->{EDITABLE} ;

display_box_edit_dialog($self->{ARROW_TYPE}) ;

$self->setup($self->{ARROW_TYPE}, $self->{END_X}, $self->{END_Y}, $self->{EDITABLE}) ;
}

use Glib ':constants';
use Gtk2 -init;
use Glib qw(TRUE FALSE);

sub display_box_edit_dialog
{
my ($rows) = @_ ;

my $window = new Gtk2::Window() ;

my $dialog = Gtk2::Dialog->new('Arrow attributes', $window, 'destroy-with-parent')  ;
$dialog->set_default_size (220, 270);
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

$treeview->show() ;
$vbox->show() ;
$sw->show() ;

$dialog->run() ;

$dialog->destroy ;
}

#-----------------------------------------------------------------------------

sub create_model 
{
my ($rows) = @_ ;

my $model = Gtk2::ListStore->new(qw/Glib::String Glib::String  Glib::String  Glib::String Glib::Boolean/);

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

# column for row titles
my $row_renderer = Gtk2::CellRendererText->new;
$row_renderer->set_data (column => 0);

$treeview->insert_column_with_attributes
			(
			-1, '', $row_renderer,
			text => 0,
			) ;
my $column = $treeview->get_column(0) ;
$column->set_sizing('fixed') ;
$column->set_fixed_width(80) ;

my $current_column = 1 ;
for my $column_title('start', 'body', 'end')
	{
	my $renderer = Gtk2::CellRendererText->new;
	$renderer->signal_connect (edited => \&cell_edited, [$model, $rows]);
	$renderer->set_data (column => $current_column );

	$treeview->insert_column_with_attributes 
				(
				-1, $column_title, $renderer,
				text => $current_column,
				editable => 4, 
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

1 ;
