package CAD::Drawing::IO::Image;
our $VERSION = '0.02';

use CAD::Drawing;
use CAD::Drawing::Defined;

use warnings;
use strict;

use Carp;
use UNIVERSAL qw(isa);

use Image::Magick;

########################################################################
=pod

=head1 NAME

CAD::Drawing::IO::Image - Output methods for images

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

  CAD::Drawing
  Image::Magick

=cut

########################################################################

=head1 Requisite Plug-in Functions

See CAD::Drawing::IO for a description of the plug-in architecture.

=cut
########################################################################
# the following are required to be a disc I/O plugin:
our $can_save_type = "img";

=head2 check_type

Returns true if $type is "img" or $filename matches one of the
ImageMagick type extensions.

  $fact = check_type($filename, $type);

=cut
sub check_type {
	my ($filename, $type) = @_;
	if(defined($type)) {
		# FIXME: need a better method for spec'ing arbitrary type
		($type eq "img") and return("img");
		return();
	}
	elsif($filename =~ m/.*\.(\w+)$/) {
		my $ext = $1;
		($ext =~ m/tif|gif|jpg|png|bmp|fax|fig|pict|psd|xcf/) &&
			return("img");
	}
	return();
} # end subroutine check_type definition
########################################################################

=head1 Methods

=cut
########################################################################

=head2 load

Requires vectorization...

  load();

=cut
sub load {
	croak("load image not written");
} # end subroutine load definition
########################################################################

=head2 save

  save();

=cut
sub save {
	my $self = shift;
	my ($filename, $opt) = @_;
	our %img_out_functions;
	my %opts;
	my $accuracy = 1; # digits of accuracy with which to bother
	if(isa($opt, 'HASH')) {
		%opts = %$opt;
	}
	else {
		$opt and croak("not a hash");
	}
	my $imwidth = $opts{width};
	my $imheight = $opts{height};
	(defined($imwidth) and defined($imheight)) or
		carp("can't save image without width and height\n");
	my $outobj = Image::Magick->new(size=>"${imwidth}x${imheight}");
	my $bgcolor = "white";
	my $defaultcolor = "black";
	if($opts{defaultcolor}) {
		$defaultcolor = $opts{defaultcolor};
	}
	# $CAD::Drawing::default_color{$self} = $defaultcolor; # XXX ?
	if($opts{bgcolor}) {
		$bgcolor = $opts{bgcolor};
	}
	$outobj->ReadImage("xc:$bgcolor");
	if($opts{transparent}) {
		$outobj->Transparent(color=>"$bgcolor");
	}
	unless($opts{prescaled}) {
		carp("must prescale drawing object for now\n");
		# FIXME:  this should now go into the fit-to-bound deal
	}
# 	$outobj->Set(antialias=>"False");
	my $matte = "white";
	$outobj->Set(mattecolor=>$matte);
	$opts{imtype} and $outobj->Set(type => $opts{imtype});
	$opts{imcomp} and $outobj->Set(compression => $opts{imcomp});
	my %img_data = (
		imobj => $outobj,
		height => $imheight,
		width => $imwidth,
		accuracy => $accuracy,
		bgcolor => $bgcolor,
		defcolor => $defaultcolor,
		# FIXME:  need some way to make this selective?
		filled => $opts{'filled'} || 'none',
		lw     => defined($opts{'linewidth'}) ? $opts{'linewidth'} : 3.0,
		font => $opts{font} ? $opts{font} : 'arial',
		);
	my $count = $self->outloop(\%img_out_functions, \%img_data);
	my $err = $outobj->Write($filename);
	$err and die;
	return($count);
} # end subroutine save definition
########################################################################

