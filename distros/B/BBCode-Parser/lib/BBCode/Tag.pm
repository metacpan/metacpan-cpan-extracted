# $Id: Tag.pm 284 2006-12-01 07:51:49Z chronos $
package BBCode::Tag;
use BBCode::Util qw(:quote :tag multilineText);
use BBCode::TagSet;
use Carp qw(croak);
use HTML::Entities ();
use strict;
use warnings;
our $VERSION = '0.34';

# Note: Due to the huge differences between using BBCode::Tag and
#       subclassing BBCode::Tag, the POD is no longer interleaved
#       with the code.  It has been moved to the end of the file.


# Class methods meant for overriding

sub Tag($):method {
	my $class = shift;
	$class = ref($class) || $class;
	$class =~ s/'/::/g;
	$class =~ s/^.*:://;
	return $class;
}

sub Class($):method {
	return ();
}

sub BodyPermitted($):method {
	return 0;
}

sub BodyTags($):method {
	return ();
}

sub NamedParams($):method {
	return ();
}

sub RequiredParams($):method {
	return shift->NamedParams;
}

sub DefaultParam($):method {
	return undef;
}

sub OpenPre($):method {
	return "";
}

sub OpenPost($):method {
	return "";
}

sub ClosePre($):method {
	return "";
}

sub ClosePost($):method {
	return "";
}


# Instance methods meant for overriding

sub validateParam($$$):method {
	return $_[2];
}


# Methods meant to be inherited

sub new:method {
	my($pkg, $parser, $tag) = splice(@_, 0, 2);

	if($pkg eq __PACKAGE__) {
		$tag = shift;
		$pkg = $parser->resolveTag($tag);
	}
	$tag = $pkg->Tag;

	croak "Tag [$tag] is not permitted by current settings"
		if not $parser->isPermitted($tag);

	my $this = (bless { parser => $parser }, $pkg)->init();

	while(@_) {
		my($k,$v) = (undef,shift);
		($k,$v) = @$v if ref $v and UNIVERSAL::isa($v,'ARRAY');
		$k = $this->DefaultParam if not defined $k or $k eq '';
		croak "No default parameter for [".$this->Tag."]" if not defined $k;
		$this->param($k, $v);
	}

	return $this;
}

sub init($):method {
	my $this = shift;

	$this->{params} = {};
	foreach($this->NamedParams) {
		$this->{params}->{$_} = undef;
	}

	if($this->BodyPermitted) {
		$this->{body} = [];
		$this->{permit} = BBCode::TagSet->new;
		$this->{forbid} = BBCode::TagSet->new;
		if($this->BodyTags) {
			$this->{permit}->add($this->BodyTags);
		} else {
			$this->{permit}->add(':ALL');
		}
	}

	return $this;
}

sub parser($):method {
	return shift->{parser};
}

sub isPermitted($$):method {
	my($this,$child) = @_;
	if(exists $this->{body}) {
		foreach(tagHierarchy($child)) {
			return 0 if $this->{forbid}->contains($_);
			return 1 if $this->{permit}->contains($_);
		}
	}
	return 0;
}

sub forbidTags($@):method {
	my $this = shift;
	if(exists $this->{body}) {
		my $set;
		if(@_ == 1 and UNIVERSAL::isa($_[0],'BBCode::TagSet')) {
			$set = shift;
		} else {
			$set = BBCode::TagSet->new(@_);
		}
		$this->{permit}->remove($set);
		$this->{forbid}->add($set);
		foreach my $child ($this->body) {
			warn qq(Nested child is now forbidden) unless $this->isPermitted($child);
			$child->forbidTags($set);
		}
	}
	return $this;
}

sub body($):method {
	my $this = shift;
	if(exists $this->{body}) {
		return @{$this->{body}} if wantarray;
		return $this->{body};
	} else {
		return () if wantarray;
		return [];
	}
}

sub bodyHTML($):method {
	return multilineText map { scalar $_->toHTML } shift->body;
}

sub bodyText($):method {
	return multilineText map { scalar $_->toText } shift->body;
}

sub pushBody($@):method {
	my $this = shift;
	croak qq(Body contents not permitted) unless $this->BodyPermitted;
	while(@_) {
		my $tag = shift;
		if(ref $tag) {
			croak qq(Expected a BBCode::Tag) unless UNIVERSAL::isa($tag, 'BBCode::Tag');
		} else {
			$tag = BBCode::Tag->new($this->{parser}, 'TEXT', [ undef, $tag ]);
		}
		croak qq(Invalid tag nesting) if not $this->isPermitted($tag);
		$tag->forbidTags($this->{forbid});
		push @{$this->{body}}, $tag;
	}
	return $this;
}

