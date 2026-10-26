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

package App::FuguWeb;
our $VERSION = '0.11.0';

# App::FuguWeb - a static documentation site for a Perl project.
#
# The tool renders mdoc(7) manuals, POD sidecars and Markdown into one
# site. A project describes its site in .fuguwebrc and needs no build
# recipe of its own.
#
# The namespace is an application, not a library. It uses Fugu:: and
# core Perl. It never uses another App:: namespace, and no sibling
# uses it: a sibling application is not a library.
#
# This file holds what more than one module in the namespace needs:
# the name of the configuration file, the name of the stylesheet in
# the output, the decode and the encode at each edge, the fold of a
# name, the escapes that guard a value on its way into HTML, the reader
# of an attribute, the directory listing, the prefix test, and the
# reader of a reference.
#
# Text is UTF-8 at each edge, and characters inside. The build decodes
# the description, each source and each output of a renderer, and it
# encodes each page that it writes. A name of a file stays bytes,
# because the file system reads bytes.

use Encode             ();
use Unicode::Normalize ();

# The configuration file, at the project root. The name and the
# discovery match .fuguvmrc.
use constant CONFIG_FILE => '.fuguwebrc';

# The stylesheet, as the output directory holds it. The sheet sits at
# the top level, outside every language tree, so one file serves each
# tree.
use constant STYLESHEET => 'style.css';

# The two pages of the top level, which a host serves. The forward
# sends a visitor of the root into the default tree. The top-level
# 404.html holds the body of the 404.html of each tree, and it answers
# each path that no file answers.
use constant {
	FORWARD_PAGE   => 'index.html',
	NOT_FOUND_PAGE => '404.html',
};

# The staging directory for the mdoc sources, inside the output
# directory. The build makes it, uses it, and removes it again.
#
# The name lives here because two modules need it. The build owns the
# directory. The description must refuse a key directory of the same
# name, because the build would remove the published keys with the
# staging.
use constant STAGING_DIR => '.man';

# decode($bytes, $name, $reason):
#	The characters of UTF-8 bytes, per WEB-SITE-5. The function
#	returns undef when the bytes are not UTF-8, with the reason in
#	$reason. The reason names the file or the output, and the
#	offset of the first byte that is wrong.
#
#	The decode is strict. It refuses an overlong form, a
#	surrogate, a noncharacter and a code point above U+10FFFF. The
#	quiet mode stops at the first fault and keeps the rest, so the
#	function needs no eval.
sub decode ( $bytes, $name, $reason )
{
	my $rest = $bytes;
	my $text = Encode::decode( 'UTF-8', $rest, Encode::FB_QUIET );
	return $text unless length $rest;

	my $at = length($bytes) - length($rest);
	$$reason = "$name is not valid UTF-8 at byte $at";

	return;
}

# encode($text):
#	The UTF-8 bytes of characters. Each page goes through here on
#	its way to the disk.
sub encode ($text)
{
	return Encode::encode( 'UTF-8', $text );
}

# as_text($bytes):
#	The characters of a name or a field that a page shows: a name
#	of the description, a name of a file, or a field of a key. The
#	description is UTF-8, per WEB-SITE-5, so each of its names
#	decodes. A name of a file that is not UTF-8 takes U+FFFD for
#	each wrong byte. Its link then names no file, and the check
#	reports it.
sub as_text ($bytes)
{
	return Encode::decode( 'UTF-8', $bytes );
}

# fold_name($name):
#	The fold of a name or a path of the output, per WEB-OUTPUT-17:
#	its characters in NFD, the canonical decomposition of Unicode,
#	then the full case fold of fc. A file system without case, such
#	as APFS on Darwin, keeps two names of one fold as one entry.
#	APFS joins an NFC name and its NFD form, two cases of a name,
#	and the sharp s U+00DF and SS. The fold joins each such pair.
#
#	The fold reads the Unicode version of this Perl. A file system
#	of an earlier version joins fewer pairs, and a guard then
#	refuses more than it must, which is safe. A file system of a
#	later version can fold a character that this Perl does not
#	know, and a guard then misses that pair.
sub fold_name ($name)
{
	return fc Unicode::Normalize::NFD( as_text($name) );
}

# escape_html($text):
#	Escape the three characters that change the meaning of HTML
#	text: the ampersand first, so an escape that the function
#	itself writes is not escaped again.
#
#	The function reads characters and returns characters. Each
#	character outside ASCII passes through, and the encode of the
#	page writes its bytes.
sub escape_html ($text)
{
	return '' unless defined $text;

	my $escaped = $text;
	$escaped =~ s/&/&amp;/g;
	$escaped =~ s/</&lt;/g;
	$escaped =~ s/>/&gt;/g;

	return $escaped;
}

# escape_attr($text):
#	Escape a value on its way into a double-quoted attribute. The
#	quote is the character that matters here: a value that holds
#	one ends the attribute early, and everything after it becomes
#	markup. escape_html alone does not guard an attribute.
sub escape_attr ($text)
{
	my $escaped = escape_html($text);
	$escaped =~ s/"/&quot;/g;

	return $escaped;
}

# The value of an attribute, in each of its three forms: in double
# quotes, in single quotes, and with no quotes.
my $VALUE = qr{"([^"]*)"|'([^']*)'|([^\s"'=<>`]+)}a;

