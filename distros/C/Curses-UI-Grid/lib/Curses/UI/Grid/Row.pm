###############################################################################
# subclass of Curses::UI::Row is a widget that can be used to display
# and manipulate row in grid model
#
# (c) 2004 by Adrian Witas. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as perl itself.
###############################################################################


package Curses::UI::Grid::Row;


use strict;
use warnings;

use Curses;
use Curses::UI::Common;
use Curses::UI::Grid;

use vars qw(
    $VERSION 
    @ISA
    );

$VERSION = '0.14';

@ISA = qw(
	     Curses::UI::Grid
        );


sub new ()
{
    my $class = shift;

    my %userargs = @_;
    keys_to_lowercase(\%userargs);

    my %args = ( 
        # Parent info
        -parent          => undef       # the parent object
        # Position and size
        ,-y               => 0           # vertical position (rel. to -window)
	# Grid model 
	,-focusable	 => 1
	,-type		 => undef	 # row type: head,data
        ,-cells		 => undef	 # data cell  
        ,-cells_undo	 => {}	 	 # holds  data chaned	
	,-bg_		 => undef	 # user defined background color
	,-fg_		 => undef	 # user defined font color
        ,%userargs
    );
    
    # Create the Row
    my $this = {%args,-canvasscr=>$args{-parent}->canvasscr};
    bless $this;
    return $this;
}


sub layout {
   my $this = shift;
    $this->layout_row;
   return $this;
}



sub layout_content {
   my $this = shift;
   return $this;
}


sub layout_row($;){
    my $this = shift;
    my $p=$this->parent;
    my $c=\@{ $p->{_cells} };
    my $text = '';
    my $w = $p->canvaswidth;
    
    for my $i ( 0 ..    $#{$c} ) {
				my $cell = $p->id2cell($$c[$i]);
				$text .=  ($cell->layout_text() || '')
				. ' '
				  unless $cell->hidden;
    }
    $text = substr(sprintf("%-" . $w . "s", $text), 0, $w);
}


sub draw(;$) {
    my $this = shift;
    my $no_doupdate = shift || 0;
    my $grid = $this->parent;
    return $this if $Curses::UI::screen_too_small;
    return $this if $this->hidden;
    $this->layout_row;
    $this->draw_row($no_doupdate);
    doupdate() if ! $no_doupdate && ! $grid->test_more;
    return $this;
}    



sub draw_row(;$) {
    my $this = shift;
    my $no_doupdate = shift || 0;

    # Return immediately if this object is hidden.
    return $this if $this->hidden;


    my $p=$this->parent();
    $this->canvasscr->attron(A_BOLD) if($this->{-focus});

       $p->run_event('-onrowdraw',$this);	

       # Let there be color for data cell
       # for header grid's colors
       my $fg=($this->type ne 'head') ? $this->fg : $p->{-fg} ;
       my $bg=($this->type ne 'head') ? $this->bg : $p->{-bg} ;
       my $pair=$p->set_color($fg,$bg,$this->canvasscr);
      
       my $c=\@{ $p->{_cells} };
        for my $i(0 .. $#{$c} ) { 
	    $p->id2cell( $$c[$i] )->draw_cell(1,$this);;
	}
       $this->canvasscr->attroff(A_BOLD) if($this->{-focus});
       $p->color_off($pair,$this->canvasscr);
    
    $this->draw_vline() if($this->type ne "head");

    $this->canvasscr->noutrefresh;
    return $this;
}



sub draw_vline {
    my $this = shift;
    my $grid = $this->parent;
    my $pair = $grid->set_color( 
      ($grid->{-bfg} || '') ne '-1' 
        ? $grid->{-bfg} 
        : $grid->{-fg},
      $this->bg,
      $this->canvasscr
    );
	
		foreach my $x (@{$grid->vertical_lines}) {
	      $this->canvasscr->move($this->y,$x);
        $this->canvasscr->vline(ACS_VLINE,1);	    
		}
    
    $grid->color_off($pair, $this->canvasscr);
		$this;
}


