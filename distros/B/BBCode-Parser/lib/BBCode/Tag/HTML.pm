# $Id: HTML.pm 284 2006-12-01 07:51:49Z chronos $
package BBCode::Tag::HTML;
use base qw(BBCode::Tag);
use BBCode::Util qw(multilineText);
use strict;
use warnings;
our $VERSION = '0.34';

sub NamedParams($):method {
	return qw(CODE);
}

sub DefaultParam($):method {
	return 'CODE';
}

sub toBBCode($):method {
	my $this = shift;
	return multilineText "[HTML]".$this->param('CODE')."[/HTML]";
}

sub toHTML($):method {
	my $this = shift;
	return multilineText $this->param('CODE');
}

1;
