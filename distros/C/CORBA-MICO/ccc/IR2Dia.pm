package CORBA::MICO::IR2Dia;
require Exporter;

use Gtk2 '1.140';
require CORBA::MICO::Misc;
use CORBA::MICO::Pixtree;

use Symbol ();

use strict;

@CORBA::MICO::IR2Dia::ISA = qw(Exporter);
@CORBA::MICO::IR2Dia::EXPORT = qw();
@CORBA::MICO::IR2Dia::EXPORT_OK = qw(
     dump_interface
);

my $vspacing = 4;
my $hspacing = 4;

#--------------------------------------------------------------------
# Dump XML-representation of IR object
#     $fh      - file name/handler XML code will be written to
#     \@nodes  - list of interfaces (objects of class CORBA::MICO::IREntry)
# Return value: TRUE - Ok, error else
#--------------------------------------------------------------------
sub dump_interface {
  my ($fh, $nodes) = @_;
  return _dump_interface($fh, $nodes) if ref($fh);
  my $hnd = Symbol::gensym();
  unless( open($hnd, ">$fh") ) {
    CORBA::MICO::Misc::warning(qq/Can't open "$fh": $!/);
    return 0;
  }
  my $retval = _dump_interface($hnd, $nodes);
  close($hnd);
  return 1;
}

#--------------------------------------------------------------------
# Private version of dump_interface 
#--------------------------------------------------------------------
sub _dump_interface {
  my ($fh, $nodes) = @_;
  my @levels = ();
  my %tree_desc = ();
  CORBA::MICO::Pixtree::prepare_tree($nodes, 0, 0, 1, \@levels, \%tree_desc);
  my ($maxwidth) = reverse sort @levels;
  my $maxitem_w = 0;
  my $maxitem_h = 0;
  foreach my $iname (keys %tree_desc) {
    #my $tw = width_cb($iname);
    my $tw = length($iname);
    $maxitem_w = $tw if $maxitem_w < $tw;
    # my $th = height_cb($iname);
    my $th = 1;
    $maxitem_h = $th if $maxitem_h < $th;
    $tree_desc{$iname}{WIDTH} = $tw;
    $tree_desc{$iname}{HEIGHT} = $th;
  }
  my $box_w = $maxitem_w;
  my $box_h = $maxitem_h;
  my $full_width = $maxwidth * ($box_w + $hspacing);
  my $full_height = @levels * ($box_h + $vspacing);
  for( my $lev = 0; $lev < @levels; ++$lev ) {
    my @curr_lev = sort { $tree_desc{$a}{OFFSET} <=> $tree_desc{$b}{OFFSET} } 
                     grep { $tree_desc{$_}{LEVEL} == $lev } keys %tree_desc; 
    my $lev_width = @curr_lev * ($box_w + $hspacing);
    my $lev_hoffs = int($hspacing/2) + int(($full_width - $lev_width)/2);
    my $levnum = $#levels - $lev;
    my $lev_voffs = int($vspacing/2) + $levnum * ($box_h + $vspacing);
    foreach my $item (@curr_lev) {
      $tree_desc{$item}{VPOS} = $lev_voffs;
      $tree_desc{$item}{HPOS} = $lev_hoffs;
      $lev_hoffs += ($box_w + $hspacing);
    }
  }
  my $id = dia_begin($fh);
  foreach my $item (keys %tree_desc) {
    dump_item($id, $box_w, $box_h, $item, $tree_desc{$item});
  }
  foreach my $item (keys %tree_desc) {
    dump_deps($id, $box_w, $box_h, $item, $tree_desc{$item}, \%tree_desc);
  }
  dia_end($id);
  return 1;
}

#--------------------------------------------------------------------
sub dump_item {
  my ($id, $w, $h, $item_name, $item_data) = @_;
  my $x = $item_data->{HPOS};
  my $y = $item_data->{VPOS};
  my $iw = $item_data->{WIDTH};
  my $ih = $item_data->{HEIGHT};
  $item_data->{OBJID} = $id->{ID};
  obj_begin($id, 'UML - Class', 0, $x, $y, $iw, $ih);
  attr_string($id, 'name', $item_name);
  attr_bool($id, 'abstract', 0);
  attr_bool($id, 'suppress_attributes', 0);
  attr_bool($id, 'suppress_operations', 0);
  attr_bool($id, 'visible_attributes', 0);
  attr_bool($id, 'visible_operations', 0);
  obj_end($id);
}
#--------------------------------------------------------------------
sub dump_deps {
  my ($id, $w, $h, $item_name, $item_data, $tree_desc) = @_;
  my $parents = $item_data->{PARENTS} or return;
  my $nparents = @$parents            or return;
  my $x = $item_data->{HPOS};
  my $y = $item_data->{VPOS};
  my $middle = 2.5;
  my $x0 = $x + $middle;
  foreach my $parent (@$parents) {
    my $parent_data = $tree_desc->{$parent};
    my $x1 = $parent_data->{HPOS} + $middle;
    my $y1 = $parent_data->{VPOS} + $parent_data->{HEIGHT};
    dump_arrow($id, $x0, $y, $x1, $y1, 
                                $item_data->{OBJID}, $parent_data->{OBJID});
  }
}

#--------------------------------------------------------------------
sub dump_arrow {
  my ($id, $x0, $y0, $x1, $y1, $child_id, $parent_id) = @_;
  obj_begin($id, 'UML - Generalization', 0, undef, undef, undef, undef);
  my $ym = ($y1+$y0)/2;
  attr_points($id, 'orth_points', 
              [$x1, $y1], [$x1, $ym], [$x0, $ym], [$x0, $y0]);
  attr_enums($id, 'orth_orient', 1, 0, 1);      
  dump_connections($id, [1, $child_id, 1], [0, $parent_id, 6]);
  obj_end($id);
}

#--------------------------------------------------------------------
my @dia_prefix = (
  '<?xml version="1.0"?>',
  '<dia:diagram xmlns:dia="http://www.lysator.liu.se/~alla/dia/">',
  '  <dia:diagramdata>',
  '  </dia:diagramdata>',
  '  <dia:layer name="Background" visible="true">',
);
sub dia_begin {
  my $fh = shift;
  my $id = { 'ID' => 0, 'HND' => $fh, 'IDENT' => 2 };
  foreach my $line (@dia_prefix) {
    dump_line($id, $line, 0);
  }
  return $id;
}

#--------------------------------------------------------------------
my @dia_suffix = (
  '  </dia:layer>',
  '</dia:diagram>'
);
sub dia_end {
  my $id = shift;
  foreach my $line (@dia_suffix) {
    dump_line($id, $line, 0);
  }
  $id->{'IDENT'} = 0;
}

#--------------------------------------------------------------------
sub dump_line {
  my ($id, $line, $ident) = @_;
  $ident = $id->{'IDENT'} unless defined $ident;
  my $hnd = $id->{'HND'};
  print $hnd join('', '  ' x $ident, $line, "\n");
}

#--------------------------------------------------------------------
sub dump_lines {
  my ($id, $ident, @lines) = @_;
  foreach my $line (@lines) {
    dump_line($id, $line, $ident);
  }
}

#--------------------------------------------------------------------
sub obj_begin {
  my ($id, $cname, $ver, $x, $y, $w, $h) = @_;
  my $line = "<dia:object type=\"$cname\" version=\"$ver\" id=\"$id->{ID}\">";
  dump_line($id, $line);
  $id->{'IDENT'}++;
  $id->{'ID'}++;
  attr_point($id, "obj_pos", $x, $y)     if defined($x) and defined($y);
  attr_point($id, "elem_corner", $x, $y) if defined($x) and defined($y);
  attr_real($id, "elem_width", $w)       if defined($w);
  attr_real($id, "elem_height", $h)      if defined($h);
}  

#--------------------------------------------------------------------
sub obj_end {
  my ($id) = @_;
  my $line =  '<dia:attribute name="attributes"/>';
  dump_line($id, $line);
  $line = '<dia:attribute name="operations"/>';
  dump_line($id, $line);
  $line = '<dia:attribute name="templates"/>';
  dump_line($id, $line);
  $id->{'IDENT'}--;
  $line = "</dia:object>";
  dump_line($id, $line);
}  

#--------------------------------------------------------------------
sub dia_attr {
  my ($id, $name, @lines) = @_;
  dump_line($id, "<dia:attribute name=\"$name\">");
  dump_lines($id, $id->{'IDENT'}+1, @lines);
  dump_line($id, "</dia:attribute>");
}

#--------------------------------------------------------------------
sub attr_point {
  my ($id, $name, $x, $y) = @_;
  my $line = "<dia:point val=\"$x,$y\"/>";
  dia_attr($id, $name, $line);
}

#--------------------------------------------------------------------
sub attr_points {
  my ($id, $name, @points) = @_;
  my @lines;
  foreach my $point (@points) {
    my $line = "<dia:point val=\"$point->[0],$point->[1]\"/>";
    push(@lines, $line);
  }
  dia_attr($id, $name, @lines);
}

#--------------------------------------------------------------------
sub attr_enums {
  my ($id, $name, @vals) = @_;
  my @lines;
  foreach my $val (@vals) {
    my $line = "<dia:enum val=\"$val\"/>";
    push(@lines, $line);
  }
  dia_attr($id, $name, @lines);
}

#--------------------------------------------------------------------
sub dump_connections {
  my ($id, @conns ) = @_;
  dump_line($id, '<dia:connections>');
  my @lines;
  foreach my $conn (@conns) {
    my $line = "<dia:connection handle=\"$conn->[0]\" to=\"$conn->[1]\" connection=\"$conn->[2]\"/>";
    push(@lines, $line);
  }
  dump_lines($id, $id->{'IDENT'}+1, @lines);
  dump_line($id, '</dia:connections>');
}

#--------------------------------------------------------------------
sub attr_string {
  my ($id, $name, $val) = @_;
  my $line = "<dia:string>#$val#</dia:string>";
  dia_attr($id, $name, $line);
}

#--------------------------------------------------------------------
sub attr_real {
  my ($id, $name, $val) = @_;
  my $line = "<dia:real val=\"$val\"/>";
  dia_attr($id, $name, $line);
}

#--------------------------------------------------------------------
sub attr_bool {
  my ($id, $name, $val) = @_;
  my $cval = $val ? 'true' : 'false';
  my $line = "<dia:boolean val=\"$cval\"/>";
  dia_attr($id, $name, $line);
}