sub bg() {
    my $this = shift;
    my $bg= shift;
    $this->{-bg_}=$bg if(defined $bg);
    return  $this->{-bg_} ? $this->{-bg_} : exists( $this->{-bg} ) ? $this->{-bg} : $this->parent()->{-bg};
}

sub fg() {
    my $this = shift;
    my $fg= shift;
    $this->{-fg_}=$fg if(defined $fg);
    return  $this->{-fg_} ? $this->{-fg_} :exists( $this->{-fg} ) ? $this->{-fg} : $this->parent()->{-fg};
}

sub event_onfocus() {
    my $this = shift;
    my $p=$this->parent;
    return $p->focus($this) unless($this->focusable);
    # Let the parent find another widget to focus
    # if this widget is not focusable.
    $this->{-focus} = 1;
    $p->run_event('-onrowfocus',$this);
    $p->{-row_idx}=$p->{-rowid2idx}{ $this->{-id} };
    # clear date change info
    $this->{-cell_undo} = {};
    $this->draw(1);
        my $cell = $p->get_foused_cell;
           $cell->event_onfocus if (defined $cell);
    return $this;
}

sub event_onblur() {
    my $this = shift;
    my $p=$this->parent;

    #check if data row was changed
    my $changed=0;
    for my $k (keys %{ $this->{-cell_undo} } ) {
	 if( $this->{-cell_undo}{$k} ne $this->{-cell}{$k} ) {
	    $changed=1;
	    last;
	}
    }

    if($changed) {
	my $ret= $p->run_event('-onrowchange',$this);
	#if event return values and it's equal 0 then cancell onblur event
	if(defined $ret) {
    	    if($ret eq "0") {
        	return '';
    	    }
	}
    }


    #If the Container loose it focus
    #the current focused child must be unfocused
    my $cell = $this->parent->get_foused_cell;

    #test if current row can be unfocused otherwise cancel current event
     if(defined $cell) {
	my $ret = $cell->event_onblur();
	return 0 if(defined $ret && !$ret);
    }

    my $ret=$p->run_event('-onrowblur',$this);
	if(defined $ret) {
    	    if($ret eq "0") {
        	return '';
    	    }
	}
    $this->{-focus} = 0;
    $p->{-row_idx_prev}=$p->{-rowid2idx}{ $this->{-id} };
    $this->draw;
    return $this;
}

# y position of row
sub y(){
    my $this = shift;
    return $this->{-y} ? $this->{-y} +1:$this->{-y};
}

sub type(){ shift()->{-type}; }

sub set_value($;) {
    my $this = shift;
    my $cell = shift;
    my $data = shift;
    my $cell_id=ref($cell) ? $cell->{-id} : $cell;
    $this->{-cells}{$cell_id}=$data;
    $this->draw if($this->{-focus});
}


sub set_values($;) {
    my $this = shift;
    my %data = @_;
    if(defined $this->{-cells} ) {
      $this->{-cells}={ %{$this->{-cells}} , %data } ;
    } else {     $this->{-cells}={ %data } ;}


    $this->draw if($this->{-focus});
}


sub set_undo_value($;) {
    my $this = shift;
    my $cell = shift;
    my $data = shift;
    my $cell_id=ref($cell) ? $cell->{-id} : $cell;
    $this->{-cells_undo}{$cell_id}=$data;
}

sub get_undo_value($;) {
    my $this = shift;
    my $cell = shift;
    my $result='';
    my $cell_id=ref($cell) ? $cell->{-id} : $cell;
    $result= $this->{-cells_undo}{$cell_id} if(exists($this->{-cells}{$cell_id}));
    return $result;
}



sub get_value($;) {
    my $this = shift;
    my $cell = shift;
    my $cell_id=ref($cell) ? $cell->{-id} : $cell;
    return $this->{-cells}{$cell_id};
}

