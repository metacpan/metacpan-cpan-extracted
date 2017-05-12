# $Id: TEXT.pm 284 2006-12-01 07:51:49Z chronos $
package BBCode::Tag::TEXT;
use base qw(BBCode::Tag);
use BBCode::Util qw(encodeHTML multilineText);
use strict;
use warnings;
our $VERSION = '0.34';

sub Class($):method {
	return qw(TEXT INLINE);
}

sub NamedParams($):method {
	return qw(STR);
}

sub DefaultParam($):method {
	return 'STR';
}

sub toBBCode($):method {
	my $this = shift;
	local $_ = $this->param('STR');
	s/\[/[[/g;
	s/\]/]]/g;
	s/&/[ENT=amp]/g;
	s/<(?=UR[IL]:)/[ENT=lt]/gi;
	return multilineText $_;
}

sub toHTML($):method {
	my $this = shift;
	my $html = encodeHTML($this->param('STR'));
	$html =~ s/&#xA;/\n/g;
	$html =~ s#(?=\n)#<br/>#g;
	return multilineText $html;
}

sub toText($):method {
	return multilineText shift->param('STR');
}

1;
