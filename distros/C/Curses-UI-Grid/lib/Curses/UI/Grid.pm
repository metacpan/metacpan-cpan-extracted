package Curses::UI::Grid;

###############################################################################
# subclass of Curses::UI::Grid is a widget that can be used to display 
# and manipulate data in grid model 
#
# (c) 2004 by Adrian Witas. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as perl itself.
###############################################################################

use strict;
use warnings;


use Curses;
use Curses::UI::Widget;
use Curses::UI::Common;

use vars qw(
    $VERSION 
    @ISA
);

$VERSION = '0.15';


@ISA = qw(
    Curses::UI::Common
    Curses::UI::Widget
);




=head1 NAME

Curses::UI::Grid - Create and manipulate data in grid model

=head1 CLASS HIERARCHY

 Curses::UI::Widget
    |
    +----Curses::UI::Grid


=head1 SYNOPSIS

    use Curses::UI;
    my $cui = new Curses::UI;
    my $win = $cui->add('window_id', 'Window');
    my $grid =$win->add(
      'mygrid', 'Grid'
      -rows    => 3,
      -columns => 5,
    );

    # set header desc 
    $grid->set_label("cell$_", "Head $_")
      for (1 .. 5);

    # add some data
    $grid->set_cell_value("row1", "cell$_", "value $_")
      for 1 .. 5;
    my $val = $grid->get_value("row1", "cell2");


=head1 DESCRIPTION


       Curses::UI::Grid is a widget that can be used to
       browsing or manipulate data in grid model


      See exampes/grid-demo.pl in the distribution for a short demo.


=head1 STANDARD OPTIONS

       -parent, -x, -y, -width, -height, -pad, -padleft,
       -padright, -padtop, -padbottom, -ipad, -ipadleft,
       -ipadright, -ipadtop, -ipadbottom, -title,
       -titlefull-width, -titlereverse, -onfocus, -onblur,
       -fg,-bg,-bfg,-bbg

=head1 WIDGET-SPECIFIC OPTIONS

=over

=item * B<-basebindings> < HASHREF >

Basebindings is assigned to bindings with editbindings  
if editable option is set.

Hash key is a keystroke and the value is a routines that will be  bound.  In the event key is empty,
the corresponding routine will become the default routine for all not mapped keys.


B<process_bindings> applies to unmatched keystrokes it receives.

By default, the following mappings are used for basebindings:

    KEY                 ROUTINE
    ------------------  ----------
    CUI_TAB             next_cell
    KEY_ENTER()         next_cell
    KEY_BTAB()          prev-cell
    KEY_UP()            prev_row
    KEY_DOWN()          next_row
    KEY_RIGHT()         cursor_right
    KEY_LEFT()          cursor_left
    KEY_HOME()          cursor_home
    KEY_END()           cursor_end
    KEY_PPAGE()         grid_pageup
    KEY_NPAGE()         grid_pagedown

=cut

my %basebindings = (
  CUI_TAB()                => 'next-cell',
  KEY_ENTER()              => 'next-cell',
  KEY_BTAB()               => 'prev-cell',
  KEY_UP()                 => 'prev-row',
  KEY_DOWN()               => 'next-row',
  KEY_RIGHT()              => 'cursor-right',
  KEY_LEFT()               => 'cursor-left',
  KEY_HOME()              =>  'cursor-home',
  KEY_END()               =>  'cursor-end',
  KEY_PPAGE()              => 'grid-pageup',
  KEY_NPAGE()              => 'grid-pagedown',
);

=item * B<-editindings> < HASHREF >

By default, the following mappings are used for basebindings:


    KEY                 ROUTINE
    ------------------  ----------
    any                 add_string
    KEY_DC()            delete_character
    KEY_BACKSPACE()     backspace
    KEY_IC()            insert_row
    KEY_SDC()           delete_row

=cut

my %editbindings = (
  ''              => 'add-string',
  KEY_IC()        => 'insert-row',
  KEY_SDC()       => 'delete-row',
  KEY_DC()        => 'delete-character',
  KEY_BACKSPACE() => 'backspace',
);


=item * B<-routines> < HASHREF >

    ROUTINE          ACTION
    ----------       -------------------------
    loose_focus      loose grid focus
    first_row        make first row active
    last_row         make last  row active
    grid-pageup      trigger event -onnextpage
    grid-pagedown    trigger event -onprevpage

    next_row         make next row active
    prev_row         make prev row active


    next_cell        make next cell active
    prev_cell        make prev cell active
    first_cell       make first row active
    last_cell        make last  row active

    cursor_home      move cursor into home pos in focused cell
    cursor_end       move cursor into end pos in focused cell
    cursor_righ      move cursor right in focused cell
    cursor_left      move cursor left in focused cell
    add_string       add string to focused cell
    delete_row       delete active row from grid, shift rows upstairs
    insert_row       insert row in current position

    delete_character delete_character from focused cell
    backspace        delete_character from focused cell

=cut


my %routines = (
  'loose-focus'      => \&loose_focus,
  'cursor-right'     => \&cursor_right,
  'cursor-left'      => \&cursor_left,
  'add-string'       => \&add_string,
  'grid-pageup'      => \&grid_pageup,
  'grid-pagedown'    => \&grid_pagedown,
  'cursor-home'      => \&cursor_to_home,
  'cursor-end'       => \&cursor_to_end,
  'next-cell'        => \&next_cell,
  'prev-cell'        => \&prev_cell,
  'next-row'         => \&next_row,
  'prev-row'         => \&prev_row,
  'insert-row'       => \&insert_row,
  'delete-row'       => \&delete_row,
  'delete-character' => \&delete_character,
  'backspace'        => \&backspace,
  'mouse-button1'    => \&mouse_button1,
);


=item * B<-editable>  < BOOLEAN > 

The grid widget will be created as a editable grid for the truth value,
otherwise it will be in read  only mode (data viewer) 
Default value is true.


=item * B<-columns>   < COLUMNS > 

This option control how many cell objects should be created for the grid widget. 
Default value is 0. If this value is set to non FALSE, construtor creates empty cells.


=item * B<-rows>  < ROWS >  

This option control how many row objects should be created for the grid widget. 
Default value is 0. If this value is set to non FALSE, construtor creates empty rows.


=item * B<-count>   < COUNT >

This option store logical number of all rows.
It can be used for calculating vertical scroll.


=item * B<-page>  < NUMBER >  

This option store logical number of current page.
It can be used for calculating vertical scroll.

=back

=head2 GRID EVENTS

=over

=item * B<-onnextpage>  < CODEREF >

This sets the onnextpage event handler for the widget.
If the widget trigger event nextpage, the code in CODEREF will
be executed.

=item * B<-onprevpage>  < CODEREF >

This sets the onnextpage event handler for the widget.
If the widget trigger event previouspage, the code in CODEREF will
be executed.

