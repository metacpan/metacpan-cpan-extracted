# $Id: URL.pm 284 2006-12-01 07:51:49Z chronos $
package BBCode::Tag::URL;
use base qw(BBCode::Tag);
use BBCode::Util qw(:parse encodeHTML multilineText);
use strict;
use warnings;
our $VERSION = '0.34';

sub Class($):method {
	return qw(LINK INLINE);
}

sub BodyPermitted($):method {
	return 1;
}

sub BodyTags($):method {
	return qw(:INLINE !:LINK);
}

sub NamedParams($):method {
	return qw(HREF FOLLOW NEWWINDOW TITLE);
}

sub RequiredParams($):method {
	return qw(HREF);
}

sub DefaultParam($):method {
	return 'HREF';
}

sub validateParam($$$):method {
	my($this,$param,$val) = @_;

	if($param eq 'HREF') {
		my $url = parseURL($val);
		if(defined $url) {
			return $url->as_string;
		} else {
			die qq(Invalid value "$val" for [URL]);
		}
	}
	if($param eq 'FOLLOW') {
		return parseBool $val;
	}
	if($param eq 'NEWWINDOW') {
		return parseBool $val;
	}
	return $this->SUPER::validateParam($param,$val);
}

sub replace($):method {
	my $this = shift;
	my $href = $this->param('HREF');
	if(not defined $href) {
		my $text = $this->bodyText;
		my $url = parseURL $text;
		if(not defined $url) {
			return BBCode::Tag->new($this->parser, 'TEXT', [ undef, $text ]);
		}
		$this->param(HREF => $url);
	}
	return $this;
}

sub toHTML($):method {
	my $this = shift;

	my $ret = '';
	my $href = $this->param('HREF');
	if(defined $href) {
		my $title = $this->param('TITLE');
		$ret .= '<a href="'.encodeHTML($href).'"';
		$ret .= ' rel="nofollow"' if not $this->isFollowed;
		$ret .= ' target="_blank"' if $this->openInNewWindow;
		$ret .= ' title="'.encodeHTML($title).'"' if defined $title;
		$ret .= '>';
	}
	$ret .= $this->bodyHTML;
	if(defined $href) {
		$ret .= '</a>';
	}

	return multilineText $ret;
}

sub toText($):method {
	my $this = shift;

	my $href = $this->param('HREF');
	my $text = $this->bodyText;
	my $ret;
	if(defined $href) {
		$ret = "_${text}_";
		if($href =~ /^mailto:([\w.+-]+\@[\w.-]+)$/) {
			$ret .= " <$1>";
		} else {
			$ret .= " <URL:$href>";
		}
	} else {
		$ret = $text;
	}
	return multilineText $ret;
}

sub toLinkList($;$):method {
	my $this = shift;
	my $ret = shift;
	$ret = [] if not defined $ret;

	my $href = $this->param('HREF');
	if(defined $href) {
		push @$ret, [ $this->isFollowed, $this->Tag, $href, $this->bodyText ];
	}
	return $this->SUPER::toLinkList($ret);
}

1;
