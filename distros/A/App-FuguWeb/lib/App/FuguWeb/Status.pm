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

package App::FuguWeb::Status;
our $VERSION = '0.11.0';

use App::FuguWeb ();
use Digest::SHA  ();
use Fugu::File;
use Fugu::Signify;

# App::FuguWeb::Status - the translation status of a site.
#
# A translation follows its source, and a source changes. The record
# names the version of the default source that each translated file
# follows, per WEB-STATUS-1. The module reads the description and the
# record, and it gives each part of a language other than the default
# that does not follow its source, per WEB-STATUS-3. It also writes
# the line of a translated file into the record, per WEB-STATUS-2.
#
# The record takes the manifest form, and Fugu::Signify reads it and
# writes it. The build and the check do not read the record, per
# WEB-STATUS-6, so the CLI is the one caller of this module.

# The record, at the project root beside the description. It must not
# sit below the source directory, where the build publishes each plain
# file as an asset.
use constant RECORD => 'TRANSLATIONS';

# App::FuguWeb::Status->new(config => $config):
#	The translation status of the site of one loaded description.
sub new ( $class, %args )
{
	return bless {
		config => $args{config},
		digest => {},
		error  => undef,
		fault  => 0,
	}, $class;
}

# $self->error:
#	The reason of the most recent failure, or undef.
sub error ($self) { return $self->{error}; }

# $self->fault:
#	True when the most recent failure is a fault of the project
#	files: a record or a source that does not read, or a
#	description that WEB-STATUS-7 refuses. The CLI gives such a
#	failure the code of a description that does not load.
sub fault ($self) { return $self->{fault}; }

# $self->report:
#	The lines of WEB-STATUS-3 as an array reference, or undef with
#	the reason in error. A line holds the tag, the state, the kind
#	of the part and its name, with one tab between two fields. The
#	lines follow the order of the languages, and then the order of
#	the description. An empty list means that each part follows its
#	source, per WEB-STATUS-5.
sub report ($self)
{
	$self->_sources           or return;
	my $record = $self->_read or return;

	my @lines;
	for my $part ( $self->_parts ) {
		my $state = $self->_state( $part, $record ) // return;
		next unless length $state;

		push @lines, join "\t", $part->{tag}, $state, $part->{kind},
		    $part->{name};
	}

	return \@lines;
}

# $self->record(@files):
#	Write the line of each file into the record, per WEB-STATUS-2,
#	with the digest that its default source has now. Each file is a
#	path from the project root, and the record names it in the form
#	of App::FuguWeb::canonical_path. The method keeps each other
#	line, and Fugu::Signify sorts the lines by path. It returns 1,
#	or undef with the reason in error. A failure writes nothing.
sub record ( $self, @files )
{
	my $source = $self->_sources or return;
	my $record = $self->_read    or return;

	for my $file (@files) {
		my $path = App::FuguWeb::canonical_path($file);
		my $from = $source->{$path} // return $self->_fail(
			"$file translates no source of the description");
		$record->{$path} = $self->_digest($from) // return;
	}

	my $path    = $self->_path;
	my $signify = Fugu::Signify->new;
	my $text    = $signify->write_manifest($record)
	    // return $self->_fail( "$path: " . $signify->error );

	Fugu::File->write_atomic( $path, $text )
	    or return $self->_fail("Cannot write $path");

	return 1;
}

# $self->_parts:
#	Each part of each language other than the default, per
#	WEB-STATUS-3, in the order of the languages and then of the
#	description. A part is a hash reference:
#
#		tag	the tag of the language
#		kind	site, label, title, page, heading, manual or
#			footer
#		name	the name of the block that takes its
#			translation, or the page of a manual
#		from	the tag of the language that it comes from
#		file	the source that the language takes, from the
#			project root, or undef for a value
#		source	the default source, from the project root, or
#			undef for a value
#
#	Each path takes the form of App::FuguWeb::canonical_path, so a
#	path setting of './web' or 'web/' gives the key of the record.
#
#	A value is a word of the description: the site name, a nav
#	label, a page title or a group heading, per WEB-LANGUAGE-8. The
#	other parts are files. A file part with no default source
#	follows no source, so the list leaves it out.
sub _parts ($self)
{
	my $config = $self->{config};
	my ( $default, @others ) = $config->languages;
	my @pages = $config->pages;

	my @parts;
	for my $language (@others) {
		my $tag = $language->tag;

		push @parts, _value( $tag, 'site', $tag, $language->site_lang );

		push @parts,
		    _value( $tag, 'label', $_->{href}, $_->{label_lang} )
		    for $config->nav($tag);

		my @own = $config->pages($tag);
		for my $i ( 0 .. $#own ) {
			my $page = $own[$i];
			push @parts,
			    _value( $tag, 'title', $page->{file},
				$page->{title_lang} ),
			    _file(
				$tag,
				'page',
				$page->{file},
				$page->{lang},
				$self->_page_source($page),
				$self->_page_source( $pages[$i] ) );
		}

		for my $group ( $config->groups ) {
			push @parts,
			    _value( $tag, 'heading', $group->name,
				$group->heading_lang($tag) );

			# Each language holds the manuals of the default dir,
			# in the same order, per WEB-LANGUAGE-9.
			my @base    = $group->manuals;
			my @manuals = $group->manuals($tag);
			for my $i ( 0 .. $#manuals ) {
				my $manual = $manuals[$i];
				push @parts,
				    _file(
					$tag,
					'manual',
					$manual->page,
					$manual->lang,
					$self->_from_root( $manual->path ),
					$self->_from_root( $base[$i]->path ) );
			}
		}

		push @parts,
		    _file(
			$tag,
			'footer',
			$tag,
			$language->footer_lang,
			$self->_fragment( $language->footer ),
			$self->_fragment( $default->footer ) );
	}

	return @parts;
}