=back

=head2 GRID-ROW-SPECIFIC OPTIONS

=over

=item * B<-onrowdraw> < CODEREF >

This sets the onrowdraw event handler for the widget.
If the widget trigger event rowdraw, the code in CODEREF will
be executed. 
This can be useful for dynamically setting colors
appropriate to some conditions.

    my $grid=$w->add('grid'
      'Grid',
      -rows      => 3,
      -columns   => 4,
      -onrowdraw => sub {
        my $row = shift;
        #check conditions and set color for row
        my $value = $row->get_value('cell0');
            # some stuff here
            #....
        if ( .... ) {
            $row->bg('black');
            $row->fg('yellow');
        } else { 
          # return back to origin color
          $row->bg(''); 
          $row->fg(''); 
        }
      },
    );


=item * B<-onrowfocus> < CODEREF >

This sets the onrowfocus event handler for the widget.
If the widget trigger event rowfocus, the code in CODEREF will
be executed. 

=item * B<-onrowblur>   < CODEREF >

This sets the onrowblur event handler for the widget.
If the widget trigger event rowblur, the code in CODEREF will
be executed.  The CODEREF can return FALSE to cancel rowblur 
action and current row will not lose the focus.

=item * B<-onrowchange> < CODEREF >

This sets the onrowchange event handler for the widget.
If the widget trigger event rowchange, the code in CODEREF will
be executed. The CODEREF can return FALSE to cancel onrowblur 
action and current row will not lose the focus.

=item * B<-onbeforerowinsert> < CODEREF >

This sets the onbeforerowinsert event handler for the widget.
If the widget trigger event onbeforerowinsert, the code in CODEREF will
be executed. The CODEREF can return FALSE to cancel insert_row action
See more about insert_row method.

=item * B<-onrowinsert> < CODEREF >

This sets the oninsert event handler for the widget.
If the row widget trigger event onrowinsert, the code in CODEREF will
be executed. See more about insert_row method.


=item * B<-onrowdelete> < CODEREF >

This sets the onrowdelete event handler for the widget.
If the widget trigger event onrowdelete, the code in CODEREF will
be executed. The CODEREF can return FALSE to cancel delete_row action
See more about delete_row method.

=item * B<-onfterrowdelete> < CODEREF >
This sets the onrowdelete event handler for the widget.
If the widget trigger event onrowdelete, the code in CODEREF will
be executed. See more about delete_row method

=back

=head2 GRID-CELL-SPECIFIC OPTIONS

=over

=item * B<-oncelldraw>   < CODEREF >

This sets the oncelldraw event handler for the widget.
If the widget trigger event celldraw, the code in CODEREF will
be executed. Gets the cell widget reference as its
argument. 


=item * B<-oncellfocus>  < CODEREF >

This sets the oncellfocus event handler for the widget.
If the widget trigger event cellfocus, the code in CODEREF will
be executed. Gets the cell  widget reference as its
argument. 


=item * B<-oncellblur>   < CODEREF >

This sets the oncellblur event handler for the widget.
If the widget trigger event cellblur, the code in CODEREF will
be executed. Gets the cell  widget reference as its
argument. The CODEREF can return FALSE to cancel oncellblur 
action and current cell will not lose the focus.

    my $grid = $w->add('grid'
        'Grid'
        -rows     => 3,
        -columns  => 4,
        -oncellblur => sub {
            my $cell=shift;
            # some validation 
            if(... ) {
                  return 0; # cancel oncellblur event
            }
            $cell;
        },
    );

=item * B<-oncellchange> < CODEREF >

This sets the oncellchange event handler for the widget.
If the widget trigger event cellchange, the code in CODEREF will
be executed. Gets the cell  widget reference as its
argument. The CODEREF can return FALSE to cancel oncellblur 
action and current cell will not lose the focus.


    my $grid=$w->add('grid'
      'Grid',
      -rows       => 3,
      -columns    => 4,
      -oncellblur => sub {
          my $cell=shift;
          my $old_value=$cell->text_undo;
          my $value=$cell->text;
          # some validation 
          if(... ) {
              return 0; # cancell oncellchange and oncellblur event 
          }
          return $cell;
          }
    );


=item * B<-oncellkeypress> < CODEREF >

This sets the oncellkeypress event handler for the widget.
If the widget trigger event cellkeypress, the code in CODEREF will
be executed. Gets the cell  widget reference and added string as its
argument. The cellkeypress event is called by method add_string 
in cell obejct. The CODEREF can return FALSE to cancel add_string action.


=item * B<-oncelllayout> < CODEREF >

This sets the oncelllayout event handler for the widget.
If the widget trigger event cellkeypress, the code in CODEREF will
be executed. Gets the cell widget  reference and value as its
argument. The CODEREF can return any text which will be proceeded
insted of the orgin value.

    my $grid = $w->add('grid'
      'Grid',
      -rows         => 3,
      -columns      => 4,
      -oncelllayout => sub {
          my $cell = shift;
          my $value = $cell->text;
          # mask your value
          ....
          return $value;
      }
    );

=cut

=back

=head2 METHODS

=over

=item debug_msg

Debugs messages.

=cut

sub debug_msg {
    return unless ($Curses::UI::debug);
    my $caller = (caller(1))[3];
    my $msg = shift || '';
    my $indent = ($msg =~ /^(\s+)/ ? $1 : '');
    $msg =~ s/\n/\nDEBUG: $indent/mg;

    warn 'DEBUG: ' .
        ($msg ?
            "$msg in $caller" :
            "$caller() called by " . ((caller(2))[3] || 'main')
        ) .
        "().\n";
}


=item new( OPTIONS )

Constructs a new grid object. 
Takes list of options as parameters.

=cut

