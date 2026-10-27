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

package App::FuguWeb::Config;
our $VERSION = '0.11.2';

use App::FuguWeb;
use App::FuguWeb::Keys;
use App::FuguWeb::Language;
use App::FuguWeb::Manual;
use File::Find ();
use Fugu::Config;
use Fugu::File;
use Fugu::KeyDir;
use Fugu::OpenPGP;

# App::FuguWeb::Config - the site description over Fugu::Config.
#
# The grammar, the quoting and the yes/no spellings come from
# Fugu::Config. This file holds what is true of a site: the settings
# and their defaults, the ordered navigation, the ordered pages, and
# the rules that a description must obey before a build reads it.
#
# The object is immutable once loaded. Two sites in one process
# therefore share nothing.

# The settings that a project may leave out, and what they mean when
# it does. 'site' and 'url' have no default: a site with no name or no
# address is a mistake, not a default.
use constant {
	DEFAULT_OUT_DIR     => 'web/build',
	DEFAULT_SOURCE_DIR  => 'web',
	DEFAULT_ENTRY       => 'index.html',
	DEFAULT_MODULE_ROOT => 'lib',
	DEFAULT_MAN_URL     => 'https://man.openbsd.org/',
};

# The settings that name a path inside the project. Each one is
# checked for a parent-directory step, because a build must write
# inside the project and read inside it.
my @PATH_SETTINGS = qw(out_dir source_dir module_root stylesheet footer);

# The settings of the description, per WEB-SITE-4. fuguwebrc(5)
# documents each one. A setting that the list does not name is a
# typo, and a typo that the parser swallows is a setting that
# silently does not apply. An old setting fails the same way.
my %SETTING = map { $_ => 1 } qw(
    site url footer out_dir source_dir entry module_root man_url
    stylesheet
);

# The block types of the description, and the settings of each
# default block, per WEB-SITE-4. fuguwebrc(5) and fuguweb-keys(7)
# document each one.
my %BLOCK = (
	language => [qw(name dir site footer)],
	nav      => [qw(label)],
	page     => [qw(title body markdown index unlinked)],
	manuals  => [qw(heading dir namespace)],
	modules  => [qw(heading dir)],
	keys     => [qw(org contact expires url)],
	key      => [qw(status since until email fingerprint)],
);

# The block types that take no translation. A language block names
# one language, and a key directory and a key hold no prose. A
# translation of either one would describe a second language, a
# second directory or a second key.
my @UNTRANSLATED = qw(language keys key);

# The three ways a page block names its content. Exactly one of them
# must appear. An index page can take a body as well, which opens it,
# per WEB-MANUALS-8.
my @PAGE_SOURCES = qw(body markdown index);

# The block types that take a translation, per WEB-LANGUAGE-6, and the
# settings that a translation of each one takes, per WEB-LANGUAGE-7.
# A translation holds the words of one language. Any other setting is
# a typo, or a value that no language can change.
my %TRANSLATION = (
	page    => [qw(title body markdown)],
	nav     => [qw(label)],
	manuals => [qw(heading dir)],
	modules => [qw(heading dir)],
);

# The shape of a group name, per WEB-MANUALS-7. The name is the anchor
# of the heading of the group on the index page, so it is one word
# that every language shares.
my $GROUP_NAME = qr/\A[a-z0-9-]+\z/;
my $GROUP_RULE =
    'a group name is one word of lowercase letters, digits and hyphens';

# The statuses that a key block may name. Fugu::KeyDir holds the
# vocabulary, so the two can never disagree.
my %KEY_STATUS = map { $_ => 1 } Fugu::KeyDir::STATUSES;

# The settings that the key block of each type takes, per WEB-KEYS-7
# and WEB-X509-4. An email address is the user id of an OpenPGP key,
# and a fingerprint names the bytes of an OpenPGP key or of a
# certificate. A signify key file holds its whole public key in one
# body line, so it takes neither. Either setting on a key of another
# type therefore describes another file.
my %TYPE_SETTING = (
	signify => {},
	openpgp => { email       => 1, fingerprint => 1 },
	x509    => { fingerprint => 1 },
);

# The width of the fingerprint of each type that takes one. An
# OpenPGP fingerprint holds 40 hexadecimal characters, and the
# SHA-256 of the DER of a certificate holds 64.
my %FINGERPRINT_WIDTH = (
	openpgp => 40,
	x509    => 64,
);

# A timestamp of RFC 3339, which is what the Expires field of
# security.txt holds. The pattern takes a Z and a numeric offset, and
# it takes an optional fraction of a second.
my $RFC3339 = qr{
	\A
	[0-9]{4} - [0-9]{2} - [0-9]{2}
	[Tt]
	[0-9]{2} : [0-9]{2} : [0-9]{2} (?: \.[0-9]+ )?
	(?: [Zz] | [+-][0-9]{2}:[0-9]{2} )
	\z
}x;

# App::FuguWeb::Config->load(%args):
#	root  => $dir		the project root (default: discover)
#	error => \$reason	where the failure message goes
#
#	Read and validate the description. The method returns the
#	object, or undef with the reason in $reason. Every message
#	names the file, and the block when a block is at fault.
#
#	The reason travels through a reference because the object that
#	would hold it does not exist when the load fails. The module
#	keeps no package state for it: two sites in one process must
#	not share a failure.
sub load ( $class, %args )
{
	my $reason = $args{error} // \my $ignored;

	my $root = $args{root}
	    // Fugu::Config->find_project_root(App::FuguWeb::CONFIG_FILE);
	unless ( defined $root ) {
		$$reason =
		      'Not in a FuguWeb project: no '
		    . App::FuguWeb::CONFIG_FILE
		    . ' above the working'
		    . " directory. Run 'fuguweb init' first.";
		return;
	}

	my $path = "$root/" . App::FuguWeb::CONFIG_FILE;
	unless ( -f $path ) {
		$$reason = "Cannot read $path: no such file";
		return;
	}

	my $file = Fugu::Config->new( file => $path );
	unless ( $file->load ) {
		$$reason = $file->error;
		return;
	}

	# WEB-SITE-5. The parse reads bytes, so the load holds the whole
	# description to UTF-8 here. Each value of it then decodes.
	my $bytes = Fugu::File->read($path);
	unless ( defined $bytes ) {
		$$reason = "Cannot read $path";
		return;
	}
	App::FuguWeb::decode( $bytes, $path, $reason ) // return;

	my $self = bless {
		root        => $root,
		path        => $path,
		file        => $file,
		nav         => {},
		page        => {},
		group       => [],
		translation => {},
		keys_order  => [],
		keys_block  => {},
	}, $class;

	$self->_check_words($reason)       or return;
	$self->_apply_settings($reason)    or return;
	$self->_read_languages($reason)    or return;
	$self->_read_translations($reason) or return;
	$self->_read_nav($reason)          or return;
	$self->_read_pages($reason)        or return;
	$self->_read_groups($reason)       or return;
	$self->_check_paths($reason)       or return;
	$self->_check_pages($reason)       or return;
	$self->_check_sources($reason)     or return;
	$self->_read_keys($reason)         or return;

	return $self;
}

# App::FuguWeb::Config->anonymous($root):
#	A description that names nothing but the project root.
#
#	'fuguweb clean --out <dir>' uses it. Removing a directory that
#	the caller named needs a project root and nothing else, and
#	clean is the command an operator reaches for when the
#	description is the thing that is broken.
sub anonymous ( $class, $root )
{
	# The object holds no page, no manual and no key block, so the
	# inventory is empty. The clean then accepts the files of the
	# top level and of the declared language trees, which it reads
	# by shape, and no more. A default of a content setting here
	# would make a clean believe that a description named a
	# directory.
	#
	# It does read the names of the file that did not load: the
	# source directory, the output directory, the tag of each
	# language block, and the name and org of each keys block.
	# Fugu::Config keeps every setting and block that it parsed
	# before the fault, and a broken block is usually the last one.
	# Those names decide which target the guard refuses, and which
	# trees the clean takes. A guard that read a default instead
	# would refuse the wrong directory of the project.
	#
	# A fault above a keys block hides it. The clean then refuses
	# the key tree of its own output, which is the safe answer,
	# and the operator removes that tree by hand. A fault above a
	# language block hides that tree the same way.
	my $self = bless {
		root       => $root,
		languages  => [ _english() ],
		group      => [],
		keys_order => [],
		keys_block => {},
	}, $class;

	my $path = "$root/" . App::FuguWeb::CONFIG_FILE;
	return $self unless -f $path;

	my $file = Fugu::Config->new( file => $path );
	$file->load;

	$self->{source_dir} = $file->get( 'source_dir', DEFAULT_SOURCE_DIR );
	$self->{out_dir}    = $file->get( 'out_dir',    DEFAULT_OUT_DIR );

	# WEB-LANGUAGE-4. A file that declares no language has the one
	# language en, as a description that loads does.
	my @tags = grep { App::FuguWeb::Language::is_tag($_) }
	    map { $_->{name} } $file->blocks('language');
	$self->{languages} =
	    [ map { App::FuguWeb::Language->new( tag => $_ ) } @tags ]
	    if @tags;

	# The org as well as the name. The org pins a key file to this
	# organization, so a guard without it would take the published
	# key of another one.
	for my $keys ( $file->blocks('keys') ) {
		my $name = $keys->{name};
		next unless defined $name && length $name;
		next if $self->{keys_block}{$name};

		push @{ $self->{keys_order} }, $name;
		$self->{keys_block}{$name} =
		    { org => $keys->{settings}{org} };
	}

	return $self;
}