sub param($$;$):method {
	my($this,$param) = splice @_, 0, 2;

	$param = $this->DefaultParam if not defined $param or $param eq '';
	croak qq(Missing parameter name) unless defined $param;
	$param = uc $param;
	croak qq(Invalid parameter name "$param") unless exists $this->{params}->{$param};

	if(@_) {
		$this->{params}->{$param} = $this->validateParam($param,@_);
	}

	return $this->{params}->{$param};
}

sub params($):method {
	my $this = shift;
	my @ret;
	foreach my $k ($this->NamedParams) {
		next unless exists $this->{params}->{$k};
		my $v = $this->{params}->{$k};
		push @ret, $k, $v if defined $v;
	}
	return @ret if wantarray;
	return { @ret };
}

sub replace($):method {
	return $_[0];
}

sub replaceBody($):method {
	my $this = shift->replace;
	my $body = $this->body;
	@$body = grep { defined } map { $_->replaceBody } @$body;
	return $this;
}

sub isFollowed($):method {
	my $this = shift;
	my $follow = $this->parser->follow_links;
	if($follow or $this->parser->follow_override) {
		eval {
			my $f = $this->param('FOLLOW');
			$follow = $f if defined $f;
		};
	}
	return $follow;
}

sub openInNewWindow($):method {
	my $this = shift;
	my($nw,$nwo) = $this->parser->get(qw(newwindow_links newwindow_override));
	if($nwo) {
		eval {
			my $user = $this->param('NEWWINDOW');
			$nw = $user if defined $user;
		};
	}
	return $nw;
}

sub toBBCode($):method {
	my $this = shift->replace;

	my $ret = $this->OpenPre.'['.$this->Tag;

	my @p = $this->params;

	if(@p) {
		my $def = $this->DefaultParam;
		my @params;

		while(@p) {
			my($k,$v) = splice @p, 0, 2;
			if(defined $def and $def eq $k) {
				$ret .= '='.quote($v);
				$def = undef;
			} else {
				push @params, quote($k).'='.quote($v);
			}
		}

		$ret = join(", ", $ret, @params);
	}

	$ret .= ']'.$this->OpenPost;

	if($this->BodyPermitted) {
		foreach($this->body) {
			$ret .= $_->toBBCode;
		}
		$ret .= $this->ClosePre.'[/'.$this->Tag.']'.$this->ClosePost;
	}

	return multilineText $ret;
}

sub toHTML($):method {
	my $this = shift;
	my $that = $this->replace;
	if($this == $that) {
		croak qq(Not implemented);
	} else {
		return $that->toHTML;
	}
}

sub toText($):method {
	my $this = shift->replace;
	return $this->bodyText();
}

sub toLinkList($;$):method {
	my $this = shift->replace;
	my $ret = shift;
	$ret = [] if not defined $ret;
	foreach my $child ($this->body) {
		$child->toLinkList($ret);
	}
	return @$ret if wantarray;
	return $ret;
}

1;

=head1 NAME

BBCode::Tag - Perl representation of a BBCode tag

=head1 DESCRIPTION

See L<the documentation on BBCode::Parser|BBCode::Parser> for an overview of
the typical usage of this package.

=head1 GENERAL USE

=head2 METHODS

=head3 new

	$parser = BBCode::Parser->new(...);
	$tag = BBCode::Tag->new($parser, 'B');

Called as a class method.  Takes three or more parameters: a class name
(ignored), a L<BBCode::Parser object|BBCode::Parser>, the tag to be created,
and any initial parameters.  Returns a newly constructed tag of the
appropriate subclass.

Initial parameters can be provided in one of two ways:

=over

=item *

The value for the default parameter can be given as a plain string.

=item *

The value for any named parameter can be given as an anonymous array of length
2.  The first element is the parameter name, and the second is the value.  If
the first element is undefined or the empty string, the default parameter is
set instead.

=back

Example:

	$url = BBCode::Tag->new(
		$parser,
		'URL',
		# Sets the default parameter (style 1)
		'http://www.example.com/',
		# Sets the FOLLOW parameter
		[ 'FOLLOW', '1' ],
	);
	$text = BBCode::Tag->new(
		$parser,
		'TEXT',
		# Sets the default parameter (style 2)
		[ undef, 'Example.com' ],
	);
	$url->pushBody($text);

