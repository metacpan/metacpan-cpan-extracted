package App::Codit::Plugins::Exporter;

=head1 NAME

App::Codit::Plugins::Exporter - plugin for App::Codit

=cut

use strict;
use warnings;
use Carp;
use vars qw( $VERSION );
$VERSION = 0.14;

require Syntax::Kamelon;
require Tk::CodeText::Theme;
use Imager;
use Imager::Color;
use Imager::Font;
use Imager::Fill;

use base qw( Tk::AppWindow::BaseClasses::Plugin );

=head1 DESCRIPTION

Export your document to HTML or PNG.

=head1 DETAILS

Plugin Exporter allows you to export the current selected document
to HTML or PNG. You will find two entries for this in the File menu:

=over 4

=item B<Export to HTML>

Exporting to html is done using the standard facilities available in
<LSyntax::Kamelon>. We are looking to extend that in future versions.

A form will pop up where you can set:

=over 4

=item B<Output file>

A default file is suggested. Change it if you like.

=item B<Theme>

Pick one of the available themes.

=item B<Line numbers>

Tick this if you want line numbers displayed in the left column.

=item B<Fold markers>

Tick this if you want fold markers displayed in the left column.

=item B<Scrolled pane>

Tick this if you want the content to appear in a scrollable pane.

=back

=item B<Export to PNG>

A form will pop up. All your changes except
for Output file are saved. You can set:

=over 4

=item B<Output file>

A default file is suggested. Change it if you like.

=item B<Background>

Background color of your image. By default the background
color of the Tk::CodeText widget is set.

=item B<Foreground>

Default color of the text in your image. By default the foreground
color of the Tk::CodeText widget is set.

=item B<Theme file>

Select the Tk::CodeText theme file (extension '.ctt') to use for syntax highlighting.
By default the theme file used in the Tk::CodeText widget is set. You can create your
custom theme file through Menu->Codit->Settings and select the highlighting panel.

=item B<Font>

Set the font used to draw text in your image. By default the font
of the Tk::CodeText widget is set.

=item B<Line numbers>

Tick this if you want line numbers displayed in the left column.

=item B<Tab size>

Set the size of tabs in characters.

=item B<Max width>

If set to 0 the image will grow in width whenever needed.
Otherwise it will wrap text when the max width (in pixels) has been reached.

=item B<Margins>

Set the top, left, bottom and right margins around your image.

=back

Beware! Exporting to PNG is painstakingly slow.

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	return undef unless defined $self;
	
	$self->{BACKGROUND} = undef;
	$self->{IMAGE} = undef;
	$self->{IHEIGHT} = 0;
	$self->{IWIDTH} = 0;
	$self->{MAXWIDTH} = 0;
	$self->{XPOS} = 0;
	$self->{TABSTRING} = '';
	$self->{YPOS} = 0;
	$self->cmdConfig(
		'export_html' => ['export2html', $self],
		'export_png' => ['export2png', $self],
	);
	return $self;
}

sub background {
	my $self = shift;
	$self->{BACKGROUND} = shift if @_;
	return $self->{BACKGROUND}
}

sub export2html {
	my $self = shift;
	my $mdi = $self->mdi;

	#setting initial values
	my %iv = ();
	my $name = $mdi->docSelected;
	return unless defined $name;
	$iv{'outfile'} = "$name.html";
	$iv{'theme'} = 'White';
	$iv{'scrolled'} = '';
	$iv{'lineoffset'} = 1;
	$iv{'foldmarkers'} = '';

	#popping the form
	my %options = $self->popForm(
		-acceptempty => 1,
		-initialvalues => \%iv,
		-oktext => 'Export',
		-structure => [
			'*section' => 'Output',
			outfile => ['file', 'File'],
			'*end',
			'*section' => 'Theme',
			theme => ['radio', 'Color', -values => [qw/White LightGray Gray DarkGray Black/]],
			'*end',
			'*section' => 'Features',
			scrolled => ['boolean', 'Scrolled'],
			foldmarkers => ['boolean', 'Fold markers'],
			'*column',
			lineoffset => ['boolean', 'Line numbers'],
			'*end',
		],
		-title => 'Export to HTML',
	);
	return unless %options;
	
	#checking data
	my $file = delete $options{'outfile'};
	croak "Outfile not specified" if $file eq '';
	my %params = ();
	for (sort keys %options) {
		my $val = $options{$_};
		$params{$_} = $val if $val;
	}
	
	#exporting
	my $widg = $mdi->docWidget;
	my $hl = Syntax::Kamelon->new(
		syntax => $widg->cget('-syntax'),
		formatter => ['HTML4', %params],
	);
	$hl->Reset;
	my $text = $widg->get('1.0', 'end - 1c');
	$hl->Parse($text);
	if (open my $fh, '>', $file) {
		print $fh $hl->Format;
		close $fh
	} else {
		$self->logWarning("Can not open '$file'");
	}
}