sub new {
    my $class = shift;
    my %userargs = @_;
    keys_to_lowercase(\%userargs);
    
    # support only arguments listed in @valid_args;
    my @valid_args = (
      'x', 'y', 'width', 'height',
      'pad', 'padleft', 'padright', 'padtop', 'padbottom',
      'ipad', 'ipadleft', 'ipadright', 'ipadtop', 'ipadbottom',
      'border','bg', 'fg' ,'bfg' ,'bbg','titlereverse',
      'intellidraw',
      'onrowchange',
      'onfocus','onblur','onnextpage','onprevpage',
      'onrowdraw','onrowfocus','onrowblur','onrowchange',
      'onbeforerowinsert','onrowinsert','onrowdelete','onafterrowdelete',
      'oncelldraw','oncellfocus','oncellblur','oncellchange','oncelllayout','oncellkeypress',
      'routines', 'basebindings','editbindings',
      'parent',
      'rows','columns','editable',
      'test_more',
      'sh','sw',
      'canvasscr',
    );
    
    foreach my $arg (keys %userargs) {
        unless (grep($arg eq "-$_", @valid_args)) {
            debug_msg ("  deleting invalid arg '$arg'");
            delete $userargs{$arg};
        }
    }

    my %args = ( 
      # Parent info
     -parent            => undef,          # the parent object

      # Position and size
      -x                 => 0,            # horizontal position (rel. to -window)
      -y                 => 0,            # vertical position (rel. to -window)
      -width             => undef,        # horizontal editsize, undef = stretch
      -height            => undef,        # vertical editsize, undef = stretch

      # Initial state
      -xpos              => 0,            # cursor position
      -ypos              => 0,            # cursor position

      # General options
      -border            => undef,        # use border?
      -frozen_with       => 0,
      -x_offsetbar       => 0,            # show vertical scrollbar
      -hscrollbar        => 0,            # show horizontal scrollbar
      -x_offset          => 0,            # vertical offset
      -hscroll           => 0,            # horizontal offset
      -editable          => 1,            # 0 - only used as viewer
      -focus             => 1,

      # Events
      # grid event
      -onfocus           => undef,
      -onblur            => undef,
      -onnextpage        => undef,
      -onprevpage        => undef,

      # row event
      -onrowblur         => undef,
      -onrowfocus        => undef,
      -onrowchange       => undef,
      -onrowdraw         => undef,
      -onbeforerowinsert => undef,
      -onrowinsert       => undef,
      -onrowdelete       => undef, 
      -onafterrowdelete  => undef,
      # cell event
      -oncellblur        => undef,
      -oncellfocus       => undef,
      -oncellchange      => undef,
      -oncelldraw        => undef,
      -oncellkeypress    => undef,
      -oncelllayout      => undef,


      # Grid model 
      -columns           => 0,            # number of coluns
      -rows              => 0,            # number of rows
      -page_size         => 0,            # max number rows in grid = canvasheight - 2
      -row_idx_prev      => 0,            # previous row idx
      -row_idx           => 0,            # current index idx
      -cell_idx_prev     => 0,            # current cell idx
      -cell_idx          => 0,            # current cell idx
      -count             => 0,            # numbers of all rows from data source
      -page              => 0,            # current page
      _cells             => [],           # collection of cells id
      _rows              => [],           # collection of rows id
      -rowid2idx         => {},
      -focusable         => 1,
      -test_more         => undef,
      %userargs,
      -routines          => {%routines},  # binding routines

      # Init values
      -focus             => 0,
    );


    #overwrite base bindings
    %basebindings = (%{$args{-basebindings}}) if exists($args{-basebindings});
    #overwrite base editbindings
    %editbindings = (%{$args{-editbindings}}) if exists($args{-editbindings});
    
    # Create the Widget.
    my $this = $args{-test_more} 
    ? bless {%args}, $class
    : $class->Curses::UI::Widget::new( %args );
    
    $this->set_mouse_binding('mouse-button1', BUTTON1_CLICKED())
      if ($Curses::UI::ncurses_mouse && ! $this->test_more);
    
    $this->initialise(%args);
} 


=item initialise( OPTIONS )

Initialises Grid object

=cut

sub initialise {
    my ($this, %args) = @_;
    $this->{-page_size} = $this->canvasheight - 2;
    $this->add_row('header', %args, -type => 'head');
    $this->create_default_cells;       # if column is not FALSE add empty cells to grid
    $this->create_default_rows;        # if rows is not FALSE add empty rows to grid
    $this->{-xpos}     = 0;   # X position for cursor in the document
    $this->{-ypos}     = 0;   # Y position for cursor in the document
    $this->layout_content;     
    $this->editable($args{-editable}); 
    return $this;
}


=item id2cell

Return cell object, taks cell id.

=cut

sub id2cell{ 
    my ($this, $id) = @_;
    $this->{-id2cell}{$id}
}


=item id

=cut

sub id  {shift()->{-id}}


=item readonly

=cut

sub readonly  { shift()->{-readonly}  }


=item canvasscr

Returns canva ref.

=cut

sub canvasscr { shift()->{-canvasscr} }


=item test_more

Returns flag if uses test mode.

=cut

sub test_more { shift()->{-test_more} }


=item editable( BOOLEAN )

Sets bindings model for editable gird if passed in varaible is true, otherwise
read-only model will be set.

=cut 

sub editable {
    my ($this, $editable) = @_;
    $this->{-editable} = $editable;

    if ($editable) {
        $this->{-bindings} = {
          %basebindings,
          %editbindings
        };

    } else {
        $this->{-bindings} = {%basebindings};
    }
    $this;
}


=item bindings

Sets/gets binigs for Grid.

=cut

sub bindings {
    my ($this, $bindings) = @_;
    $this->{-bindings} = $bindings
      if defined $bindings;
    $this->{-bindings};
}

=item create_default_rows( OPTIONS )

Creates defaults rows for grid. 
Takes grid options as parameters.
Number of rows to be created is taken from
-rows options passed in or from -rows grid's attribute

=cut

sub create_default_rows {
    my ($this, %userargs) = @_;
    keys_to_lowercase(\%userargs);
    my $rows = exists $userargs{-rows} 
      ? $userargs{-rows} 
      : $this->{-rows};
      
    for my $i (1  ..  $rows ) {
        $this->add_row("row$i",
          -type  => 'data',
          -fg    => -1,
          -bg    => -1,
          -cells =>{},
        );
    }
}


=item create_default_cells( OPTIONS )

Creates defaults cells for grid.
Takes grid options as parameters.
Number of rows to be created is taken from
-cells options passed in or from -cells grid's attribute

=cut

sub create_default_cells {
    my ($this, %userargs) = @_;
    keys_to_lowercase(\%userargs);
    my $cols = $this->{-columns};
    $this->add_cell("cell$_", 
      -width  => 10,
      -align => 'L', 
      %userargs,
    ) for 1 .. $cols;
    
}


=item current_cell_index

Sets/gets current cell index.

=cut

sub current_cell_index {
    my ($this, $index) = @_;
    $this->{-cell_idx} = $index 
      if defined $index;
    $this->{-cell_idx};
}


=item cell_id ( INDEX )

Returns current cell id. Takes cell position index. 

=cut

sub cell_id {
    my ($this, $index) = @_;
    $index ||= $this->current_cell_index;
    my $cells = $this->_cells;
    $cells->[$index]
}


=item cell_index_for_id

=cut

sub cell_index_for_id {
    my ($this, $id, $index) = @_;
    my $cellid2idx = $this->{-cellid2idx};
    $cellid2idx->{$id} = $index
      if defined $index;
    $cellid2idx->{$id};  
}


=item cell( ID, cell )

Sets/gets cell for passed in id.

=cut

sub cell {
    my ($this, $id, $cell) = @_;
    my $id2cell = $this->{-id2cell};
    $id2cell->{$id} = $cell
      if defined $cell;
    $id2cell->{$id};
}


=item _cells

Returns id cells list.

=cut

