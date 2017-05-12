# $Id: SIZE.pm 284 2006-12-01 07:51:49Z chronos $
package BBCode::Tag::SIZE;
use base qw(BBCode::Tag::Inline);
use BBCode::Util qw(:parse);
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
		my $size = parseFontSize($val);
		if(defined $size) {
			return $size;
		} else {
			die qq(Invalid value "$val" for [SIZE]);
		}
	}
	return $this->SUPER::validateParam($param,$val);
}

sub replace($):method {
	my $this = shift;
	my $that = BBCode::Tag->new($this->parser, 'FONT', [ 'SIZE', $this->param('VAL') ]);
	@{$that->body} = @{$this->body};
	return $that;
}

1;
