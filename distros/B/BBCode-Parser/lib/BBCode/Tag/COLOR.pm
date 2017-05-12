# $Id: COLOR.pm 284 2006-12-01 07:51:49Z chronos $
package BBCode::Tag::COLOR;
use base qw(BBCode::Tag::Inline);
use BBCode::Util qw(:parse encodeHTML);
use strict;
use warnings;
our $VERSION = '0.34';

sub BodyPermitted($):method {
	return 1;
}

sub NamedParams($):method {
	return qw(VAL);
}

sub DefaultParam($):method {
	return 'VAL';
}

sub validateParam($$$):method {
	my($this,$param,$val) = @_;

	if($param eq 'VAL') {
		my $color = parseColor($val);
		if(defined $color) {
			return $color;
		} else {
			die qq(Invalid value "$val" for [COLOR]);
		}
	}
	return $this->SUPER::validateParam($param,$val);
}

sub replace($):method {
	my $this = shift;
	my $that = BBCode::Tag->new($this->parser, 'FONT', [ 'COLOR', $this->param('VAL') ]);
	@{$that->body} = @{$this->body};
	return $that;
}

1;