sub _cells {
    my $this = shift;
    $this->{_cells};
}

=item cells_count

Returns number of defined cells - 1;

=cut

sub cells_count {
    my $this = shift;
    $#{$this->{_cells}};
}


=item cell_for_x_position

Return cell for passed in x position.

=cut

sub cell_for_x_position {
   my ($this, $x) = @_;
   my $cells = $this->{_cells};
   my $event_cell = $cells->[0];
   my $line_width = 0;
   
   for my $i (0 ..$#{$cells}) {
        my $cell = $this->id2cell($cells->[$i]);
        unless ($cell->hidden) {
            return $event_cell
              if ($x >= $line_width && $x < $line_width + $cell->current_width + 1);
            $line_width += $cell->current_width+1;
        }
    }
    $event_cell;
}


=item current_row_index

Sets/gets current row index.

=cut

sub current_row_index {
    my ($this, $index) = @_;
    $this->{-row_idx} = $index 
      if defined $index;
    $this->{-row_idx};
}


=item row_id ( INDEX )

Returns current row id. Takes row position index. 

=cut

sub row_id {
    my ($this, $index) = @_;
    $index ||= $this->current_row_index;
    my $rows = $this->_rows;
    $rows->[$index]
}


=item row_index_for_id

=cut

sub row_index_for_id {
    my ($this, $id, $index) = @_;
    my $rowid2idx = $this->{-rowid2idx};
    $rowid2idx->{$id} = $index
      if defined $index;
    $rowid2idx->{$id};  
}


=item row( ID, ROW )

Sets/gets row for passed in id.

=cut

sub row {
    my ($this, $id, $row) = @_;
    return unless $id;
    my $id2row = $this->{-id2row};
    $id2row->{$id} = $row
      if defined $row;
    $id2row->{$id};
}


=item row_for_index

Returns row for passed in y position

=cut

sub row_for_index {
    my ($this, $index)  = @_;
    if($index <= $this->rows_count) {
        return $this->row($this->row_id($index));
   }
}


=item _rows

Returns is rows list.

=cut

sub _rows {
    my $this = shift;
    $this->{_rows} ||= [];
}


=item rows_count

Returns number of defined rows -1;

=cut

sub rows_count {
    my ($this) = @_;
    $#{$this->{_rows}};
}

=item add_row( ID, OPTIONS )

Adds a row to grid. Takes the row id and row options.
For available options see Curses::UI::Grid::Row. 
Returns the row object or undef on failure.

=cut

sub add_row {
    my ($this, $id, %args) =@_;
    my $idx;
    my $rows = $this->_rows;
    if ($args{-type} && $args{-type} eq 'head') {
        $idx = 0;
        $args{-focusable} = 0;
  
    } else {
        $args{-type} = 'data';
        $idx = @$rows;
        $args{-focusable} = 1;
        $id = "row$idx"
          unless (defined $id);
    }

    return if(exists($this->{-id2row}{$id}));
    return if($idx > $this->{-page_size});
    push @$rows, $id;
    $this->row_index_for_id($id, $idx);
    $this->row($id, $this->add($id,
      'Curses::UI::Grid::Row',
      %args,
      -x  => 0,
      -id => $id,
      -y  => $idx,
    ));
}


=item delete_row( POSITION )

This routine will delete row data from passed in possition - default current position. 
The function calls event onrowdelete, shifts others row up
and runs event onafterrowdelete and remove last row if onafterrowdelete 
CODEREF doesn't return FALSE.

Note. If onrowdelete CODEREF returns FALSE then  
the delete_row routine will be cancelled.
Returns TRUE or FALSE on failure.

=cut

sub delete_row {
    my ($this, $position) = @_;
    my $rows = $this->_rows;
    my $row = $this->get_foused_row;

    $this->run_event('-onrowdelete', $row)
      or return;
   
    $position = $this->{-rowid2idx}{$row->{-id}}
      unless defined $position;
    $this->reorganize_rows($position, -1);   
    $this->run_event('-onafterrowdelete', $row);
    $this->_delete_row;
    $row = $this->get_foused_row;
    $row->event_onfocus 
      if ref($row);
    $this->draw;
    $this;
}


=item insert_row( POSITION )

This routine will add empty row data to grid at cureent position.
All row data below curent row will be shifted down. 
Add_row method will be called if rows number is less than page size.
Then onrowinsert event is called with row object as parameter.
Returns the row object or undef on failure.

=cut

sub insert_row {
    my ($this, $position) = @_;
    $position ||= 0;
    my $rows = $this->_rows;
    my $page_size = $this->{-page_size};
    my $row = $this->get_foused_row;

    $row->event_onblur 
      or return
        if (ref($row));

    $this->run_event('-onbeforerowinsert', $this)
      or return;

    # add row obj to end
    $row = $this->{-id2row}{$$rows[-1]} 
      if ($position == -1);

    my $current_position = 
      exists($this->{-rowid2idx}{ $row->{-id}}) 
        ? $this->{-rowid2idx}{$row->{-id}}
        : 0;

    if($current_position <= $page_size) {
        $this->add_row;
        $row = $this->row($$rows[-1]) 
          if ($current_position == 0);
    }
    
    # adding row to end not requires shift rows
    if ($position == -1) {
        $row = $this->{-id2row}{$$rows[-1]};

    } elsif ($current_position) {
        $this->reorganize_rows($current_position, 1);

    }

    # triggers event oninsertrow
    $this->run_event('-onrowinsert', $row);

    # makes row focused
    $this->draw;
    $row->event_onfocus();
    $row;
}


=item reorganize_rows( POSITION, DIRECTION )

Rewrites rows properties from grid, starts from passed in position,
direction tells if shifts or pops other rows up or down

=cut

sub reorganize_rows {
    my ($this, $pos, $dir) = @_;
    $dir ||= -1;
    my $rows = $this->_rows;
    if($dir == 1 && $#{$rows} > 1) {
        for (my $i = $#{$rows}; $i >= $pos + 1; $i--) {
            my $dst = $this->{-id2row}{$$rows[$i]};
            my $src = $this->{-id2row}{$$rows[$i - 1]};
            $$dst{-cells} = $$src{-cells};
            $$dst{$_} = $$src{$_}  
              for (qw(-fg_ -bg_ -fg -bg));
        }

        my $dst = $this->{-id2row}{$$rows[$pos]};
        $$dst{$_} = '' for (qw(-fg_ -bg_));
        $$dst{-cells} = {};
        
    } elsif ($dir == -1) {
        for my $i($pos .. $#{$rows} - 1) {
            my $dst = $this->{-id2row}{$$rows[$i]};
            my $src = $this->{-id2row}{$$rows[$i + 1]};
            $$dst{-cells} = $$src{-cells};
            for (qw(-fg_ -bg_ -fg -bg)) {
                $$dst{$_} = $$src{$_} if($$src{$_});
            }
        }
      
        my $dst = $this->{-id2row}{$$rows[-1]};
        $$dst{$_} = '' for (qw(-fg_ -bg_));
        $$dst{-cells} = {};
    }
}


