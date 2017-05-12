###############################################################################
# subclass of Curses::UI::Cell is a widget that can be used to display
# and manipulate cell in grid model
#
# (c) 2004 by Adrian Witas. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as perl itself.
###############################################################################


package Curses::UI::Grid::Cell;


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
@ISA = qw(Curses::UI::Grid);
    

sub new () {
    my $class = shift;

    my %userargs = @_;
    keys_to_lowercase(\%userargs);
    my %args = ( 
        # Parent info
        -parent          => undef       # the parent object
	,-row		 => undef	# row object
        # Position and size
        ,-x               => 0           # horizontal position (rel. to -window)
	,-current_width	  => undef
        ,-width           => undef       # default width 10
        ,-align       	  => 'L'         # align L - left, R - right
	# Initial state
        ,-xpos             => 0           # cursor position

        # General options
        ,-maxlength       => 0           # the maximum length. 0 = infinite
        ,-overwrite       => 1           # immdiately overwrite cell unless function char 
	,-overwritetext	  => 1		 # contol overwrite and function char (internally set)

	# Grid model 
	,-text	   	  => ''	# text
	,-fldname	  => '' # field name for data bididngs
    	,-frozen	  => 0  # field name for data bididngs	        
	,-focusable	  => 1  # internally set 
	,-readonly	  => 0  # readonly ?
        ,%userargs
	# Init values
        ,-focus           => 0
        ,-bg_            => undef        # user defined background color
        ,-fg_            => undef        # user defined font color
    );
    

    # Create the Widget.
    my $this = {%args};
    bless $this;

    $this->{-xoffset}  = 0; #
    $this->{-xpos}     = 0; # X position for cursor in the document
    $this->parent->layout_content;
    $this;
}

# set layout
sub set_position {
    my ($this, $x, $current_width) = @_;
    $this->x($x);
    $this->current_width($current_width);
    if($current_width  > 0) { 
    		$this->show
     } else {
     		$this->hide; 
     }

		$current_width;
}	


sub layout_text {
   my $this = shift;
   my $row= $this->row;
   my $grid = $this->parent;
   my $current_width = $this->current_width  
     or return;
   my $width = $this->width;
	 my $alignlign = $this->align;
   my $text = $this->text;
   
   # backward event compatibility
   if	($grid->is_event_defined('-oncelllayout') && $row->type ne 'head') {
   		my $text_layouted = $grid->run_event('-oncelllayout', $this, $text);
   		$text = ref($text_layouted)
   		  ? $text
   		  : $text_layouted;
   }
   
	 my $text_length = length(($text || ''));
	
	if($alignlign eq 'R' && $text_length > $current_width) {
	    $text = substr(
	      $text, 
	      ($text_length - $current_width - $this->xoffset), 
	      $current_width
	    );
	} 
	
	if($alignlign eq 'L' && abs($this->xoffset)) {
	    $text = substr($text, -$this->xoffset, $current_width);
	}

  $text = sprintf("%".(($alignlign || '') eq 'L'  ? "-":"") . $width . "s", ($text ||''));
  $text = $alignlign eq 'L' 
    ? substr($text, 0, $current_width) 
    : substr($text, (length($text) - $current_width), $current_width);
  $text .= ' '
    if(ref($this->row) && $this->row->type ne 'data');
	
  $text;
}


sub draw($;) {
    my $this = shift;
    my $no_doupdate = shift || 0;

    # Return immediately if this object is hidden.
    return $this if $this->hidden;
    return $this if $Curses::UI::screen_too_small; 
     my $grid =$this->parent;
     my $row=$this->row(1);

   if( $#{$grid->{_rows}} > 1 ) {
        $this->{-nocursor}=0;
    } else {
        $this->{-nocursor}=1;
    }

     $row->canvasscr->attron(A_BOLD) if($row->{-focus});
     $this->draw_cell(1,$row);
     $row->canvasscr->attroff(A_BOLD) if($row->{-focus});
     doupdate() if ! $no_doupdate && ! $grid->test_more;
     $row->canvasscr->move($row->y,$this->xabs_pos);
     $row->canvasscr->noutrefresh;


    return $this;
}    


sub draw_cell($$$) {
    my $this = shift;
    my $no_doupdate = shift || 0;
    my $row = shift;
    $row = $this->row($row);
    return $this 
      if $this->hidden;
    my $grid = $this->parent;
    
    $grid->run_event('-oncelldraw', $this)
      if ($row->type ne 'head');
      
    my $fg=$row->type ne 'head' ? $this->fg : $grid->{-fg};
    my $bg=$row->type ne 'head' ? $this->bg : $grid->{-bg};
    my $pair=$grid->set_color($fg,$bg,$row->canvasscr);
    my $x = $this->x;
    my $text = $this->layout_text || '';
    $text = substr($text, 0, $grid->canvaswidth - $x) 
      if (length($text) + $x >= $grid->canvaswidth);
    $row->canvasscr->addstr($row->y, $x, $text);
    $grid->color_off($pair, $row->canvasscr);
    $this;
}

