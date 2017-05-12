package Chemistry::Artificial::Graphics;
$VERSION = '0.01';
# $Id: Graphics.pm, v 0.01 2005/04/26 12:30:17 brequesens Exp $

=head1 NAME

Graphics - Graphic plot for artificial with database support

=head1 SYNOPSIS

    use strict;
    use Chemistry::SQL;
    use Chemistry::Artificial::Graphics;
    
    my $dbname = $ARGV[0];
    my $chaname = $ARGV[1];
    my $file = $ARGV[2];
    my $mode = $ARGV[3];
    
    if (scalar(@ARGV)!=4)
    {  print "Error in parameter number \n";
       print "perl chaplot.pl DB_NAME 
       CHA_NAME FILE_NAME MODE (svg | svg_static | text)\n";
       exit;
    }
    my $db1 = Chemistry::SQL->new(db_host=>"127.0.0.1",db_user=>"root",db_port=>"3306",sb_pwd=>"",db_name=>"$dbname",db_driver=>"mysql");
    $db1->connect_db;
    my $pcha = Chemistry::Artificial::Graphics->new(db => $db1, width=> "800",height=>"600",radius=> "10",distanceh=>"200",file=> $file,
    mode=> $mode);
    $pcha->ch_plot("$chaname");


=head1 DESCRIPTION

This package, along with I<Chemistry::SQL>, includes all the necessary to 
generate graphics of the artificial chemistry in database.

=cut

=head2 Graphics Attributes

	* db: Working database.
	* width: Width screen value.
	* height: Height screen value.
	* def_fathercolor: Components that have >=1 childs.
	* def_childcolor: Components that don't have any child.
	* def_font: Font name.
	* def_font_size: Font size in the graphic.
	* def_font_color: Font color in the graphic.
	* radius: Radius for each component (radius of the circle).
	* inix: This will be the first position X position.
	* iniy: This will be the first position Y position.
	* distanceh: Horitzontal distance from one component to each other.
	* id: First id component.
	* file: File name where we are going to save the graphic.
	* mode: Working mode (svg|svg_static|text).

=cut

use strict;
use Chemistry::Reaction;
use Chemistry::File::SMILES;
use Chemistry::SQL;

=head1 METHODS

Implements the methods.

=over 4

=item Graphics->new(SQL_OBJECT, width, height, radius, distanceh,
distancev, file, mode)

Creates a new object graphics to plot artificial chemistry.

I<* Example:>

	my $pcha = Graphics->new(db => $db1,width=>"1400",height=>"1024",
        radius=>"10",distanceh=>"10",file=>"$file",
	mode=>"svg");

=cut

sub new 
{ 	
 my $class=shift;
 my %args = @_;
    my $self = 
    bless 
    {    
        db => "",
        width => "800",
        def_fathercolor => "green",
        def_childcolor => "red",
        def_font  => "Verdana",
        def_font_size => "10",
        def_font_color => "blue",
        height => "600",
        radius => 10,
        inix => "",
        distanceh => "",
        iniy => 40,
        id => 1,
        mode => "",
        file => "",

  }, ref $class || $class;
  foreach my $attribute (keys %args) {
    $self->{$attribute}= $args{$attribute};    #$self->$attribute($args{$attribute});
  }
  $self->{inix} = $self->{width}/2;
  return $self;
}

=back

=head2 File functions

These functions are oriented to the generic I/O graphic file, and they are:

=cut

=over 4

=item $graph->ini_file()

This function only creates the file where the graphic is going to be writed.

This function uses I<$self->{file>} parameter to set the name of the 
output file.

This function should be called from the inside of the module, not being 
recomended to call it from an external applicattion.

=cut

sub ini_file		
{
my $self = shift;
open (svgfile,">$self->{file}") or die("Couldn't open File\n");
close(svgfile);
}

=back

=head2 Component functions

These are auxiliar functions used to work with components:

=cut

=over 4

=item $graph->smiles_string(component)

Returns SMILES format string of the component.

It is often used to get the SMILES string of the components in the function.

	$self->smiles_string($component);

=cut

sub smiles_string	
{
my $self=shift;
my ($component)=@_;
return $component->print(format => 'smiles', unique => 1);
#return $component->sprintf("%S");
#return $component->sprintf("%s");
}

=back

=head2 Graphic plot

These functions are used in the plot process.

=cut

=head3 Common functions (not depending of the graphic type)

These functions are used to write SVG files, and they are:

=cut

=over 4

=item $graph->write_style()

Here we define the style of the objects in the graph, for example: path (the 
lines), circle(the components), text (text properties)...

Here we defined the arrows directions too.

This function should be called from the inside of the module, not being 
recomended to call it from an external applicattion.

=cut

