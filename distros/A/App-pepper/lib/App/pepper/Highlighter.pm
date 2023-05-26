package App::pepper::Highlighter;
use Term::ANSIColor;
use HTML::Entities qw(encode_entities_numeric);
use vars qw($buffer $depth $indent $tag $end);
use strict;

# output buffer
our $buffer;

# indent depth
our $depth;

# indent string
our $indent = '  ';

# arrayref identifying the "current" tag, used to do short-tags
our $tag;

# this string contains a regexp that will match the end of the buffer if we've just opened a new tag
our $end = quotemeta('>'.color('reset'));

sub StartDocument {
	# initialise variables
	$buffer	= '';
	$depth	= 0;
	$tag	= undef;
}

sub StartTag {
	$buffer .= "\n" if ($buffer ne '' && "\n" ne substr($buffer, -1));

	# open the tag
	$buffer .= sprintf(
		'%s%s<%s',
		($indent x $depth),
		color('cyan'),
		$_[1]
	);

	# print attributes
	foreach my $name (keys(%_)) {
		$buffer .= sprintf(
			' %s%s="%s%s%s"%s',
			color('green'),
			$name,
			color('reset'),
			encode_entities_numeric($_{$name}, '<>&'),
			color('green'),
			color('reset'),
		);
	}

	# close the tag
	$buffer .= sprintf(
		"%s>%s",
		color('cyan'),
		color('reset'),
	);

	# increase indent depth
	$depth++;

	# record this element as the current tag
	$tag = [ $_[1], $depth ];
}

sub EndTag {
	if ($tag && $tag->[0] eq $_[1] && $tag->[1] == $depth && $buffer =~ /$end$/) {
		# we are closing a tag that has no child elements, so convert it to a "short" tag (ie <foo/>)
		$buffer =~ s/$end$//g;
		$buffer .= '/>'.color('reset');

	} else {
		# we have some children, so close normally

		$buffer .= "\n".($indent x ($depth-1)) if ($buffer =~ /$end$/);

		$buffer .= sprintf(
			"%s</%s>%s",
			color('cyan'),
			$_[1],
			color('reset'),
		);
	}

	# decrement depth
	$depth--;

	# reset current tag
	$tag = undef;
}

sub Text {
	# remove any enclosing whitespace around the text
	$_[0]->{'Text'} =~ s/^[ \t\r\n]+//sg;
	$_[0]->{'Text'} =~ s/[ \t\r\n]+$//sg;

	# indent if on a newline
	$buffer .= ($indent x $depth) if ("\n" eq substr($buffer, -1));

	# append text
	$buffer .= encode_entities_numeric($_[0]->{'Text'}, '<>&');
}

sub EndDocument {
	# remove trailing whitespace
	$buffer =~ s/[ \t\r\n]+$//sg;

	# make sure we don't bleed any colours
	$buffer .= color('reset');

	# replace newlines with any line prefix that is defined
	$buffer =~ s/\n/\n$_[0]->{'lineprefix'}/sg;

	# output
	print $_[0]->{'lineprefix'}.$buffer."\n";
}

1;