sub text($$) {
    my $this = shift;
    my $text = shift;
    my $result='';
    my $row=$this->row;
    my $grid =$this->parent;
    my $type= $row->type || '';
    my $id=$this->id;
    #if row type is head return or set label attribute otherwise cell value
    if(defined $text) {
	if($type eq 'head') { 
	   $this->{-label}=$text; 
	} else {  
	   $row->{-cells}{$id}=$text; 
	}
    }
    
    $result = $type eq 'head' ? $this->{-label} : exists $row->{-cells}{$id} ? $row->{-cells}{$id} :'' if($type) ;
    return $result;
}

sub cursor_right($) {
    my $this = shift;
    $this->overwriteoff;
    $this->xoffset($this->xoffset-1) if($this->xpos()   == ($this->current_width -1) );
    $this->xpos($this->xpos+1);
    $this->draw(1);
    
    return $this;																	        return $this;	    
}

sub cursor_left($) {
    my $this = shift;
    $this->overwriteoff;
    $this->xoffset($this->xoffset+1) unless($this->xpos($this->xpos));
    $this->xpos($this->xpos-1);
    $this->draw(1);
    return $this;	    
}

sub cursor_to_home($) {
    my $this = shift;
    $this->overwriteoff;
    my $text = $this->text;
    my $current_width = $this->current_width;
    my $align = $this->align;
    
    $this->xoffset($align eq 'L' 
      ?  $current_width 
      : (length($text) - $current_width > 0 
        ? length($text) - $current_width
        : 0 )
    );

    $this->xpos($align eq 'L' 
      ? 0 
      : $current_width - length($text)
    );
    $this->draw(1);
}


sub cursor_to_end($) {
    my $this = shift;
    $this->overwriteoff;
    my $text_lenght = length $this->text;
    my $current_width = $this->current_width;
    my $align = $this->align;
    $current_width = $current_width > $text_lenght && $align eq 'L' 
      ? $text_lenght + 1 
      : $current_width;
    $this->xoffset(
      $align eq 'R' 
        ? 0
        : $current_width -  $text_lenght - 1) 
          if ($text_lenght >= $current_width);
    
    $this->xpos($align eq 'L' 
      ? $current_width - 1 
      : $current_width-1);
    
    $this->draw(1);
}

sub delete_character($) {
    my $this = shift;
    return if $this->readonly;
    my $ch = shift;
    my $grid = $this->parent;
    $grid->run_event('-oncellkeypress', $this, $ch) 
      or return;
    $this->overwriteoff;
    my $text=$this->text;
    my $xo = $this->xoffset;
    my $pos = $this->text_xpos;
    my $len = $this->current_width+abs($this->xoffset);
    my $align = $this->align;
    my $current_width = $this->current_width;

    return if($align eq 'R' && $pos <= 0);  
    $this->xoffset($this->xoffset-1) if($align eq 'R' &&  $xo && length($text) - $xo >= $current_width);
    $this->xoffset($this->xoffset-1) if($align eq 'L' && length($text) > $len);
    $pos-- if($align eq 'R');
    substr($text, $pos, 1, '') if(abs($pos) <= length($text));
    $this->text($text);
    $this->draw(1);
}

sub backspace($) {
    my $this = shift;
    my $ch = shift;
    return if $this->readonly;
    my $grid =$this->parent;
    $grid->run_event('-oncellkeypress', $this, $ch) 
      or return;
    $this->overwriteoff;
    my ($align,$xo)=($this->align,$this->xoffset);
    $this->cursor_left;
    $this->delete_character();
    $this->cursor_right  if($align eq 'R' );
}

sub add_string($$;) {
    my $this = shift;
    my $ch = shift;
    return if $this->readonly;
    my $grid = $this->parent;

    my $ret= $grid->run_event('-oncellkeypress', $this, $ch)
      or return;

    my @ch = split //, $ch;
    $ch = '';
    foreach (@ch) {
        $ch .= $this->key_to_ascii($_);
    }


    $this->text('') if( $this->overwritetext );

    my ($xo,$pos,$len,$align)= ($this->xoffset ,$this->text_xpos,  length($this->text),$this->align);
    my $text=$this->text;

    substr($text, abs($pos) , 0) = $ch  if($pos <= $len );
    $this->text($text);
    $this->cursor_right if($align eq 'L');
    $this->draw();
    $grid->run_event('-onaftercellkeypress', $this, $ch);
}



# x of cell
sub x($;) {
    my $this=shift;
    my $x=shift;
    $this->{-x}=$x if(defined $x);
    return $this->{-x};
}

