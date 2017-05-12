# $Id: I.pm 284 2006-12-01 07:51:49Z chronos $
package BBCode::Tag::I;
use base qw(BBCode::Tag::Simple BBCode::Tag::Inline);
use BBCode::Util qw(multilineText);
use strict;
use warnings;
our $VERSION = '0.34';

sub BodyPermitted($):method {
	return 1;
}

sub toText($):method {
	return multilineText '/'.shift->bodyText().'/';
}

1;