=item _delete_row( BOOLEAN )

This routine will delete last row object from grid. 
Redraws immediate grid if passed in value is TRUE.
Returns TRUE or FALSE on failure.

=cut

sub _delete_row {
    my ($this, $redraw) = @_;
    my $rows = $this->_rows;
    return 
      unless $#{$rows};
    
    my $id = $rows->[-1];
    my $focused_row = $this->get_foused_row;
    
    $this->focus_row($focused_row, 1, -1) 
      if ($id eq $focused_row->id);
    
    my $row = $this->row($id);
    return 
      if (ref($row) && ! $row->isa('Curses::UI::Grid::Row'));
    pop @$rows;

    $row->cleanup;
    $this->draw(1) 
      if $redraw;

    return 1;
}


=item add_cell( ID, OPTIONS )

This routine will add cell to grid using options in the HASH options.
For available options see Curses::UI::Grid::Cell. 
Returns the cell object or undef on failure.

=cut

sub add_cell {
    my ($this, $id, %options) = @_;;
    my $cells = $this->_cells;
    my $idx = $#{$cells} + 1;

    $this->{-id2cell}{$id}= $this->add($id, 'Curses::UI::Grid::Cell',
      -x         => 0,
      -focusable => 1,
      -id        => $id,
      %options,
    );
    
    $this->{_cells}[$idx]=$id;
    $this->{-cellid2idx}{$id}=$idx;
    $this->{-columns}++;
}


=item _delete_cell( ID )

This routine will delete given cell. 
Returns TRUE or FALSE on failure.

=cut

sub _delete_cell {
    my ($this, $id) = @_;
    my $cell = $this->id2cell($id);
    return 0 unless defined $cell;
    my $idx = $this->id2idx($id);
    splice(@{$this->{_cells}}, $idx, 1);
    $cell->cleanup;
    $this->layout_content;
    $this;
}


=item add( ID, CLASS, OPTIONS )

Adds cell or row object to grid.

=cut

sub add {
    my ($this, $id, $class, %options) = @_;
    $this->root->usemodule($class)
      unless $this->test_more;
    my $object = $class->new(
        %options,
        -parent => $this
    );

    # begin by AGX: inherith parent background color!
    if (defined($object->{-bg})) {
        if ($object->{-bg} eq '-1') {
            $object->{-bg} = $this->{-bg}
              if defined($this->{-bg});
        }
    }

    # begin by AGX: inherith parent foreground color!
    if (defined( $object->{-fg})) {
        if ($object->{-fg} eq '-1') {
            $object->{-fg} = $this->{-fg}
              if defined($this->{-fg});
        }
    }
    $object;
}


=item get_cell( ID | CELL )

Returns cell, takes cell's id or cell.

=cut

sub get_cell {
    my ($this, $cell) = @_;
    ref($cell) && $cell->isa('Curses::UI::Grid::Cell')
      ? $cell
      : $this->id2cell($cell);
}


=item get_row( ID | ROW )

Returns row, takes row's id or row object.

=cut

sub get_row {
    my ($this, $row) = @_;
    ref($row) && $row->isa('Curses::UI::Grid::Row')
      ? $row
      : $this->row($row);
}


=item set_label( CELL_ID, LABEL )

Sets lable for passed in cell object.

=cut

sub set_label {
    my ($this, $cell, $label) = @_;
    my $cell_obj = ref($cell) 
      ? $cell 
      : $this->id2cell($cell);
    $cell_obj->label($label);
}


=item set_cell_width( CELL_ID, WIDTH )

Sets width for passed in cell object.

=cut

sub set_cell_width {
    my ($this, $cell, $width) = @_;
    my $cell_obj = ref($cell)
      ? $cell
      : $this->id2cell($cell);
    $cell_obj->width($width);
    $this->layout_content;
    $this;
}


=item get_foused_row

Return focused row if rows defined.

=cut

sub get_foused_row {
    my $this = shift;
    my $rows = $this->_rows;
    my $current_row_index = $this->current_row_index;
    my $rows_count = $this->rows_count;
    return if ($rows_count < $current_row_index);
    my $row = $this->row($this->row_id($current_row_index));
    
    if($row && $row->type eq 'head') {
        $row = $this->row($this->row_id($current_row_index + 1));
        $row->event_onfocus if $row;
    }
    if($row->hidden) {
        $row = $this->get_last_row;
        $row->event_onfocus;
    }
    $row;
}


=item getfocusrow

See L<get_foused_row>.

=cut

*getfocusrow = \&get_foused_row;


=item get_foused_cell

Return focused cell if cells defined.

=cut

sub get_foused_cell {
    my $this = shift;
    my $cell = $this->id2cell($this->{_cells}[$this->{-cell_idx}]);
    return undef unless  defined $cell;
    $cell->row($this->get_foused_row);
    $cell;
}


=item getfocuscell

See L<get_foused_cell>.

=cut

*getfocuscell = \&get_foused_cell;


=item get_last_row

Returns last row.

=cut

sub get_last_row {
    my $this = shift;
    my $rows = $this->_rows;
    for (my $i = $#{$rows}; $i > 1; $i--) {
        my $row = $this->get_row($rows->[$i]);
        return $row  if ($row->focusable && ! $this->hidden);
    }
}


=item get_first_row

Returns first row.

=cut

sub get_first_row {
    my $this = shift;
    $this->get_row($this->row_id(1));
}


=item page

Sets/gets page number.

=cut

sub page { 
    my ($this, $page) = @_;
    $this->{-page} = $page 
      if(defined $page);
    $this->{-page};
}


=item page_size

Sets/gets page size.

=cut

sub page_size($;)  { 
    my ($this, $page_size) = @_;
    $this->{-page_size} = $page_size 
      if(defined $page_size);
    $this->{-page_size};
}


=back

=head3 Layout methods

=over

=item layout

Lays out the grid object with rows and cells, makes sure it fits 
on the available screen.

=cut

sub layout {

    my $this = shift;
    $this->SUPER::layout() or return
      unless $this->test_more;
    $this->layout_content();
    return $this;
}


=item layout_content

=cut

sub layout_content {
    my $this = shift;
    return $this if $Curses::UI::screen_too_small;
    $this->layout_cells;
    $this->layout_vertical_scrollbar;
    return $this;
}


=item layout_cells

Horizontal cells layout of the screen.

=cut

