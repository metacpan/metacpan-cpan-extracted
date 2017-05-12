# $Id: Inline.pm 284 2006-12-01 07:51:49Z chronos $
package BBCode::Tag::Inline;
use base qw(BBCode::Tag);
use strict;
use warnings;
our $VERSION = '0.34';

sub Class($):method {
	return qw(INLINE);
}

sub BodyTags($):method {
	return qw(:INLINE);
}

1;