sub write_style
{	
my $self = shift;
open (svgfile,">>$self->{file}") or die("Couldn't open File\n");
my $function2 = '
<defs>
<radialGradient id="mygradient1" cx="10%" cy="10%" r="100%" fx="25%" fy="25%" 
gradientUnits="objectBoundingBox">
 <stop id="2stop1" offset="0%" style="stop-color:blue;"/>
 <stop id="2stop2" offset="100%" style="stop-color:black;"/>
</radialGradient>
<marker id="Triangle_down" viewBox="0 0 10 10" refX="10" refY="5"
 markerUnits="strokeWidth" markerWidth="16" markerHeight="12" stroke="green"
 orient="90">
 <path d="M0,0 L10,5 L0,10 z"/>
</marker>
<marker id="Triangle_up" viewBox="0 0 10 10" refX="10" refY="5"
 markerUnits="strokeWidth" markerWidth="16" markerHeight="12" stroke="green"
 orient="270">
 <path d="M0,0 L10,5 L0,10 z"/>
</marker>

<marker id="Triangle_up_down" viewBox="0 0 10 10" refX="10" refY="5"
 markerUnits="strokeWidth" markerWidth="16" markerHeight="12" stroke="green"
 orient="270">
 <path d="M0,0 L10,5 L0,10 z"/>
</marker>


</defs>'."\n";
print svgfile $function2;
close (svgfile);
}

=item $graph->write_circle(x, y, id, color, smilestring, child, formula,
reaction, reaction_type, atommap, elembefore)

This function writes a component in the graph.

	The properties:
	* id: This is an unique id for one component in the graph.
	* cx: X position.

This function should be called from the inside of the module, not being 
recomended to call it from an external applicattion.

=cut

sub write_circle
{	
my $self = shift;
my ($x,$y,$id,$color,$smilestring,$child,$formula,$reaction,$reaction_type,
$atommap,$elembefore)=@_;
open (svgfile,">>$self->{file}") or die("Couldn't open File\n");
print svgfile '<circle id="c'. $id .'" onclick="showContentAndRelatives(evt)" 
cx="'. $x. '" cy="' .$y. '" r="20" stroke="'.$color.'" 
smilestring="'. $smilestring .'" child="'. $child.'" formula="'. $formula.'" 
reaction="'. $reaction.'" reactiontype="'. 
$reaction_type.'" atommap="'. $atommap.'" elembefore="'. $elembefore.'"  
style="fill:url(#mygradient1)" stroke-with="1"/>' ."\n";
close (svgfile);
}

=item $graph->write_text(text, x, y, id)

Function used to write a text line in the SVG.

	The properties:
	* x: X position to start the text.
	* y: Y positicion to start the text.

This function should be called from the inside of the module, not being 
recomended to call it from an external applicattion.

=cut

