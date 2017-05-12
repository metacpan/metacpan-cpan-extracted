package Apache::Wyrd::Site::GDButton;
use strict;
our $VERSION = '0.98';
use base qw(Apache::Wyrd::Interfaces::Setter Apache::Wyrd::Site::Widget Apache::Wyrd);
use Apache::Wyrd::Services::SAK qw(:file token_parse);
use Apache::Util;
use Digest::SHA qw(sha1_hex);
use GD;

=pod

=head1 Apache::Wyrd::Site::GDButton - Auto-generated buttons/text graphics

A wyrd to generate rectangular buttons using the GD library.

=head1 SYNOPSIS

	<BASENAME::GDButton name="pushme" src="/img/pushbutton.gif" />

=head1 DESCRIPTION

GDButton produces a rectangular button with given text using the GD library.
 It can produce either image input or img tags, as requested.

GDButton uses it's membership in the Apache::Wyrd::Site::Widget class to
track changes and decide when the output file should be regenerated.  Note:
GDButton internally draws itself at 5x the regular size and scales down in
order to make a more aesthetically pleasing final result.

=head2 HTML ATTRIBUTES

=over

=item src

File attribute.  Must be absolute, relative, or root-dir-relative.  Will
seek through those options to find a writeable location and set the HTML
attribute of the same to reflect the location of the output file.  This file
must end in either .png or .gif.  The format of the output file will be
determined by this file extension.

=item template

What file to use as a base image for this button.  It is located in the same way
the src file is.  The file can be a GIF or PNG file (it will need to have the
right file extension of .gif or .png, case insensitive).  The template file is
copied to memory and then written to the file area indicated by the src
attribute.

=item width, height

(required w/o template) in pixels.

=item bgcolor, color