sub export2png {
	my $self = shift;
	my $mdi = $self->mdi;

	#setting initial values
	my %iv = ();
	my $name = $mdi->docSelected;
	return unless defined $name;
	my $widg = $mdi->docWidget;

	my $folder = $self->configGet('-configfolder');
	if (-e "$folder/export2pngrc") {
		my $cff = $self->extGet('ConfigFolder');
		%iv = $cff->loadHash('export2pngrc', 'exporterpng');
	} else {
		$iv{'background'} = $widg->Subwidget('XText')->cget('-background');
		$iv{'foreground'} = $widg->Subwidget('XText')->cget('-foreground');
		$iv{'themefile'} = $self->extGet('ConfigFolder')->ConfigFolder . '/highlight_theme.ctt';
		$iv{'font'} = $self->configGet('-contentfont');
		$iv{'linenumbers'} = 1;
		$iv{'margins'} = 10;
		$iv{'maxwidth'} = 0;
		$iv{'tabsize'} = 3;
	}
	$iv{'outfile'} = "$name.png";

	#popping the form
	my %options = $self->popForm(
#		-acceptempty => 1,
		-initialvalues => \%iv,
		-oktext => 'Export',
		-structure => [
			'*section' => 'Output',
			outfile => ['file', 'File', -width => 50],
			'*end',
			'*section' => 'Theme',
			'*frame',
			background => ['color', 'Background', -width => 8],
			'*column',
			foreground => ['color', 'Foreground', -width => 8],
			'*end',
			themefile => ['file', 'Theme file'],
			font => ['font', 'Font'],
			'*end',
			'*section' => 'Features',
			linenumbers => ['boolean', 'Line numbers'],
			tabsize => ['spin', 'Tab size', -width => 6],
			'*column',
			maxwidth => ['spin', 'Max width', -width => 6],
			margins => ['spin', 'Margins', -width => 6],
			'*end',
		],
		-title => 'Export to PNG',
	);
	return unless %options;

	#saving options
	my $cff = $self->extGet('ConfigFolder');
	$cff->saveHash('export2pngrc', 'exporterpng', %options);

	#checking data
	my $file = delete $options{'outfile'};
	croak "Outfile not specified" if $file eq '';
	my $tabstr = '';
	for (1 .. $options{'tabsize'}) { $tabstr = "$tabstr " }
	$self->background(Imager::Color->new($options{'background'}));
	$self->imargin($options{'margins'});
	$self->linenumbers($options{'linenumbers'});
	$self->linecolumn(length($widg->linenumber('end - 1c')));
	$self->maxwidth($options{'maxwidth'});
	$self->tabstring($tabstr);

	#converting data
	my $art = $self->extGet('Art');
	my $l = $self->Label(-font => $options{'font'});
	my $f = $l->cget('-font');
	my $fntnorm = $widg->fontCompose($f, -slant => 'roman', -weight => 'normal');
	my $fntbold = $widg->fontCompose($f, -slant => 'roman', -weight => 'bold');
	my $fntbolditalic = $widg->fontCompose($f, -slant => 'italic', -weight => 'bold');
	my $fntitalic = $widg->fontCompose($f, -slant => 'italic', -weight => 'normal');

	my $linespace = $self->fontMetrics($f, '-linespace');
	my $desc = $self->fontMetrics($f, '-descent');

	$l->destroy;

	my $foreground =  Imager::Color->new($options{'foreground'});

	$self->xpos($self->imargin);
	$self->ypos($self->imargin + $linespace - $desc);
	$self->iwidth($self->imargin * 2);
	$self->iheight(($self->imargin * 2) + $linespace);

	$self->image($self->inew($self->iwidth, $self->iheight));

	#setting up tags
	my $thmfl = $options{'themefile'};
	my $theme = Tk::CodeText::Theme->new;
	unless (-e $thmfl) {
		$self->logError("Theme file '$thmfl' does not exist");
		return
	}
	$theme->load($thmfl);
	my %tags = ();
	for ($theme->tagList) {
		my $tag = $_;
#		print "tag: $tag\n";
		my %options = ();
		my $bold = $theme->getItem($tag, '-weight');
		$bold = 0 unless defined $bold;
		my $slant = $theme->getItem($tag, '-slant');
		$slant = 0 unless defined $slant;
		if ($bold and $slant) {
#			print "  setting font bold/italic\n";
			$options{'-font'} = $fntbolditalic
		} elsif ($bold) {
#			print "  setting font bold\n";
			$options{'-font'} = $fntbold
		} elsif ($slant) {
#			print "  setting font italic\n";
			$options{'-font'} = $fntitalic
		} else {
#			print "  normal font remains\n";
			$options{'-font'} = $fntnorm
		}
		my $fg = $theme->getItem($tag, '-foreground');
		if ($fg ne '') {
#			print "  setting foreground $fg\n";
			$options{'-foreground'} = Imager::Color->new($fg);
		} else {
#			print "  default foreground remains\n";
			$options{'-foreground'} = $foreground;
		}
		my $bg = $theme->getItem($tag, '-background');
		if ($bg ne '') {
#			print "  default background $bg\n";
			$options{'-background'} = Imager::Color->new($bg);
		} else {
#			print "  default background remains\n";
#			$options{'-background'} = $self->background;
		}
		$tags{$tag} = \%options;
	}

	#setting up highlighter
	my $syntax = $widg->cget('-syntax');
	my $hl;
	if ($syntax ne 'None') {
		$hl = Syntax::Kamelon->new(
			syntax => $syntax,
			formatter => ['Base',
#				foldingdepth => 'all',
			],
		);
		$hl->Reset;
	}

	#exporting
	my $last = $widg->linenumber('end - 1c');
	my $end = $widg->index('end - 1c');
	my $count = 0;
	$self->mdi->progressAdd('exporter', 'Exporting', $last, \$count);
	for (1 .. $last) {
		my $linenum = $_;
		my $linestart = "$linenum.0";

		my $lineend = $widg->index("$linestart lineend + 1c");
		$lineend = $end if $widg->compare($end,'<',$lineend);

		$self->iprintln($linenum, $fntnorm, $foreground) if $self->linenumbers;

		my $line = $widg->get($linestart, $lineend);
		if ($syntax eq 'None') {
			$self->iprint($line, $fntnorm, $foreground);
		} else {
			my @h = $hl->ParseRaw($line);
			while (@h) {
				my $string = shift @h;
				my $tag = shift @h;
				my $t = $tags{$tag};
				$self->iprint($string, $t->{'-font'}, $t->{'-foreground'}, $t->{'-background'});
			};
			$self->iprint("\n", $fntnorm, $foreground) if $line =~ /\n$/;
		}
		$count++;
		$self->update;
	}
	$self->mdi->progressRemove('exporter');
	
	my $out = $self->inew($self->iwidth, $self->iheight);
	$out->paste(src => $self->image);
	$out->write(file => $file, type => 'png');

}

