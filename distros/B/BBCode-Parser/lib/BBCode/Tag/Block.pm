# $Id: Block.pm 284 2006-12-01 07:51:49Z chronos $
package BBCode::Tag::Block;
use base qw(BBCode::Tag);
use strict;
use warnings;
our $VERSION = '0.34';

sub Class($):method {
	return qw(BLOCK);
}

sub BodyTags($):method {
	return qw(:BLOCK :INLINE);
}

sub bodyHTML($):method {
	local $_ = shift->SUPER::bodyHTML();
	s#^\s* (?: <br/> \s* )*  ##x;
	s# \s* (?: <br/> \s* )* $##x;
	return $_ unless wantarray;
	return split /(?<=\n)/, $_;
}

1;
