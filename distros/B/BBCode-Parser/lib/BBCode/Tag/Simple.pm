# $Id: Simple.pm 284 2006-12-01 07:51:49Z chronos $
package BBCode::Tag::Simple;
use BBCode::Util qw(encodeHTML multilineText);
use strict;
use warnings;
our $VERSION = '0.34';

sub toHTML($):method {
	my $this = shift;
	my $ret = "<".lc($this->Tag);

	my @p = $this->params;
	while(@p) {
		my($k,$v) = splice @p, 0, 2;
		$ret .= sprintf ' %s="%s"', lc($k), encodeHTML($v);
	}
	if($this->BodyPermitted) {
		$ret .= '>'.$this->bodyHTML.'</'.lc($this->Tag).'>';
	} else {
		$ret .= ' />';
	}
	return multilineText $ret;
}

1;
