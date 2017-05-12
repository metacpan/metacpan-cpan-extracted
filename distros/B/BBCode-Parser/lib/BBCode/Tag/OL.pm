# $Id: OL.pm 284 2006-12-01 07:51:49Z chronos $
package BBCode::Tag::OL;
use base qw(BBCode::Tag::LIST);
use strict;
use warnings;
our $VERSION = '0.34';

sub ListDefault($):method {
	return qw(ol);
}

1;
