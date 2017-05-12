package CAD::Drawing::IO::DWGI;
our $VERSION = '0.12';

use 5.006;
use strict;
use warnings;

BEGIN {
	my $dir = __FILE__;
	$dir =~ s#.pm$#/#;
	our $functions = $dir . "functions.c";
	# print "functions at begin: $functions\n";
}

use Inline (
		C => Config => 
		INC => '-I/usr/local/include',
		MYEXTLIB => '/usr/local/lib/ad2.a /usr/local/lib/ad2pic.a',
		NAME => "CAD::Drawing::IO::DWGI",
		#FILTERS => 'Strip_POD',
		VERSION => '0.12',
		# CLEAN_AFTER_BUILD => 0,
#        FORCE_BUILD => 1,
		# NOTE:  you can just call this with -MInline=NOISY,NOCLEAN,etc
		);
our $functions;
use Inline C => $functions;

# NOTE: this file contains little or no Perl code, the entire module is
# implemented using the Inline.pm module and all C code is contained in
# the file functions.c (the contents of which are distributed under the
# __DATA__ section below.)

=pod

=head1 NAME

CAD::Drawing::IO::DWGI - Perl bindings to the OpenDWG toolkit

=head1 WARNING

This module is intended to serve as a backend to CAD::Drawing and is not
guaranteed to remain interface stable.  Do not use this module directly
unless you have a need for higher-speed access than that which is
provided by CAD::Drawing (which also provides loads of other features.)

Just 

  use CAD::Drawing 

=head1 AUTHOR

  Eric L. Wilhelm
  ewilhelm at cpan dot org
  http://scratchcomputing.com

=head1 COPYRIGHT

This module is Copyright (C) 2003-2006 by Eric L. Wilhelm.  Portions
Copyright (C) 2003 Eric L. Wilhelm and A. Zahner Co.  