(required w/o template) background and foreground color, in six-digit hex form
(#RRGGBB).

=item size

Font size, in pixels.

=item font

Path to the font file.  Either absolute, relative, or root-dir-relative.  It
must be a TrueType font file, and your version of GD must support TrueType
fonts.

=item margin, tmargin, rmargin, bmargin, lmargin

Margin between text and edge of button, in pixels.  Margin represents an
overall number, and is the default for the others.  Specific top, right,
bottom, and left margins can be defined separately, falling back to the
margin value.

=item name id action method alt align onmouseover onmouseout onclick border ismap longdesc usemap

Regular image attributes.  Passed to the HTML untouched.

=back

=head2 FLAGS

=over

=item noantialias

Turn off antialiasing for the button.

=back

=head1 BUGS/CAVEATS

Reserves the _format_output and _generate_output methods.

=cut

sub _format_output {
	my ($self) = @_;
	my @required_attributes = qw(src name outfile bgcolor color size font);
	unless ($self->{'template'}) {
		push @required_attributes, qw(width height);
	}
	my @optional_attributes = qw(margin lmargin rmargin bmargin tmargin halign valign);
	my $defaults = $self->_defaults;
	$defaults = {} unless (ref($defaults) eq 'HASH');
	map {$self->{$_} ||= ($defaults->{$_})} @required_attributes, @optional_attributes;
	$self->{'outfile'} = $self->file_attribute('src', 'rw') if ($self->{'src'});
	$self->{'template'} = $self->file_attribute('template', 'rf') if ($self->{'template'});
	$self->{'font'} = $self->file_attribute('font', 'rf') if ($self->{'font'});
	#When these are inputs, the name is more important than the text.
	$self->{'text'} ||= ($self->_data || ucfirst($self->{'name'}) || 'Click Me');
	#When these are images, the name is less important than the SRC attribute
	$self->{'name'} ||= ($self->{'src'});
	$self->{'halign'} ||= ('center');
	$self->{'valign'} ||= ('middle');
	$self->{'type'} ||= ('input');
	my @missing = grep {not($self->{$_})} @required_attributes;
	@missing = grep {$_ ne 'name'} @missing if ($self->{'type'} ne 'input');#inputs must have names, but others don't have to.
	$self->_raise_exception("Missing attributes: " . join ", ", @missing) if (@missing);
	$self->{_fingerprint} = join(':', (map {$self->{$_}} @required_attributes, @optional_attributes));
}

sub _generate_output {
	my ($self) = @_;
	#trueColor is necessary in order to avoid crappy text rendering
	GD::Image->trueColor(1);
	my $changed = ($self->widgetindex->update_entry($self) or not(-f $self->{'outfile'}));
	if ($changed) {
		my $antialias = 1;
		$antialias = -1 if ($self->_flags->noantialias);

		#prep the background and allocate the foreground
		my ($image, $base_image) = ();
		my $template = $self->{'template'};
		if ($template) {
			my $type = $self->{'template'} =~ /\.(png|gif)/i;
			unless ($type) {
				$self->_raise_exception('template base image must be PNG or GIF.');
			}
			if (lc($type) eq 'gif') {
				$base_image = GD::Image->newFromGif($template);
			} else {
				$base_image = GD::Image->newFromPng($template);
			}
			my $width = $self->{'width'} = $base_image->width;
			my $width = $self->{'height'} = $base_image->height;
			$image = GD::Image->new($self->{'width'} * 5, $self->{'height'} * 5);
			$image->copyResampled($base_image, 0, 0, 0, 0, $self->{'width'} * 5, $self->{'height'} * 5, $self->{'width'}, $self->{'height'});
		} else {
			#Draw everything at 5 times the given size, since font shape and spacing issues are less prominent
			$image= GD::Image->new($self->{'width'} * 5, $self->{'height'} * 5);
			my $bg = $image->colorAllocate($self->_get_color($self->{'bgcolor'}));
			$image->filledRectangle(0, 0, $self->{'width'} * 5, $self->{'height'} * 5, $bg);
		}
		my $fg = $image->colorAllocate($self->_get_color($self->{'color'}));

		#First get the size of the text image.  Since font shapes falling below
		#the drawing line will throw off the placment, this value will be taken
		#into account by _get_startpoint, which attempts to place the text at a
		#more "natural" location. This setting is overridden with the "absolute"
		#flag.
		my @abstract = GD::Image->stringFT($antialias * $fg, $self->{'font'}, $self->{'size'} * 5, 0, 0, 0, $self->{'text'});
		my ($x, $y) = $self->_get_startpoint(@abstract);

		#Then render the actual text using the calculated start point.
		my @bounds = $image->stringFT($antialias * $fg, $self->{'font'}, $self->{'size'} * 5, 0, $x, $y, $self->{'text'}, {resolution => "72,72", kerning => 1});

		#Shrink it down to 1/5 the rendered size.
		my $final = GD::Image->new($self->{'width'}, $self->{'height'});
		$final->copyResampled($image, 0, 0, 0, 0, $self->{'width'}, $self->{'height'}, $self->{'width'} * 5, $self->{'height'} * 5);
		
		open FILE, "> " . $self->{'outfile'};
		binmode FILE;
		print FILE ($self->{'outfile'}=~/gif$/) ? $final->gif : $final->png;
		close FILE;
	}

	#attempt to preserve any normal IMG or INPUT attributes
	my @attrs =  qw(name id action method alt src align onmouseover onmouseout onclick border height width ismap longdesc usemap class style);
	my %attrs =  map {$_ => $self->{$_}} @attrs;
	$attrs{'src'} = Apache::Util::escape_uri($attrs{'src'});
	if ($self->{'type'} eq 'input') {
		$self->_data(q(<input type="image") . $self->_attribute_template(@attrs) . q(>));
	} else {#consider anything else as an image tag.
		$self->_data(q(<img) . $self->_attribute_template(@attrs) . q(>));
	}
	return $self->_set(\%attrs);
}

=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

sub _get_color {
	my ($self, $color) = @_;
	my ($r, $g, $b) = ();
	if (ref($color) ne 'ARRAY') {
		return (hex($1), hex($2), hex($3)) if ($color =~ /^#([0-9a-fA-F][0-9a-fA-F])([0-9a-fA-F][0-9a-fA-F])([0-9a-fA-F][0-9a-fA-F])$/);
		return ($1, $2, $3) if ($color =~ /^\s*(\d+)[\s,]+(\d+)[\s,]+(\d+)\s*/);
		$self->_raise_exception("Illegal color value '$color'");
	}
	return $color if (scalar(@$color) == 3);
	$self->_raise_exception("Illegal color value: " . join ', ', @$color);
}

sub index_digest {
	my ($self) = @_;
	return sha1_hex($self->{'_fingerprint'});
}

sub _get_startpoint {
	my ($self, $lbx, $lby, $rbx, $rby, $rtx, $rty, $ltx, $lty) = @_;
	my $w = $self->{'width'} * 5;
	my $h = $self->{'height'} * 5;
	my $maxrx = ($rtx > $rbx ? $rtx : $rbx);
	my $maxlx = ($ltx < $lbx ? $ltx : $lbx);
	my $dx = $maxrx - $maxlx;
	my $maxty = ($rty < $lty ? $rty : $lty);
	my $maxby = ($lby > $rby ? $lby : $rby);
	my $dy = $maxby - $maxty;
	#internal offsets are the amount to subtract from x or y to reach the starting point
	#warn ("w: $w, h: $h");
	#warn ("iox: $iox, maxby: $maxby");
	#warn ("maxrx: $maxrx, maxlx: $maxlx");
	#warn ("maxty: $maxty, maxby: $maxby");
	#warn ("deltax: $dx, deltay: $dy");
	my $lm = ($self->{'lmargin'} || $self->{'margin'} || 0);
	my $tm = ($self->{'tmargin'} || $self->{'margin'} || 0);
	my $bm = ($self->{'bmargin'} || $self->{'margin'} || 0);
	my $rm = ($self->{'rmargin'} || $self->{'margin'} || 0);
	my ($x, $y) = (0, 0);
	my $shift = 1;
	$shift = 0 if ($self->_flags->absolute);
	if ($self->{'halign'} eq 'right') {
		$x = $w - $dx - $rm - $maxlx;
	} elsif ($self->{'halign'} eq 'left') {
		$x = 0 + $lm - $maxlx;
	} else {
		$x = $lm + (($w - $lm - $rm)/2) - $dx/2 - ($maxlx * $shift);
	}
	if ($self->{'valign'} eq 'top') {
		$y = $dy  + $tm + $maxby;
	} elsif ($self->{'valign'} eq 'bottom') {
		$y = $h - $bm - $maxby;
	} else {
		$y = (($h - $tm - $bm)/2) + $tm + $dy/2 - ($maxby * $shift);
	}
	#warn ("lm: $lm, rm: $rm, tm: $tm, bm: $bm");
	#warn ("dy: $dy");
	#warn ("x: $x, y: $y");
	return ($x, $y);
}

1;
