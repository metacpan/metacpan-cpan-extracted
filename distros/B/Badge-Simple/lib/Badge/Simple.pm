#!perl
package Badge::Simple;
use warnings;
use strict;
use Carp;
use File::Basename qw/fileparse/;
use File::Spec::Functions qw/catfile/;
use Imager ();
use XML::LibXML ();

# For AUTHOR, COPYRIGHT, AND LICENSE see the bottom of this file

our $VERSION = '0.04';

use Exporter 'import';
our @EXPORT_OK = qw/ badge /;

my $DEFAULT_FONT = eval {
	my (undef,$mydir) = fileparse( $INC{'Badge/Simple.pm'} );
	my $fontf = catfile($mydir, 'Simple', 'DejaVuSans.ttf');
	-e $fontf ? Imager::Font->new( file => $fontf ) : undef };

our %COLORSCHEMES = ( blue => '#007ec6', brightgreen => '#4c1',
	green => '#97CA00', lightgrey => '#9f9f9f', orange => '#fe7d37',
	red => '#e05d44', yellow => '#dfb317', yellowgreen => '#a4a61d' );

my %BADGE_KNOWN_ARGS = map {$_=>1} qw/ left right color font style /;

sub badge {  ## no critic (RequireArgUnpacking)
	croak "badge: bad number of arguments" if @_%2;
	my %args = @_;
	$BADGE_KNOWN_ARGS{$_} or croak "badge: unknown argument '$_'" for keys %args;
	length($args{$_}) or croak "badge: must specify '$_'" for qw/ left right /;
	$args{color} ||= 'lightgrey';
	$args{color}=$COLORSCHEMES{$args{color}} if exists $COLORSCHEMES{$args{color}};
	croak "badge: bad color '$args{color}'" unless $args{color}=~/\A#[0-9A-Fa-f]{3,6}\z/;
	croak "badge: bad style '$args{style}'" if defined($args{style}) && $args{style} ne 'flat';
	
	my $font;
	if (defined $args{font}) {
		croak "badge: unable to find font file '$args{font}'" unless -e $args{font};
		$font = Imager::Font->new( file => $args{font} )
			or croak "badge: failed to load font '$args{font}': ".Imager->errstr }
	else { $font = $DEFAULT_FONT or croak "badge: no font specified and failed to load default font" }
	
	my $l_txt_w = $font->bounding_box(size=>11, string=>$args{left} )->display_width;
	my $r_txt_w = $font->bounding_box(size=>11, string=>$args{right})->display_width;
	my $total_w = $l_txt_w + $r_txt_w + 24;
	my $l_txt_c = $l_txt_w/2 + 7;
	my $r_txt_c = $total_w - $r_txt_w/2 - 7;
	my $l_w = $l_txt_w + 12;
	my $r_w = $r_txt_w + 12;
	
	my $doc = XML::LibXML::Document->createDocument();
	
	my $newel = sub {
		my ($parent,$name,%atts) = @_;
		my $el = $doc->createElementNS('http://www.w3.org/2000/svg', $name);
		$el->setAttribute($_=>$atts{$_}) for keys %atts;
		$parent->appendChild($el) if defined($parent);
		return $el;
	};
	
	my $root = $newel->(undef, 'svg', width=>$total_w, height=>20);
	$doc->setDocumentElement($root);
	
	my $lingrad = $newel->($root, 'linearGradient', id=>'smooth', x2=>'0', y2=>'100%' );
	$newel->($lingrad, 'stop', offset=>'0', 'stop-color'=>'#bbb', 'stop-opacity'=>'.1' );
	$newel->($lingrad, 'stop', offset=>'1', 'stop-opacity'=>'.1' );
	
	# Travis/Coveralls SVG:
	#$newel->($root, 'rect', rx=>'3', width=>$total_w, height=>'20', fill=>'#555' );
	#$newel->($root, 'rect', rx=>'3', x=>$l_w, width=>$r_w, height=>'20', fill=>$args{color} );
	#$newel->($root, 'path', fill=>$args{color}, d=>"M$l_w 0h4v20h-4z" );
	#$newel->($root, 'rect', rx=>'3', width=>$total_w, height=>'20', fill=>'url(#a)' );
	
	my $cp = $newel->($root, 'clipPath', id=>'round' );
	$newel->($cp, 'rect', fill=>'#fff', height=>'20', rx=>'3', width=>$total_w );
	
	my $cpg = $newel->($root, 'g', 'clip-path'=>'url(#round)' );
	$newel->($cpg, 'rect', fill=>'#555', height=>'20', width=>$l_w );
	$newel->($cpg, 'rect', fill=>$args{color}, height=>'20', width=>$r_w, x=>$l_w );
	$newel->($cpg, 'rect', fill=>'url(#smooth)', height=>'20', width=>$total_w );
	
	my $grp = $newel->($root, 'g', fill=>'#fff', 'text-anchor'=>'middle',
		'font-family'=>'DejaVu Sans,Verdana,Geneva,sans-serif', 'font-size'=>'11' );
	
	$newel->($grp, 'text', x=>$l_txt_c, y=>'15', fill=>'#010101', 'fill-opacity'=>'.3')
		->appendText($args{left});
	$newel->($grp, 'text', x=>$l_txt_c, y=>'14' )->appendText($args{left});
	
	$newel->($grp, 'text', x=>$r_txt_c, y=>'15', fill=>'#010101', 'fill-opacity'=>'.3')
		->appendText($args{right});
	$newel->($grp, 'text', x=>$r_txt_c, y=>'14' )->appendText($args{right});
	
	return $doc;
}