sub get_values($;) {
    my $this = shift;
    return %{ $this->{-cells} };
}

sub get_values_ref($;) {
    my $this = shift;
    return \%{  $this->{-cells} };
}


sub cleanup {
    my $this = shift;
    my $grid = $this->parent or return;		
    delete $grid->{-rowid2idx}{$this->id};
    delete $grid->{-id2row}{$this->id};
    $grid->{-rows}--;
    $this->{$_} = ''
    for (qw(-canvasscr -parent));
}


sub DESTROY($;) {
    my $this = shift;
    $this->cleanup;
}

1;

__END__

=pod

=head1 NAME

Curses::UI::Grid::Row - Create and manipulate row in grid model.

=head1 CLASS HIERARCHY

 Curses::UI::Grid
    |
    +----Curses::UI::Row


=head1 SYNOPSIS

    use Curses::UI;
    my $cui = new Curses::UI;
    my $win = $cui->add('window_id', 'Window');
    my $grid =$win->add('mygrid','Grid' );
    my $row1=$grid->add_row( -fg=>'blue'
                            ,-bg->'white' );



=head1 DESCRIPTION

       Curses::UI::Grid::Row is a widget that can be used to
       manipulate row in grid model


      See exampes/grid-demo.pl in the distribution for a short demo.



=head1 STANDARD OPTIONS

       -parent,-fg,-bg


=head1 WIDGET-SPECIFIC OPTIONS

=over 4

=item * B<-cells> < HASH >


=item * B<-cells_undo> < HASH >


=back

=head1 METHODS

=over 4


=item * B<new> ( OPTIONS )

Constructs a new grid object using options in the hash OPTIONS.


=item * B<layout> ( )

Lays out the row object with cells, makes sure it fits
on the available screen.


=item * B<draw> ( BOOLEAN )

Draws the grid object along with cells. If BOOLEAN
is true, the screen is not updated after drawing.

By default, BOOLEAN is true so the screen is updated.


=back

=head1 WIDGET-SPECIFIC OPTIONS

=over 4

=item * B<layout_row> ( )

Lays out the row with cells, makes sure it fits
on the available screen.


=item * B<draw_row> ( BOOLEAN )

Draws the row object along with cells. If BOOLEAN
is true, the screen is not updated after drawing.

By default, BOOLEAN is true so the screen is updated.


=item * B<set_value>  (  CELL , VALUE  )

This routine will set value for given  cell.
CELL could by either cell object or id cell.


=item * B<set_values> ( HASH  )

This routine will set values for cells.
HASH should contain cells id as keys.
This method will not affect cells which are not given in HASH.


=item * B<get_value>  (  CELL )

This routine will return value for given cell.
CELL could by either cell object or id cell.


=item * B<get_values> (  )

This routine will return  HASH values for row cells.
HASH will be contain cells id as keys.


=item * B<get_values_ref> ( )

This routine will return  HASH reference  for given row values.


=item * B<fg> ( COLOR )

This routine could set or get foreground color using -fg_ option . 
If -fg_  is NULL then -fg or parent fg color is return.


=item * B<bg> ( COLOR )

This routine could set or get background color using -bg_ option. 
If -bg_  is NULL then -bg or parent bg color is return.


=item * B<text> ( TEXT )

This routine will set or get value for cell and active row.


=item * B<draw_vline>

Draws line.

=item * B<event_onblur>

=item * B<event_onfocus>

=item * B<get_undo_value>

=item * B<layout_content>

=item * B<set_undo_value>

=item * B<type>

=item * B<y>

=item * B<cleanup>

Cleanup association between parent, canva, etc..

=back

=head1 SEE ALSO

L<Curses::UI::Grid::Cell>
L<Curses::UI::Grid>

=head1 AUTHOR

Copyright (c) 2004 by Adrian Witas. All rights reserved.



=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


