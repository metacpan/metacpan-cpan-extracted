package CORBA::MICO::Pixtree;
require Exporter;

use Gtk2 '1.140';
use CORBA::MICO::IREntry;

use strict;

@CORBA::MICO::Pixtree::ISA = qw(Exporter);
@CORBA::MICO::Pixtree::EXPORT = qw();
@CORBA::MICO::Pixtree::EXPORT_OK = qw(
     pixtree_create
     pixtree_show
);

my $margin = 2;
my $vspacing = 10;
my $hspacing = 10;

#--------------------------------------------------------------------
# Create a 'pixtree' object 
#--------------------------------------------------------------------
sub pixtree_create {
  my $retval = new Gtk2::ScrolledWindow(undef,undef); # scrolled for main text
  $retval->set_policy( 'automatic', 'automatic' );

  my $drawing = Gtk2::DrawingArea->new();               # drawing area widget
  $retval->add_with_viewport($drawing);
#  $retval->set_user_data([$drawing, undef]);           # store children !!!!
#  $retval->signal_connect('destroy', sub { undef @{$_[0]->get_user_data()}; });
  my $pixtree_hnd = [$retval, $drawing, undef];
  $drawing->signal_connect('expose_event',  \&expose_event_cb, $pixtree_hnd);
#  $drawing->signal_connect('size_allocate', \&size_allocate_cb, $retval);
  $retval->show_all();
  return $pixtree_hnd;
}

#--------------------------------------------------------------------
# Show a tree via 'pixtree' object 
# In: pixtree - pixtree object returned by pixtree_create()
#     \@nodes  - list of interfaces (objects of class CORBA::MICO::IREntry)
#--------------------------------------------------------------------
sub pixtree_show {
  my ($pixtree_hnd, $nodes) = @_;
  my $pixtree = $pixtree_hnd->[0];
  $pixtree_hnd->[2] = $nodes;
  $pixtree_hnd->[1]->queue_draw();
}

#--------------------------------------------------------------------
sub text_size {
   my ($w, $text) = @_;
   my $layout = $w->create_pango_layout($text);
   return $layout->get_pixel_size;
}