# $self->root, $self->path:
#	The project root, and the description that this object read.
sub root ($self) { return $self->{root}; }
sub path ($self) { return $self->{path}; }

# The settings. Each one is a plain accessor over the merged value, so
# a caller never repeats a default. The site name is characters, and
# every other setting is a name of a file or an address, so it stays
# bytes.
sub site        ($self) { return $self->{site}; }
sub url         ($self) { return $self->{url}; }
sub out_dir     ($self) { return $self->{out_dir}; }
sub source_dir  ($self) { return $self->{source_dir}; }
sub entry       ($self) { return $self->{entry}; }
sub module_root ($self) { return $self->{module_root}; }
sub man_url     ($self) { return $self->{man_url}; }
sub stylesheet  ($self) { return $self->{stylesheet}; }

# $self->url_path:
#	The path of the url: the part after the host, which starts and
#	ends with a solidus. It is the base href of a page of the top
#	level, per WEB-TOP-3, so each relative link of that page
#	resolves from the site root.
sub url_path ($self)
{
	return $self->{url} =~ s{\Ahttps?://[^/]+}{}r;
}

# $self->keys_dirs:
#	The name of each key directory, in file order. The list is
#	empty for a description that holds no keys block, so it is the
#	test for one.
#
#	A site publishes as many key directories as the description
#	names. Each one holds its own root of trust, per D-02, and a
#	binding never crosses a directory.
sub keys_dirs ($self)
{
	return @{ $self->{keys_order} // [] };
}

# The settings of one key directory. Each accessor takes the name of
# the directory, and each one answers undef for a name that no keys
# block holds.
sub keys_org ( $self, $dir ) { return $self->_keys_setting( $dir, 'org' ); }

sub keys_contact ( $self, $dir )
{
	return $self->_keys_setting( $dir, 'contact' );
}

sub keys_expires ( $self, $dir )
{
	return $self->_keys_setting( $dir, 'expires' );
}

sub keys_url ( $self, $dir ) { return $self->_keys_setting( $dir, 'url' ); }

# $self->_keys_setting($dir, $name):
#	One setting of the keys block of the directory.
sub _keys_setting ( $self, $dir, $name )
{
	return unless defined $dir;

	my $block = $self->{keys_block}{$dir} or return;

	return $block->{$name};
}

# $self->keys_path($dir, $name):
#	The path of a file in the source key directory, or of the
#	directory itself when the caller names nothing. The method
#	answers undef for a name that no keys block holds.
sub keys_path ( $self, $dir, $name = undef )
{
	return unless defined $dir && $self->{keys_block}{$dir};

	my $path = $self->source_path($dir);

	return defined $name ? "$path/$name" : $path;
}

# $self->site_keys($dir):
#	The key blocks of one key directory, in file order. Each entry
#	is a hash reference with name, stem, type, serial, purpose,
#	status, since, until, email and fingerprint. The name is the
#	key file, and the stem is the block name.
#
#	The list is named site_keys and not keys, because a method
#	named keys in this package makes every call of the builtin
#	ambiguous.
sub site_keys ( $self, $dir )
{
	my $block = $self->{keys_block}{ $dir // '' } // {};

	return @{ $block->{key} // [] };
}

# $self->site_bindings($dir):
#	The binding files of one key directory, in name order. Each
#	entry is a hash reference with name, target, signer and type.
#	The target and the signer are key file names, and the type is
#	the type of the signer.
#
#	A binding carries no block: its name holds every field, and
#	Fugu::KeyDir parses it. The list holds a binding whose target
#	and whose signer are both keys of the same directory, so the
#	checks report every other name as a stray file.
sub site_bindings ( $self, $dir )
{
	my $block = $self->{keys_block}{ $dir // '' } // {};

	return @{ $block->{binding} // [] };
}

# $self->source_path($name):
#	The path of a file in the source directory, or of the
#	directory itself when the caller names nothing.
sub source_path ( $self, $name = undef )
{
	my $dir = "$self->{root}/$self->{source_dir}";

	return defined $name ? "$dir/$name" : $dir;
}

# $self->nav($tag):
#	The navigation of one language, in file order. Each entry is a
#	hashref with href, label and label_lang. The label is
#	characters, and the label_lang is the tag of the language that
#	it comes from, per WEB-LANGUAGE-8. The tag defaults to that of
#	the default language.
sub nav ( $self, $tag = undef )
{
	$tag //= $self->default_language->tag;

	return @{ $self->{nav}{$tag} // [] };
}

# $self->pages($tag):
#	The pages of one language, in file order. Each entry is a
#	hashref with file, title, source, value, unlinked, lang and
#	title_lang. The source is one of body, markdown or index. The
#	value is what that source names, and the body that opens an
#	index page. The lang is the tag of the language of that value:
#	the tag of the page when its translation names the value, and
#	the default tag when the page takes it from the default block,
#	per WEB-LANGUAGE-8. The title is characters, and the title_lang
#	is the tag of its language, by the same rule. The tag defaults
#	to that of the default language.
sub pages ( $self, $tag = undef )
{
	$tag //= $self->default_language->tag;

	return @{ $self->{page}{$tag} // [] };
}

# $self->assets:
#	The names of the files in the source directory that the build
#	copies as they stand, sorted. An asset is any file there that
#	the build does not render: not a body fragment, not Markdown,
#	and not a dot file.
#
#	Thus robots.txt and CNAME need no entry in the description, and
#	a CLAUDE.md beside them is not published. Markdown in the
#	source directory is either a page source, which a page block
#	names and lowdown renders, or notes for the maintainers.
#	Neither belongs in the output as it stands.
#
#	The build and the checks read the same list, so the two can
#	never disagree about what the site holds.
sub assets ($self)
{
	my $dir = $self->source_path;
	return () unless -d $dir;

	my $names = App::FuguWeb::list_dir($dir) or return ();

	return
	    grep { !/^\./ && !/\.body\.html$/ && !/\.md$/ && -f "$dir/$_" }
	    @$names;
}

# $self->languages:
#	Each language of the site, as an App::FuguWeb::Language, in the
#	order of the declaration. The first one is the default, per
#	D-05. Each one names a tree of the output, per WEB-LANGUAGE-5.
sub languages ($self)
{
	return @{ $self->{languages} };
}

# $self->default_language:
#	The first language of the declaration, per D-05.
sub default_language ($self)
{
	return $self->{languages}[0];
}

# $self->language($tag):
#	The declared language of the tag, or undef.
sub language ( $self, $tag )
{
	my ($language) = grep { $_->tag eq $tag } $self->languages;

	return $language;
}

# $self->page_names:
#	The name of each page of one tree: the pages of the
#	description, then one page for each manual of each group. Each
#	tree holds the same names, so the list takes no language.
sub page_names ($self)
{
	return ( map { $_->{file} } $self->pages ),
	    ( map { $_->page } map { $_->manuals } $self->groups );
}

# $self->top_pages:
#	The pages of the top level, which a host serves: the forward
#	to the default tree, and the top-level 404.html when the
#	description holds that page.
sub top_pages ($self)
{
	my $not_found = App::FuguWeb::NOT_FOUND_PAGE;

	return App::FuguWeb::FORWARD_PAGE,
	    grep { $_ eq $not_found } map { $_->{file} } $self->pages;
}

# $self->inventory:
#	Every name that the output directory must hold after a build:
#	each page of each tree, the pages of the top level, the
#	stylesheet, the assets, and every path of the key directory.
#	The build and the checks read the same list, so the two can
#	never disagree about what the site holds.
#
#	A page of a tree is <path>/<page>, where the path is that of the
#	tree of its language. The pages of the top level, the
#	stylesheet and the assets are one segment. Each key directory
#	is one part below the root, so its entries hold a solidus.
sub inventory ($self)
{
	my @names = $self->page_names;

	return (
		map {
			my $path = $_->path;
			map { "$path/$_" } @names
		} $self->languages
	    ),
	    $self->top_pages, App::FuguWeb::STYLESHEET, $self->assets,
	    $self->key_paths;
}

# $self->key_paths:
#	Every path of every key directory in the output, relative to
#	the output directory, or the empty list when the description
#	holds no keys block. The paths hold a solidus: a key directory
#	is one part of a site that is not one flat directory.
#
#	Two directories share the well-known tree: they serve one
#	policy file, and one file for an address that both name. The
#	list holds each path once, because it is the inventory of the
#	output and the output holds one file for one path.
sub key_paths ($self)
{
	my %seen;

	return grep { !$seen{$_}++ }
	    map { App::FuguWeb::Keys->new( config => $self, dir => $_ )->paths }
	    $self->keys_dirs;
}

# $self->groups:
#	The manual groups, in file order. Each entry is an
#	App::FuguWeb::Config::Group.
sub groups ($self)
{
	return @{ $self->{group} };
}

# $self->_check_words($reason):
#	Refuse each block type and each setting that fuguwebrc(5) and
#	fuguweb-keys(7) do not document, per WEB-SITE-4. The message
#	names the block and the word. A translation takes the settings
#	of its own list, and _read_translations holds it to that list.
sub _check_words ( $self, $reason )
{
	my $file = $self->{file};

	for my $name ( $file->setting_names ) {
		next if $SETTING{$name};
		return $self->_fail( $reason,
			"the description names the unknown setting $name" );
	}

	# The first block of an unknown type in the file is the one that
	# the message names.
	my ($stranger) =
	    sort { $a->{order} <=> $b->{order} }
	    map  { $file->blocks($_) }
	    grep { !$BLOCK{$_} } $file->block_types;
	if ($stranger) {
		return $self->_fail( $reason,
			_label($stranger)
			    . " names the unknown block type $stranger->{type}"
		);
	}

	for my $type (@UNTRANSLATED) {
		for my $block ( $file->blocks($type) ) {
			next if @{ $block->{args} } == 1;

			return $self->_fail( $reason,
				      _label($block)
				    . " takes more than a name, and a $type"
				    . ' block takes no translation' );
		}
	}

	for my $type ( sort keys %BLOCK ) {
		my %takes = map { $_ => 1 } @{ $BLOCK{$type} };

		for my $block ( $self->_defaults($type) ) {
			for my $key ( sort keys %{ $block->{settings} } ) {
				next if $takes{$key};
				return $self->_fail( $reason,
					_label($block)
					    . " names the unknown setting $key"
				);
			}
		}
	}

	return $self;
}

# $self->_apply_settings($reason):
#	Copy each setting out of the parse, with its default. The site
#	name is characters, and each other setting stays bytes.
sub _apply_settings ( $self, $reason )
{
	my $file = $self->{file};

	# WEB-SITE-2. The site name of each language whose block names
	# none, per WEB-LANGUAGE-3.
	my $site = $file->get('site');
	unless ( defined $site && length $site ) {
		return $self->_fail( $reason, 'no site setting' );
	}
	$self->{site} = App::FuguWeb::as_text($site);

	# WEB-SITE-1. The absolute URL of the site root. A link of the
	# head names a page as this URL and the path of the page, so
	# the URL ends in a solidus.
	my $url = $file->get('url');
	unless ( defined $url ) {
		return $self->_fail( $reason, 'no url setting' );
	}
	unless ( $url =~ m{\Ahttps?://[^/\s]+(?:/\S*)?\z} && $url =~ m{/\z} ) {
		return $self->_fail( $reason,
			      "url is $url, which is not an absolute URL of"
			    . ' https or http that ends in a solidus' );
	}
	$self->{url} = $url;

	# WEB-SITE-3. The footer fragment of each language whose block
	# names none, per WEB-LANGUAGE-3, below the source directory.
	$self->{footer} = $file->get('footer');

	$self->{out_dir}     = $file->get( 'out_dir',     DEFAULT_OUT_DIR );
	$self->{source_dir}  = $file->get( 'source_dir',  DEFAULT_SOURCE_DIR );
	$self->{entry}       = $file->get( 'entry',       DEFAULT_ENTRY );
	$self->{module_root} = $file->get( 'module_root', DEFAULT_MODULE_ROOT );

	# A trailing slash would survive into the prefix that a module
	# name drops, and the name would then keep the whole path.
	$self->{module_root} =~ s{/+$}{};
	$self->{man_url}    = $file->get( 'man_url', DEFAULT_MAN_URL );
	$self->{stylesheet} = $file->get('stylesheet');

	return $self;
}

# $self->_read_languages($reason):
#	Read each language block, in file order, per WEB-LANGUAGE. The
#	first one is the default, per D-05. A description with no
#	language block has the one language en, per WEB-LANGUAGE-4.
#
#	A language takes the site and the footer of its own block, and
#	those of the description where its block holds none, per
#	WEB-LANGUAGE-3 and WEB-LANGUAGE-8. The description holds the
#	words of the default language, so each value that a language
#	takes from it is of that language.
sub _read_languages ( $self, $reason )
{
	my @blocks = $self->{file}->blocks('language');
	unless (@blocks) {
		$self->{languages} = [
			_english(
				site   => $self->{site},
				footer => $self->{footer} ) ];
		return $self;
	}

	my ( @languages, %seen );
	for my $block (@blocks) {
		my $tag      = $block->{name};
		my $settings = $block->{settings};
		my $label    = _label($block);

		# WEB-LANGUAGE-1. The tag names the language in the
		# path, in lang and in hreflang, per D-05.
		unless ( App::FuguWeb::Language::is_tag($tag) ) {
			return $self->_fail( $reason,
				      "$label names no BCP 47 tag in its"
				    . ' canonical case, such as en, zh-Hans or'
				    . ' pt-BR' );
		}
		if ( $seen{$tag}++ ) {
			return $self->_fail( $reason,
				"$label is declared twice" );
		}

		# WEB-LANGUAGE-2.
		my $name = $settings->{name};
		unless ( defined $name && length $name ) {
			return $self->_fail( $reason, "$label has no name" );
		}

		my $dir = $settings->{dir}
		    // App::FuguWeb::Language::LEFT_TO_RIGHT;
		unless (   $dir eq App::FuguWeb::Language::LEFT_TO_RIGHT
			|| $dir eq App::FuguWeb::Language::RIGHT_TO_LEFT )
		{
			return $self->_fail( $reason,
				"$label sets dir to $dir; use ltr or rtl" );
		}

		my $footer = $settings->{footer};
		if ( _has_parent_step($footer) ) {
			return $self->_fail( $reason,
"$label footer is $footer, which leaves the project"
			);
		}

		# WEB-LANGUAGE-3. The value of the block, or the value of
		# the description when the block names none. The
		# description holds the words of the default language.
		my $default = @languages ? $languages[0]->tag : $tag;
		my $site    = $settings->{site};

		push @languages,
		    App::FuguWeb::Language->new(
			tag  => $tag,
			name => App::FuguWeb::as_text($name),
			dir  => $dir,
			site => defined $site
			? App::FuguWeb::as_text($site)
			: $self->{site},
			site_lang   => defined $site ? $tag : $default,
			footer      => $footer // $self->{footer},
			footer_lang => defined $footer ? $tag : $default,
		    );
	}

	$self->{languages} = \@languages;

	return $self;
}

# _english(%values):
#	The language en, which a description that declares none has,
#	per WEB-LANGUAGE-4. It holds the site name and the footer of
#	the description.
sub _english (%values)
{
	return App::FuguWeb::Language->new(
		tag => App::FuguWeb::Language::ENGLISH,
		%values
	);
}

# $self->_read_translations($reason):
#	Sort the blocks into the defaults and the translations, per
#	WEB-LANGUAGE-6. A block of one argument is the default. A block
#	of two is a translation: the first argument is the tag of its
#	language, and the second names the default that it translates.
#	The method keeps each translation by type, name and tag, and
#	the readers below read the defaults alone.
sub _read_translations ( $self, $reason )
{
	my %declared = map { $_->tag => 1 } $self->languages;
	my $default  = $self->default_language->tag;

	for my $type ( sort keys %TRANSLATION ) {
		my %default = map { $_->{name} => 1 } $self->_defaults($type);
		my %takes   = map { $_         => 1 } @{ $TRANSLATION{$type} };

		my @set  = @{ $TRANSLATION{$type} };
		my $last = pop @set;
		my $set  = @set ? join( ', ', @set ) . " and $last" : $last;

		for my $block ( $self->{file}->blocks($type) ) {
			my @args = @{ $block->{args} };
			next if @args == 1;

			my $label = _label($block);
			my ( $tag, $name ) = @args;

			if ( @args > 2 ) {
				return $self->_fail( $reason,
					      "$label takes "
					    . scalar(@args)
					    . ' arguments, and a translation takes'
					    . ' a language tag and a name' );
			}

			# WEB-LANGUAGE-6. The tag names a declared language,
			# and the default block holds the words of the
			# default one.
			unless ( $declared{$tag} ) {
				return $self->_fail( $reason,
					      "$label names the language $tag,"
					    . ' and no language block declares it'
				);
			}
			if ( $tag eq $default ) {
				return $self->_fail( $reason,
					      "$label names $tag, which is the"
					    . ' default language; the default'
					    . ' block holds it' );
			}

			unless ( $default{$name} ) {
				return $self->_fail( $reason,
					"$label translates no $type block,"
					    . " because no $type \"$name\""
					    . ' stands in the description' );
			}
			if ( $self->{translation}{$type}{$name}{$tag} ) {
				return $self->_fail( $reason,
					"$label is declared twice" );
			}

			for my $key ( sort keys %{ $block->{settings} } ) {
				next if $takes{$key};

				return $self->_fail( $reason,
					"$label names the setting $key, and"
					    . " a translation of a $type block"
					    . " takes $set" );
			}

			$self->{translation}{$type}{$name}{$tag} =
			    $block->{settings};
		}
	}

	return $self;
}

# $self->_defaults($type):
#	The default blocks of one type, in file order: each block of
#	one argument. A translation takes two, and a block of more
#	fails in _read_translations.
sub _defaults ( $self, $type )
{
	return grep { @{ $_->{args} } == 1 } $self->{file}->blocks($type);
}

# $self->_merged($block, $tag):
#	The settings of a default block in one language, per
#	WEB-LANGUAGE-8: each value of its translation, and the value of
#	the default where the translation holds none. The method also
#	returns the label that a message names, and the settings of the
#	translation alone. Those are empty for the default language,
#	and for a block that the language does not translate.
sub _merged ( $self, $block, $tag )
{
	my $own =
	    $self->{translation}{ $block->{type} }{ $block->{name} }{$tag};

	return ( $block->{settings}, _label($block), {} )
	    if $tag eq $self->default_language->tag || !$own;

	return ( { %{ $block->{settings} }, %$own },
		qq{$block->{type} $tag "$block->{name}"}, $own );
}

# $self->_from($own, $key, $tag):
#	The tag of the language of one value of a block in the language
#	of the tag, per WEB-LANGUAGE-8: that tag when the translation
#	names the value, and the default tag when the value comes from
#	the default block.
sub _from ( $self, $own, $key, $tag )
{
	return defined $own->{$key} ? $tag : $self->default_language->tag;
}

# $self->_read_nav($reason):
#	Collect the nav blocks in file order, once for each language.
sub _read_nav ( $self, $reason )
{
	for my $block ( $self->_defaults('nav') ) {
		my $href = $block->{name};

		for my $tag ( map { $_->tag } $self->languages ) {
			my ( $settings, $label, $own ) =
			    $self->_merged( $block, $tag );

			my $text = $settings->{label};
			unless ( defined $text && length $text ) {
				return $self->_fail( $reason,
					"$label has no label" );
			}

			push @{ $self->{nav}{$tag} },
			    {
				href       => $href,
				label      => App::FuguWeb::as_text($text),
				label_lang =>
				    $self->_from( $own, 'label', $tag ),
			    };
		}
	}

	return $self;
}

# $self->_read_pages($reason):
#	Collect the page blocks in file order, once for each language.
#	No two blocks name the same output file, and each language
#	holds the same files, per WEB-LANGUAGE-5.
sub _read_pages ( $self, $reason )
{
	my %seen;

	for my $block ( $self->_defaults('page') ) {
		my $name = $block->{name};

		# The block name becomes a file in the output directory,
		# so it is a path and gets the same guard the sources
		# get. Without it a page block writes anywhere the
		# builder can write.
		if ( my $why = _unsafe_output_name($name) ) {
			return $self->_fail( $reason, "page \"$name\" $why" );
		}

		# Each language tree is one flat directory of pages. A
		# name with a solidus would write into a directory below
		# the tree, and the build would fail at the write with
		# a reason that names no page.
		if ( $name =~ m{/} ) {
			return $self->_fail( $reason,
				      "page \"$name\" holds a solidus, and a"
				    . ' tree is one flat directory of pages' );
		}

		# Two names of one fold are one file on a file system
		# without case, per WEB-OUTPUT-17.
		if ( $seen{ App::FuguWeb::fold_name($name) }++ ) {
			return $self->_fail( $reason,
				"page \"$name\" is declared twice" );
		}

		for my $tag ( map { $_->tag } $self->languages ) {
			my ( $settings, $label, $own ) =
			    $self->_merged( $block, $tag );

			my $entry =
			    $self->_page( $reason, $label, $name, $settings )
			    or return;

			# WEB-LANGUAGE-8. A body or a title that the
			# translation does not name comes from the default
			# block.
			$entry->{lang} =
			    ( grep { defined $own->{$_} } qw(body markdown) )
			    ? $tag
			    : $self->default_language->tag;
			$entry->{title_lang} =
			    $self->_from( $own, 'title', $tag );

			push @{ $self->{page}{$tag} }, $entry;
		}
	}

	return $self;
}

# $self->_page($reason, $label, $name, $settings):
#	One page of one language, or undef with the reason. The
#	settings name exactly one source. An index page can take a body
#	as well, which opens it, per WEB-MANUALS-8.
sub _page ( $self, $reason, $label, $name, $settings )
{
	my @named = grep { defined $settings->{$_} } @PAGE_SOURCES;
	@named = grep { $_ ne 'body' } @named if defined $settings->{index};

	unless ( @named == 1 ) {
		my $what =
		    @named
		    ? 'names ' . join ' and ', @named
		    : 'names no source (body, markdown or index)';
		return $self->_fail( $reason, "$label $what" );
	}

	my $source = $named[0];
	if ( $source eq 'index'
		&& !$self->{file}->parse_bool( $settings->{index}, 0 ) )
	{
		return $self->_fail( $reason,
			      "$label sets index to $settings->{index};"
			    . ' the index source needs yes' );
	}

	# The value of an index page is the body that opens it, which
	# the page can leave out.
	my $key   = $source eq 'index' ? 'body' : $source;
	my $value = $settings->{$key};
	if ( _has_parent_step($value) ) {
		return $self->_fail( $reason,
			"$label $key names $value, which leaves the project" );
	}

	# A yes/no setting that does not parse is a typo, and a typo
	# that the parser swallows is a setting that silently does not
	# apply.
	my $unlinked = $self->{file}->parse_bool( $settings->{unlinked}, 0 );
	if ( $self->{file}->error ) {
		return $self->_fail( $reason,
			      "$label sets unlinked to"
			    . " $settings->{unlinked}; use yes or no" );
	}

	return {
		file   => $name,
		title  => App::FuguWeb::as_text( $settings->{title} // $name ),
		source => $source,
		value  => $value,
		unlinked => $unlinked,
	};
}

# The two block types that describe a manual group, and the kind that
# each one produces.
my %GROUP_BLOCK = ( manuals => 'manuals', modules => 'modules' );

# $self->_read_groups($reason):
#	Collect the default manuals and modules blocks, in file order,
#	and give each group the translations of its block. A group
#	whose directory does not exist is an error: a silent empty
#	group hides a typo in a path, and a rename that nothing catches
#	is what this file exists to prevent.
sub _read_groups ( $self, $reason )
{
	# The two types interleave as the file wrote them, so the order
	# key decides and not the type.
	my @blocks =
	    sort { $a->{order} <=> $b->{order} }
	    map { $self->_defaults($_) } sort keys %GROUP_BLOCK;

	my %seen;
	for my $block (@blocks) {
		my $name     = $block->{name};
		my $settings = $block->{settings};
		my $kind     = $GROUP_BLOCK{ $block->{type} };
		my $label    = _label($block);

		$self->_group_name( $reason, $block ) or return;

		# WEB-MANUALS-7. The name is the anchor of a heading on
		# the index page, and the manuals and the modules groups
		# share that page.
		if ( defined $seen{$name} ) {
			return $self->_fail( $reason,
				      "$seen{$name} and $label share one name,"
				    . ' and a group name is the anchor of one'
				    . ' heading' );
		}
		$seen{$name} = $label;

		my $heading = $settings->{heading};
		unless ( defined $heading && length $heading ) {
			return $self->_fail( $reason, "$label has no heading" );
		}
		$heading = App::FuguWeb::as_text($heading);

		my $dir = $settings->{dir};
		$self->_group_dir( $reason, $label, $dir ) or return;

		# The namespace prefixes a manual name, and that name
		# becomes both the staged file and the published page.
		# It is a name, so it may not hold a path separator.
		my $namespace = $settings->{namespace};
		if ( defined $namespace && $namespace =~ m{/} ) {
			return $self->_fail( $reason,
				      "$label namespace is $namespace, which"
				    . ' holds a path separator' );
		}

		# A modules group turns a path below the module root
		# into a Perl name. A directory outside that root has no
		# name to turn into, and the build would publish the
		# whole absolute path instead.
		if ( $kind eq 'modules'
			&& !App::FuguWeb::path_below( $dir,
				$self->{module_root} ) )
		{
			return $self->_fail( $reason,
				      "$label names $dir, which is not below"
				    . " the module root $self->{module_root}" );
		}

		my $group = App::FuguWeb::Config::Group->new(
			kind        => $kind,
			name        => $name,
			heading     => $heading,
			lang        => $self->default_language->tag,
			dir         => "$self->{root}/$dir",
			namespace   => $namespace,
			module_root => "$self->{root}/$self->{module_root}",
		);
		$self->_translate_group( $reason, $block, $group ) or return;

		push @{ $self->{group} }, $group;
	}

	return $self;
}

# $self->_group_name($reason, $block):
#	Hold the name of a default group block to WEB-MANUALS-7. The
#	name is the anchor of the heading of the group, so it is one
#	word that every language shares.
sub _group_name ( $self, $reason, $block )
{
	return $self if $block->{name} =~ $GROUP_NAME;

	return $self->_fail( $reason,
		_label($block) . " has no group name: $GROUP_RULE" );
}

# $self->_group_dir($reason, $label, $dir):
#	Hold the dir of a group block, or of a translation of one, to
#	the project. A group whose directory does not exist is an
#	error, because a silent empty group hides a typo in a path.
sub _group_dir ( $self, $reason, $label, $dir )
{
	unless ( defined $dir && length $dir ) {
		return $self->_fail( $reason, "$label has no dir" );
	}
	if ( _has_parent_step($dir) ) {
		return $self->_fail( $reason,
			"$label dir is $dir, which leaves the project" );
	}
	unless ( -d "$self->{root}/$dir" ) {
		return $self->_fail( $reason,
			"$label names $dir, which is not a directory" );
	}

	return $self;
}

# $self->_translate_group($reason, $block, $group):
#	Give the group the heading and the dir of each translation of
#	its block. A translation dir mirrors the default dir, so each
#	source of it must have a namesake there, per WEB-LANGUAGE-9.
sub _translate_group ( $self, $reason, $block, $group )
{
	for my $tag ( map { $_->tag } $self->languages ) {
		my ( $settings, $label, $own ) = $self->_merged( $block, $tag );
		next unless %$own;

		unless ( length $settings->{heading} ) {
			return $self->_fail( $reason, "$label has no heading" );
		}

		my $dir = $own->{dir};
		if ( defined $dir ) {
			$self->_group_dir( $reason, $label, $dir ) or return;
		}

		$group->translate(
			$tag,
			heading => App::FuguWeb::as_text( $own->{heading} ),
			dir     => defined $dir ? "$self->{root}/$dir" : undef,
		);

		my $orphan = $group->orphan($tag);
		next unless defined $orphan;

		my $mirror = $block->{settings}{dir};
		$orphan =~ s{\A\Q$self->{root}\E/}{};

		return $self->_fail( $reason,
			      "$label holds $orphan, which has no namesake in"
			    . " $mirror; a translation dir mirrors the"
			    . ' default dir' );
	}

	return $self;
}

# $self->_read_keys($reason):
#	Read each keys block and the key blocks that they hold. A
#	description with no keys block builds a site with no key
#	directory, so every description that predates the key
#	directory keeps its behavior.
#
#	The method resolves each key block to the key file that it
#	names. The build and the checks then read one list, and
#	neither one repeats the file name pattern.
sub _read_keys ( $self, $reason )
{
	my @blocks = $self->{file}->blocks('keys');
	unless (@blocks) {

		# A key block with no keys block names a directory that
		# nothing publishes. The description means to publish a
		# key, and a misspelled keys block would swallow the
		# whole directory in silence.
		my @orphan = $self->{file}->blocks('key');
		return $self unless @orphan;

		return $self->_fail( $reason,
			      "key \"$orphan[0]{name}\" stands with no keys"
			    . ' block' );
	}

	for my $block (@blocks) {
		$self->_read_keys_block( $reason, $block ) or return;
	}

	return $self->_read_key_blocks($reason);
}

# $self->_read_keys_block($reason, $block):
#	Read the settings of the keys block, and hold the source
#	directory to the rules of a path in the output.
sub _read_keys_block ( $self, $reason, $block )
{
	my $name     = $block->{name};
	my $settings = $block->{settings};

	# The block name becomes a directory in the source tree and in
	# the output. It is a path, so it gets the guard that a page
	# name gets. It is also one segment: the published prefix is
	# one directory, and the index page links its keys beside it.
	if ( my $why = _unsafe_output_name($name) ) {
		return $self->_fail( $reason, "keys \"$name\" $why" );
	}
	if ( $name =~ m{/} ) {
		return $self->_fail( $reason,
			      "keys \"$name\" holds a solidus, and the key"
			    . ' directory is one segment below the source'
			    . ' directory' );
	}

	# A single dot names the directory itself. The inventory would
	# then hold './KEYS' where the tree holds 'KEYS', and the build
	# would remove the file that it wrote in the same run. Two dots
	# never reach here, because _unsafe_output_name answers first.
	if ( $name eq '.' ) {
		return $self->_fail( $reason,
			      "keys \"$name\" names a directory of the path,"
			    . ' and not a directory of its own' );
	}

	# The build makes its staging directory in the output under a
	# fixed name, and it removes that directory at the end. A key
	# directory of the same name would publish nothing. Each test
	# of a name against a name of the output folds the two, per
	# WEB-OUTPUT-17.
	my $fold = App::FuguWeb::fold_name($name);
	if ( $fold eq App::FuguWeb::fold_name(App::FuguWeb::STAGING_DIR) ) {
		return $self->_fail( $reason,
			      "keys \"$name\" is the staging directory of"
			    . ' the build, which the build removes' );
	}

	# WEB-KEYS-34. The tree of a declared language takes its path
	# in the output. A key directory of that name would take the
	# place of the tree, and the prune of the build would read its
	# files as stale pages.
	for my $language ( $self->languages ) {
		next unless App::FuguWeb::fold_name( $language->path ) eq $fold;

		return $self->_fail( $reason,
			      "keys \"$name\" is the path of the tree of the"
			    . ' language '
			    . $language->tag
			    . ', which takes that name' );
	}

	# WEB-KEYS-1. Two blocks that name one directory would become
	# one tree in the output, and no reader could say which block
	# describes a file of it.
	if ( grep { App::FuguWeb::fold_name($_) eq $fold } $self->keys_dirs ) {
		return $self->_fail( $reason,
			      "keys \"$name\" is declared twice, and one"
			    . ' directory takes one block' );
	}

	my $org = $settings->{org};
	unless ( defined $org && length $org ) {
		return $self->_fail( $reason, "keys \"$name\" has no org" );
	}

	# Fugu::KeyDir dies for an org word that no key name can hold,
	# because a site build reads the word from its own description.
	# This is that description, so the failure is a reason and not
	# a death.
	my $keydir = eval { Fugu::KeyDir->new( org => $org ) };
	unless ($keydir) {

		# A failed eval leaves $@ as the empty string and never
		# as undef, so a defined-or test can never reach its
		# own fallback.
		my $why = length $@ ? $@ : 'the org is not usable';
		$why =~ s/\s+\z//;
		return $self->_fail( $reason, "keys \"$name\": $why" );
	}

	# WEB-KEYS-2. A key name carries the org word and no directory
	# name, and the serial of a purpose counts inside one
	# directory. A mint of the second block would therefore write
	# a name that the first block publishes already.
	for my $held ( @{ $self->{keys_order} } ) {
		next unless $self->{keys_block}{$held}{org} eq $org;

		return $self->_fail( $reason,
			      "keys \"$name\" and keys \"$held\" both name"
			    . " the org $org, and one org word names one"
			    . ' directory' );
	}

	# WEB-KEYS-3. A site publishes one security.txt, so one block
	# alone names the contact and the expiry. A second block that
	# named either one would describe a second such file.
	my $contact = $settings->{contact};
	my $expires = $settings->{expires};
	if ( defined $self->{keys_security} ) {
		for my $only (qw(contact expires)) {
			next unless defined $settings->{$only};

			return $self->_fail( $reason,
				      "keys \"$name\" names $only, and keys"
				    . " \"$self->{keys_security}\" names one"
				    . ' already; a site holds one'
				    . ' security.txt' );
		}
	}

	# RFC 9116 makes Expires a necessary field, so a contact with
	# no expiry writes no security.txt. An expiry with no contact
	# is a setting that nothing reads, which is a typo.
	if ( defined $contact && !defined $expires ) {
		return $self->_fail( $reason,
			      "keys \"$name\" names a contact and no expires;"
			    . ' RFC 9116 makes both necessary' );
	}
	if ( defined $expires && !defined $contact ) {
		return $self->_fail( $reason,
			"keys \"$name\" names expires and no contact" );
	}

	# RFC 9116 makes the Expires field a timestamp of RFC 3339. A
	# value of another shape reaches the published file, and every
	# reader of security.txt rejects it. No other gate of the site
	# would have said so.
	if ( defined $expires && $expires !~ /$RFC3339/ ) {
		return $self->_fail( $reason,
			      "keys \"$name\" expires is $expires, which is"
			    . ' not an RFC 3339 timestamp' );
	}

	# The url is the published prefix of the directory. The
	# Encryption field of security.txt needs an absolute URL, and
	# a site that names none writes no such field.
	my $url = $settings->{url};
	if ( defined $url && $url !~ m{\A[a-z][a-z0-9+.-]*://\S+\z} ) {
		return $self->_fail( $reason,
			      "keys \"$name\" url is $url, which is not an"
			    . ' absolute URL' );
	}
	$url =~ s{/+$}{} if defined $url;

	unless ( -d $self->source_path($name) ) {
		return $self->_fail( $reason,
			      "keys \"$name\" names $self->{source_dir}/$name,"
			    . ' which is not a directory' );
	}

	# WEB-KEYS-30. The key directory becomes a directory of the
	# output, and any file of the same name collides with it. The
	# build would fail late, on a write to a directory, and it
	# would leave a tree that is half built. The inventory holds
	# every name that the output takes, so the test reads that one
	# list. Each path of a key directory holds a solidus, so this
	# test never answers for a second keys block. The test above
	# holds that one.
	for my $held ( $self->inventory ) {
		next unless App::FuguWeb::fold_name($held) eq $fold;
		return $self->_fail( $reason,
			      "keys \"$name\" and $held of the site both"
			    . ' become the same name in the output' );
	}

	push @{ $self->{keys_order} }, $name;
	$self->{keys_block}{$name} = {
		org     => $org,
		contact => $contact,
		expires => $expires,
		url     => $url,
		keydir  => $keydir,
		key     => [],
		binding => [],
	};

	# The block that holds security.txt of the site. Every later
	# block that names a contact or an expiry fails above.
	$self->{keys_security} = $name
	    if defined $contact || defined $expires;

	return $self;
}

# $self->_read_key_blocks($reason):
#	Read each key block, and resolve it to the one file that it
#	names. The block name is the stem, and the extension of the
#	file on disk decides the type, so the description repeats the
#	type nowhere.
#
#	The directory that holds the file owns the block, as the
#	extension of that file owns the type. A stem that two
#	directories hold names two files, and the description cannot
#	say which one, so the load refuses it.
sub _read_key_blocks ( $self, $reason )
{
	my %names;
	for my $dir ( $self->keys_dirs ) {
		my $path = $self->keys_path($dir);

		my $names = App::FuguWeb::list_dir($path)
		    or return $self->_fail( $reason, "cannot read $path: $!" );

		# A symlink in a key directory publishes whatever it
		# points at, from anywhere on the machine. The
		# manifest would then record the digest of that
		# target. The source directory gets the same rule one
		# level up. A key directory needs it more, because its
		# bytes are the trust anchor of every release.
		for my $name (@$names) {
			next unless -l "$path/$name";
			return $self->_fail( $reason,
				      "$self->{source_dir}/$dir/$name is a"
				    . ' symlink; the build would publish what'
				    . ' it points at' );
		}

		$names{$dir} = $names;
	}

	my %seen;
	for my $block ( $self->{file}->blocks('key') ) {
		my $stem     = $block->{name};
		my $settings = $block->{settings};

		# One stem names one block of the whole description.
		# The rotation rewrites a block by its stem, so two
		# blocks of one stem would take one rewrite.
		if ( $seen{$stem}++ ) {
			return $self->_fail( $reason,
				"key \"$stem\" is declared twice" );
		}

		my @files;
		for my $dir ( $self->keys_dirs ) {
			push @files, map { "$dir/$_" }
			    grep { /\A\Q$stem\E\.[^.]+\z/ } @{ $names{$dir} };
		}

		unless (@files) {
			return $self->_fail(
				$reason,
				"key \"$stem\" names no file in "
				    . join ' and ',
				map { "$self->{source_dir}/$_" }
				    $self->keys_dirs
			);
		}

		# Fugu::KeyDir holds one current key for each purpose,
		# so a signify key and an OpenPGP key take two
		# purposes. Two files under one stem would be one
		# purpose with two types.
		if ( @files > 1 ) {
			return $self->_fail( $reason,
				      "key \"$stem\" names "
				    . join( ' and ', sort @files )
				    . ', and one key block names one file' );
		}

		my ( $dir, $name ) = split m{/}, $files[0], 2;
		my $block_of = $self->{keys_block}{$dir};

		my $parts = $block_of->{keydir}->parse_name($name);
		unless ($parts) {
			return $self->_fail( $reason,
				"key \"$stem\": "
				    . $block_of->{keydir}->error );
		}

		my $entry =
		    $self->_key_entry( $reason, $name, $parts, $settings )
		    or return;

		push @{ $block_of->{key} }, $entry;
	}

	for my $dir ( $self->keys_dirs ) {
		$self->_read_directory( $reason, $dir, $names{$dir} ) or return;
	}

	return $self;
}

# $self->_read_directory($reason, $dir, $names):
#	Read the bindings of one key directory, and hold that
#	directory to what a published one carries.
sub _read_directory ( $self, $reason, $dir, $names )
{
	unless ( $self->site_keys($dir) ) {
		return $self->_fail( $reason,
			      "keys \"$dir\" holds no key block, and a key"
			    . ' directory publishes at least one key' );
	}

	$self->_read_bindings( $dir, $names );

	# The rotation workflow writes the manifest pair, and the build
	# copies it as it stands. A directory with no manifest
	# publishes keys that a consumer cannot verify, which is the
	# one thing a key directory exists to prevent.
	for my $needed ( App::FuguWeb::Keys::MANIFEST,
		App::FuguWeb::Keys::SIGNATURE )
	{
		next if -f $self->keys_path( $dir, $needed );
		return $self->_fail( $reason,
			      "keys \"$dir\" holds no $needed in"
			    . " $self->{source_dir}/$dir" );
	}

	return $self;
}

# $self->_read_bindings($dir, $names):
#	Read each binding file of one key directory. A binding is the
#	signature of one key file by another key, and its name holds
#	the target, the signer and the type of the signer. The name
#	carries every field, so a binding needs no block.
#
#	The method keeps a binding whose target and whose signer are
#	both keys of that directory. It drops every other name
#	silently, and App::FuguWeb::Keys then reports that name as a
#	stray file with the reason. A load that failed here would
#	refuse a build over a directory that one bad name broke, and
#	the checks are what report such a directory.
#
#	A binding never crosses a directory, per D-02: each directory
#	holds its own root, and a signer of another directory names a
#	key that this one does not publish.
sub _read_bindings ( $self, $dir, $names )
{
	my $block  = $self->{keys_block}{$dir};
	my $keydir = $block->{keydir};

	my %key = map { $_->{name} => 1 } @{ $block->{key} };

	for my $name ( sort @$names ) {
		next if $key{$name};

		my $parts = $keydir->parse_binding($name) or next;
		next
		    unless $key{ $parts->{target} } && $key{ $parts->{signer} };

		push @{ $block->{binding} }, { %$parts, name => $name };
	}

	return $self;
}

# $self->_key_entry($reason, $name, $parts, $settings):
#	One entry of the key list, with the settings of its block
#	checked against the type that the file name gave.
sub _key_entry ( $self, $reason, $name, $parts, $settings )
{
	my $stem = $parts->{stem};

	my $status = $settings->{status};
	unless ( defined $status && $KEY_STATUS{$status} ) {
		return $self->_fail( $reason,
			      "key \"$stem\" holds the status "
			    . ( $status // '(undef)' )
			    . ', and the vocabulary is '
			    . join( ', ', Fugu::KeyDir::STATUSES ) );
	}

	# Each type takes the settings of its own file. A signify key
	# has no email address and no fingerprint, and a certificate
	# has no user id, so such a setting is a block that describes
	# another file.
	my $takes = $TYPE_SETTING{ $parts->{type} } // {};
	for my $only (qw(email fingerprint)) {
		next unless defined $settings->{$only};
		next if $takes->{$only};
		return $self->_fail( $reason,
			      "key \"$stem\" names $only, and $name"
			    . " is a $parts->{type} key" );
	}

	# The Web Key Directory hash comes from the local part, and the
	# published path holds it. The hash is computed here, so the
	# inventory of a site reads no key file.
	my $email = $settings->{email};
	my $wkd;
	if ( defined $email ) {
		my ($local) = $email =~ /\A([^\@\s]+)\@[^\@\s]+\z/;
		unless ( defined $local ) {
			return $self->_fail( $reason,
				"key \"$stem\" email is $email, which is not"
				    . ' a local part and a domain' );
		}

		# The reader of Fugu::OpenPGP needs no gpg(1), so the
		# object serves a host that holds none.
		my $pgp  = Fugu::OpenPGP->new;
		my $hash = $pgp->wkd_hash($local);
		unless ( defined $hash ) {
			return $self->_fail( $reason,
				"key \"$stem\" email is $email: "
				    . $pgp->error );
		}
		$wkd = $hash;
	}

	# The human page and the KEYS file both write the fingerprint
	# as it stands, so the form is checked here and nowhere else.
	# The width comes from the type, because the two digests
	# differ: a check that took the shorter one would pass half of
	# the SHA-256 of a certificate.
	my $fingerprint = $settings->{fingerprint};
	if ( defined $fingerprint ) {
		my $width = $FINGERPRINT_WIDTH{ $parts->{type} };

		unless ( $fingerprint =~ /\A[0-9A-Fa-f]{$width}\z/ ) {
			return $self->_fail( $reason,
				      "key \"$stem\" fingerprint is"
				    . " $fingerprint, which is not $width"
				    . ' hexadecimal characters' );
		}
	}

	return {
		%$parts,
		name        => $name,
		status      => $status,
		since       => $settings->{since},
		until       => $settings->{until},
		email       => $email,
		wkd         => $wkd,
		fingerprint => defined $fingerprint ? uc $fingerprint : undef,
	};
}

# $self->_check_pages($reason):
#	Refuse two manuals that would become the same page. The two
#	sources would overwrite each other in the staging directory and
#	in the output, and the index would show two entries that lead
#	to one page. A page block already gets this check; a manual
#	needs it as much.
#
#	The test folds each name, per WEB-OUTPUT-17. Two names of one
#	fold are one file on a file system without case.
sub _check_pages ( $self, $reason )
{
	my %source;

	for my $group ( $self->groups ) {
		for my $manual ( $group->manuals ) {
			my $page  = $manual->page;
			my $fold  = App::FuguWeb::fold_name($page);
			my $first = $source{$fold};
			if ( defined $first ) {
				return $self->_fail( $reason,
					      "$first and "
					    . $manual->path
					    . " both become $page" );
			}
			$source{$fold} = $manual->path;
		}
	}

	for my $page ( $self->pages ) {
		my $first = $source{ App::FuguWeb::fold_name( $page->{file} ) };
		next unless defined $first;
		return $self->_fail( $reason,
			      "page \"$page->{file}\" and $first"
			    . ' both become the same page' );
	}

	return $self;
}

# $self->_check_sources($reason):
#	Refuse a source whose path from the project root holds ASCII
#	white space or a parenthesis, per WEB-SITE-6. A source is a page
#	source, a manual or a footer fragment, of any language. The
#	record of the translations names each source in the manifest
#	form of Fugu::Signify, which holds neither.
sub _check_sources ( $self, $reason )
{
	for my $path ( $self->_source_files ) {
		next unless $path =~ /[\s()]/a;

		return $self->_fail( $reason,
			      "the source $path holds ASCII white space or a"
			    . ' parenthesis, and the record of the'
			    . ' translations cannot name it' );
	}

	return $self;
}

# $self->_source_files:
#	The path from the project root of each page source, each manual
#	and each footer fragment, of each language.
sub _source_files ($self)
{
	my $source = $self->{source_dir};

	my @paths;
	for my $language ( $self->languages ) {
		my $tag = $language->tag;

		push @paths, "$source/" . $language->footer
		    if defined $language->footer;

		for my $page ( grep { defined $_->{value} } $self->pages($tag) )
		{
			push @paths,
			    $page->{source} eq 'markdown'
			    ? $page->{value}
			    : "$source/$page->{value}";
		}

		push @paths, map { substr $_->path, 1 + length $self->{root} }
		    map { $_->manuals($tag) } $self->groups;
	}

	return @paths;
}

# $self->sources:
#	The path of each source that a build reads, below the project
#	root, per WEB-OUTPUT-18. The files come first: each page source,
#	each manual and each footer of each language, and the
#	stylesheet. The directories follow: the source directory, each
#	key directory, and the directory of each group in each
#	language. The guard of the output directory names the first
#	source that a target holds, so a file comes before the
#	directory that holds it.
#
#	A description that did not load names its source directory and
#	its key directories alone.
sub sources ($self)
{
	my @files = $self->_source_files;
	push @files, $self->{stylesheet} if defined $self->{stylesheet};

	return ( map { "$self->{root}/$_" } @files ),
	    $self->source_path,
	    ( map { $self->keys_path($_) } $self->keys_dirs ),
	    ( map { $_->dirs } $self->groups );
}

# $self->_check_paths($reason):
#	Refuse a path setting that steps out of the project. A build
#	writes inside the output directory and reads inside the
#	checkout; a '..' in a setting breaks both promises at once.
sub _check_paths ( $self, $reason )
{
	for my $key (@PATH_SETTINGS) {
		next unless _has_parent_step( $self->{$key} );
		return $self->_fail( $reason,
			"$key is $self->{$key}, which leaves the project" );
	}

	# WEB-SITE-7. The record of the translations sits at the
	# project root, per WEB-STATUS-1, and the build publishes each
	# plain file of the source directory. The source directory is
	# therefore not the project root.
	unless ( length App::FuguWeb::canonical_path( $self->{source_dir} ) ) {
		return $self->_fail( $reason,
			      "source_dir is $self->{source_dir}, which is the"
			    . ' project root, where the record of the'
			    . ' translations sits' );
	}

	$self->_check_source_dir($reason) or return;

	return $self->_check_fragments($reason);
}

# $self->_check_source_dir($reason):
#	Refuse a symlink at the top level of the source directory.
#	Every file there that the build does not render is copied into
#	the site, and a symlink would publish whatever it points at,
#	from anywhere on the machine. A content directory holds
#	content.
sub _check_source_dir ( $self, $reason )
{
	my $dir = $self->source_path;
	return $self unless -d $dir;

	my $names = App::FuguWeb::list_dir($dir)
	    or return $self->_fail( $reason, "cannot read $dir: $!" );

	for my $name (@$names) {
		next unless -l "$dir/$name";
		return $self->_fail( $reason,
			      "$self->{source_dir}/$name is a symlink;"
			    . ' the build would publish what it points at' );
	}

	return $self;
}

# $self->_check_fragments($reason):
#	Refuse a symlink on the path of each fragment that the build
#	reads below the source directory: the body fragment of each
#	page in each language, and the footer of each language. A
#	fragment can sit below the top level, where the scan above does
#	not reach.
sub _check_fragments ( $self, $reason )
{
	my @paths = grep { defined } map { $_->footer } $self->languages;

	for my $tag ( map { $_->tag } $self->languages ) {
		push @paths, map { $_->{value} }
		    grep { $_->{source} ne 'markdown' && defined $_->{value} }
		    $self->pages($tag);
	}

	for my $path (@paths) {
		$self->_check_fragment( $reason, $path ) or return;
	}

	return $self;
}

# $self->_check_fragment($reason, $path):
#	Refuse a path below the source directory when one of its
#	components is a symlink: the file, or a directory on the way to
#	it. The build would read the fragment through that symlink, and
#	publish what it points at.
sub _check_fragment ( $self, $reason, $path )
{
	my $prefix;
	for my $part ( grep { length } split m{/}, $path ) {
		$prefix = defined $prefix ? "$prefix/$part" : $part;
		next unless -l $self->source_path($prefix);

		return $self->_fail( $reason,
			      "$self->{source_dir}/$prefix is a symlink;"
			    . ' the build would publish what it points at' );
	}

	return $self;
}

# _has_parent_step($path):
#	Report whether a path holds a '..' component. A name that only
#	starts with two dots, such as '..config', is not a step out.
sub _has_parent_step ($path)
{
	return 0 unless defined $path;

	return scalar grep { $_ eq '..' } split m{/}, $path;
}

# _unsafe_output_name($name):
#	Report why a name may not become a file in the output
#	directory, or undef when it may. The name is one path below the
#	output: no step out, no absolute path, and no empty name.
sub _unsafe_output_name ($name)
{
	return 'is empty' unless defined $name && length $name;
	return 'is an absolute path'         if $name =~ m{^/};
	return 'leaves the output directory' if _has_parent_step($name);

	return;
}

# _label($block):
#	The block as a message names it: the type, the language tag of
#	a translation, and the quoted name.
sub _label ($block)
{
	my @args = @{ $block->{args} };
	my $name = pop @args;

	return join ' ', $block->{type}, @args, qq{"$name"};
}

# $self->_fail($reason, $message):
#	Record the reason, with the file that is at fault, and return
#	undef.
sub _fail ( $self, $reason, $message )
{
	$$reason = "$self->{path}: $message";

	return;
}

package App::FuguWeb::Config::Group;
our $VERSION = '0.11.2';

# App::FuguWeb::Config::Group - one group of the manual index.
#
# A group is a name, a heading, and a directory. The name is the
# anchor of the heading, and every language shares it. The heading
# and the directory can change with the language. A group never holds
# a list of manuals: it reads the directory, so a manual that is added
# reaches the site with no edit anywhere.
#
# A manuals group globs mdoc sources. A modules group finds POD
# sidecars below the directory, and the file that names the directory
# itself: lib/App/FuguWeb.pod is the umbrella of lib/App/FuguWeb/.

# The sections that a manuals group globs, in the order the index
# shows them. The order follows the number of the section, and 3p
# holds the place of section 3. Add a new section at its number.
my @SECTIONS = qw(1 3p 5 7 8);

# App::FuguWeb::Config::Group->new(%args):
#	kind        => 'manuals'|'modules'
#	name        => $word	the id of the h2
#	heading     => $text	the h2 of the group
#	lang        => $tag	the default language
#	dir         => $path	the directory it reads
#	namespace   => $string	the prefix of a manuals name
#	module_root => $path	the prefix a module name drops
sub new ( $class, %args )
{
	return bless {
		kind        => $args{kind},
		name        => $args{name},
		heading     => $args{heading},
		lang        => $args{lang},
		dir         => $args{dir},
		namespace   => $args{namespace},
		module_root => $args{module_root},
		translation => {},
		manuals     => {},
	}, $class;
}

sub kind      ($self) { return $self->{kind}; }
sub name      ($self) { return $self->{name}; }
sub namespace ($self) { return $self->{namespace}; }

# $self->lang:
#	The tag of the default language. A manual of the default dir is
#	of this language.
sub lang ($self) { return $self->{lang}; }

# $self->heading($tag):
#	The h2 of the group in one language, as characters: the heading
#	of its translation, or the default heading. The tag defaults to
#	that of the default language.
sub heading ( $self, $tag = undef )
{
	$tag //= $self->{lang};

	return $self->{translation}{$tag}{heading} // $self->{heading};
}

# $self->heading_lang($tag):
#	The language of the h2 of the group in one language: the tag
#	when its translation names a heading, and the default tag when
#	the group takes the default heading, per WEB-LANGUAGE-8. The tag
#	defaults to that of the default language.
sub heading_lang ( $self, $tag = undef )
{
	$tag //= $self->{lang};

	return defined $self->{translation}{$tag}{heading}
	    ? $tag
	    : $self->{lang};
}

# $self->translate($tag, heading => $text, dir => $path):
#	Give the group the heading and the dir of one language. A
#	heading of undef keeps the default heading, and a dir of undef
#	keeps the default sources for that language.
sub translate ( $self, $tag, %args )
{
	$self->{translation}{$tag} = {
		heading => $args{heading},
		dir     => $args{dir},
	};
	delete $self->{manuals}{$tag};

	return $self;
}

# $self->dirs:
#	The directory of the group in each language: the default dir,
#	then the dir of each translation that names one, by tag.
sub dirs ($self)
{
	my $translation = $self->{translation};

	return $self->{dir}, grep { defined }
	    map { $translation->{$_}{dir} } sort keys %$translation;
}

# $self->manuals($tag):
#	The manuals of the group in one language, in the order the
#	index shows them, per WEB-LANGUAGE-9. A manual comes from the
#	dir of the translation when that dir holds its namesake, and
#	from the default dir otherwise. Each language holds the same
#	pages, in the same order. The tag defaults to that of the
#	default language. The method reads each directory once and
#	keeps the answer.
sub manuals ( $self, $tag = undef )
{
	$tag //= $self->{lang};
	$self->{manuals}{$tag} //= [ $self->_manuals_of($tag) ];

	return @{ $self->{manuals}{$tag} };
}

# $self->orphan($tag):
#	The first source of the translation dir of one language that
#	has no namesake in the default dir, or undef. Such a source
#	would be a page that no other language holds.
sub orphan ( $self, $tag )
{
	my $dir = $self->{translation}{$tag}{dir} // return;

	my %default = map { $self->_relative( $_->path ) => 1 } $self->manuals;

	for my $path ( $self->_sources($dir) ) {
		return $path unless $default{ substr $path, length $dir };
	}

	return;
}

# $self->_manuals_of($tag):
#	The manuals of one language. A source of a translation keeps
#	the name and the page of its namesake, so a module page is
#	named after the module and not after the path of the source.
sub _manuals_of ( $self, $tag )
{
	if ( $tag eq $self->{lang} ) {
		return map {
			$self->{kind} eq 'manuals'
			    ? App::FuguWeb::Manual->from_mdoc( $_, $self )
			    : App::FuguWeb::Manual->from_pod( $_, $self,
				$self->{module_root} )
		} $self->_sources( $self->{dir} );
	}

	my $dir = $self->{translation}{$tag}{dir};
	return $self->manuals unless defined $dir;

	my %own = map { substr( $_, length $dir ) => $_ } $self->_sources($dir);

	return map {
		my $path = $own{ $self->_relative( $_->path ) };
		defined $path ? $_->translated( $path, $tag ) : $_
	} $self->manuals;
}

# $self->_relative($path):
#	The part of the path of a default source after the default
#	dir. The namesake of a source of a translation dir is the
#	source of the same part, and the umbrella of a modules group
#	is the part .pod.
sub _relative ( $self, $path )
{
	return substr $path, length $self->{dir};
}

# $self->_sources($dir):
#	The path of each source of one directory, in the order the
#	index shows them.
sub _sources ( $self, $dir )
{
	return $self->{kind} eq 'manuals'
	    ? _mdoc_sources($dir)
	    : _pod_sources($dir);
}

# _mdoc_sources($dir):
#	Every mdoc source in the directory, by section in the order 1,
#	3p, 5, 7, 8, and then by file name. The sort compares bytes and
#	never reads the locale of the builder: a site must not depend
#	on the machine that built it.
#
#	The function reads the directory rather than globs it. Perl's
#	glob splits its pattern on whitespace and reads [ ] { } ? ~, so
#	a project whose path holds one of them would lose its manuals
#	or collect a sibling directory's. It also matches a directory,
#	and a directory named tool.1 is not a manual.
sub _mdoc_sources ($dir)
{
	my $names = App::FuguWeb::list_dir($dir) or return ();
	my @names = grep { !/^\./ } @$names;

	my @paths;
	for my $section (@SECTIONS) {
		for my $name (@names) {
			next unless $name =~ /\.\Q$section\E$/;
			next unless -f "$dir/$name";

			push @paths, "$dir/$name";
		}
	}

	return @paths;
}

# _pod_sources($dir):
#	Every POD sidecar below the directory, and the sidecar that
#	names the directory itself, by path. Sorting by the whole path
#	keeps Store.pod before Store/Memory.pod, because a dot sorts
#	before a slash.
sub _pod_sources ($dir)
{
	my @paths;
	push @paths, "$dir.pod" if -f "$dir.pod";

	File::Find::find( {
			no_chdir => 1,
			wanted   => sub {
				push @paths, $File::Find::name
				    if /\.pod$/ && -f $File::Find::name;
			},
		},
		$dir
	);

	my @sorted = sort @paths;

	return @sorted;
}

1;
