# $Id: BR.pm 284 2006-12-01 07:51:49Z chronos $
package BBCode::Tag::BR;
use base qw(BBCode::Tag);
use strict;
use warnings;
our $VERSION = '0.34';

sub Class($):method {
	return qw(TEXT INLINE);
}

sub toBBCode($):method {
	return "[BR]";
}

sub toHTML($):method {
	return "<br/>";
}

sub toText($):method {
	return "\n";
}

1;