# _value($tag, $kind, $name, $from):
#	One value part.
sub _value ( $tag, $kind, $name, $from )
{
	return { tag => $tag, kind => $kind, name => $name, from => $from };
}

# _file($tag, $kind, $name, $from, $file, $source):
#	One file part, or the empty list when no default source stands.
sub _file ( $tag, $kind, $name, $from, $file, $source )
{
	return () unless defined $source;

	return {
		tag    => $tag,
		kind   => $kind,
		name   => $name,
		from   => $from,
		file   => App::FuguWeb::canonical_path($file),
		source => App::FuguWeb::canonical_path($source),
	};
}

# $self->_sources:
#	The default source of each file that a language translates, as
#	a hash reference of path to path, or undef with the reason in
#	error. The record holds one digest for each file, so two parts
#	that name one file over two default sources fail, per
#	WEB-STATUS-7.
sub _sources ($self)
{
	my %source;
	for my $part ( $self->_parts ) {
		next unless defined $part->{file};
		next unless $part->{from} eq $part->{tag};

		my $first = $source{ $part->{file} } //= $part->{source};
		next if $first eq $part->{source};

		return $self->_fault( "$part->{file} translates $first and"
			    . " $part->{source}, and the record holds one"
			    . ' digest for each file' );
	}

	return \%source;
}

# $self->_state($part, $record):
#	The state of one part, per WEB-STATUS-4, or the empty string
#	when the part follows its source. A part that comes from the
#	default language is fallback. A translated file is unrecorded
#	with no line in the record, and stale when its line names
#	another digest than the one that its default source has now.
#	The method returns undef with the reason in error.
sub _state ( $self, $part, $record )
{
	return 'fallback' unless $part->{from} eq $part->{tag};
	return ''         unless defined $part->{file};

	my $recorded = $record->{ $part->{file} }        // return 'unrecorded';
	my $digest   = $self->_digest( $part->{source} ) // return;

	return $recorded eq $digest ? '' : 'stale';
}

# $self->_read:
#	The record as a hash reference of path to digest, or undef with
#	the reason in error. A project with no record, or with an empty
#	one, has an empty record. Fugu::Signify refuses a manifest of
#	no line, so the method does not pass it one.
sub _read ($self)
{
	my $path = $self->_path;
	return {} unless -e $path;

	my $bytes = Fugu::File->read($path)
	    // return $self->_fault("Cannot read $path");
	return {} unless length $bytes;

	my $signify = Fugu::Signify->new;
	my $record  = $signify->parse_manifest($bytes)
	    // return $self->_fault( "$path: " . $signify->error );

	return $record;
}

# $self->_digest($source):
#	The SHA-256 of a default source, in lowercase hexadecimal, or
#	undef with the reason in error. The method reads each source
#	once.
sub _digest ( $self, $source )
{
	return $self->{digest}{$source} if defined $self->{digest}{$source};

	my $path  = $self->{config}->root . "/$source";
	my $bytes = Fugu::File->read($path)
	    // return $self->_fault("Cannot read $path");

	return $self->{digest}{$source} = Digest::SHA::sha256_hex($bytes);
}

# $self->_page_source($page):
#	The source of one page entry, from the project root, or undef
#	when the page names none. A markdown value is a path from the
#	project root, and a body is below the source directory, as
#	_check_sources of App::FuguWeb::Config reads them. The method
#	answers one scalar, so a caller can pass it as an argument.
sub _page_source ( $self, $page )
{
	return $page->{source} eq 'markdown'
	    ? $page->{value}
	    : $self->_fragment( $page->{value} );
}

# $self->_fragment($path):
#	A fragment below the source directory, as a path from the
#	project root, or undef for no fragment. The method answers one
#	scalar, as _page_source does.
sub _fragment ( $self, $path )
{
	return defined $path ? $self->{config}->source_dir . "/$path" : undef;
}

# $self->_from_root($path):
#	The path of a manual source from the project root. A group holds
#	the project root in front of each path.
sub _from_root ( $self, $path )
{
	return substr $path, 1 + length $self->{config}->root;
}

# $self->_path:
#	The path of the record.
sub _path ($self)
{
	return $self->{config}->root . '/' . RECORD;
}

# $self->_fail($reason), $self->_fault($reason):
#	Keep the reason in error, and return undef. A fault is a
#	failure of the project files, as fault states.
sub _fail ( $self, $reason, $fault = 0 )
{
	$self->{error} = $reason;
	$self->{fault} = $fault;

	return;
}

sub _fault ( $self, $reason ) { return $self->_fail( $reason, 1 ); }

1;
