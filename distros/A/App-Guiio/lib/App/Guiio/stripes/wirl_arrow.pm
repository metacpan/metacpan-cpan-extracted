
package App::Guiio::stripes::wirl_arrow ;

use base App::Guiio::stripes::stripes ;

use strict;
use warnings;

use List::Util qw(min max) ;
use Readonly ;
use Clone ;

#-----------------------------------------------------------------------------

Readonly my $DEFAULT_ARROW_TYPE => 
	[
	#name: $start, $body, $connection, $body_2, $end
	
	['origin', '', '*', '', '', '', 1],
	['up', '|', '|', '', '', '^', 1],
	['down', '|', '|', '', '', 'v', 1],
	['left', '-', '-', '', '', '<', 1],
	['upleft', '|', '|', '.', '-', '<', 1],
	['leftup', '-', '-', '\'', '|', '^', 1],
	['downleft', '|', '|', '\'', '-', '<', 1],
	['leftdown', '-', '-', '.', '|', 'v', 1],
	['right', '-', '-','', '', '>', 1],
	['upright', '|', '|', '.', '-', '>', 1],
	['rightup', '-', '-', '\'', '|', '^', 1],
	['downright', '|', '|', '\'', '-', '>', 1],
	['rightdown', '-', '-', '.', '|', 'v', 1],
	['45', '/', '/', '', '', '^', 1, ],
	['135', '\\', '\\', '', '', 'v', 1, ],
	['225', '/', '/', '', '', 'v', 1, ],
	['315', '\\', '\\', '', '', '^', 1, ],
	] ;

sub new
{
my ($class, $element_definition) = @_ ;

my $self = bless  {}, __PACKAGE__ ;
	
$self->setup
	(
	$element_definition->{ARROW_TYPE},
	$element_definition->{END_X}, $element_definition->{END_Y},
	$element_definition->{DIRECTION},
	$element_definition->{ALLOW_DIAGONAL_LINES},
	$element_definition->{EDITABLE},
	) ;

return $self ;
}

#-----------------------------------------------------------------------------

sub setup
{
my ($self, $arrow_type, $end_x, $end_y, $direction, $allow_diagonal_lines, $editable) = @_ ;

my ($stripes, $width, $height) ;

($stripes, $width, $height, $direction) = get_arrow($arrow_type, $end_x, $end_y, $direction, $allow_diagonal_lines) ;

$self->set
	(
	STRIPES => $stripes,
	WIDTH => $width,
	HEIGHT => $height,
	DIRECTION => $direction,
	ARROW_TYPE => $arrow_type,
	END_X => $end_x,
	END_Y => $end_y,
	ALLOW_DIAGONAL_LINES => $allow_diagonal_lines,
	) ;
}

#-----------------------------------------------------------------------------

my %direction_to_arrow = 
	(
	'origin' => \&draw_origin,
	'up' => \&draw_up,
	'down' => \&draw_down,
	'left' => \&draw_left,
	'right' => \&draw_right,
	) ;
	
sub get_arrow
{
my ($arrow_type, $end_x, $end_y, $direction, $allow_diagonal_lines) = @_ ;

use constant CENTER => 1 ;
use constant LEFT => 0 ;
use constant RIGHT => 2 ;
use constant UP => 0 ;
use constant DOWN => 2 ;
print $direction;
my @position_to_direction =
	(
	[$direction =~ /^up/ ? 'left' : 'left', 'left',  $direction =~ /^down/ ? 'left' : 'left'] ,
	['up', 'origin', 'down'],
	[$direction =~ /^up/ ? 'right' : 'up', 'up', $direction =~ /^down/ ? 'down' : 'down'],
	) ;

$direction = $position_to_direction
			[$end_x == 0 ? CENTER : $end_x < 0 ? LEFT : RIGHT]
			[$end_y == 0 ? CENTER : $end_y < 0 ? UP : DOWN] ;

return($direction_to_arrow{$direction}->($arrow_type, $end_x, $end_y, $allow_diagonal_lines), $direction) ;
}