=head3 parser

	$parser = $tag->parser();

Returns the L<BBCode::Parser object|BBCode::Parser> that this tag was
constructed with.

=head3 isPermitted

	if($tag->isPermitted('URL')) {
		# $tag can contain [URL] tags
	} else {
		# [URL] tags are forbidden
	}

Checks if the given BBCode tag is allowed in the body of this tag.

=head3 forbidTags

	$tag->forbidTags(qw(IMG URL));

Mark the given tagZ<>(s) as forbidden, so that this tag (including all its
children, grandchildren, etc.) can never contain any of the forbidden tags.

At the moment, if a tag already contains one of the tags now forbidden, a
warning is raised.  In the future, this behavior will likely change.

=head3 body

	# Iterate over all this tag's immediate children
	my @body = $tag->body();
	foreach my $subtag (@body) { ...; }

	# Forcibly add a new child, overriding $tag->isPermitted()
	my $body = $tag->body();
	my $bold = BBCode::Tag->new($tag->parser(), 'B');
	push @$body, $bold;

Returns the list of child tags for this tag.  In list context, returns
a list; otherwise, returns an array reference.

CAUTION: The reference returned in scalar context is a direct pointer to a
C<BBCode::Tag> internal structure.  It is possible to bypass checks on
security and correctness by altering it directly.

=head3 bodyHTML

	print HANDLE $tag->bodyHTML();

Recursively converts everything inside this tag into HTML.  In array context,
returns the HTML line-by-line (with '\n' already appended); in scalar context,
returns the HTML as one string.

Odds are that you want to use L<toHTML()|/"toHTML"> instead.

=head3 bodyText

	print HANDLE $tag->bodyText();

Recursively converts everything inside this tag into plain text.  In array
context, returns the plain text line-by-line (with '\n' already appended); in
scalar context, returns the text as one string.

Odds are that you want to use L<toText()|/"toText"> instead.

=head3 pushBody

	$tag->pushBody(
		'Image: ',
		BBCode::Tag->new(
			$tag->parser(),
			'IMG',
			'http://www.example.org/img.png',
		)
	);

Appends one or more new child tags to this tag's body.  Security and
correctness checks are performed.  Use C<eval> to catch any exceptions.

If any arguments are strings, they are upgraded to virtual [TEXT] tags.

=head3 toBBCode

Converts this BBCode tree back to BBCode.  The resulting "deparsed" BBCode can
reveal discrepancies between what the user means vs. what BBCode::Parser
thinks the user means.

In a web environment, a round-trip using C<toBBCode> is recommended each time
the user previews his/her message.  This makes it easier for the user to spot
troublesome code.

=head3 toHTML

Converts this BBCode tree to HTML.  This is generally the entire point of
using BBCode.

At the moment, only XHTML 1.0 Strict output is supported.  Future versions will
likely support other HTML standards.

=head3 toText

Converts this BBCode tree to plain text.

Note that the result may contain Unicode characters.  It is strongly
recommended that you use UTF-8 encoding whenever you store or transmit the
resulting text, to prevent loss of information.  You might look at
L<the Text::Unidecode module|Text::Unidecode> if you want 7-bit ASCII output.

=head3 toLinkList

	foreach $link ($tag->toLinkList) {
		my($followed,$tag,$href,$text) = @$link;
		print "<URL:$href> $text\n";
	}

Converts this BBCode tree into a list of all hyperlinks.

Each hyperlink is itself an anonymous array of length 4.  The first element
is a boolean that tells whether or not the link should be followed by search
engines (see L<the follow_links setting|BBCode::Parser/"follow_links"> for
details).  The second element is a string that holds the BBCode tag name
that created this hyperlink.  The third element is a string that holds the
actual hyperlink address.  The fourth element is the text content (if any)
describing the link.

In scalar context, returns a reference to the array of hyperlinks.  In list
context, returns the array itself.

=head1 SUBCLASSING

While the details of subclassing presented below are currently accurate, a
number of major changes are likely (mostly dealing with the addition of new
BBCode tags at runtime).  The API is not yet stable and will almost certainly
change in incompatible ways.  Hic sunt dracones.

=head2 CLASS METHODS

=head3 Tag