#--------------------------------------------------------------------
sub expose_event_cb {
  my ($widget, $event, $pixtree_hnd) = @_;
  my $window = $widget->window();
  my $pixtree = $pixtree_hnd->[0];
  return 1 unless $window;
  return 1 unless defined $pixtree_hnd->[2];
  my $nodes = $pixtree_hnd->[2];
  my @levels = ();
  my %tree_desc = ();
  prepare_tree($nodes, 0, 0, 1, \@levels, \%tree_desc);
  my ($maxwidth) = reverse sort @levels;
  my $maxitem_w = 0;
  my $maxitem_h = 0;
  foreach my $iname (keys %tree_desc) {
    my ($tw, $th) = text_size($widget, $iname);
    $maxitem_w = $tw if $maxitem_w < $tw;
    $maxitem_h = $th if $maxitem_h < $th;
    $tree_desc{$iname}{WIDTH} = $tw;
    $tree_desc{$iname}{HEIGHT} = $th;
  }
  my $box_w = $maxitem_w + ($margin+1)*2;
  my $box_h = $maxitem_h + ($margin+1)*2;
  $box_w++ if ($box_w % 2);
  my $full_width = $maxwidth * ($box_w + $hspacing);
  my $full_height = @levels * ($box_h + $vspacing);
  my $curr_hspacing;
  my $curr_vspacing;
  my Gtk2::Gdk::Rectangle $rect = $widget->allocation();
  my ($allocted_w, $allocted_h) = ($rect->width(), $rect->height());
  if( $allocted_w < $full_width or $allocted_h < $full_height ) {
    $full_width = $allocted_w if $full_width < $allocted_w;
    $full_height = $allocted_h if $full_height < $allocted_h;
    $widget->size($full_width, $full_height);
  }
  else {
    ($full_width, $full_height) = ($allocted_w, $allocted_h)
  }  
  $curr_hspacing = int($full_width/$maxwidth) - $box_w;
  if( $curr_hspacing > $box_w ) {
    # Increaze $box_w if $curr_hspacing is too large
    my $sum = $curr_hspacing + $box_w;
    $box_w = int($sum/2);
    $curr_hspacing = $sum - $box_w;
  }
  $curr_vspacing = int($full_height/@levels) - $box_h;
  if( $curr_vspacing > (2*$box_h) ) {
    # Increaze $box_h if $curr_vspacing is too large
    my $sum = $curr_vspacing + $box_h;
    $box_h = int($sum/3);
    $curr_vspacing = $sum - $box_h;
  }
  my $pm = $window;
  $pm->draw_rectangle($widget->get_style()->white_gc(), 1, 
                                        0, 0, $full_width, $full_height);
  for( my $lev = 0; $lev < @levels; ++$lev ) {
    my @curr_lev = sort { $tree_desc{$a}{OFFSET} <=> $tree_desc{$b}{OFFSET} } 
                     grep { $tree_desc{$_}{LEVEL} == $lev } keys %tree_desc; 
    my $lev_width = @curr_lev * ($box_w + $curr_hspacing);
    my $lev_hoffs = int($curr_hspacing/2) + int(($full_width - $lev_width)/2);
#    my $lev_voffs = int($curr_vspacing/2) + $lev * ($box_h + $curr_vspacing);
    my $lev_voffs = int($curr_vspacing/2) + 
                          ($#levels-$lev) * ($box_h + $curr_vspacing);
    foreach my $item (@curr_lev) {
      $tree_desc{$item}{VPOS} = $lev_voffs;
      $tree_desc{$item}{HPOS} = $lev_hoffs;
      $lev_hoffs += ($box_w + $curr_hspacing);
    }
  }
  foreach my $item (keys %tree_desc) {
    draw_item($widget, $pm, $box_w, $box_h, $item, $tree_desc{$item});
  }
  foreach my $item (keys %tree_desc) {
    draw_lines($widget, $pm, $box_w, $box_h, 
               $item, $tree_desc{$item}, \%tree_desc);
  }
  return 1;
}

#--------------------------------------------------------------------
sub draw_lines {
  my ($widget, $pm, $w, $h, $item_name, $item_data, $tree_desc) = @_;
  my $line_width = 1;
  my $parents = $item_data->{PARENTS} or return;
  my $nparents = @$parents            or return;
  my $x = $item_data->{HPOS};
  my $y = $item_data->{VPOS};
  my $dist = ($w - ($nparents*$line_width)) / ($nparents+1); 
  my $style = $widget->get_style();
  my $middle = ($w - $line_width) / 2;
  my $x0 = $x + $dist;
  foreach my $parent (@$parents) {
    my $parent_data = $tree_desc->{$parent};
    my $x1 = int($parent_data->{HPOS} + $middle);
    my $y1 = $parent_data->{VPOS} + $h;
    my $i;
    if( abs($x1-$x0) <= 2 ) {
      $x1 = $x0;
    }
    for( $i = 0; $i < $line_width; ++$i ) {
      $pm->draw_line($style->fg_gc('normal'), $x0+$i, $y, $x1+$i, $y1);
    }
    $x0 = $x0 + $dist;
  }
}

#--------------------------------------------------------------------
sub draw_item {
  my ($widget, $pm, $w, $h, $item_name, $item_data) = @_;
  my $x = $item_data->{HPOS};
  my $y = $item_data->{VPOS};
  my $style = $widget->get_style();
  $pm->draw_rectangle($style->bg_gc('normal'), 1, $x, $y, $w, $h);
  $pm->draw_rectangle($style->fg_gc('normal'), 0, $x, $y, $w, $h);
  my $iw = $item_data->{WIDTH};
  my $ih = $item_data->{HEIGHT};
  my $x1 = $x + int(($w-$iw) / 2);
  my $y1 = $y + int(($h-$ih)/2);
  my $layout = $widget->create_pango_layout($item_name);
  $pm->draw_layout($style->fg_gc('normal'), $x1, $y1, $layout);
}

#--------------------------------------------------------------------
# In: \@nodes              - list of interfaces (objects of class IREntry)
#     $level               - node level (vertical): integer (0..tree_height-1)
#     ($min_off, $max_off) - position (horizontal): float (0..1)
#     $levels              - resulting array: level->number of items on it
#     $tree_desc           - resulting hash: for each name in the tree
#        contains: level, offset, array of subtree names
sub prepare_tree {
  my ($nodes, $level, $min_off, $max_off, $levels, $tree_desc) = @_;
  foreach my $node (@$nodes) {
    prepare_node($node, $level, $min_off, $max_off, $levels, $tree_desc);
  }
}
#--------------------------------------------------------------------
# In: $node                - interface (object of class CORBA::MICO::IREntry)
#     $level               - node level (vertical): integer (0..tree_height-1)
#     ($min_off, $max_off) - position (horizontal): float (0..1)
#     $levels              - resulting array: level->number of items on it
#     $tree_desc           - resulting hash: for each name in the tree
#        contains: level, offset, array of subtree names
sub prepare_node {
  my ($node, $level, $min_off, $max_off, $levels, $tree_desc) = @_;
  my $oldlev;
  my $name = $node->name();
  if( defined($tree_desc->{$name}) ) {
    $oldlev = $tree_desc->{$name}{"LEVEL"};
    if( $oldlev < $level ) {
      $tree_desc->{$name}{"LEVEL"} = $level;
    #  $tree_desc->{$name}{"OFFSET"} = ($max_off+$min_off)/2;
      $levels->[$level]++; 
      $levels->[$oldlev]--; 
    }  
  }
  else {
    $tree_desc->{$name}{"LEVEL"} = $level;
    $tree_desc->{$name}{"OFFSET"} = ($max_off+$min_off)/2;
    $levels->[$level]++;
  }  
  $level++;
  my $parents = $node->parents();
  my $diff = ($max_off-$min_off)/(@$parents+2);
  foreach my $subnode (@$parents) {
    $min_off += $diff;
    prepare_node($subnode, $level,
                 $min_off, $max_off, $levels, $tree_desc);
    if( not defined($oldlev) ) {
      push(@{$tree_desc->{$name}{"PARENTS"}}, $subnode->name());
    }
  }
}

#--------------------------------------------------------------------
# tree_desc entry:
#  'CHILDREN'   => list of children
#  'LEVEL'      => node level, greater for child, lesser for parent
#  'FOLDER'     => folder number
#  'WIDTH'      => node width - width of the widest level
#  'PARENTS'    => list of parents
#--------------------------------------------------------------------
# In: \@nodes              - list of interfaces (objects of class IREntry)
#     $level               - node level (vertical): integer (0..tree_height-1)
#     ($min_off, $max_off) - position (horizontal): float (0..1)
#     $levels              - resulting array: level->number of items on it
#     $tree_desc           - resulting hash: for each name in the tree
#        contains: level, offset, array of subtree names
sub construct_tree {
  my ($nodes, $level, $min_off, $max_off, $levels, $tree_desc) = @_;
  foreach my $node (@$nodes) {
    prepare_node($node, $level, $min_off, $max_off, $levels, $tree_desc);
  }
}
