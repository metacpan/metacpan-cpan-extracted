# $Id: QUOTE.pm 284 2006-12-01 07:51:49Z chronos $
package BBCode::Tag::QUOTE;
use base qw(BBCode::Tag::Block);
use BBCode::Util qw(:parse encodeHTML multilineText);
use strict;
use warnings;
our $VERSION = '0.34';

sub BodyPermitted($):method {
	return 1;
}

sub NamedParams($):method {
	return qw(SRC CITE FOLLOW);
}

sub RequiredParams($):method {
	return ();
}

sub DefaultParam($):method {
	return 'SRC';
}

sub validateParam($):method {
	my($this,$param,$val) = @_;
	if($param eq 'CITE') {
		my $url = parseURL($val);
		if(defined $url) {
			return $url->as_string;
		} else {
			die qq(Invalid value "$val" for [QUOTE CITE]);
		}
	}
	return $this->SUPER::validateParam($param,$val);
}

sub toHTML($):method {
	my $this = shift;
	my $pfx = $this->parser->css_prefix;

	my $who = $this->param('SRC');
	my $cite = $this->param('CITE');
	my $body = $this->bodyHTML;

	$who = (defined $who ? encodeHTML($who).' wrote' : 'Quote');
	if(defined $cite) {
		$who =
			'<a href="'.encodeHTML($cite).'"'.
			($this->isFollowed ? '' : ' rel="nofollow"').
			'>'.
			$who.
			'</a>';
	}
	$who .= ':';

	return multilineText
		qq(<div class="${pfx}quote">\n),
		qq(<div class="${pfx}quote-head">$who</div>\n),
		qq(<blockquote class="${pfx}quote-body"), (defined $cite ? ' cite="'.encodeHTML($cite).'"' : ''), qq(>\n),
		qq(<div>\n$body\n</div>\n),
		qq(</blockquote>\n),
		qq(</div>\n);
}

sub toText($):method {
	my $this = shift;

	my $who = $this->param('SRC');
	my $cite = $this->param('CITE');
	my $body = $this->bodyText;
	$body =~ s/^/\t/m;
	$body =~ s/^\t$//m;

	my $ret = '';
	$ret .= (defined $who ? "$who wrote" : 'Quote').":\n";
	$ret .= "Source: <URL:$cite>\n" if defined $cite;
	$ret .= $body;
	$ret .= "\n";
	return multilineText $ret;
}

sub toLinkList($;$):method {
	my $this = shift;
	my $ret = shift;
	$ret = [] if not defined $ret;

	my $src = $this->param('SRC');
	my $cite = $this->param('CITE');
	if(defined $cite) {
		push @$ret, [ $this->isFollowed, $this->Tag, $cite, $src ];
	}
	return $this->SUPER::toLinkList($ret);
}

1;