sub write_text 
{
my $self = shift;
my ($text,$x,$y,$id)=@_;
open (svgfile,">>$self->{file}") or die("Couldn't open File\n");
open (rsvgfile,"<$self->{file}");
my $test = join ("",<rsvgfile>);
close rsvgfile;
my $testtext = $text;
$testtext=~ s/(\(|\)|\[|\]|\+)/\\$1/g;
my $count=( $test=~ s/smilestring="$testtext"//g );
if ( $test !~ /reaction="$testtext"/g )
{print svgfile '<text id="t'.$id.'" x="'.$x .'" y="'.$y .'" font-family="
'.$self->{def_font}.'" font-size="'.$self->{def_font_size}.'" fill=" '.
$self->{def_font_color}.'"   stroke-width="1"  > '.$text."[Listed:$count]".
' </text>'."\n";}
else
{print svgfile '<text id="t'.$id.'" x="'.$x .'" y="'.$y .'" font-family="
'.$self->{def_font}.'" font-size="'.$self->{def_font_size}.'" fill=" '.
$self->{def_font_color}.'"   stroke-width="1"  > '.$text.' </text>'."\n";
}
}	

=item $graph->write_line(id,inix,iniy,xend,yend,direction)

Function used to write a line in the SVG file. This is a path component of the
SVG.

This function should be called from the inside of the module, not being 
recomended to call it from an external applicattion.

=cut	

sub write_line
{	
my $self = shift;
my ($id,$inix,$iniy,$xend,$yend,$direction)=@_;
open (svgfile,">>$self->{file}") or die("Couldn't open File\n");
my $midx=($inix+$xend)/2;
my $midy=($iniy+$yend)/2;
if ($direction==0)
{print svgfile '<path d="M'.$inix.','.$iniy.' L'.$midx.','.$midy.' L'.$xend.
 ','.$yend.'" marker-mid= "url(#Triangle_down)" stroke= "green" 
 stroke-width="1"/>' . "\n";
}
if ($direction==1)
{print svgfile '<path d="M'.$inix.','.$iniy.' L'.$midx.','.$midy.' L'.$xend.
 ','.$yend.'" marker-mid= "url(#Triangle_up)"/>' . "\n";	
}
if ($direction==2)
{print svgfile '<path d="M'.$inix.','.$iniy.' L'.$midx.','.$midy.' L'.$xend.
 ','.$yend.''. "\n";	
}
close (svgfile);
}

=item $graph->write_title_eng()

Title in english language.


This function should be called from the inside of the module, not being 
recomended to call it from an external applicattion.

=cut

sub write_title_eng
{	
my $self = shift;
open (svgfile,">>$self->{file}") or die("Couldn't open File\n");
print svgfile '<text x="10" y="15" font-family="'.$self->{def_font}.'
" font-size="20" fill="'.$self->{def_font_color}.'" > GUI ARTIFICIAL  
</text>'."\n";
close (svgfile);
}

=item $graph->write_top()

SVG needs a header to be recongnized by browsers. This function puts the head
in the SVG file.


This function should be called from the inside of the module, not being 
recomended to call it from an external applicattion.

=cut

sub write_top
{
my $self = shift;
open (svgfile,">>$self->{file}") or die("Couldn't open File\n");
print svgfile '<?xml version="1.0" encoding="iso-8859-1"?>'. "\n";
print svgfile '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 20001102//EN" 
"http://www.w3.org/TR/2000/CR-SVG-20001102/DTD/svg-20001102.dtd">'."\n";
print svgfile '<svg width="'. $self->{width}. '" height="'. $self->{height}. 
'" viewBox="0 0 '. $self->{width} . " ".  $self->{height} .'"  
xml:space="preserve">'."\n";
close (svgfile);
}

=back

=head3 Functions depending of graphic type (dynamic)

These functions depend on the graphic type. The dynamic graphic need some
diferent functions to work correctly.

=cut

=over 4

=item $graph->insert_function()

This function writes the functions and header necessary for the SVG 
interaction.

ShowContentsAndRelatives(evt): This function tales the id of the current
component and increments by one, the result is going to be the group that 
is associated at this component.

Each ball has a unique id, the child of one ball is in a group id+1.

This function should be called from the inside of the module, not being 
recomended to call it from an external applicattion.

=cut

sub insert_function
{	
my $self = shift;
open (svgfile,">>$self->{file}") or die("Couldn't open File\n");
my $function =  'function showContentAndRelatives(evt)
{ var modes =document.getElementById(\'state\');	
  if (modes.getAttribute("mode")=="E")
  {var circle = evt.target;
   if (circle.getAttribute("stroke")=="green")
   {var currentId=circle.getAttribute("id");
    var splitlevel = currentId.split("c");
    var currentLevel = splitlevel;
    var level = parseInt(currentLevel[1],10);
    level = level+1;
    var groupElement = document.getElementById("g"+level);
    if (groupElement.getAttribute("display")=="none")
    { groupElement.setAttribute("display","inline"); }
    else 
    {groupElement.setAttribute("display","none"); 
    }
   }  
  }
 else
 {var SVGDoc  = evt.target.ownerDocument;
  var SVGRoot = SVGDoc.documentElement;
  var svgNS = "http://www.w3.org/2000/svg";
  var circle = evt.target;
  var currentId=circle.getAttribute("id");
  var splitlevel = currentId.split("c");
  var x = parseInt(circle.getAttribute("cx"));
  var y = parseInt(circle.getAttribute("cy"));
  var currentLevel = splitlevel;
  var level = parseInt(currentLevel[1],10);
  var group = document.createElementNS(svgNS,"g");
  if (document.getElementById("p"+level)!=null) 
  {alert("This element already exists");}
  else 
  {group.setAttribute("id","p"+level);
   SVGRoot.appendChild(group);
   var rect=document.createElementNS(svgNS,"rect");
   rect.setAttribute("x",x);
   rect.setAttribute("id","rect"+level);
   rect.setAttribute("x",x);
   rect.setAttribute("y",y);
   rect.setAttribute("rx",5);
   rect.setAttribute("ry",5);
   rect.setAttribute("width",500);
   rect.setAttribute("height",100);
   rect.setAttribute("style","fill:white;stroke:blue;stroke-width:2;fill-opacity:0.8;stroke-opacity:0.9");
   rect.setAttribute(\'onclick\',\'close(evt)\');
   group.appendChild(rect);
   //Create a text smiles
   x = x+10;
   y = y+10;
   var textsmiles=document.createElementNS(svgNS,"text");
   textsmiles.setAttribute("x",x);   textsmiles.setAttribute("y",y);
   textsmiles.setAttribute("id","s"+level);
   textsmiles.setAttribute("style","text-anchor:right;font-size:12;font-family:Arial;fill:blue");
   smilestring = circle.getAttribute("smilestring");	
   textsmiles.appendChild(document.createTextNode("SmilesString: "+smilestring));
   group.appendChild(textsmiles)
   //Create a text child
   y = y+10;
   var childtext=document.createElementNS(svgNS,"text");
   childtext.setAttribute("x",x);	childtext.setAttribute("y",y);
   childtext.setAttribute("id","ch"+level);
   childtext.setAttribute("style","text-anchor:right;font-size:12;font-family:Arial;fill:blue");
   childstring = circle.getAttribute("child");	
   childtext.appendChild(document.createTextNode("Child Number: "+childstring));
   group.appendChild(childtext);
   //Create a text formula
   y = y+10;
   var ftext=document.createElementNS(svgNS,"text");
   ftext.setAttribute("x",x);ftext.setAttribute("y",y);
   ftext.setAttribute("id","f"+level);
   ftext.setAttribute("style","text-anchor:right;font-size:12;font-family:Arial;fill:blue");
   formulastring = circle.getAttribute("formula");	
   ftext.appendChild(document.createTextNode("Formula: "+formulastring));
   group.appendChild(ftext);
   //Create a text reaction
   y = y+10;
   var rtext=document.createElementNS(svgNS,"text");
   rtext.setAttribute("x",x);rtext.setAttribute("y",y);
   rtext.setAttribute("id","r"+level);
   rtext.setAttribute("style","text-anchor:right;font-size:12;font-family:Arial;fill:blue");
   reactionstring = circle.getAttribute("reaction");
   rtypestring = circle.getAttribute("reactiontype");	
   rtext.appendChild(document.createTextNode("Reaction: "+reactionstring +"("+rtypestring+")"));	
   group.appendChild(rtext);
   //Create a text atommap
   y = y+10;
   var amtext=document.createElementNS(svgNS,"text");
   amtext.setAttribute("x",x);amtext.setAttribute("y",y);
   amtext.setAttribute("id","am"+level);
   amtext.setAttribute("style","text-anchor:right;font-size:12;font-family:Arial;fill:blue");
   amstring = circle.getAttribute("atommap");	
   amtext.appendChild(document.createTextNode("Atommap: "+amstring));
   group.appendChild(amtext);
   //Create a text elembefore
   y = y+10;
   var ebtext=document.createElementNS(svgNS,"text");
   ebtext.setAttribute("x",x);ebtext.setAttribute("y",y);
   ebtext.setAttribute("id","eb"+level);
   ebtext.setAttribute("style","text-anchor:right;font-size:12;font-family:Arial;fill:blue");
   ebstring = circle.getAttribute("elembefore");	
   ebtext.appendChild(document.createTextNode("Element Before: "+ebstring));
   group.appendChild(ebtext);
  }
 }
}
'."\n";
print svgfile '<script type="text/ecmascript"> <![CDATA[ '."\n" ;
print svgfile $function ;
print svgfile ' ]]> </script> '."\n";
print svgfile '<script type="text/ecmascript"> <![CDATA[ 
function changeState(evt)
{var rect = evt.target;
 if (rect.getAttribute("mode")=="E")
 {rect.setAttribute("mode","P");
 var text = document.getElementById(\'properties\')	
 text.setAttribute("display","inline");
 var text = document.getElementById(\'expandtext\')	
 text.setAttribute("display","none");	
 }
 else
 {rect.setAttribute("mode","E");
 var text = document.getElementById(\'properties\')	
 text.setAttribute("display","none");
 var text = document.getElementById(\'expandtext\')	
 text.setAttribute("display","inline");			
 }
}
]]> </script>'."\n";
print svgfile '<script type="text/ecmascript"> <![CDATA[ 
function close(evt)
{	
var obj = evt.target;
obj.setAttribute("display","none");
}
]]> </script>'."\n";
print svgfile '<script type="text/ecmascript"> <![CDATA[ 
function close(evt)
{var rect = evt.target;
 var currentId=rect.getAttribute("id");
 var splitlevel = currentId.split("rect");
 var currentLevel = splitlevel;
 var level = parseInt(currentLevel[1],10);
 var smilestext = document.getElementById("s"+level);
 var childtext = document.getElementById("ch"+level);
 var ftext = document.getElementById("f"+level);
 var rtext = document.getElementById("r"+level);
 var amtext = document.getElementById("am"+level);
 var ebtext = document.getElementById("eb"+level);
 var group = document.getElementById("p"+level);
 smilestext.parentNode.removeChild(smilestext);
 childtext.parentNode.removeChild(childtext);
 ftext.parentNode.removeChild(ftext);
 amtext.parentNode.removeChild(amtext);
 ebtext.parentNode.removeChild(ebtext);
 rtext.parentNode.removeChild(rtext);
 rect.parentNode.removeChild(rect);
 group.parentNode.removeChild(group);
}
]]> </script>'."\n";
$self->{funcion} = $function;
close (svgfile);
}

=item $graph->open_group(group)

Opens a new group in the SVG file.

Here if the group is the number 1 (root elements) then it is visible, else it
is writted but is not visible.

This function should be called from the inside of the module, not being 
recomended to call it from an external applicattion.

=cut

sub open_group
{	
my $self = shift;
my ($group)=@_;
open (svgfile,">>$self->{file}") or die("Couldn't open File\n");
if ($group ==1)
{print svgfile '<g id="g'. $group .'" display="inline">' . "\n";}
else
{print svgfile '<g id="g'. $group .'" display="none" >' . "\n";}
close (svgfile);
}	

=item $graph->close_group()

Closes a group in the SVG file.

This function should be called from the inside of the module, not being 
recomended to call it from an external applicattion.

=cut

sub close_group
{	my $self = shift;
	open (svgfile,">>$self->{file}") or die("Couldn't open File\n");
	print svgfile '</g>' . "\n";
	close (svgfile);
}	

=item $graph->write_bottom()

Writes the dynamic bottom (last lines) in the SVG file. 

Here it is defined the option value (properties mode versus expand mode).

This function should be called from the inside of the module, not being 
recomended to call it from an external applicattion.

=cut

sub write_bottom
{
my $self=shift;
open (svgfile,">>$self->{file}") or die("Couldn't open File\n");
print svgfile '<rect maxid="'.$self->{id}.'" id ="state" x="600" y="5" rx="5" ry="5" width="140" 
height="20" fill="red" mode="E" onclick="changeState(evt)" style="fill:white;
stroke:blue;stroke-width:2;fill-opacity:0.8;stroke-opacity:0.9"/>'."\n";
print svgfile '<text id="properties" x="600" y="15" display="none"> 
PROPERTIES MODE </text>'."\n";
print svgfile '<text id="expandtext" x="600" y="15" display="inline"> 
EXPAND MODE </text>'."\n";
print svgfile "</svg>\n";
close (svgfile);
}

=item $graph->recursive_ch()

Plots a dinamic SVG grahic. This is the most sofisticated graphic that this
module can produce.

This function should be called from the inside of the module, not being 
recomended to call it from an external applicattion.

=cut

sub recursive_ch	
{
my $self = shift;
my ($group,$posx,$posy,$root)=@_;
if (scalar(@$root)!=0)
{
 my $rootid= pop (@$root);
 my $rootel = pop (@$root);
 my $child = $self->{db}->rec_child($rootel);
 my $color;
 if (scalar(@$child)!=0) {$color = $self->{def_fathercolor};}
 else {$color = $self->{def_childcolor};}
 my $info = $self->{db}->graphic_information($rootid,$rootel);
 $self->write_circle($posx,$$posy,$self->{id},$color,@$info[0],
 scalar(@$child)/2,@$info[1],@$info[5],@$info[3],@$info[4],@$info[2]);
 $self->write_text(@$info[0],$posx+$self->{radius}*1.5,$$posy,$self->{id});
 if ($posx != $self->{radius})
 {$self->write_line($self->{id},$posx-$self->{distanceh},$$posy,$posx,$$posy,
 @$info[3]);
  $self->write_text(@$info[5],$posx-$self->{distanceh},$$posy+$self->{radius},
  $self->{id});
 }
 $self->{id}= $self->{id}+1;
 if (scalar(@$child)!=0)
 {$group=$self->{id};
  $self->open_group($group);
  $posx = $posx+$self->{distanceh};
  $$posy=$$posy+(2*$self->{radius});
  $self->recursive_ch($group,$posx,$posy,$child);
  $self->close_group();
  $posx = $posx-$self->{distanceh};
 }
 else
 { $$posy=$$posy+(2*$self->{radius});
 }
 $$posy=$$posy+(2*$self->{radius});
 $self->recursive_ch($group,$posx,$posy,$root);
}
}

=back

=head3 Functions that depends of the graphic type (static)

Static graphics needs some diferent functions in the SVG file

=cut

=over 4

=item $graph->write_bottom_static()

Writes the bottom (last lines) in the SVG static file.

This function should be called from the inside of the module, not being 
recomended to call it from an external applicattion.

=cut

sub write_bottom_static
{	
my $self=shift;
open (svgfile,">>$self->{file}") or die("Couldn't open File\n");
print svgfile "</svg>\n";
close (svgfile);
}

=item $graph->write_circle_static(x, y, id, color, smilestring, child, formula,
reaction, reaction_type, atommap, elembefore)

This function writes a component in the graph.

	The properties:
	* id: This is an unique id for one component in the graph.
	* cx: X position.

This function should be called from the inside of the module, not being 
recomended to call it from an external applicattion.

=cut

sub write_circle_static
{	
my $self = shift;
my ($x,$y,$id,$color,$smilestring,$child,$formula,$reaction,$reaction_type,
$atommap,$elembefore)=@_;
open (svgfile,">>$self->{file}") or die("Couldn't open File\n");
print svgfile '<circle id="c'. $id .'" cx="'. $x. '" cy="' .$y. '" r="20" 
stroke="'.$color.'" smilestring="'. $smilestring .'" child="'. $child.'"
 formula="'. $formula.'" reaction="'. $reaction.'" reactiontype="'. 
$reaction_type.'" atommap="'. $atommap.'" elembefore="'. $elembefore.'"  
style="fill:url(#mygradient1)" stroke-with="1"/>' ."\n";
close (svgfile);
}

=item $graph->recursive_ch_static(x, y, root)

Represents a SVG static file with the solution in the solution graphic table.

How does it works:

Get all the root elements and then, get the childs for each one.

This function should be called from the inside of the module, not being 
recomended to call it from an external applicattion.

=cut

sub recursive_ch_static	
{
my $self = shift;
my ($posx,$posy,$root)=@_;
if (scalar(@$root)!=0)
{my $rootid= pop (@$root);
 my $rootel = pop (@$root);
 my $child = $self->{db}->rec_child($rootel);
 my $color;
 if (scalar(@$child)!=0) {$color = $self->{def_fathercolor};}
 else {$color = $self->{def_childcolor};}
 my $info = $self->{db}->graphic_information($rootid,$rootel);
 $self->write_circle_static($posx,$$posy,$self->{id},$color,@$info[0],
 scalar(@$child)/2,@$info[1],@$info[5],@$info[3],@$info[4],@$info[2]);
 $self->write_text(@$info[0],$posx+$self->{radius}*1.5,$$posy,$self->{id});
 if ($posx != $self->{radius})
 {$self->write_line($self->{id},$posx-$self->{distanceh},$$posy,$posx,$$posy,
 @$info[3]);
  $self->write_text(@$info[5],$posx-$self->{distanceh},$$posy+$self->{radius},
  $self->{id});
 }
 $self->{id}= $self->{id}+1;
 if (scalar(@$child)!=0)
 {
  $posx = $posx+$self->{distanceh};
  $$posy=$$posy+(2*$self->{radius});
  $self->recursive_ch_static($posx,$posy,$child);
  $posx = $posx-$self->{distanceh};
 }
 else
 { $$posy=$$posy+(2*$self->{radius});
 }
 $$posy=$$posy+(2*$self->{radius});
 $self->recursive_ch_static($posx,$posy,$root);
}
}

=back

=head3 Functions in text mode 

Text mode graphics needs diferent functions to write the file.

=cut

=over 4

=item $graph->write_top_text()

This function writes the title in the text version of the graphic

This function should be called from the inside of the module, not being 
recomended to call it from an external applicattion.

=cut

sub write_top_text
{
my $self = shift;
open (svgfile,">>$self->{file}") or die("Couldn't open File\n");
print svgfile 'TEXT VERSION '. "\n";
close (svgfile);
}

=item $graph->recursive_chtxt()

This function writes a txt file with the solution graph table. This is the 
simplest way to see a graphic structure of I<cha>

This function should be called from the inside of the module, not being 
recomended to call it from an external applicattion.

=cut

sub recursive_chtxt	
{
my $self = shift;
my ($posx,$root)=@_;
if (scalar(@$root)!=0)
{my $rootid = pop @$root;
 my $rootel = pop @$root;
 my $child = $self->{db}->rec_child($rootel);
 my $info = $self->{db}->graphic_information($rootid,$rootel);
 my $arrow;
 if (@$info[3]==0) {$arrow=@$info[5]."-->";}
 if (@$info[3]==1) {$arrow="<--".@$info[5];}
 if (@$info[3]==2) {$arrow="<-".@$info[5]."->";}
 open (svgfile,">>$self->{file}") or die("Couldn't open File\n");
 for (my $x=0; $x<$posx; $x++){ print svgfile " ";}
 if ($posx!=1)
 { print svgfile $arrow . "   "; }
 print svgfile  $self->smiles_string($rootel) .  "\n";
 close (svgfile);
 $self->{id}= $self->{id}+1;
 if (scalar(@$child)!=0)
 {$posx = $posx+5;
  $self->recursive_chtxt($posx,$child);
  $posx = $posx-5;
 }
 $self->recursive_chtxt($posx,$root);
}
}

=back

=head2 Plotting functions

These functions are used to plot and prepare the table before graphic drawing

=cut

=head3 Preparing and drawing artificial chemistry

These functions are used to work with specific artificial chemistry

=cut 

=over 4

=item $graph->ch_plot()

Using I<Chemistry::SQL> module store in the I<sgraph> table the necessary 
data to draw the graphic of artificial chemistry (designed by name).

After this, plot using the apropiate function, it depends of the selected mode.

I<Example (Dynamic SVG):>

	my $cha5 = Graphics::new($db1,"1400","1024","10","10","25",
	"cha.svg","svg");
	$cha5->ch_plot("$chaname");

I<Example (Static SVG):>

	my $cha6 = Graphics::new($db1,"1400","1024","10","10","25",
	"cha.svg","svg_static");
	$cha6->ch_plot("$chaname");

I<Example (Text):>

	my $cha7 = Graphics::new($db1,"1400","1024","10","10","25",
	"cha.txt","text");
	$cha7->ch_plot("$chaname");

=cut

sub ch_plot	
{
my $self = shift;
my ($qname) = @_;
my $root;
$self->ini_file;	
print "You are working on $self->{mode} mode\n";		
$self->{db}->clean_tables("sgraph");
$self->{db}->gsg_complete($qname);
$root=$self->{db}->rec_root;
if ($self->{mode} eq "text")
{$self->write_top_text;
 $self->recursive_chtxt("1",$root);
}
if ($self->{mode} eq "svg")
{$self->write_top;
 $self->insert_function;
 $self->write_style;
 $self->write_title_eng;
 my $posy_static=$self->{iniy};
 $self->recursive_ch("1",$self->{radius},\$posy_static,$root);
 $self->write_bottom;
}
if ($self->{mode} eq "svg_static")
{$self->write_top;
 $self->write_style;
 $self->write_title_eng;
 my $posy_static=$self->{iniy};
 $self->recursive_ch_static($self->{radius},\$posy_static,$root);
 $self->write_bottom_static;
}
}

=item $graph->ch_plot_levels(qname, startlevel,endlevel)

Using I<Chemistry::SQL> module store in the I<sgraph> table the necessary 
data to draw the graphic of artificial chemistry (designed by name) 
from startlevel to endlevel.

After this, plot using the apropiate function, it depends of the selected mode.

I<Example (Dynamic SVG):>

	my $cha = Graphics::new($db1,"1400","1024","10","10","25",
	"chalevel.svg","svg");
	$cha->ch_plot_levels("$chaname",2,3);

I<Example (Static SVG):>

	my $cha = Graphics::new($db1,"1400","1024","10","10","25",
	"chalevels.svg","svg_static");
	$cha->ch_plot_levels("$chaname",2,3);

I<Example (Text):>

	my $cha = Graphics::new($db1,"1400","1024","10","10","25",
	"chalevel.txt","text");
	$cha->ch_plot_levels("$chaname",2,3);

=cut

sub ch_plot_levels	
{
my $self = shift;
my ($qname,$initlevel,$endlevel) = @_;
my $root;
# Create a new SVG graph
$self->ini_file;	
print "You are working on $self->{mode} mode\n";
$self->{db}->clean_tables("sgraph");
$self->{db}->gsg_levels($qname,$initlevel,$endlevel);
$root=$self->{db}->rec_root;
if ($self->{mode} eq "text")
{$self->write_top_text;
 $self->recursive_chtxt("1",$root);
}
if ($self->{mode} eq "svg")
{$self->write_top;
 $self->insert_function;
 $self->write_style;
 $self->write_title_eng;
  my $posy_static=$self->{iniy};
 $self->recursive_ch("1",$self->{radius},\$posy_static,$root);
 $self->write_bottom;
}
if ($self->{mode} eq "svg_static")
{$self->write_top;
 $self->write_style;
 $self->write_title_eng;
 my $posy_static=$self->{iniy};
 $self->recursive_ch_static($self->{radius},\$posy_static,$root);
 $self->write_bottom_static;
}	
}

=back

=head3 Preparing and plotting independent results

These functions are used to work with especific results (components), 
and they are:

=cut 

=over 4

=item $graph->ch_plot_fsc(Reference_array_start_components)

Using I<Chemistry::SQL> module store in the I<sgraph> table the necessary 
data to draw the possibilities from the start components in 
the Reference_Array

After this, draw using the apropiate function, it depends of the selected mode.

I<Example (Dynamic SVG):>

	my $cha = Graphics::new($db1,"1400","1024","10","10","25",
	"gsg_fsc.svg","svg");
	my @root;
	push @root,Chemistry::Mol->
	parse("OC1C(C(C(CO)OC1OC1(CO)C(C(C(CO)O1)O)O)O)O", format => 'smiles');
	push @root,Chemistry::Mol->
	parse("OC1C(C(C(CO)OC1OC)O)O", format => 'smiles');
	push @root,Chemistry::Mol->
	parse("OC1=CC=CC=C1C1=CC=CC=C1", format => 'smiles');
	push @root,Chemistry::
	Mol->parse("[O-]C1=CC=CC=C1C1=CC=CC=C1.[Na+]", format => 'smiles');
	$cha->ch_plot_fsc(\@root);

I<Example (Static SVG):>

	my $cha = Graphics::new($db1,"1400","1024","10","10","25",
	"gsg_fscs.svg","svg_static");
	my @root;
	push @root,Chemistry::Mol->
	parse("OC1C(C(C(CO)OC1OC1(CO)C(C(C(CO)O1)O)O)O)O", format => 'smiles');
	push @root,Chemistry::Mol->
	parse("OC1C(C(C(CO)OC1OC)O)O", format => 'smiles');
	push @root,Chemistry::Mol->
	parse("OC1=CC=CC=C1C1=CC=CC=C1", format => 'smiles');
	push @root,Chemistry::Mol->
	parse("[O-]C1=CC=CC=C1C1=CC=CC=C1.[Na+]", format => 'smiles');
	$cha->ch_plot_fsc(\@root);

I<Example (Text):>

	my $cha = Graphics::new($db1,"1400","1024","10","10","25",
	"gsg_fsc.txt","text");
	my @root;
	push @root,Chemistry::Mol->
	parse("OC1C(C(C(CO)OC1OC1(CO)C(C(C(CO)O1)O)O)O)O", format => 'smiles');
	push @root,Chemistry::Mol->
	parse("OC1C(C(C(CO)OC1OC)O)O", format => 'smiles');
	push @root,Chemistry::Mol->
	parse("OC1=CC=CC=C1C1=CC=CC=C1", format => 'smiles');
	push @root,Chemistry::Mol->
	parse("[O-]C1=CC=CC=C1C1=CC=CC=C1.[Na+]", format => 'smiles');
	$cha->ch_plot_fsc(\@root);

=cut

sub ch_plot_fsc	
{
my $self = shift;
my ($rootcomp) = @_;
$self->ini_file;	
print "You are working on $self->{mode} mode\n";
$self->{db}->clean_tables("sgraph");
$self->{db}->gsg_fsc($rootcomp);
my $root=$self->{db}->rec_root;
if ($self->{mode} eq "text")
{$self->write_top_text;
 $self->recursive_chtxt("1",$root);
}
if ($self->{mode} eq "svg")
{$self->write_top;
 $self->insert_function;
 $self->write_style;
 $self->write_title_eng;
  my $posy_static=$self->{iniy};
 $self->recursive_ch("1",$self->{radius},\$posy_static,$root);
 $self->write_bottom;
}
if ($self->{mode} eq "svg_static")
{$self->write_top;
 $self->write_style;
 $self->write_title_eng;
 my $posy_static=$self->{iniy};
 $self->recursive_ch_static($self->{radius},\$posy_static,$root);
 $self->write_bottom_static;
}
}

=item $graph->ch_plot_fec(qname, Reference_array_end_components)

Using I<Chemistry::SQL> module store in the I<sgraph> table the necessary 
data to draw from the end components in the I<Reference_Array>

After this, draw using the apropiate function, it depends of the selected mode.

I<Example (Dynamic SVG):>

	my $cha = Graphics::new($db1,"1400","1024","10","10","25",
	"gsg_fec.svg","svg");
	my @root;
	push @root,Chemistry::Mol->parse("OC12C3C=CC4C5C6C=CC1(C35)C462", 
	format => 'smiles');
	push @root,Chemistry::Mol->parse("OC1C2C=CC3C=1C13C2C2C3C2C31", 
	format => 'smiles');
	$cha->ch_plot_fec(\@root);

I<Example (Static SVG):>

	my $cha = Graphics::new($db1,"1400","1024","10","10","25",
	"gsg_fecs.svg","svg_static");
	my @root;
	push @root,Chemistry::Mol->parse("OC12C3C=CC4C5C6C=CC1(C35)C462",
	format => 'smiles');
	push @root,Chemistry::Mol->parse("OC1C2C=CC3C=1C13C2C2C3C2C31",
	format => 'smiles');
	$cha->ch_plot_fec(\@root);

I<Example (Text):>

	my $cha = Graphics::new($db1,"1400","1024","10","10","25",
	"gsg_fec.txt","text");
	my @root;
	push @root,Chemistry::Mol->parse("OC12C3C=CC4C5C6C=CC1(C35)C462",
	format => 'smiles');
	push @root,Chemistry::Mol->parse("OC1C2C=CC3C=1C13C2C2C3C2C31",
	format => 'smiles');
	$cha->ch_plot_fec(\@root);

=cut

sub ch_plot_fec	
{
my $self = shift;
my ($rootcomp) = @_;
# Create a new SVG graph
$self->ini_file;	
print "You are working on $self->{mode} mode\n";
#$self->write_title_eng;			
$self->{db}->clean_tables("sgraph");
$self->{db}->gsg_fec($rootcomp);
my $root=$self->{db}->rec_root;
if ($self->{mode} eq "text")
{$self->write_top_text;
 $self->recursive_chtxt("1",$root);
}
if ($self->{mode} eq "svg")
{$self->write_top;
 $self->insert_function;
 $self->write_style;
 $self->write_title_eng;
 my $posy_static=$self->{iniy};
 $self->recursive_ch("1",$self->{radius},\$posy_static,$root);
 $self->write_bottom;
}
if ($self->{mode} eq "svg_static")
{ $self->write_top;
 $self->write_style;
 $self->write_title_eng;
 my $posy_static=$self->{iniy};
 $self->recursive_ch_static($self->{radius},\$posy_static,$root);
 $self->write_bottom_static;
}
}

1;

=back

=head1 VERSION

0.01

=head1 SEE ALSO

L<Chemistry::Artificial::SQL>,L<Chemistry::SQL>

The PerlMol website L<http://www.perlmol.org/>

=head1 AUTHOR

Bernat Requesens E<lt>brequesens@gmail.comE<gt>.

=head1 COPYRIGHT

This program is free software; it can be redistributed and/or modified under
the same terms as Perl itself.

=cut