# absolute x position to row
sub xabs_pos($;) {
    my $this=shift;
    my $result="";
    my $xpos=( $this->xpos > ($this->current_width-1) ? $this->current_width-1 : $this->xpos );
    $xpos =0 if($xpos < 0);
    return $this->{-x} + $xpos;
}


# cursor relative x pos
sub xpos($;) {
    my $this=shift;
    my $x=shift;
    if(defined $x){ 
	$x = 0 if($x < 0);
	$x= $this->width-1 if($x > $this->width-1 );
        $this->{-xpos}=$x;
    }
    return $this->{-xpos};
}


# cursor position in text
sub text_xpos($;) {
    my $this=shift;
    my ($w,$x,$xo,$align,$l)=($this->current_width-1,$this->xpos,$this->xoffset,$this->align,length($this->text));    
    return  $align eq 'R' ? $l-($w-$x+abs($xo)) : $x-$xo;
}


# offset to x pos
sub xoffset($;) {
    my $this=shift;
    my $xo=shift;
    my ($align,$l,$w)=($this->align,length(($this->text || '')),$this->current_width);

    if( defined($xo) ) {
	if($align eq 'L' ) {
        $xo=0 if($xo > 0);
        #$xo=$this->w-1 if($xo < 0);
	} else {
	    $xo=$l-$w if($xo > ($l-$w) && $xo);
	    $xo=0 if($xo < 0);
	}


	$this->{-xoffset}=$xo;
    }
    return $this->{-xoffset};
}


# event of focus
sub event_onfocus()
{
    my $this = shift;
    my $grid =$this->parent;
    $this->overwriteon;
    $grid->{-cell_idx}=$grid->{-cellid2idx}{ $this->{-id} };

    # Store value of cell in case of data change
    if(ref($this->row) && $this->row->type ne 'head' ) {
	$this->row->set_undo_value($this->id,$this->text);
    }
    # Let the parent find another cell to focus
    # if this widget is not focusable.
    $this->{-focus} = 1;
    if ($this->width != ($this->current_width ||0) || $this->hidden ) {
				my $vs = $grid->get_x_offset_to_obj($this);
	   		$grid->x_offset($vs);
    }

    $this->xpos($this->align eq 'L' ? 0 : $this->current_width - 1);
    $this->xoffset(0);
    $grid->run_event('-oncellfocus', $this);
    $this->draw(1);
    return $this;
}


sub event_onblur() {
    my $this = shift;
    my  $grid =$this->parent;
    $this->xpos($this->align eq 'L' ? 0 : $this->current_width - 1);
    $this->xoffset(0);
    $grid->run_event('-oncellblur',$this)
      or return;
    
    if (ref($this->row) && $this->row->type ne 'head' ) {
				my $undo = $this->row->get_undo_value($this->id);
				my $text = $this->text;
	
				# if data was changed

	    	$grid->run_event('-oncellchange', $this) 
	    	  or return
	    	    if ($undo || '') ne ($text || '');
    }
    
    $grid->{-cell_idx_prev} = $grid->{-cellid2idx}{$this->{-id}};
    $this->{-focus} = 0;

    $this->draw;
    $this;
}

sub overwriteoff() { shift()->{-overwritetext}=0 }
sub overwriteon() { shift()->{-overwritetext}=1 }


sub overwritetext($;) {
    my $this=shift;
    my $result=!$this->{-overwrite} ? $this->{-overwrite}  : $this->{-overwritetext};
    $this->overwriteoff();
    return $result;
}

sub has_focus() {
    my $this=shift;
    my $grid =$this->parent;
    my $result=0;
    $result=1 if($this->{-focus});
return $result;
}


sub focus($;) {
    my $this=shift;
    # Let the parent focus this object.
    my $parent = $this->parent;
    $parent->focus($this) if defined $parent;
    $this->draw(1);
    return $this;
}


sub bg() {
    my $this = shift;
    my $bg=shift;
    $this->{-bg_}=$bg if(defined $bg);
    return  $this->{-bg_} ? $this->{-bg_} : exists( $this->{-bg} ) && $this->{-bg} ? $this->{-bg} : $this->row->bg;
}

sub fg() {
    my $this = shift;
    my $fg=shift;
    $this->{-fg_}=$fg if(defined $fg);
    return  $this->{-fg_} ? $this->{-fg_} : exists( $this->{-fg} ) && $this->{-bg} ? $this->{-fg} : $this->row->fg;
}

sub row() {
    my ($this, $row) = @_;
    $this->{-row} = $row 
      if defined $row;
    $this->{-row} = $this->parent->get_foused_row
	    if(!ref($this->{-row}) ||  ref($this->{-row}) ne 'Curses::UI::Grid::Row');
    return $this->{-row};
}