sub layout_cells {
    my $this = shift;
    my $canvas_width = $this->canvaswidth;
    my $virtual_scroll = $this->x_offset;
    my $line_width = 0;
    my $frozen_width = 0;
    my $cells_width = 0;  
    $this->clear_vline();   
    my $cells = $this->{_cells};
    for my $i( 0 ..$#{$cells} ) {
        my $cell = $this->id2cell($cells->[$i]);
        $cell->hide;
        my ($cell_width, $is_frozen) = ($cell->width, $cell->frozen);
        $cells_width += $cell->width;
        if($is_frozen) {
             $cell->set_position($line_width++, $cell_width, 1);
             $frozen_width += $cell_width + 1;
             
        } elsif (($virtual_scroll + $frozen_width) <= $line_width) {
            if ($canvas_width >= ($line_width + $cell_width)) {
                $cell_width = $cell->set_position($line_width++, $cell_width, 1);
                
            } elsif($canvas_width > ($line_width) ) {
                $cell_width = $cell->set_position($line_width++, $canvas_width - $line_width + 1, 1);
                
            }

        } elsif($virtual_scroll < $cell_width) {
            $cell_width = $cell->set_position($line_width++, $cell_width - $virtual_scroll - 1, 0);
            $virtual_scroll = 0;
            
        } else {
            $virtual_scroll -= $cell_width;
            $cell_width = 0;
            
       }

       $line_width += $cell_width;
       $this->add_vline($line_width - 1) 
         if ($line_width > 0 
           && $line_width < $canvas_width 
           && ! $cell->hidden);
    }
    $this->layout_horizontal_scrollbar($cells_width);
}


=item layout_horizontal_scrollbar

Layouts horizontal scrollbar, takes total cells width

=cut

sub layout_horizontal_scrollbar {
    my ($this, $cells_width) = @_;

    if ($this->{-hscrollbar}) {
        my $longest_line = $cells_width;
        $this->{-hscrolllen} = $longest_line + 1;
        $this->{-hscrollpos} = $this->{-xpos} + $this->x_offset;
    } else {
        $this->{-hscrolllen} = 0;
        $this->{-hscrollpos} = 0;
    }
}


=item layout_vertical_scrollbar

Layouts vertical scrollbar, takes total cells width

=cut

sub layout_vertical_scrollbar {
    my ($this) = @_;
    if ($this->{-x_offsetbar}) {
        $this->{-x_offsetlen} = $this->{-pages} * $this->rows;
        $this->{-x_offsetpos} = $this->{-pages} + $this->{-y} - 1;
    } else {
        $this->{-x_offsetlen} = 0;
        $this->{-x_offsetpos} = 0;
    }
    $this;
}


=item get_x_offset_to_obj

Returns position to the x_offset for a new focued cell, takes a cell object as parameter.

=cut

sub get_x_offset_to_obj {
    my ($this, $current_cell) = @_;
    my $cell_idx_prev = $this->{-cell_idx_prev} || 0;
    my $idx = $this->{-cell_idx};
    my $cells = $this->{_cells};
    
    
    my $offset_to_current_cell = 0;
    my $canvas_width = $this->canvaswidth;
    my $forward = $cell_idx_prev < $idx;
    my $x_offset = $this->x_offset;
    my $result;
    my $cell;
    for (my $i = 0; $i <= $#{$cells}; $i++) {
       $cell = $this->id2cell($$cells[$i]);
       $offset_to_current_cell += $cell->width +
         ($canvas_width > $offset_to_current_cell ? 1 : 0);
       last if($cell eq $current_cell);
    }

    if($offset_to_current_cell >= $canvas_width) {
        $result = $forward || ! $x_offset
          ? $offset_to_current_cell - $canvas_width - 2
          : $offset_to_current_cell - $canvas_width + $cell->width;
          
    } else {
          $result = ! $forward || $x_offset
            ? 0
            : $offset_to_current_cell - $canvas_width + $cell->width;
    }

    $result;
}


=item vertical_lines

Gets/sets vertical lines.

=cut

sub vertical_lines {
    my ($this, $vertical_lines) = @_;
    $this->{-vertical_lines} = $vertical_lines
      if defined $vertical_lines;
    $this->{-vertical_lines};
}

=item add_vline

Adds vline that will be drawn.

=cut

sub add_vline {
    my ($this, $line) = @_;
    push @{$this->vertical_lines}, $line;
}


=item clear_vline

Clears vertcal lines position.

=cut


sub clear_vline() {
    my $this = shift;
    $this->vertical_lines([]);
}


=item focus_row( ROW, FORCE, DIRECTION )

Moves focus to passed in row.

=cut

sub focus_row {
    my $this      = shift;
    return $this->focus_obj('row'
        ,shift || undef
        ,shift
        ,shift );
}


=item focus_cell( ROW, FORCE, DIRECTION )

Moves focus to passed in cell.

=cut

sub focus_cell {
    my $this      = shift;
    return $this->focus_obj('cell'
        ,shift || undef
        ,shift
        ,shift );

}


=item focus_obj( TYPE, OBJECT, FORCE, DIRECTION )

Moves focus to passed in object. Takes TYPE that can be row or cell. 
Force parameter is boolean and force changing focus in case focus events fails.

=cut

sub focus_obj {
    my ($this, $type, $focus_to, $forced, $direction) = @_;
    $direction = 1 
      unless defined($direction);
    my $idx;
    my $index = "-" . $type . "_idx";
    my $index_prev = "-" . $type . "_idx_prev";
    my $collection = "_" . $type . "s";
    my $map2idx = "-" . $type . "id2idx";
    my $map2id = "-id2" . $type;
    my $onnextpage = 0;
    my $onprevpage = 0;

    my $cur_id  = $this->{$collection}[$this->{$index}];
    my $cur_obj = $this->{$map2id}{$cur_id};

    $focus_to = $cur_id if(! defined $focus_to || ! $focus_to);
    $direction = ($direction < 0 ? -1 : $direction );

   # Find the id for a object if the argument
   # is an object.
    my $new_id = ref $focus_to
               ? $focus_to->{-id}
               : $focus_to;


    my $new_obj = $this->{$map2id}{$new_id};

    if(defined $new_id && $direction != 0) {
        # Find the new focused object.
        my $idx = $this->{$map2idx}{$new_id};
        my $start_idx = $idx;

        undef $new_obj;
        undef $new_id;

        OBJECT: for(;;) {
            $idx += $direction;
            if($idx > @{$this->{$collection}} - 1){

                if($type eq 'row') {
                    # if curent position is less than page size and grid is editable
                    # and cursor down then add new row
                    return $this->insert_row(-1) 
                      if ($idx <= $this->{-page_size} && $this->{-editable});
                    $onnextpage = 1;  #set trigger flag to next_page
                }
               $idx = 0;
            }

            if($idx < 0) {
                $idx = @{$this->{$collection}}-1 ;
                $onprevpage = 1 
                  if ($type eq 'row');  #set trigger flag to prev_page
            }

            last if $idx == $start_idx;

            my $test_obj  = $this->{$map2id}{$this->{$collection}->[$idx]};
            my $test_id = $test_obj->{-id};

            if($test_obj->focusable) {
                $new_id  = $test_id;
                $new_obj = $test_obj;
                last OBJECT
            }
        }
    }

     # Change the focus if a focusable objects was found and tiggers not return FALSE.
      if($forced or defined $new_obj and $new_obj ne $cur_obj) {
          my $result = 1;
          # trigger focus to new object if ret isn't FALSE  and any page trigger is set
          $result=$this->grid_pageup(1)   
            if ($result && $onprevpage);
          $result=$this->grid_pagedown(1) 
            if ($result && $onnextpage);

          $result = $cur_obj->event_onblur 
            if ($result && $cur_obj);
          $new_obj->event_onfocus 
            if ($result && ref($new_obj));
     }
     
    $this;
}


