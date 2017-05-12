# $Id: HR.pm 284 2006-12-01 07:51:49Z chronos $
package BBCode::Tag::HR;
use base qw(BBCode::Tag::Block);
use strict;
use warnings;
our $VERSION = '0.34';

sub toBBCode($):method {
	return "[HR]";
}

sub toHTML($):method {
	return "<hr/>";
}

1;