sub draw_down
{
my ($arrow_type, $end_x, $end_y) = @_ ;

my ($stripes, $width, $height) = ([], 1, $end_y + 1) ;
my ($start, $body, $connection, $body_2, $end) = @{$arrow_type->[2]}[1 .. 5] ;

push @{$stripes},
	{
	'HEIGHT' => $height,
	'TEXT' => $height == 2	? "$start\n$end" : $start . "\n" . ("$body\n" x ($height -2)) . $end,
	'WIDTH' => 1,
	'X_OFFSET' => 0,
	'Y_OFFSET' => 0,
	};
	
return($stripes, $width, $height) ;
}

sub draw_origin
{
my ($arrow_type, $end_x, $end_y) = @_ ;

my ($stripes, $width, $height) = ([], 1, 1) ;
my ($start, $body, $connection, $body_2, $end) = @{$arrow_type->[0]}[1 .. 5] ;

push @{$stripes},
	{
	'HEIGHT' => 1,
	'TEXT' => $body,
	'WIDTH' => 1,
	'X_OFFSET' => 0,
	'Y_OFFSET' => 0,
	};
	
return($stripes, $width, $height) ;
} 

sub draw_up
{
my ($arrow_type, $end_x, $end_y) = @_ ;

my ($stripes, $width, $height) = ([], 1, -$end_y + 1) ;
my ($start, $body, $connection, $body_2, $end) = @{$arrow_type->[1]}[1 .. 5] ;

push @{$stripes},
	{
	'HEIGHT' => $height,
	'TEXT' => $height == 2 ? "$end\n$start" : $end . "\n" . ("$body\n" x ($height -2)) . $start, 
	'WIDTH' => 1,
	'X_OFFSET' => 0,
	'Y_OFFSET' => $end_y, 
	};
	
return($stripes, $width, $height) ;
}

sub draw_left
{
my ($arrow_type, $end_x, $end_y) = @_ ;

my ($stripes, $width, $height) = ([], -$end_x + 1, 1) ;
my ($start, $body, $connection, $body_2, $end) = @{$arrow_type->[3]}[1 .. 5] ;

push @{$stripes},
	{
	'HEIGHT' => 1,
	'TEXT' => $width == 2 ? "$end$start" : $end . $body x ($width -2) . $start,
	'WIDTH' => $width,
	'X_OFFSET' => $end_x,
	'Y_OFFSET' => 0,
	};
	
return($stripes, $width, $height) ;
}


sub draw_right
{
my ($arrow_type, $end_x, $end_y) = @_ ;

my ($stripes, $width, $height) = ([], $end_x + 1, 1) ;
my ($start, $body, $connection, $body_2, $end) = @{$arrow_type->[8]}[1 .. 5] ;

push @{$stripes},
	{
	'HEIGHT' => 1,
	'TEXT' => $width == 2 ? "$start$end" : $start . $body x ($width -2) . $end,
	'WIDTH' => $width,
	'X_OFFSET' => 0,
	'Y_OFFSET' => 0,
	};
	
return($stripes, $width, $height) ;
}
#-----------------------------------------------------------------------------

sub get_selection_action
{
my ($self, $x, $y) = @_ ;

if	(
	   ($x == 0 && $y == 0)
	|| ($x == $self->{END_X} && $y == $self->{END_Y})
	)
	{
	'resize' ;
	}
else
	{
	'move' ;
	}
}

#-----------------------------------------------------------------------------

sub get_connector_points
{
my ($self) = @_ ;

return
	(
	{X => 0, Y => 0, NAME => 'start'},
	{X => $self->{END_X}, Y => $self->{END_Y}, NAME => 'end'},
	) ;
}
#-----------------------------------------------------------------------------

sub get_named_connection
{
my ($self, $name) = @_ ;

if($name eq 'start')
	{
	return( {X => 0, Y => 0, NAME => 'start'} ) ;
	}
elsif($name eq 'end')
	{
	return( {X => $self->{END_X}, Y => $self->{END_Y}, NAME => 'end'} ) ;
	}
else
	{
	return ;
	}
}

#-----------------------------------------------------------------------------