1;
__END__

=head1 Name

Badge::Simple - Generate simple SVG badges

=head1 Synopsis

 use Badge::Simple qw/badge/;
 badge( left => "Hello", right => "World!", color => "yellow" )
     ->toFile( "hello.svg" );

=for html
<div>&rarr; <code>hello.svg</code>:
<img src="https://raw.githubusercontent.com/haukex/Badge-Simple/master/t/hello.svg?sanitize=true"
	alt="If this image doesn't display, see the samples in the 't' directory of this module's distribution." /></div>

=head1 Description

This module generates simple badges, based heavily on the default
"flat" style of L<Shields.io|http://shields.io>.

The module currently exports a single function, C<badge>, which
returns an L<XML::LibXML::Document|XML::LibXML::Document> object
representing the SVG file. The function takes the following
arguments:

=over

=item C<left>

Text on the left side of the badge. Required.

=item C<right>

Text on the right side of the badge. Required.

=item C<color>

Either an HTML hex color string (C<"#AABBCC">), or one of the
following predefined color schemes: C<blue>, C<brightgreen>,
C<green>, C<lightgrey>, C<orange>, C<red>, C<yellow>,
C<yellowgreen>. If omitted, defaults to C<lightgrey>.

=item C<font>

The filename of a font file (as supported by
L<Imager::Font|Imager::Font>), for example you might point this at
your local copy of F<Verdana.ttf>. This font is currently I<only>
used to calculate the width of the badge. If omitted, defaults to
F<DejaVuSans.ttf>, which is distributed with this module.

B<Note:> Different font libraries may calculate the widths of fonts
slightly differently. This module's tests check to make sure that
these variations are not too large (within a couple of pixels), but
I<be aware> that badges generated on different systems might have
slightly different widths.

=back

The return value of C<badge>, an
L<XML::LibXML::Document|XML::LibXML::Document> object, can easily
be used in one of the following ways (C<$svg> is the return value):

=over

=item *

Write to a file: C<< $svg->toFile($filename); >>

=item *

Save to a string: C<< my $string = $svg->toString(); >>

=item *

Write to a file with the XML nicely indented:
C<< $svg->toFile($filename, 1); >>

=item *

Save to a string with the XML nicely indented:
C<< my $string = $svg->toString(1); >>

=back

=head2 Samples

The following samples should be visible if you are viewing an HTML
version of this documentation and you have an Internet connection
available. Otherwise, please see the sample images in the F<t/>
directory of the module distribution.

=begin html

<p>
<code>badge( left =&gt; "Hello", right =&gt; "World!", color =&gt; "yellow" )</code> &rarr;
<img src="https://raw.githubusercontent.com/haukex/Badge-Simple/master/t/hello.svg?sanitize=true" />
</p>

<p>
<code>badge( left=&gt;'CPAN Testers', right=&gt;'100%', color=&gt;'brightgreen' )</code> &rarr;
<img src="https://raw.githubusercontent.com/haukex/Badge-Simple/master/t/cpt100.svg?sanitize=true" />
</p>

<p>
<code>badge( left=&gt;'foo', right=&gt;'bar', color=&gt;'#e542f4' )</code> &rarr;
<img src="https://raw.githubusercontent.com/haukex/Badge-Simple/master/t/foo.svg?sanitize=true" />
</p>

=end html

=head1 See Also

L<https://github.com/badges/shields>

=head1 Author, Copyright, and License

Copyright (c) 2018 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command C<perldoc perlartistic> or see
L<http://perldoc.perl.org/perlartistic.html>.

Please see the file F<README.md> in the module's distribution for
additional information.

=cut