our %img_out_functions = (
lines => sub {
	my ($obj, $data) = @_;
	my $img = $data->{imobj};
	my $acc = $data->{accuracy};
	my @pts = map({
		[map({sprintf("%0.${acc}f", $_)} (@$_)[0,1])]
		} @{$obj->{pts}});
	## warn "points: @{$pts[0]}  and @{$pts[1]}\n";
	# XXX is this needed?
	if(($pts[0][0] == $pts[1][0]) and ($pts[0][1] == $pts[1][1])) {
		## warn "bad line\n";
		return();
	}
	$pts[$_][1] = $data->{height} - $pts[$_][1] for 0..1;
	my $pt_string = join(" ", map({join(",", @$_)} @pts));
	my $color = image_color($obj->{color}, $data);
	$img->Draw(
		primitive => 'line',
		strokewidth => $obj->{lw} || $data->{lw},
		stroke => $color,
		fill => $data->{filled},
		points => $pt_string,
		);
},
plines => sub {
	my ($obj, $data) = @_;
	my $img = $data->{imobj};
	my $acc = $data->{accuracy};
	my @pts = map({
		[map({sprintf("%0.${acc}f", $_)} (@$_)[0,1])]
		} @{$obj->{pts}});
	$pts[$_][1] = $data->{height} - $pts[$_][1] for 0..$#pts;
	my $pt_string = join(" ", map({join(",", @$_)} @pts));
	my $color = image_color($obj->{color}, $data);
	$img->Draw(
		primitive => $obj->{closed} ? 'polygon' : 'polyline',
		strokewidth => $obj->{lw} || $data->{lw},
		stroke => $color,
		fill => $data->{filled},
		points => $pt_string,
		);
},
circles => sub {
	my ($obj, $data) = @_;
	my $img = $data->{imobj};
	my $acc = $data->{accuracy};
	my @pt = (@{$obj->{pt}})[0,1];
	$pt[1] = $data->{height} - $pt[1];
	my $r = $obj->{rad};
	my @rec = ( # some consistency would be nice!
		#[map({sprintf("%0.${acc}f", $_ - $r)} @pt)],
		[map({sprintf("%0.${acc}f", $_)} @pt)],
		[map({sprintf("%0.${acc}f", $_)} $pt[0] - $r, $pt[1])],
		);
	my $pt_string = join(" ", map({join(",", @$_)} @rec));
	my $color = image_color($obj->{color}, $data);
	$img->Draw(
		primitive => 'circle',
		strokewidth => $data->{lw},
		stroke => $color,
		fill => $data->{filled},
		antialias => 'true',
		points => $pt_string,
		);

},
texts => sub {
	my ($obj, $data) = @_;
	my $img = $data->{imobj};
	my $acc = $data->{accuracy};
	my @pt = map({sprintf("%0.${acc}f", $_)} (@{$obj->{pt}})[0,1]);
	$pt[1] = $data->{height} - $pt[1];
	my $height = sprintf("%0.0f", $obj->{height});
	## warn "handling text : $obj->{string} (h=$height)\n";
	## warn "point:  $pt[0], $pt[1]\n";
	my $color = image_color($obj->{color}, $data);
	my $res = $img->Annotate(
		x => $pt[0],
		y => $pt[1],
		text => $obj->{string},
		font => $data->{font},
		stroke => $color,
		fill => $color,
		antialias => 'true',
		pointsize => $height,
		rotate => $obj->{angle} ? (-$obj->{angle} * 180 / $pi) : 0,
		);
	warn $res if $res;
},
arcs => sub {
	my ($obj, $data) = @_;
	my $img = $data->{imobj};
	my $acc = $data->{accuracy};
	my @pt = @{$obj->{pt}}[0,1];
	$pt[1] = $data->{height} - $pt[1];
	my $r = $obj->{rad};
	my @rec = (
		[map({sprintf("%0.${acc}f", $_ - $r)} @pt)],
		[map({sprintf("%0.${acc}f", $_ + $r)} @pt)],
		);
	my @angs = reverse(map({-$_ * 180/$pi} @{$obj->{angs}})); # whee!
	my $pt_string = join(" ", map({join(",", @$_)} @rec, \@angs));
	## warn "pts:  $pt_string\n";
	my $color = image_color($obj->{color}, $data);
	## warn "color: $color";
	$img->Draw(
		primitive => 'arc',
		strokewidth => $data->{lw},
		stroke => $color,
		fill => $data->{filled},
		antialias => 'true',
		# XXX super-unstable interface completely broken in 5.5.7.9-1.1?
		points => $pt_string,
		# points => '40,40 80,80 0,90',
		);

},
); # end img_out_functions
$img_out_functions{points} = 0 ? 
sub {
	my ($obj, $data) = @_;
	my $img = $data->{imobj};
	my $acc = $data->{accuracy};
	my @pt = map({sprintf("%0.${acc}f", $_)} (@{$obj->{pt}})[0,1]);
	$pt[1] = $data->{height} - $pt[1];
	my $pt_string = join(",", @pt);
	my $color = image_color($obj->{color}, $data);
	$img->Draw(
		primitive => 'point',
		stroke => $color,
		points => $pt_string,
		);
}
:
sub {
 	my ($obj, $data) = @_;
 	$img_out_functions{circles}->(
		{%$obj, rad => 0.1},
		{%$data, lw => 1, filled => 1}
		);
};

=head2 image_color

  image_color($color, $data);

=cut
sub image_color {
	my ($color, $data) = @_;
	# XXX fixme: %no should be based on defcolor
	my %no = map( { $_ => 1} 0, 7, 256);
	$no{$color} && return($data->{defcolor});
	return($aci2hex[$color]);
} # end subroutine image_color definition
########################################################################
1;