sub iheight {
	my $self = shift;
	$self->{IHEIGHT} = shift if @_;
	return $self->{IHEIGHT}
}

sub image {
	my $self = shift;
	$self->{IMAGE} = shift if @_;
	return $self->{IMAGE}
}

sub imargin {
	my $self = shift;
	$self->{IMARGIN} = shift if @_;
	return $self->{IMARGIN}
}


sub inew {
	my ($self, $width, $height) = @_;
	my $new = Imager->new(xsize => $width, ysize => $height, channels => 4);
	$new->flood_fill(x => 0, y => 0, color => $self->background);
	return $new
}

sub inewline {
	my ($self, $font) = @_;
	my $linespace = $self->fontMetrics($font, '-linespace');
	my $height = $self->iheight + $linespace;
	my $new = $self->inew($self->iwidth, $height);
	$new->paste(src => $self->image);
	$self->image($new);
	$self->ypos($self->ypos + $linespace);
	$self->xpos($self->imargin);
	$self->iheight($height);
}

sub iprint {
	my ($self, $string, $font, $fg, $bg) = @_;
	my $cur = $self->image;
	my $ifont = $self->extGet('Art')->imagerFont($font);
	my $newline = 0;
	my $part = '';
	while ($string ne '') {
		if ($string =~ s/^([^\n]*)\n//) {
			$newline = 1;
			$part = $1;
		} else {
			$part = $string;
			$string = '';
		}

		#replace tabs
		my $tab = $self->tabstring;
		$part =~ s/\t/$tab/g;

		#wrap if bigger than maxwidth
		my $partsize = $self->fontMeasure($font, $part);
		my $linesize = $self->xpos + $partsize + $self->imargin;
		my $mw = $self->maxwidth;
		if (($mw > 0) and ($mw < $linesize)) { #bigger than maxwidth
			while ($mw < $linesize) {
				my $section = '';
				while (($self->xpos + $self->fontMeasure($font, $section) + $self->imargin) < $mw) {
					$section = $section . substr($part, 0, 1);
					$part = substr($part, 1);
				}
				$self->iprints($section, $font, $fg, $bg);
				$self->inewline($font);
				$self->iprintln(' ', $font, $fg) if $self->linenumbers;
				$partsize = $self->fontMeasure($font, $part);
				$linesize = $self->xpos + $partsize + $self->imargin;
			}
		}


		#output part
		$self->iprints($part, $font, $fg, $bg);

		#output newline
		$self->inewline($font) if ($newline);

		$part = '';
		$newline = 0;
	}
}