sub get_section_direction
{
my ($self, $section_index) = @_ ;

return $self->{DIRECTION} ;
}

#-----------------------------------------------------------------------------

sub move_connector
{
my ($self, $connector_name, $x_offset, $y_offset, $hint) = @_ ;

if($connector_name eq 'start')
	{
	my ($x_offset, $y_offset, $width, $height, undef) = 
		$self->resize(0, 0, $x_offset, $y_offset, $hint) ;
	
	return 
		$x_offset, $y_offset, $width, $height,
		{X => $self->{END_X}, Y => $self->{END_Y}, NAME => 'start'} ;
	}
elsif($connector_name eq 'end')
	{
	my ($x_offset, $y_offset, $width, $height, undef) = 
		$self->resize(-1, -1, $self->{END_X} + $x_offset, $self->{END_Y} + $y_offset, $hint) ;

	return 
		$x_offset, $y_offset, $width, $height,
		{X => $self->{END_X}, Y => $self->{END_Y}, NAME => 'end'} ;
	}
else
	{
	die "unknown connector '$connector_name'!\n" ;
	}
}

#-----------------------------------------------------------------------------

sub resize
{
my ($self, $reference_x, $reference_y, $new_x, $new_y, $hint, $connector_name) = @_ ;

my $is_start ;

if(defined $connector_name)
	{
	if($connector_name eq 'start')
		{
		$is_start++ ;
		}
	}
else
	{
	if($reference_x == 0 && $reference_y == 0)
		{
		$is_start++ ;
		}
	}

if($is_start)
	{
	my $x_offset = $new_x ;
	my $y_offset = $new_y ;
	
	my $new_end_x = $self->{END_X} - $x_offset ;
	my $new_end_y = $self->{END_Y} - $y_offset ;
	
	$self->setup($self->{ARROW_TYPE}, $new_end_x, $new_end_y, $hint || $self->{DIRECTION},$self ->{ALLOW_DIAGONAL_LINES}, $self->{EDITABLE}) ;

	return($x_offset, $y_offset, $self->{WIDTH}, $self->{HEIGHT}, 'start') ;
	}
else
	{
	my $new_end_x = $new_x ;
	my $new_end_y = $new_y ;

	$self->setup($self->{ARROW_TYPE}, $new_end_x, $new_end_y, $hint || $self->{DIRECTION}, $self ->{ALLOW_DIAGONAL_LINES}, $self->{EDITABLE}) ;

	return(0, 0, $self->{WIDTH}, $self->{HEIGHT}, 'end') ;
	}
}

#-----------------------------------------------------------------------------

sub edit
{
my ($self) = @_ ;

return unless $self->{EDITABLE} ;

display_arrow_edit_dialog($self->{ARROW_TYPE}) ; # inline modification

my ($stripes, $width, $height, $x_offset, $y_offset) =
	$direction_to_arrow{$self->{DIRECTION}}->($self->{ARROW_TYPE}, $self->{END_X}, $self->{END_Y}) ;

$self->set(STRIPES => $stripes,) ;
}

use Glib ':constants';
use Gtk2 -init;
use Glib qw(TRUE FALSE);

sub display_arrow_edit_dialog
{
my ($rows) = @_ ;

my $window = new Gtk2::Window() ;

my $dialog = Gtk2::Dialog->new('Arrow attributes', $window, 'destroy-with-parent')  ;
$dialog->set_default_size (450, 505);
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

my $model = Gtk2::ListStore->new(qw/Glib::String Glib::String Glib::String  Glib::String  Glib::String Glib::String Glib::Boolean/);

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
$column->set_fixed_width(120) ;

my $current_column = 1 ;
for my $column_title('start', 'body', 'connection', 'body_2', 'end')
	{
	my $renderer = Gtk2::CellRendererText->new;
	$renderer->signal_connect (edited => \&cell_edited, [$model, $rows]);
	$renderer->set_data (column => $current_column );

	$treeview->insert_column_with_attributes 
				(
				-1, $column_title, $renderer,
				text => $current_column,
				editable => 6, 
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









