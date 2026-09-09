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
our $VERSION = '0.5.0';

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
# the output, the escapes that guard a value on its way into HTML,
# the directory listing, and the prefix test.

# The configuration file, at the project root. The name and the
# discovery match .fuguvmrc.
use constant CONFIG_FILE => '.fuguwebrc';

# The stylesheet, as the output directory holds it and as every page
# links it. The site is served from one flat directory, so the name
# is a file name there.
use constant STYLESHEET => 'style.css';

# The staging directory for the mdoc sources, inside the output
# directory. The build makes it, uses it, and removes it again.
#
# The name lives here because two modules need it. The build owns the
# directory. The description must refuse a key directory of the same
# name, because the build would remove the published keys with the
# staging.
use constant STAGING_DIR => '.man';

# escape_html($text):
#	Escape the three characters that change the meaning of HTML
#	text: the ampersand first, so an escape that the function
#	itself writes is not escaped again.
#
#	The function takes bytes and returns bytes. No file in the
#	namespace carries 'use utf8', so a multi-byte character passes
#	through untouched.
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
#	A site is one flat directory of files, and the key directory
#	is the one part below it. The output therefore needs a walk of
#	the tree wherever a walk of one level served before.
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

1;