sub iprintln {
	my ($self, $line, $font, $foreground) = @_;
	my $lc = $self->linecolumn;
	while (length($line) < $lc) { $line = " $line" };
	$self->iprint("$line ", $font, $foreground);
}

sub iprints {
	my ($self, $string, $font, $fg, $bg) = @_;
	my $ifont = $self->extGet('Art')->imagerFont($font);
	my $partsize = $self->fontMeasure($font, $string);
	my $linesize = $self->xpos + $partsize + $self->imargin;
	if ($linesize > $self->iwidth) { #need to enlarge in x direction?
		my $new = $self->inew($linesize, $self->iheight);
		$new->paste(src => $self->image);
		$self->image($new);
		$self->iwidth($linesize);
	}
	
	if (defined $bg) { #paint background
		my $linespace = $self->fontMetrics($font, '-linespace');
		my $descent = $self->fontMetrics($font, '-descent');
		my $x1 = $self->xpos;
		my $x2 = $x1 + $partsize;
		my $y2 = $self->ypos + $descent;
		my $y1 = $y2 - $linespace;
		$self->image->polygon(
			points => [[$x1, $y1], [$x2, $y1], [$x2, $y2], [$x1, $y2]],
			color => $bg,
		);
	}

	$self->image->string(
		x => $self->xpos,
		y => $self->ypos,
		font => $ifont,
		string => $string,
		color => $fg,
		aa => 1,
	);
	$self->xpos($self->xpos + $partsize);
}

sub iwidth {
	my $self = shift;
	$self->{IWIDTH} = shift if @_;
	return $self->{IWIDTH}
}

sub linecolumn {
	my $self = shift;
	$self->{LINECOLUMN} = shift if @_;
	return $self->{LINECOLUMN}
}

sub linenumbers {
	my $self = shift;
	$self->{LINENUMBERS} = shift if @_;
	return $self->{LINENUMBERS}
}

sub maxwidth {
	my $self = shift;
	$self->{MAXWIDTH} = shift if @_;
	return $self->{MAXWIDTH}
}

sub MenuItems {
	my $self = shift;
	return (
		[ 'menu_normal', 'File::Close', 'Export to ~HTML', 'export_html', 'text-html'],
		[ 'menu_normal', 'File::Close', 'Export to P~NG', 'export_png', 'image-x-generic'],
		[ 'menu_separator', 'File::Close',  'F3'],
	)
}

sub tabstring {
	my $self = shift;
	$self->{TABSTRING} = shift if @_;
	return $self->{TABSTRING}
}

sub Unload {
	my $self = shift;
	$self->cmdRemove('export_html');
	$self->cmdRemove('export_png');
	return $self->SUPER::Unload;
}

sub xpos {
	my $self = shift;
	$self->{XPOS} = shift if @_;
	return $self->{XPOS}
}

sub ypos {
	my $self = shift;
	$self->{YPOS} = shift if @_;
	return $self->{YPOS}
}


=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 TODO

=over 4

=back

=head1 BUGS AND CAVEATS

If you find any bugs, please contact the author.

=head1 SEE ALSO

=over 4

=back

=cut

1;
