=item event_onfocus

Calls supercall events onfocus 

=cut

sub event_onfocus {
    my $this = shift;
    my $row = $this->get_foused_row;
    $this->focus_row(undef,1,1) if(!ref($row) || $row->type eq 'head');
    return $this->SUPER::event_onfocus(@_)
      unless $this->test_more;
}


=back

=head3 Draw methods

=over

=item draw( BOOLEAN )

Draws the grid object along with the rows and cells. If BOOLEAN
is true, the screen is not updated after drawing.

By default, BOOLEAN is true so the screen is updated.

=cut

sub draw {
    my ($this, $no_doupdate) = @_;
    $no_doupdate ||= 0;

    $this->SUPER::draw(1) or return $this
      unless $this->test_more;
    $this->draw_grid(1);
    $this->{-nocursor} = $this->rows_count ? 0 : 1;
    doupdate() 
      if ! $no_doupdate && ! $this->test_more;
    $this;
}    


=item draw_grid

Draws grid.

=cut

sub draw_grid {
    my ($this, $no_doupdate) = @_;
    $no_doupdate ||= 0;

    $this->draw_header_vline;
    my $pair = $this->set_color(
      $this->{-fg},
      $this->{-bg},
      $this->canvasscr
    );
    my $rows = $this->_rows;
    for (my $i = $#{$rows}; $i >= 0; $i--) {
       $this->row($$rows[$i])->draw_row;
    }
    $this->color_off($pair, $this->canvasscr);

    my $cell = $this->get_foused_cell;
    my $row = $this->get_foused_row;
    my $y = ref($row) ? $row->y : 0;
    my $x =ref($cell) ? $cell->xabs_pos : 0;
    $this->{-ypos} = $y;
    $this->{-xpos} = $x;
    $this->canvasscr->move($this->{-ypos}, $this->{-xpos});
    $this->canvasscr->noutrefresh 
      if $no_doupdate;
}


=item draw_header_vline

Draws header lines.

=cut

sub draw_header_vline {
    my $this = shift;
    my $pair = $this->set_color(
      $this->{-fg},
      $this->{-bg},
      $this->canvasscr
    );
    $this->canvasscr->addstr(0, 0, 
      sprintf("%-" . ($this->canvaswidth * $this->canvasheight) . "s", ' ')
    );
    $this->color_off($pair, $this->canvasscr);

    my $fg = $this->{-bfg} && $this->{-bfg} ne '-1'
      ? $this->{-bfg} 
      : $this->{-fg};
    my $bg = $this->{-bbg} && $this->{-bbg} ne '-1'
      ? $this->{-bbg} 
      : $this->{-bg};
    my $column_number = 0;
    
    $this->canvasscr->move(1, 0);
    $pair = $this->set_color($fg, $bg, $this->canvasscr);
    $this->canvasscr->hline(ACS_HLINE, $this->canvaswidth);

    if($this->rows_count > 0 )  {
        foreach my $x (@{$this->vertical_lines}) {
            $column_number++;
            if($this->canvaswidth - 1 == $x && $column_number == $this->{-columns}) {
                $this->canvasscr->move(1, $x) ;
                $this->canvasscr->vline(ACS_URCORNER, 1);
                 next;
            }

            $this->canvasscr->move(1, $x);
            $this->canvasscr->vline(ACS_TTEE, 1);
        }
    }
    $this->color_off($pair, $this->canvasscr);
    return $this;
}


=item x_offset

Sets/gets x offset for grid.

=cut

sub x_offset { 
    my ($this, $x_offset) = @_;
    if(defined $x_offset) {
        $this->{-x_offset} = $x_offset;
        $this->layout_content();
        $this->draw(1);
    }
    $this->{-x_offset};
}


=back

=head3 Colors methods

=over

=item set_color( BG_COLOR, FG_COLOR, CANVAS )

Sets color for passed in canvaed object. Returns color pair.

=cut

sub set_color($;) {
    my ($this, $bg, $fg, $canvas) = @_;
    return 
      unless ref($canvas);
    $bg ||= -1;
    $fg ||= -1;
    return 
      if($fg eq '-1' || $bg eq '-1');

    my $color_pair;
    if($Curses::UI::color_support && $bg && $fg) {
        my $color = $Curses::UI::color_object;
        $canvas->attron(A_REVERSE);
        $color_pair = $color->get_color_pair($fg, $bg);
        $canvas->attron(COLOR_PAIR($color_pair));
        $this->canvasscr->attron(COLOR_PAIR($color_pair));
    }
    $color_pair;
}


=item color_off( COLOR_PAIR, CANVAS )

Sets color for passed in canvaed object

=cut

sub color_off {
    my ($this, $color_pair, $canvas) = @_;
    if($Curses::UI::color_support && $color_pair) {
        $canvas->attroff(A_REVERSE);
        $canvas->attroff(COLOR_PAIR($color_pair));
    }
}


=back

=head3 Event  functions

=over

=item run_event( EVENT, OBJECT)

Runs passed event, takes event name as first parameter 
and row or cell or grid object as caller.

=cut 

sub run_event {
    my ($this, $event, $obj) = @_;
    return $this 
      unless $this->is_event_defined($event);
    my $callback = $this->{$event};
    if (defined $callback) {
        if (ref $callback eq 'CODE') {
            return $callback->(ref($obj) ? $obj : $this);
            
        } else {
            $this->root->fatalerror(
                "$event callback for $this "
              . "($callback) is no CODE reference"
            );
        }
    }
    $this;
}


=item is_event_defined( EVENT ) 

Returns true if passed in event is defined.

=cut

sub is_event_defined {
    my ($this, $event, $obj) = @_;
    my $callback = $this->{$event};
    $callback && ref($callback) eq 'CODE';
}

=back

=head3 Data maipulation methods

=over

=item set_value( ROW , CELL , VALUE  )

This routine will set value for given row and cell.
CELL can by either cell object or id cell.
ROW  can by either row object or id row.

=cut

sub set_value {
    my ($this, $row, $cell, $data) = @_;
    $row = $this->get_row($row);
    $cell = $this->get_row($cell);
    $row->set_value($cell, $data) 
      if ref($row);
}


