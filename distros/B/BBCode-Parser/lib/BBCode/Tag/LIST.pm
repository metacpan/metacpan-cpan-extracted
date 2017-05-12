# $Id: LIST.pm 284 2006-12-01 07:51:49Z chronos $
package BBCode::Tag::LIST;
use base qw(BBCode::Tag::Block);
use BBCode::Util qw(:parse encodeHTML multilineText createListSequence);
use BBCode::Tag::TEXT ();
use strict;
use warnings;
our $VERSION = '0.34';

sub Class($):method {
	return qw(LIST BLOCK);
}

sub BodyPermitted($):method {
	return 1;
}

sub BodyTags($):method {
	return qw(LI TEXT);
}

sub NamedParams($):method {
	return qw(TYPE START BULLET OUTSIDE);
}

sub RequiredParams($):method {
	return ();
}

sub DefaultParam($):method {
	return 'TYPE';
}

sub validateParam($$$):method {
	my($this,$param,$val) = @_;
	if($param eq 'TYPE') {
		return $val if parseListType($val) > 0;
		return '*';
	}
	if($param eq 'START') {
		return parseInt $val;
	}
	if($param eq 'BULLET') {
		my $url = parseURL($val);
		if(defined $url) {
			return $url->as_string;
		} else {
			die qq(Invalid value "$val" for [LIST BULLET]);
		}
	}
	if($param eq 'OUTSIDE') {
		return parseBool $val;
	}
	return $this->SUPER::validateParam($param,$val);
}

sub _text($$):method {
	my $this = shift;
	my $text = shift;
	my $tag = BBCode::Tag->new($this->parser, 'TEXT', [ undef, $text ]);
	return $tag;
}

sub _li($$):method {
	my $this = shift;
	my $text = shift;
	my $tag = BBCode::Tag->new($this->parser, 'LI');
	$tag->pushBody($this->_text($text));
	return $tag;
}

sub pushBody($@):method {
	my $this = shift;
	my @tags;

	while(@_) {
		my $tag = shift;

		next if not defined $tag;

		if(not ref $tag) {
			unshift @_, $this->_text($tag);
			next;
		}

		if(UNIVERSAL::isa($tag,'BBCode::Tag::TEXT')) {
			my $str = $tag->param(undef);
			unless($str =~ /^\s*$/) {
				push @tags, $this->_text("$1") if $str =~ s/^(\s+)//;
				unshift @_, $this->_text("$1") if $str =~ s/(\s+)$//;
				while($str =~ s/^(.*\S)(\s*\n\s*)//) {
					my($item,$sep) = ($1,$2);
					push @tags, $this->_li($item);
					push @tags, $this->_text($sep);
				}
				push @tags, $this->_li($str);
				next;
			}
		}

		push @tags, $tag;
	}

	return $this->SUPER::pushBody(@tags);
}

sub bodyHTML($):method {
	my $this = shift;
	my $html = '';
	foreach($this->body) {
		next unless UNIVERSAL::isa($_,'BBCode::Tag::LI');
		$html .= $_->toHTML;
#		die qq(\n> $html[$#html]\nOMGWTFBBQ?) if $html[$#html] =~ m#<br\s*/>#i;
	}
	return multilineText $html;
}

sub ListDefault($):method {
	return qw(ul);
}

sub toHTML($):method {
	my $this = shift;
	my @list = parseListType($this->param('TYPE'));
	@list = $this->ListDefault unless @list;

	my @css;
	if(@list > 1) {
		push @css, qq(list-style-type: $list[1]);
	}

	my $start = $this->param('START');
	if($list[0] eq 'ol' and defined $start) {
		$start = qq( start="$start");
	} else {
		$start = '';
	}

	if($list[0] eq 'ul' and $this->parser->allow_image_bullets) {
		my $url = $this->param('BULLET');
		if(defined $url) {
			push @css, sprintf "list-style-image: url('%s')", encodeHTML($url->as_string);
		}
	}

	my $outside = $this->param('OUTSIDE');
	if(defined $outside) {
		push @css, "list-style-position: ".($outside ? "outside" : "inside");
	}

	my $css = @css ? qq( style=").join("; ", @css).qq(") : "";
	my $body = $this->bodyHTML;
	$body =~ s#(<li>)(<[uo]l>)#$1\n$2#g;
	$body =~ s/^/\t/mg;
	$body =~ s#^\t(?!</?li>)#\t\t#mg;
	return multilineText "<$list[0]$start$css>\n$body</$list[0]>\n";
}

sub toText($):method {
	my $this = shift;
	my @body = grep { $_->isa('BBCode::Tag::LI') } $this->body;
	my $seq = createListSequence($this->param('TYPE'), $this->param('START'), scalar(@body));

	my $text = "";
	foreach(@body) {
		$text .= $seq->()." ".$_->toText."\n";
	}
	return multilineText $text;
}

1;
