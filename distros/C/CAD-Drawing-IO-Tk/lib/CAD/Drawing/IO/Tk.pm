package CAD::Drawing::IO::Tk;
our $VERSION = '0.04';

use CAD::Drawing;
use CAD::Drawing::Defined;

use CAD::Calc qw(dist2d);

# with the new plug-in architecture, this seems odd to have a
# strictly-inherited module in the IO::* namespace (when this thing
# finally grows-up, maybe we use a GUI::* namespace?)

our $is_inherited = 1;


use vars qw(
	%dsp
	$textsize
	$text_base
	);

$text_base = 8;

use warnings;
use strict;
use Carp;

my %default = (
	width    => 800,
	height   => 600,
	zoom     => "fit",
	);

=pod

=head1 NAME

CAD::Drawing::IO::Tk - GUI I/O methods for CAD::Drawing

=head1 NOTICE

This module is considered extremely pre-ALPHA and its use is probably
deprecated by the time you read this.

=head1 AUTHOR

Eric L. Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com

=head1 COPYRIGHT

This module is copyright (C) 2004-2006 by Eric L. Wilhelm.  Portions
copyright (C) 2003 by Eric L. Wilhelm and A. Zahner Co.

=head1 LICENSE

This module is distributed under the same terms as Perl.  See the Perl
source package for details.