Returns the name of the tag as used in BBCode.  For instance, the
following code prints "URL":

	my $parser = BBCode::Parser->new;
	my $tree = $parser->parse("[URL]example.com[/URL]");
	printf "%s\n", $tree->body->[0]->Tag;

The default implementation returns the final component of the object's class
name.  (For instance, C<BBCode::Tag::URL> becomes "URL".)  Override this in
subclasses as needed.

=head3 Class

Returns a list of zero or more strings, each of which is a class
that this tag belongs to (without any colon prefixes).  For instance, [B] and
[I] tags are both of class :INLINE, meaning that they can be found inside
fellow inline tags.  Therefore, both their implementations return qw(INLINE).
Tag classes are listed in order from most specific to least.

For a more thorough discussion of tag classes, see
L<"CLASSES" in BBCode::Parser|BBCode::Parser/"CLASSES">.

The default implementation returns an empty list.

=head3 BodyPermitted

C<BodyPermitted> indicates whether or not the tag can contain a body of some
sort (whether it be text, more tags, or both).

The default implementation returns false.

=head3 BodyTags

Returns a list of tags and classes that are permitted or forbidden
in the body of this tag.  See L<BBCode::Parser-E<gt>permit()|BBCode::Parser/"permit">
for syntax.  If this tag doesn't permit a body at all, this value is ignored.

The default implementation returns an empty list (all tags are permitted).

=head3 NamedParams

Returns a list of named parameters that can be set on this tag.
By default, the order in this list determines the order in "deparsed" BBCode.
Override L<toBBCode()|/"toBBCode"> if this isn't acceptable.

At the moment, parameter aliases are not available.  This may change in the
future.

The default implementation returns an empty list (no parameters are permitted).

=head3 RequiredParams

Returns a list of named parameters that B<must> be set on this tag.

If the returned list contains a named parameter that doesn't exist in the
C<NamedParams()> list, then the tag cannot be used.  So don't do that.

The default implementation returns whatever C<NamedParams()> returns (all
permitted parameters are required).

(At the moment, this value B<still> doesn't do anything, despite having been
there since before 0.01 was released.  However, it will eventually take effect
somewhere around $tag->replaceBody time as $parser->parse finishes up.  I think
a $tag->finalize method is in order.)

=head3 DefaultParam

Returns the name of a single parameter that is fundamental
enough that it is I<the> parameter of the tag.  Returns C<undef> if no such
parameter exists.

As an example, the C<[URL HREF]> parameter is important enough to the C<[URL]>
tag that the following two lines of BBCode are equivalent:

	[URL HREF=example.com]Link[/URL]
	[URL=example.com]Link[/URL]

In this example, C<DefaultParam()> returns 'HREF'.

The default implementation returns C<undef>.

=head3 OpenPre

Returns a "fudge factor" value used in the default C<toBBCode()>.  The
returned string is inserted into the "deparsed" BBCode just before the opening
tag.

It is B<STRONGLY> recommended that this value should only contain whitespace.

The default implementation returns the empty string.

=head3 OpenPost

Returns a "fudge factor" value used in the default C<toBBCode()>.  The
returned string is inserted into the "deparsed" BBCode just after the opening
tag and before the contents begin.

It is B<STRONGLY> recommended that this value should only contain whitespace.

The default implementation returns the empty string.

=head3 ClosePre

Returns a "fudge factor" value used in the default C<toBBCode()>.  The
returned string is inserted into the "deparsed" BBCode just before the closing
tag and after the contents end.

It is B<STRONGLY> recommended that this value should only contain whitespace.

The default implementation returns the empty string.

=head3 ClosePost

Returns a "fudge factor" value used in the default C<toBBCode()>.  The
returned string is inserted into the "deparsed" BBCode just after the closing
tag.

It is B<STRONGLY> recommended that this value should only contain whitespace.

The default implementation returns the empty string.

=head2 INSTANCE METHODS

=head3 validateParam

Takes three parameters: the object, the name of a parameter, and the requested
value for the parameter.  Returns the actual value for the parameter.  Throws
an exception if the requested value is entirely unacceptable.

The default implementation returns all values unchanged.  Override this to
perform checking on the values of named parameters.

FIXME: This API is clunky, especially for inheriting.

=head1 SEE ALSO

L<BBCode::Parser|BBCode::Parser>

=head1 AUTHOR

Donald King E<lt>dlking@cpan.orgE<gt>

=cut
