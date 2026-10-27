# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2026 Dick Olsson <hi@senzilla.io>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use v5.36;

package App::FuguWeb::Language;
our $VERSION = '0.11.2';

use App::FuguWeb;

# App::FuguWeb::Language - one declared language of a site.
#
# A language block of the description declares one language, per
# WEB-LANGUAGE. The object holds what the build needs of it: the tag,
# the name, the direction, the path of its tree, the site name and the
# footer. App::FuguWeb::Config makes each object, and every other
# module reads it.
#
# The site name and the footer of a language come from its own block,
# or from the description when its block names none, per
# WEB-LANGUAGE-3. The description holds the words of the default
# language. The object holds each value with the tag of the language
# that it comes from, so a page can mark it, per WEB-LANGUAGE-11.

# The tag of English. A description that declares no language has
# this one language, per WEB-LANGUAGE-4. The human page of a key
# directory is a page of it, per WEB-CHROME-8.
use constant ENGLISH => 'en';

# The two directions of WEB-LANGUAGE-2. The first one is the default.
use constant {
	LEFT_TO_RIGHT => 'ltr',
	RIGHT_TO_LEFT => 'rtl',
};

# The tag rule of WEB-LANGUAGE-1: a BCP 47 tag of RFC 5646, in its
# canonical case. The tag holds a language subtag of two or three
# lowercase letters, then an optional script subtag of four letters
# with the first in uppercase, then an optional region subtag of two
# uppercase letters or three digits. The rule takes no other subtag.
my $TAG = qr{
	\A
	[a-z]{2,3}
	(?: - [A-Z][a-z]{3} )?
	(?: - (?: [A-Z]{2} | [0-9]{3} ) )?
	\z
}xa;

# App::FuguWeb::Language::is_tag($tag):
#	Report whether a word is a tag of WEB-LANGUAGE-1.
sub is_tag ($tag)
{
	return defined $tag && $tag =~ $TAG ? 1 : 0;
}

# App::FuguWeb::Language->new(%args):
#	tag         => $tag	the tag (required)
#	name        => $text	the name of the language in itself
#	dir         => $dir	ltr or rtl (default: ltr)
#	site        => $text	the site name in this language
#	site_lang   => $tag	the language of the site name
#	footer      => $path	the footer fragment, below the source
#				directory
#	footer_lang => $tag	the language of the footer
#
#	The description decides each value, and App::FuguWeb::Config
#	holds it to WEB-LANGUAGE before it makes the object. A tag or a
#	direction of another shape here is therefore a programming
#	error, and the constructor dies.
sub new ( $class, %args )
{
	my $tag = $args{tag};
	die "not a language tag: " . ( $tag // '(undef)' )
	    unless is_tag($tag);

	my $dir = $args{dir} // LEFT_TO_RIGHT;
	die "not a direction: $dir"
	    unless $dir eq LEFT_TO_RIGHT || $dir eq RIGHT_TO_LEFT;

	return bless {
		tag         => $tag,
		name        => $args{name},
		dir         => $dir,
		site        => $args{site},
		site_lang   => $args{site_lang} // $tag,
		footer      => $args{footer},
		footer_lang => $args{footer_lang} // $tag,
	}, $class;
}

# $self->tag, $self->name, $self->dir:
#	The tag, the name of the language in itself, and its
#	direction.
sub tag  ($self) { return $self->{tag}; }
sub name ($self) { return $self->{name}; }
sub dir  ($self) { return $self->{dir}; }

# $self->path:
#	The path of the tree of the language below the output: the tag
#	in lowercase, per WEB-LANGUAGE-5. The tree of zh-Hans is
#	zh-hans.
sub path ($self)
{
	return lc $self->{tag};
}

# $self->site, $self->site_lang:
#	The site name in this language, and the tag of the language
#	that it comes from.
sub site      ($self) { return $self->{site}; }
sub site_lang ($self) { return $self->{site_lang}; }

# $self->footer, $self->footer_lang:
#	The footer fragment of this language, as a path below the
#	source directory, or undef for a site with no footer. The tag
#	of the language that it comes from.
sub footer      ($self) { return $self->{footer}; }
sub footer_lang ($self) { return $self->{footer_lang}; }

# $self->attributes:
#	The attributes of the html element of a page of this language,
#	per WEB-LANGUAGE-10: the tag as lang, and dir="rtl" when the
#	language is right to left. Each attribute has a space in front
#	of it.
sub attributes ($self)
{
	my $attributes =
	    ' lang="' . App::FuguWeb::escape_attr( $self->{tag} ) . '"';
	$attributes .= ' dir="' . RIGHT_TO_LEFT . '"'
	    if $self->{dir} eq RIGHT_TO_LEFT;

	return $attributes;
}

# $self->marks($other):
#	The attributes that an element carries on a page of this
#	language when its text comes from the other language, per
#	WEB-LANGUAGE-11: the tag of the other language as lang, and its
#	direction as dir when the two directions differ. Each attribute
#	has a space in front of it. Text of the language of the page
#	takes no mark, because the html element carries that language.
sub marks ( $self, $other )
{
	return '' if $other->tag eq $self->{tag};

	my $marks = ' lang="' . App::FuguWeb::escape_attr( $other->tag ) . '"';
	$marks .= ' dir="' . $other->dir . '"'
	    unless $other->dir eq $self->{dir};

	return $marks;
}

1;