=item set_values( ROW , HASH )

This routine will set values for given row. 
HASH should contain cells id as keys and coredpondend values.
ROW  can by either row object or id row.

    $grid->set_values('row1',cell1=>'cell 1',cell4=>'cell 4');

    $grid->set_values('row1',cell2=>'cell 2',cell3=>'cell 3');

This method will not affect cells which are not given in HASH.

=cut

sub set_values {
    my ($this, $row, %data) = @_;
   $row = $this->get_row($row);
   $row->set_values(%data) 
     if ref($row);
}


=item get_value( ROW, CELL )

This routine will return value for given row and cell. 
CELL can by either cell object or id cell.
ROW  can by either row object or id row.

=cut

sub get_value {
    my ($this, $row, $cell) = @_;
    $row = $this->get_row($row);
    $cell = $this->get_cell($cell); 
    $row->get_value($cell) 
      if ref($row);
}

=item get_values ( ROW )

This routine will return  HASH values for given row. 
HASH will be contain cell id as key.
ROW  can by either row object or id row.

=cut

sub get_values {
    my ($this, $row) = @_;
    $row = $this->get_row($row);
    $row->get_values 
      if ref($row);
}


=item get_values_ref ( ROW )

This routine will return  HASH reference  for given row values. 
ROW  can by either row object or id row.

  my $ref=$grid->get_values_ref('row1');
    $$ref{cell1} = 'cell 1 ';
    $$ref{cell2} = 'cell 2 ';
    $$ref{cell3} = 'cell 3 ';
    $grid->draw();

Note. After seting values by reference you should call draw method.

=cut

sub get_values_ref {
    my ($this, $row, $ref) = @_;
    $row = $this->get_row($row);
    $row->get_values_ref
      if ref($row);
}


=back

=head3 Navigation methods.

=over

=item next_row

Return next row object.

=cut

sub next_row {
    my $this = shift;
    my $row = $this->get_foused_row;
    $this->focus_row($this->get_foused_row, undef, 1);
    $this->get_foused_row;
}


=item prev_row

Return previous row object.

=cut

sub prev_row {
    my $this = shift;
    $this->focus_row($this->get_foused_row,undef,-1);
    $this->get_foused_row;
}


=item first_row

Return first row object.

=cut

sub first_row {
    my $this = shift;
    my $row = $this->get_first_row;
    $this->focus_row($row,1,0);
    $this->get_foused_row;
}


=item last_row

Return last row object.

=cut

sub last_row {
    my $this = shift;
    my $row = $this->get_last_row;
    $this->focus_row($row, 1, 0);
    $this->get_foused_row;
}


=item grid_pageup( BOOLEAN )

Calls grid onprevpage event.
Redraws immediate grid if passed in value is TRUE.

=cut

sub grid_pageup {
    my ($this, $do_draw) = @_;
    $this->run_event('-onprevpage', $this)
      or return;
    $this->draw(1) 
      if $do_draw;
    $this->focus_row($this->get_foused_row, 1, 0) 
      if ($do_draw && $do_draw != 1);
    $this;
}


=item grid_pagedown( BOOLEAN )

Calls grid onnextpage event.
Redraws immediate grid if passed in value is TRUE.

=cut

sub grid_pagedown($;) {
    my ($this, $do_draw) = @_;
    $this->run_event('-onnextpage', $this)
      or return;
    $this->draw(1) 
      if $do_draw;
    $this->focus_row($this->get_foused_row, 1, 0) 
      if ($do_draw && $do_draw != 1);
    $this;
}


=item first_cell

Returns first cell object.

=cut

sub first_cell {
    my $this = shift;
    my $cell = $this->get_cell($this->{_cells}[0]);
    $this->focus_cell($cell, 1, 0);
    $this->get_foused_cell;
}


=item last_cell

Returns last cell object.

=cut

sub last_cell {
    my $this = shift;
    my $cell=$this->get_cell($this->{_cells}[$#{$this->{_cells}}]);
    $this->focus_cell($cell, 1, 0);
    $this->get_foused_cell;
}


=item prev_cell

Returns previous cell object.

=cut

sub prev_cell {
    my $this = shift;
    $this->focus_cell($this->get_foused_cell, undef, -1);
    $this->get_foused_cell;
}


=item next_cell

Returns next cell object.

=cut

sub next_cell {
    my $this = shift;
    $this->focus_cell($this->get_foused_cell, undef, 1);
    $this->get_foused_cell;
}


=back

=head3 Cells methods.

=over

=item cursor_left

Calls cursor left on focsed cell.
Return focued cells.

=cut

sub cursor_left {
    my $this = shift;
    my $cell = $this->get_foused_cell;
    $cell->cursor_left;
    $cell;
}


=item cursor_right

Calls cursor right on focsed cell.
Return focued cells.

=cut

sub cursor_right {
    my $this = shift;
    my $cell = $this->get_foused_cell;
    $cell->cursor_right;
    $cell;
}


=item cursor_to_home

Calls cursor home on focsed cell.
Return focued cells.

=cut

sub cursor_to_home {
    my $this = shift;
    my $cell = $this->get_foused_cell;
    $cell->cursor_to_home;
    $cell;

}


=item cursor_to_end

Calls cursor end on focsed cell.
Return focued cells.

=cut

sub cursor_to_end {
    my $this = shift;
    my $cell = $this->get_foused_cell;
    $cell->cursor_to_end;
    $cell;    
}


=item delete_character

Calls delete character on focsed cell.
Return focued cells.

=cut

sub delete_character {
    my $this = shift;
    my $cell = $this->get_foused_cell;
    $cell->delete_character(@_);
    $cell;    
}


=item backspace

Calls backspace on focsed cell.
Return focued cells.

=cut

sub backspace {
    my $this = shift;
    my $cell = $this->get_foused_cell;
    $cell->backspace(@_);
    $cell;    
}


=item add_string

Calls add_string on focsed cell.
Return focued cells.

=cut

sub add_string {
    my $this = shift;
    my $cell = $this->get_foused_cell;
    $cell->add_string(@_);
    $cell;    
}

=back

=head3 Mouse event method.

=over

=item mouse_button1

=cut



sub mouse_button1 {
    my ($this, $event, $x, $y) = @_;
    my $row = $this->row_for_index($y -1 );
    if( ref $row ) {
        my $cell = $this->cell_for_x_position($x);
        $this->focus_row($row, undef, 0);
        $this->focus_cell($cell, undef, 0) 
          if ref($cell);
    }

  return $this;
}


1;

__END__


=back

=head1 SEE ALSO

Curses::UI::Grid::Row Curses::UI::Grid::Cell

=head1 AUTHOR

Copyright (c) 2004 by Adrian Witas. All rights reserved.

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itthis. 

=cut