You may use this software under one of the following licenses:

  (1) GNU General Public License
    (found at http://www.gnu.org/copyleft/gpl.html)
  (2) Artistic License
    (found at http://www.perl.com/pub/language/misc/Artistic.html)

=head1 NO WARRANTY

This software is distributed with ABSOLUTELY NO WARRANTY.  The author,
his former employer, and any other contributors will in no way be held
liable for any loss or damages resulting from its use.

=head1 Modifications

The source code of this module is made freely available and
distributable under the GPL or Artistic License.  Modifications to and
use of this software must adhere to one of these licenses.  Changes to
the code should be noted as such and this notification (as well as the
above copyright information) must remain intact on all copies of the
code.

Additionally, while the author is actively developing this code,
notification of any intended changes or extensions would be most helpful
in avoiding repeated work for all parties involved.  Please contact the
author with any such development plans.

=head1 SEE ALSO

  CAD::Drawing::IO
  Tk

=cut

=head1 Methods

There is no constructor for this class, its methods are inherited via
CAD::Drawing::IO

=head1  Thoughts

Need to re-structure the entire deal to have its own object which
belongs to the drawing object (or does the drawing object belong to this
object?)  Either way, we need to be able to build-up into interactive
commands (possibly using eval("\$drw->$command"); ?)

Ultimately, the focus here will likely drift toward supporting perlcad
and enabling use of perlcad from within CAD::Drawing scripts.  However,
the nature of lights-out scripting vs the nature of on-screen drafting
is quite different, so there will be some tricks involved.  Once each
entity has its own class, the ability to install callbacks and the
resolution of notifications should get easier.  But, there will still
be the issue that a debug popup does not know it will appear when the
entities are created, while a drafting viewport does (or does it?)

Possibly, adding a list of tk-id's to each $obj as it is drawn would be
a good starting point, but this gets us into trouble with multiple
viewports.

=cut

=head2 show

Creates a new window (no options are required.)

  $drw->show(%options);

=over

=item Available Options

  forkokay  => bool         -- Attempt to fork the new window
  window    => MainWindow   -- Use the pre-existing Tk object
  stl       => Message      -- Use pre-existing Message widget
  size      => [W,H]        -- Specify window size in pixels
  width     => W            -- alias to size
  height    => H            -- ditto
  center    => [X,Y]        -- Center the drawing at (X,Y)
  scale     => factor       -- Zoom by factor (default to fit)
  bgcolor   => color        -- defaults to "white"
  hang      => boolean      -- if not, you just get the canvas widget
  items     => \@list       -- sorry, not compatible with select_addr :(

=back

=cut
sub show {
	my $self = shift;
	my %options = @_;
	# XXX cannot do "use" or we get silly _TK_EXIT_(0) from everywhere!
	require Tk;
	require Tk::WorldCanvas;
	my $kidpid;
	if($options{forkokay}) {
		$SIG{CHILD} = 'IGNORE';
		if($kidpid = fork()) {
			return($kidpid);
		}
		defined($kidpid) or croak("cannot fork $!\n");
		$options{forkokay} = 0;
	}
	my $mw = $options{window};
	defined($mw) || ($mw = MainWindow->new());
	unless($options{size}) {
		foreach my $item ("width", "height") {
			my $val = $options{$item};
			$val || ($val = $default{$item});
			push(@{$options{size}}, $val);
		}
	}
	$options{bgcolor} || ($options{bgcolor} = "white");
	# FIXME: should have an indication of viewport number?
	$options{title} || ($options{title} = "Drawing");
	$mw->title($options{title});
	my ($w,$h) = @{$options{size}};
#    print "requesting $w x $h\n";
	my $cnv = $mw->WorldCanvas(
				'-bg' => $options{bgcolor},
				'-width' => $options{size}[0],
				'-height' => $options{size}[1],
				);
	# XXX scrolling when you want to wheelzoom is icky.  What's up with
	# that? (Tk::Canvas is a mess, that's what!)
	## print "bound to ", $cnv->bind('<4>'), "\n";
	$cnv->pack(-fill => 'both', -expand=>1);
	# XXX break this out into pieces
	my $stl;
	my %stl_conf = (
			-anchor => "sw",
			-width => $w,
			-justify=>"left",
			);
	my %stl_pack = (-fill => 'x', -expand=>0, -side => "bottom");
		
	unless($stl = $options{stl}) {
		$stl = $mw->Message(%stl_conf);
		$stl->pack(%stl_pack);
	}
	else {
		$stl->configure(%stl_conf);
		$stl->pack(%stl_pack);
	}
# FIXME: cannot just have a simplistic command line, it has to be powerful
#    my $cmd = $mw->Text(
#        -height=> 2,
#        -width => $w,
#        );
#    $cmd->pack(-fill => 'x', -expand=>0, -side => "bottom");
	# XXX $self here is a drawing, maybe that's not what we want...
	$self->tkbindings($mw, $cnv, $stl);
	$options{items} || ($options{items} = $self->select_addr({all=>1}));
	$self->Draw($cnv, %options);
	$cnv->viewAll();
	text_size_reset($cnv);
	if(defined($kidpid) or $options{hang}) {
	    $mw->MainLoop;
	}
	else {
		return($cnv);
	}
} # end subroutine show definition
########################################################################

=head2 Draw

Draws geometry on the Tk canvas $cnv.  List of items to draw must be
specified via addresses stored in $options{items}.

The newest fad (:e) is the $options{tag} argument, which uses
addr_to_tktag() to tag the item.

  $drw->Draw($cnv, %options);

=cut
sub Draw {
	my $self = shift;
	my $cnv = shift; 
	my %options = @_;
	my @list = @{$options{items}};
	foreach my $item (@list) {
		my $type = $item->{type};
#        print "item: $type\n";
		if($dsp{$type}) {
			my @tk_ids = $dsp{$type}->($self, $cnv, $item);
			if($options{tag}) {
				foreach my $tk_id (@tk_ids) {
					my $tagstring = $self->addr_to_tktag($item);
					$cnv->itemconfigure($tk_id, -tags => $tagstring);
				}
			}
		}
		else {
			carp "no function for $type\n";
		}
	}
	
} # end subroutine Draw definition
########################################################################

=head2 tkbindings

Setup the keybindings.

  $drw->tkbindings($mw, $cnv);

=cut
sub tkbindings {
	my $self = shift;
	my ($mw, $cnv, $stl) = @_;
	# FIXME: this should be much more robust

# maybe a vim-style modal binding? or possibly a command-line based
# system.
# just bind ":" to switch to the command bindings and <Esc> to go back
# to visual mode (and the end of every command must go to visual mode.)

	# this one basically means 'focusFollowsMouse', which is evil.
	# $mw->bind('<Any-Enter>' => sub{ $cnv->Tk::focus});

#    $mw->bind('<q>' => sub{$mw->destroy});
#    $cnv->CanvasBind('<q>' => sub{print "called\n";exit;});
	$mw->bind('<q>' => sub {$mw->destroy});

	# XXX move this...
	# middle-button pan:
	my @pan_start;
	my $drag_current;
	$cnv->CanvasBind(
		'<ButtonPress-2>' => sub {
			@pan_start = $cnv->eventLocation();
#            print "starting pan at @pan_start\n";
		});
	# have to have this here to prevent spurious panning with double-clicks
	$cnv->CanvasBind('<B2-Motion>' => sub {$drag_current = 1});
	$cnv->CanvasBind(
		'<ButtonRelease-2>' => sub {
			$drag_current || return();
			my @pan_stop = $cnv->eventLocation();
			my $scale = $cnv->pixelSize();
#            print "\tdouble: $isdouble\n";
#            print "\tdrag: $drag_current\n";
#            print "scale is $scale\n";
#            print "stopping pan at @pan_stop\n";
			my @diff = map({$pan_start[$_] - $pan_stop[$_]} 0,1);
#            my $panx = abs($diff[0])/$scale;
#            my $pany = abs($diff[1])/$scale;
#            print "pixels: ($panx,$pany)\n";
#            my $dopan = ( $panx > 10) | ( $pany > 10);
#            $dopan && print "panning by @diff\n";
#            $dopan && $cnv->panWorld(@diff);
			$cnv->panWorld(@diff);
			$drag_current = 0;
		});
	
	# OKAY, so we've got 4 zoom actions and we don't get text or images
	# for free.

	# this takes away all of our fun of having sizable texts (hmm. I
	# guess we could create this font from anywhere?)
	
	# XXX this is going to have some odd behaviour for now, but it isn't
	# worth trying to make a word-processor widget behave like scalable
	# text.
	$textsize = $text_base;
	$cnv->fontCreate(
			'cad-drawing-font',
			-family => 'lucidasans',
			-size   => $textsize,
			);
	text_size_reset($cnv);
#    print "view is @coords\n";
#    print "other configs:\n", 
#        join("\n", map({join(" ", @$_ )} $cnv->configure())), "\n";
#    print "width is: ", $cnv->cget(-width), "\n";
	
	# mouse-wheel zooming:
	$cnv->CanvasBind('<Button-4>' => sub{
				$cnv->zoom(1.125);
				text_size_reset($cnv);
				# print "$textsize\n";
				if(0) {
					package Tk::WorldCanvas;
					my $pdata = $cnv->privateData();
					print "pdata: $pdata\n";
					foreach my $key (keys(%$pdata)) {
						print "$key: $pdata->{$key}\n";
					}
					print "size is now $pdata->{width} x $pdata->{height}\n";
				}

			}
			);
	$cnv->CanvasBind('<Button-5>' => sub{
				$cnv->zoom(1/1.125);
				text_size_reset($cnv);
			}
			);
	# zoom extents:
	$cnv->CanvasBind('<Double-Button-2>' => sub{
				$cnv->viewAll();
				text_size_reset($cnv);
			}
			);
	# zoom window:
	$mw->bind(
		'<z>' => sub {
			$stl->configure(-text=>"Pick window corners");
			windowzoom($cnv, $stl);
			});
	# measure:
	$mw->bind(
		'<m>' => sub {
			$stl->configure(-text=>"Pick ends");
			free_dist($cnv, $stl);
			});


} # end subroutine tkbindings definition
########################################################################

=head2 text_size_reset

  text_size_reset($cnv);

=cut
sub text_size_reset {
	my $cnv = shift;
	my @c = $cnv->getView();
	my $width = $c[2] - $c[0];
	my $disp = $cnv->cget(-width);
	# print "showing $width in $disp\n";
	# print "scale is ", $disp / $width, "\n";
	$textsize = $text_base * $disp / $width;
	# print "textsize is $textsize\n";
	# XXX this is really getting to be a pain (too-large text causes slow-down)
	($textsize > 100) && ($textsize = 100);
	if($textsize >= 2) {
		## print "textsize: $textsize\n";
		$cnv->fontConfigure('cad-drawing-font', -size => $textsize);
	}
	else {
		$cnv->fontConfigure('cad-drawing-font', -size => 2);
	}


} # end subroutine text_size_reset definition
########################################################################

=head2 free_dist

  free_dist();

=cut
sub free_dist {
	my $cnv = shift;
	my $stl = shift;
	# this is crappy
	$cnv->CanvasBind(
		'<ButtonPress-1>' => sub {
			$cnv->rubberBand(0);
		});
	$cnv->CanvasBind(
		'<B1-Motion>' => sub {
			$cnv->rubberBand(1);
		});
	$cnv->CanvasBind(
		'<ButtonRelease-1>' => sub {
			my @box = $cnv->rubberBand(2);
			# print "box is @box\n";
			my $dist = dist2d([@box[0,1]],[@box[2,3]]);
			my $dx = $box[2] - $box[0];
			my $dy = $box[1] - $box[3];
			foreach my $item qw(
							<ButtonPress-1>
							<B1-Motion>
							<ButtonRelease-1>
							) {
				# print "item: $item\n";
				$cnv->CanvasBind($item => "");
			}
			$stl->configure(-text=>"$dist ($dx,$dy)");
			warn("measure: $dist ($dx,$dy)\n");
		});
} # end subroutine free_dist definition
########################################################################

=head2 windowzoom

Creates temporary bindings to drawing a rubber-band box.

  windowzoom($cnv);

=cut
sub windowzoom {
	my $cnv = shift;
	my $stl = shift;
	$cnv->CanvasBind(
		'<ButtonPress-1>' => sub {
			$cnv->rubberBand(0);
		});
	$cnv->CanvasBind(
		'<B1-Motion>' => sub {
			$cnv->rubberBand(1);
		});
	$cnv->CanvasBind(
		'<ButtonRelease-1>' => sub {
			my @box = $cnv->rubberBand(2);
			#print "box is @box\n";
			$cnv->viewArea(@box);
			text_size_reset($cnv);
			foreach my $item qw(
							<ButtonPress-1>
							<B1-Motion>
							<ButtonRelease-1>
							) {
				# print "item: $item\n";
				$cnv->CanvasBind($item => "");
			}
			$stl->configure(-text=>"");
		});
} # end subroutine windowzoom definition
########################################################################


=head2 tksetview

No longer used

  $drw->tksetview($cnv, %options);

=cut
sub tksetview {
	my $self = shift;
	my $cnv = shift;
	my %options = @_;
	my $width = $options{size}[0];
	my $height = $options{size}[1];
	my @ext = $self->OrthExtents($options{items});
	print "got extents: ", 
		join(" by ", map({join(" to ", @$_)} @ext)), "\n";
	my @cent = map({($_->[0] + $_->[1]) / 2} @ext);
	$options{center} && (@cent = @{$options{center}});
	print "center is @cent\n";
	my $scale = $options{scale};
	unless($scale) {
		$scale = $self->scalebox($options{size}, \@ext);
#        print "got scale: $scale\n";
	}
	$cnv->scale('all'=> 0,0 , $scale, $scale);
	my $bbox = $options{bbox};
	$_ *= $scale for @$bbox;
#    print "bbox now: @$bbox\n";
	$cnv->configure(-scrollregion=> $bbox);
#    my $xv = $ext[0][0] * $scale / $bbox->[2];
	my $xv = ($ext[0][0] * $scale - $bbox->[0]) / 
				($bbox->[2] - $bbox->[0]);
##    my $xv = ($width / 2 - $bbox->[0]) /
##                ($bbox->[2] - $bbox->[0]);

	print "xview: $xv\n";
	$cnv->xviewMoveto($xv);
	my (undef(), $yv) = tkpoint([0,$ext[1][0]]); 
	print "ypt: $yv\n";
	print "ext top: $ext[1][1] bottom: $ext[1][0]\n";
	print "bbox (t&b): $bbox->[1] $bbox->[3]\n";
	$yv = (-$ext[1][0] * $scale + $bbox->[3] - $height / 2) / 
				($bbox->[3] - $bbox->[1]);
	print "yview: $yv\n";
	$cnv->yviewMoveto($yv);
} # end subroutine tksetview definition
########################################################################

=head2 scalebox

Returns the scaling required to create a view which most closely
matches @ext to @size of canvas.

  $scale = $drw->scalebox(\@size, \@ext);

=cut
sub scalebox {
	my $self = shift;
	my ($size, $ext) = @_;
	my ($ew, $eh) = map({abs($_->[0] - $_->[1])} @$ext);
	my $dx = $size->[0] / $ew;
	my $dy = $size->[1] / $eh;
#    print "factors: $dx $dy\n";
	my $scale = [$dx => $dy] -> [$dy <= $dx];
	return($scale);
} # end subroutine scalebox definition
########################################################################

=head2 dsp subroutine refs

each of these should do everything necessary to draw the item on the
canvas (but they might like to have a few options available?)  and then
return a list of the Tk id's of the created items.  Caller will then
assign identical tags to each id which is returned by each per-entity
call.

=cut

%dsp = (
	lines => sub {
		my ($self, $cnv, $addr) = @_;
		my $arrow = "none";
		$CAD::Drawing::IO::Tk::arrow && ($arrow = "last");
		my $obj = $self->getobj($addr);
		my $line = $cnv->createLine(
						map({tkpoint($_)} 
							@{$obj->{pts}},
							),
						# '-dash' => "",
						# '-activedash' => ",",
						# '-activefill' => "#ff0000",
						'-fill'=> $aci2hex[$obj->{color}],
						'-arrow' => $arrow,
						);
#        print "line item: $line (ref: ", ref($line), ")\n";
		# my @list = $cnv->itemconfigure($line);
		# foreach my $deal (@list) {
		#	print "got deal: @$deal\n";
		#}
		return($line);
	}, # end sub $dsp{lines}
	plines => sub {
		my ($self, $cnv, $addr) = @_;
		my $arrow = "none";
		$CAD::Drawing::IO::Tk::arrow && ($arrow = "last");
		my $obj = $self->getobj($addr);
		my $st = $obj->{closed} ? -1 : 0;
		my @ids;
		for(my $i = $st; $i < scalar(@{$obj->{pts}}) -1; $i++) {
			my @pts = map({tkpoint($_)}
						$obj->{pts}[$i], $obj->{pts}[$i+1],
						);
			# print "adding @pts ($i -> ", $i+1, ")\n";
			my $pline = $cnv->createLine(
						@pts,
						'-fill' => $aci2hex[$obj->{color}],
						'-arrow' => $arrow,
						);
#            print "pline item: $pline\n";
			push(@ids, $pline);
		}
		return(@ids);
	}, # end sub $dsp{plines}
	arcs => sub {
		my ($self, $cnv, $addr) = @_;
		my $obj = $self->getobj($addr);
#        print "keys: ", join(" ", keys(%$obj)), "\n";
		my $rad = $obj->{rad};
		my @pt = tkpoint($obj->{pt});
		# stupid graphics packages:
		my @rec = (
			map({$_ - $rad} @pt),
			map({$_ + $rad} @pt),
			);
		my @angs = @{$obj->{angs}};
		# stupid graphics packages:
		@angs = map({$_ * 180 / $pi} @angs);
		$angs[1] = $angs[1] - $angs[0];
		$angs[1] += 360;
		while($angs[1] > 360) {
			$angs[1] -= 360;
		}
		my $arc =  $cnv->createArc(
					@rec,
					'-start'  => $angs[0],
					'-extent' => $angs[1],
					'-outline' => $aci2hex[$obj->{color}],
					'-style' => "arc",
					);
		return($arc);
	}, # end sub $dsp{arcs}
	circles => sub {
		my ($self, $cnv, $addr) = @_;
		my $obj = $self->getobj($addr);
		my $rad = $obj->{rad};
		my @pt = tkpoint($obj->{pt});
		# stupid graphics packages:
		my @rec = (
			map({$_ - $rad} @pt),
			map({$_ + $rad} @pt),
			);
		my $circ = $cnv->createOval(
					@rec,
					'-outline' => $aci2hex[$obj->{color}],
					);
		return($circ);
	}, # end sub $dsp{circles}
	texts => sub {
		my ($self, $cnv, $addr) = @_;
		my $obj = $self->getobj($addr);
		my @pt = tkpoint($obj->{pt});
		my $height = $obj->{height};
		my $string = $obj->{string};
		my @text;
		# FIXME: if tk doesn't get its act together, this becomes kludge:
		if($obj->{render}) {
			die "this is broken";
		}
		else {
			@text = $cnv->createText(
						@pt,
						-font => "cad-drawing-font", #
						-anchor => "sw",
						-text => $string,
						-fill => $aci2hex[$obj->{color}],
						);
		}
		return(@text);
	}, # end sub $dsp{texts}
		
); # end %dsp coderef hash
########################################################################

=head2 tkpoint

Returns only the first and second element of an array reference as a
list.

  @xy_point = tkpoint(\@pt);

=cut
sub tkpoint {
	return($_[0]->[0], $_[0]->[1]);
} # end subroutine tkpoint definition
########################################################################

=head2 addr_to_tktag

Returns a stringified tag of form:  <layer>###<type>###<id>

  my $tag = $drw->addr_to_tktag($addr);

=cut
sub addr_to_tktag {
	my $self = shift;
	my $addr = shift;
	return(join("###", $addr->{layer}, $addr->{type}, $addr->{id}));
} # end subroutine addr_to_tktag definition
########################################################################

=head2 tktag_to_addr

Returns an anonymous hash reference which should serve as an address,
provided that $tag is a valid <layer>###<type>###<id> tag (and that the
entity exists in the $drw object (check this yourself.)

  my $addr = $drw->tktag_to_addr($tag);

=cut
sub tktag_to_addr {
	my $self = shift;
	my $tag = shift;
	my @these = split(/###/, $tag);
	(@these == 3) or croak("parsing tag failed! ($tag)\n");
	my @order = qw(layer type id);
	return({map({$order[$_] => $these[$_]} 0..2)});
} # end subroutine tktag_to_addr definition
########################################################################

1;