# One attribute of a start tag, from the end of the attribute before
# it: the attribute as it stands, its name, and its value. The walk
# starts at the first attribute and steps over each value as a whole.
# So the text of a value, such as title="see id=x", is never an
# attribute. The space in front of the name keeps a name such as
# data-id out.
#
# HTML separates two attributes with ASCII white space alone, so \s
# takes the ASCII rule. A page that the check reads is bytes, and
# without the rule the last byte 0xA0 of a character such as U+00E0
# would end a value with no quotes.
my $ATTRIBUTE = qr{\G(\s+([^\s"'>/=]+)(?:\s*=\s*(?:$VALUE))?)}a;

# edit_attributes($attributes, $edit):
#	The attributes of a start tag, each one as the function returns
#	it. The function takes the attribute as it stands, its name, and
#	its value, or undef when it has none. A text after the last
#	attribute, such as a slash, stays. The fit of a fragment and the
#	check read each attribute here, so the two agree.
sub edit_attributes ( $attributes, $edit )
{
	return $attributes =~
	    s{$ATTRIBUTE}{ $edit->( $1, $2, $3 // $4 // $5 ) }ger;
}

# attribute($attributes, $name):
#	The value of the first attribute of the name in a start tag, or
#	undef when no attribute of the name has a value. The name is in
#	lowercase, and the name of the attribute compares in lowercase.
sub attribute ( $attributes, $name )
{
	my $value;
	edit_attributes(
		$attributes,
		sub ( $attribute, $has, $of ) {
			$value //= $of if lc $has eq $name;
			return $attribute;
		} );

	return $value;
}

# list_dir($dir):
#	The names in one directory, sorted, without '.' and '..'. The
#	function returns an array reference, or undef with the reason
#	in $!, so a caller can tell an empty directory from one it
#	cannot read.
#
#	The sort compares bytes and never reads the locale of the
#	builder: a site must not depend on the machine that built it.
sub list_dir ($dir)
{
	opendir my $dh, $dir or return;
	my @names = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
	closedir $dh;

	return \@names;
}

# list_tree($dir, $prefix):
#	Every leaf below the directory, as paths relative to it: each
#	file, each symlink, and each directory that holds nothing. The
#	function returns an array reference, or undef with the reason
#	in $!.
#
#	The function recurses into a plain directory, and never
#	through a symlink. A symlinked directory is one entry: the
#	build owns neither the target of the link nor what sits under
#	it.
#
#	An empty directory is a leaf, so a caller sees it. A walk that
#	answered with files alone would hide a stray directory from
#	the checks, and the clean refuses one.
#
#	Each language tree and each key directory sits below the top
#	level of a site. The output therefore needs a walk of the
#	tree wherever a walk of one level would serve one directory.
sub list_tree ( $dir, $prefix = '' )
{
	my $names = list_dir($dir) or return;

	my @paths;
	for my $name (@$names) {
		my $path     = "$dir/$name";
		my $relative = "$prefix$name";

		if ( -d $path && !-l $path ) {
			my $below = list_tree( $path, "$relative/" ) or return;
			push @paths, @$below ? @$below : $relative;
			next;
		}

		push @paths, $relative;
	}

	return \@paths;
}

# path_below($path, $root):
#	Report whether $path is $root or lies below it. A trailing
#	slash on either does not change the answer. Both paths must be
#	of the same kind: both absolute, or both relative to the same
#	directory.
sub path_below ( $path, $root )
{
	my $one = $path =~ s{/+$}{}r;
	my $two = $root =~ s{/+$}{}r;

	return 1 if $one eq $two;

	return index( $one, "$two/" ) == 0 ? 1 : 0;
}

# canonical_path($path):
#	The one form of a path from the project root: no '.' step, no
#	empty step, and no final solidus. The record of the
#	translations names each file in this form, per WEB-STATUS-1.
#	The form of the project root is the empty string.
sub canonical_path ($path)
{
	return join '/', grep { length && $_ ne '.' } split m{/}, $path;
}

# ref_parts($ref):
#	The path and the fragment of one reference. A query is no part
#	of the name of a file, so the path holds none, per WEB-LINKS-3.
#	The chrome and the check read each reference here, so the two
#	agree.
sub ref_parts ($ref)
{
	my ( $path, $fragment ) = split /#/, $ref, 2;
	$path = ( $path // '' ) =~ s{\?.*}{}sr;

	return ( $path, $fragment );
}

# resolve_ref($dir, $ref):
#	One relative reference, as a path below the output directory.
#	The reference is relative to the directory, which is a path
#	below the site root: a language tree, a key directory, or the
#	empty path of the top level.
sub resolve_ref ( $dir, $ref )
{
	my @parts = grep { length } split m{/}, $dir;

	for my $step ( split m{/}, $ref, -1 ) {
		next if $step eq '' || $step eq '.';
		if ( $step eq '..' ) {

			# A step above the site root names no file of
			# the output. A pop of an empty list does
			# nothing, so the reference would clamp to the
			# root and read like a link that resolves.
			return unless @parts;
			pop @parts;
			next;
		}
		push @parts, $step;
	}

	# A reference of './' names the directory of its own page, and
	# a directory is no page of a site. An empty answer also reads
	# as false in the walk of the reachability check. The walk
	# would then stop at the first page that holds one.
	return unless @parts;

	return join '/', @parts;
}

1;