This is module is free software as described under the terms below.
Permission to use, modify and distribute this module shall be governed
by these terms (the module code is distributed and licensed
independently from the OpenDWG consortium's code.)  All notices and
disclaimers must remain intact with any copies of this software.

=head1 LICENSE

This module is distributed under the same terms as Perl.  See the Perl
source package for details.

=head1 REQUIREMENTS

You must obtain and install the OpenDWG libraries from the OpenDWG
consortium in order to use this module.  By using this module, you have
the responsibility to adhere to both the licensing of this module and
the licensing of the OpenDWG consortium.

=head1 SYNOPSIS

  use CAD::Drawing::IO::DWGI;
  $dwg = CAD::Drawing::IO::DWGI->new();
  $dwg->loadfile("file.dwg");
  $dwg->getentinit();
  while(my($layer, $color, $type) = $dwg->getent()) {
    my $type = $dwg->entype($type);
    if($type eq "lines") {
      $line = $dwg->getLine();
      }
    }
  
  $dxf = CAD::Drawing::IO::DWGI->new();
  $dxf->newfile(1);
  $dxf->getentinit();
  $dxf->writeCircle({"pt"=>[$x, $y], "rad" => 1.125, "color" => 9});
  $dxf->savefile("check.dxf", 1);

=head1 SPEED

Wow!  This is fast!  I had originally implemented this with a
function-call based wrapper which had the drawback that the layerhandle
had to be found for every object which was being saved.  See the
writeLayer() and setLayer() functions below for details of the improved
methods.  Also note that while the speed is amazing from this level,
very little speed is lost by moving up a level to using CAD::Drawing
(please do this.)

=head1 Accuracy

The dxf file accuracy is set internally at 14 digits after the decimal
place.  Providing an interface to set this would take a bit of coding
in C, so you are more than welcome to submit a patch.

=cut

=head1 Constructor

=cut

=head2 new

Creates a new blessed reference which gives access to the following
object methods.

  $d = CAD::Drawing::IO::DWGI->new();

=head1 File Actions

=head2 loadfile

Loads a file from disk into the toolkit data structure.

  $d->loadfile("filename.dxf|dwg");

=head2 closefile

undocumented

=head2 newfile

Creates an empty data structure and initializes some default values.

  $d->newfile($version);

=cut

=head2 savefile

Writes the data to disk.

  $d->savefile($name, $type);

=cut

=head1 Layer Actions

=cut

=head2 listlayers

Returns a list of layers in the loaded object.

  @layers = $d->listlayers();

=cut

=head2 writeLayer

Add a new layer to the database and set it as the current layer.  A
newfile() starts with layer "0" as the default.

  %layer_opt = (
    name => $name,  # limit of 255 characters?
    color => 9,     # must be 0-256
    );
  $dwg->writeLayer(\%layer_opt)

Currently, the only parameter supported is the name and color.

=cut

=head2 setLayer

Set layer as the default.  Layer must have been previously created with
writeLayer().

  $dwg->setLayer($name) or die "layer not in drawing yet";

=cut

=head1 Typed Entity Functions

NOTE that all getThing methods must be part of a getent() loop.

=cut


=head2 getCircle

Reads a circle from the current entity.  

  $circle = $d->getCircle();
  print "point:  ", join(",", @{$circle->{pt}}), "\n";
  print "rad:    $circle->{rad}\n";

=cut

=head2 writeCircle

Writes a circle to the object structure.

  $d->writeCircle({"pt"=>[$x,$y,$z], "rad"=>$rad, "color"=>$color});

=cut

=head2 getEllipse

Reads an ellipse from the current entity.

  $el = $d->getEllipse();
  print "center:  ", join(",", @{$el->{pt}}), "\n";
  print "offset:  ", join(",", @{$el->{off}}), "\n";
  print "minor / major ratio:   $el->{ratio}\n";
  print "start / end:  ", join(",", @{$el->{angs}}), "\n";

There is (as usual) some discrepency between the odwg docs and the adesk
dxf ref as to wtf this parameter thing is.  There are some undocumented
functions in the toolkit, which seem to only reduce the arc-angles.
NOTE that the angles given are relative to the baseline described by the
vector stored in $el->{off}.

=cut


=head2 getArc

Reads an arc from the current entity.

  $arc = $d->getArc();
  print "point:  ", join(",", @{$arc->{pt}}), "\n";
  print "rad:    $arc->{rad}\n";
  print "radian angles: ", join(",", @{$arc->{angs}}), "\n";

=cut

=head2 writeArc

Writes an arc to the object structure.

  %ArcOpts = (
    "pt" => [$x,$y,$z],
    "rad" => $rad,
    "angs" => [$start, $end],
    "color" => $color,
    );
  $d->writeArc(\%ArcOpts);

=cut

=head2 getLine

Reads a line from the current entity.

  $line = $d->getLine();
  print "endpoints:  ",
    join("\n", 
      map({join(",", @{$_})}
        @{$line->{pts}}
      )
    ), "\n";

=cut


=head2 writeLine

Writes a line to the object structure.

  %LineOpts = (
    "pts" => [ [$x1,$y1,$z1], [$x2,$y2,$z2] ],
    "color" => $color,
    );
  $d->writeLine(\%LineOpts);

=cut

=head2 getText

  $text = $d->getText();
  print "point:  ", join(",", @{$text->{pt}}), "\n";
  print "string: ", $text->{string}, "\n";
  print "height: ", $text->{height}, "\n";

=cut

=head2 writeText

  %TextOpts = (
    "pt" => [$x, $y, $z],
    "string" => $string,
    "height" => $height,
    "color" => $color,
    );
  $d->writeText(\%TextOpts);

=cut

=head2 getSolid

experimental

=cut

=head2 getPoint

  $point = $d->getPoint();
  print "point:  ", join(",", @{$point->{pt}}), "\n";

=cut

=head2 writePoint

  %PointOpts = (
    "pt" => [$x, $y, $z],
    "color" => $color,
    );
  $d->writePoint(\%PointOpts);

=cut

=head2 getLWPline

  $pline = $d->getLWPline();
  print "points:\n\t", 
    join("\n\t", 
        map({join(",", @{$_})}
          @{$pline->{pts}}
           )
      ), "\n";
  print $pline->{closed} ? "closed" : "open" , "\n";

=cut

=head2 writeLWPline

  @pts = (
    [0,1],
    [5,-2.25],
    [7,9],
    [4,6],
    [-2,7.375],
     );
  %PlineOpts = (
    "pts" => \@pts,
    "closed" => 1,
    "color" => 255,
    );
  $d->writeLWPline(\%PlineOpts);

=cut

=head2 getImage

Reads an image from the current entity.

=cut

=head1 Entity List handling

Entities are read and written from a list, which must be initialized on
both read and write operations.

=cut

=head2 getentinit

Initializes the entity list.  Call this before adding anything to a
newfile() or before calling getent() after loadfile()

=cut

=head2 getent

Returns the next entity.  This is paired with getentinit() and the two
act as a pair much like the Perl open() and $line = <FILEHANDLE> setup.

=cut

=head1 Utilities

=cut

=head2 get_extrusion

Returns the extrusion vector of the current entity as an array
reference.  Returns undef if extrusion is not set.

  if(my $extrusion = $dwg->get_extrusion()) {
    print "extrusion is @$extrusion\n";
  }

=cut

=head2 set_extrusion

Sets the extrusion direction of the current entity.  Not intended to be
used from Perl (each write<entity> function calls this itself if the
value of $opts{extrusion} is set.)

=cut

=head2 entype

Return a text string for the entity type code.

  $type = $d->entype($type);
  if($type eq "plines") {
    $pline = $d->getLWPline();
    }

=cut

=head2 DESTROY

This function is called under the hood by perl when variables created by
new() go out of scope.  You should never call this from your code, but
you can undef() your object and it will get called.

Note that you may in fact need to undef($dwg) to kill your object before
trying to use another one.  The toolkit doesn't like to be opened and
closed while objects are in-use, and each object has no way of knowing
whether or not there are other objects in-use.  Since I don't feel like
leaking memory with a BEGIN and END setup, you'll just have to live with
this (or make a suggestion for a better setup.)

=cut

=begin shutup_pod_coverage

Cool, huh?

=head2 dl_load_flags

What's that?

=head2 hello

I did do this one.  Maybe I should test it.

=end shutup_pod_coverage

=cut

1;