sub align()  { uc(shift()->{-align})    }
sub frozen() { shift->{-frozen}         }
# defined width
sub width()  { 
		my ($self, $width) = @_;
		$self->{-width} = $width if(defined $width);
		$self->{-width};
}

#current width
sub current_width {
    my ($this, $current_width) = @_;
    $this->{-current_width} = $current_width 
      if (defined $current_width);
    return $this->{-current_width};
}

sub cleanup {
		my $this = shift;
		my $grid = $this->parent;		
		if ($grid) {
    		delete $this->{-cellid2idx}{$this->id};
    		delete $this->{-id2cell}{$this->id};
    		$grid->{-columns}--;
				$this->{$_} = ''
					for (qw(-canvasscr -parent -row));
		}
}

sub label {
		my ($this, $label) = @_;
		$this->{-label} = $label
			if defined $label;
		$this->{-label};	
}


sub DESTROY {
    my $this = shift;
    $this->cleanup;
}

__END__

=pod

=head1 NAME

Curses::UI::Grid::Cell -  Create and manipulate cell in grid model.

=head1 CLASS HIERARCHY

 Curses::UI::Grid
    |
    +----Curses::UI::Cell




=head1 SYNOPSIS

    use Curses::UI;
    my $cui = new Curses::UI;
    my $win = $cui->add('window_id', 'Window');
    my $grid =$win->add('mygrid','Grid');

    my $row1=$grid->add_cell( -id=>'cell1'
		             ,-fg=>'blue'
			     ,-bg->'red'
			     ,-frozen=>1
			     ,-align => 'R'
			   );




=head1 DESCRIPTION


       Curses::UI::Grid::Cell is a widget that can be 
       used to manipulate cell in grid model


      See exampes/grid-demo.pl in the distribution for a short demo.



=head1 STANDARD OPTIONS

       -parent,-fg,-bg,-focusable,-width


For an explanation of these standard options, see
L<Curses::UI::Widget|Curses::UI::Widget>.



=head1 WIDGET-SPECIFIC OPTIONS


=over 4


=item * B<-id> ( ID )

This option will be contain the cell id.


=item * B<-frozen> < BOOLEAN >

This option will  make the cell visible on the same place
even if vertical scroll occurs.

<B>Note Only first X column (from right) could be frozen.


=item * B<-align> < ALIGN >

This option will make apropriate align for the data cell.
ALIGN could be either R or L.
R - rigth align;
L - left align;


=item * B<-overwrite> < BOOLEAN >

If BOOLEAN is true, and when add_string  method is called first time
after the cell becomes focused the old value will be cleared 
unless the function key will be pressed earlier. (cursor_left,cursor_to_end,etc.)


=back

=head1 METHODS

=over 4


=item * B<new> ( OPTIONS )

Constructs a new grid object using options in the hash OPTIONS.


=item * B<layout> ( )

Lays out the cell, makes sure it fits
on the available screen.


=item * B<draw> ( BOOLEAN )

Draws the cell object. If BOOLEAN
is true, the screen is not updated after drawing.

By default, BOOLEAN is true so the screen is updated.

=back

=head1 WIDGET-SPECIFIC METHODS

=over 4


=item * B<layout_cell> ( )

Lays out the cell, makes sure it fits
on the available screen.


=item * B<draw_cell> ( BOOLEAN )

Draws the cell object. If BOOLEAN
is true, the screen is not updated after drawing.

By default, BOOLEAN is true so the screen is updated.


=item * B<fg> ( COLOR )

Thid routine could set or get foreground color using -fg_ option .
If -fg_  is NULL then -fg or parent fg color is return.


=item * B<bg> ( COLOR )

Thid routine could set or get background color using -bg_ option.
If -bg_  is NULL then -bg or parent bg color is return.


=item * B<text> ( TEXT )

Thid routine could set or get text value for given cell and active row.


=item * B<add_string>

=item * B<align>

=item * B<backspace>

=item * B<current_width>

=item * B<cursor_left>

=item * B<cursor_right>

=item * B<cursor_to_end>

=item * B<cursor_to_home>

=item * B<delete_character>

=item * B<event_onblur>

=item * B<event_onfocus>

=item * B<focus>

=item * B<frozen>

=item * B<has_focus>

=item * B<label>

=item * B<layout_text>

=item * B<overwriteoff>

=item * B<overwriteon>

=item * B<overwritetext>

=item * B<row>

=item * B<set_position>

=item * B<text_xpos>

=item * B<width>

=item * B<x>

=item * B<xabs_pos>

=item * B<xoffset>

=item * B<xpos>

=item * B<cleanup>

=back

=head1 SEE ALSO

L<Crses::UI::Grid::Row>
L<Curses::UI::Grid>

=head1 AUTHOR

Copyright (c) 2004 by Adrian Witas. All rights reserved.


=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;