# $Id: TT.pm 284 2006-12-01 07:51:49Z chronos $
package BBCode::Tag::TT;
use base qw(BBCode::Tag::Simple BBCode::Tag::Inline);
use strict;
use warnings;
our $VERSION = '0.34';

sub BodyPermitted($):method {
	return 1;
}

1;
