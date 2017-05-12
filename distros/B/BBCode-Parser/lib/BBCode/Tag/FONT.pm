# $Id: FONT.pm 284 2006-12-01 07:51:49Z chronos $
package BBCode::Tag::FONT;
use base qw(BBCode::Tag::Inline);
use BBCode::Util qw(:parse encodeHTML multilineText);
use strict;
use warnings;
our $VERSION = '0.34';

sub BodyPermitted($):method {
	return 1;
}

sub NamedParams($):method {
	return qw(FACE SIZE COLOR);
}

sub RequiredParams($):method {
	return ();
}

sub DefaultParam($):method {
	return 'FACE';
}

sub validateParam($$$):method {
	my($this,$param,$val) = @_;

	if($param eq 'SIZE') {
		my $size = parseFontSize($val);
		if(defined $size) {
			return $size;
		} else {
			die qq(Invalid value [FONT SIZE="$val"]);
		}
	}
	if($param eq 'COLOR') {
		my $color = parseColor($val);
		if(defined $color) {
			return $color;
		} else {
			die qq(Invalid value [FONT COLOR="$val"]);
		}
	}
	return $this->SUPER::validateParam($param,$val);
}

sub toHTML($):method {
	my $this = shift->replace;
	my $ret = $this->bodyHTML;
	my $face = $this->param('FACE');
	my $size = $this->param('SIZE');
	my $color = $this->param('COLOR');
	my @css;
	push @css, sprintf "font-family: '%s'", encodeHTML($face)	if defined $face;
	push @css, sprintf "font-size: %s", encodeHTML($size)		if defined $size;
	push @css, sprintf "color: %s", encodeHTML($color)			if defined $color;
	return $ret unless @css;
	return multilineText '<span style="'.join('; ',@css).'">'.$ret.'</span>';
}

1;
