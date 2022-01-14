use Object::Pad 0.27;

use v5.12;
use utf8;
use autodie;

=head1 NAME

App::Licensecheck - functions for a simple license checker for source files

=head1 VERSION

Version v3.3.0

=head1 SYNOPSIS

    use App::Licensecheck;

    my $app = App::Licensecheck->new;

    my $app2 = App::Licensecheck->new( top_lines => 0 );  # Parse whole files

    printf "License: %s\nCopyright: %s\n", $app->parse( 'some-file' );

=head1 DESCRIPTION

L<App::Licensecheck> is the core of L<licensecheck> script
to check for licenses of source files.
See the script for casual usage.

=cut

package App::Licensecheck v3.3.0;

use Log::Any ();
use List::SomeUtils qw(nsort_by uniq);
use Path::Iterator::Rule;
use Path::Tiny();
use Try::Tiny;
use Fcntl qw(:seek);
use Encode 2.93;
use Array::IntSpan;
use Regexp::Pattern::License 3.4.0;
use Regexp::Pattern 0.2.12;
use String::Copyright 0.003 {
	format => sub { join ' ', $_->[0] || (), $_->[1] || () }
};
use String::Copyright 0.003 {
	threshold_after => 5,
	format          => sub { join ' ', $_->[0] || (), $_->[1] || () },
	},
	'copyright' => { -as => 'copyright_optimistic' };

class Trait {
	has $log = Log::Any->get_logger;
	has $name :reader;
	has $begin :reader;
	has $end :reader;
	has $file :reader;

	BUILD {
		my %opts = @_;

		# TODO: use Object::Pad 0.41 and slot attribute :param
		$name  = $opts{name};
		$begin = $opts{begin};
		$end   = $opts{end};
		$file  = $opts{file};

		$log->tracef(
			'located trait: %s: %d-%d "%s"',
			$name, $begin, $end,
			$file
			? substr(
				$file->content_extracleaned, $begin,
				$end - $begin
				)
			: ''
		);
	}
}

class Exception {
	has $log = Log::Any->get_logger;
	has $id :reader;
	has $begin :reader;
	has $end :reader;
	has $file :reader;

	BUILD {
		my %opts = @_;

		# TODO: use Object::Pad 0.41 and slot attribute :param
		$id    = $opts{id};
		$begin = $opts{begin};
		$end   = $opts{end};
		$file  = $opts{file};

		$log->tracef(
			'detected exception: %s: %d-%d',
			$id->{caption}, $begin, $end
		);
	}
}

class Flaw {
	has $log = Log::Any->get_logger;
	has $id :reader;
	has $begin :reader;
	has $end :reader;
	has $file :reader;

	BUILD {
		my %opts = @_;

		# TODO: use Object::Pad 0.41 and slot attribute :param
		$id    = $opts{id};
		$begin = $opts{begin};
		$end   = $opts{end};
		$file  = $opts{file};

		$log->tracef(
			'detected flaw: %s: %d-%d',
			$id->{caption}, $begin, $end
		);
	}
}

class Licensing {
	has $log = Log::Any->get_logger;
	has $name :reader;

	BUILD {
		my %opts = @_;

		# TODO: use Object::Pad 0.41 and slot attribute :param
		$name = $opts{name};

		$log->debugf(
			'collected some licensing: %s',
			$name
		);
	}
}

class Fulltext {
	has $log = Log::Any->get_logger;
	has $name :reader;
	has $begin :reader;
	has $end :reader;
	has $file :reader;
	has $traits :reader;

	BUILD {
		my %opts = @_;

		# TODO: use Object::Pad 0.41 and slot attribute :param
		$name   = $opts{name};
		$begin  = $opts{begin};
		$end    = $opts{end};
		$file   = $opts{file};
		$traits = $opts{traits} // [];

		$log->debugf(
			'collected fulltext: %s: %d-%d',
			$name, $begin, $end
		);
	}
}

class Grant {
	has $log = Log::Any->get_logger;
	has $name :reader;
	has $begin :reader;
	has $end :reader;
	has $file :reader;
	has $traits :reader;

	BUILD {
		my %opts = @_;

		# TODO: use Object::Pad 0.41 and slot attribute :param
		$name   = $opts{name};
		$begin  = $opts{begin};
		$end    = $opts{end};
		$file   = $opts{file};
		$traits = $opts{traits} // [];

		$log->debugf(
			'collected grant: %s: %d-%d "%s"',
			$name, $begin, $end,
			$file
			? substr(
				$file->content_extracleaned, $begin,
				$end - $begin
				)
			: ''
		);
	}
}

use namespace::clean qw(-except new);

class App::Licensecheck;

# try enable RE2 engine
eval { require re::engine::RE2 };
my @OPT_RE2 = $@ ? () : ( engine => 'RE2' );

# fatalize Unicode::UTF8 and PerlIO::encoding decoding errors
use warnings FATAL => 'utf8';
$PerlIO::encoding::fallback = Encode::FB_CROAK;

my $default_check_regex = q!
	/[\w-]+$ # executable scripts or README like file
	|\.( # search for file suffix
		c(c|pp|xx)? # c and c++
		|h(h|pp|xx)? # header files for c and c++
		|S
		|css|less # HTML css and similar
		|f(77|90)?
		|go
		|groovy
		|lisp
		|scala
		|clj
		|p(l|m)?6?|t|xs|pod6? # perl5 or perl6
		|sh
		|php
		|py(|x)
		|rb
		|java
		|js
		|vala
		|el
		|sc(i|e)
		|cs
		|pas
		|inc
		|dtd|xsl
		|mod
		|m
		|md|markdown
		|tex
		|mli?
		|(c|l)?hs
	)$
!;

# From dpkg-source
my $default_ignore_regex = q!
	# Ignore general backup files
	~$|
	# Ignore emacs recovery files
	(?:^|/)\.#|
	# Ignore vi swap files
	(?:^|/)\..*\.swp$|
	# Ignore baz-style junk files or directories
	(?:^|/),,.*(?:$|/.*$)|
	# File-names that should be ignored (never directories)
	(?:^|/)(?:DEADJOE|\.cvsignore|\.arch-inventory|\.bzrignore|\.gitignore)$|
	# File or directory names that should be ignored
	(?:^|/)(?:CVS|RCS|\.pc|\.deps|\{arch\}|\.arch-ids|\.svn|\.hg|_darcs|\.git|
	\.shelf|_MTN|\.bzr(?:\.backup|tags)?)(?:$|/.*$)
!;

has $log = Log::Any->get_logger;

has $path;

# resolve patterns

has $shortname_scheme :reader;

# select

has $check_regex;
has $ignore_regex;
has $recursive;

# parse

has $top_lines;
has $end_bytes;
has $encoding;
has $fh;
has $content;
has $tail_content;
has $offset;
has $license;
has $copyrights;

# report

has $skipped;
has $deb_machine;

BUILD {
	my %opts = @_;

	# TODO: use Object::Pad 0.41 and slot attribute :param
	$recursive   = $opts{recursive};
	$top_lines   = $opts{top_lines} // 60;
	$end_bytes   = $opts{end_bytes} // 5000;    # roughly 60 lines of 80 chars
	$encoding    = $opts{encoding};
	$skipped     = $opts{skipped};
	$deb_machine = $opts{deb_machine};

	$shortname_scheme = $opts{shortname_scheme};
	if ($shortname_scheme) {
		if ( not ref($shortname_scheme) eq 'ARRAY' ) {
			$shortname_scheme = [ split /[\s,]+/, $shortname_scheme ];
		}
	}
	elsif ($deb_machine) {
		$shortname_scheme = [qw(debian spdx)];
	}
	else {
		$shortname_scheme = [];
	}

	$check_regex = $opts{check_regex};
	if ( !$check_regex or $check_regex eq 'common source files' ) {
		$check_regex = qr/$default_check_regex/x;
	}
	elsif ( not ref($check_regex) eq 'Regexp' ) {
		$check_regex = qr/$check_regex/;
	}

	$ignore_regex = $opts{ignore_regex};
	if ( !$ignore_regex or $ignore_regex eq 'some backup and VCS files' ) {
		$ignore_regex = qr/$default_ignore_regex/x;
	}
	elsif ( not ref($ignore_regex) eq 'Regexp' ) {
		$ignore_regex = qr/$ignore_regex/;
	}

	$encoding = $opts{encoding};
	if ( $encoding and not ref($encoding) eq 'OBJECT' ) {
		$encoding = find_encoding($encoding);
	}
}

# TODO: drop when R::P::License v3.8.1 is required
my $hack_3_8_1 = $Regexp::Pattern::License::VERSION < v3.8.1;

method list_licenses
{
	my %names;
	for my $key ( keys %Regexp::Pattern::License::RE ) {
		for ( keys %{ $Regexp::Pattern::License::RE{$key} } ) {
			my %attr;
			my @attr = split /[.]/;

			next unless $attr[0] eq 'name';

			# TODO: simplify when R::P::License v3.8.1 is required
			if ($hack_3_8_1) {
				push @attr, undef
					if @attr % 2;
				%attr = @attr[ 2 .. $#attr ];
				next if exists $attr{version};
				next if exists $attr{until};
			}
			else {
				%attr = @attr[ 2 .. $#attr ];
				next if exists $attr{until};
			}
			for my $org (@$shortname_scheme) {
				if ( exists $attr{$org} ) {
					$names{$key} //= $attr{$org};
					next KEY;
				}
			}
		}
		$names{$key} //= $Regexp::Pattern::License::RE{$key}{name} || $key;
	}

	print "$_\n" for sort { lc $a cmp lc $b } values %names;
}

sub list_naming_schemes
{
	my $_prop = '(?:[a-z][a-z0-9_]*)';
	my $_any  = '[a-z0-9_.()]';

	print "$_\n"
		for uniq sort map {/^(?:name|caption)\.alt\.org\.($_prop)$_any*/}
		map               { keys %{ $Regexp::Pattern::License::RE{$_} } }
		grep              {/^[a-z]/} keys %Regexp::Pattern::License::RE;
}

method find
{
	my @paths = @_;

	my $do      = Path::Iterator::Rule->new;
	my %options = (
		follow_symlinks => 0,
	);

	$do->max_depth(1)
		unless $recursive;
	$do->not( sub {/$ignore_regex/} );
	$do->file->nonempty;

	if ( @paths >> 1 ) {
		if ( $log->is_debug or $skipped && $log->is_warn ) {
			my $dont = $do->clone->not( sub {/$check_regex/} );
			foreach ( $dont->all( @paths, \%options ) ) {
				if ($skipped) {
					$log->warnf( 'skipped file %s', $_ );
				}
				else {
					$log->debugf( 'skipped file %s', $_ );
				}
			}
		}
		$do->and( sub {/$check_regex/} );
	}

	return $do->all( @paths, \%options );
}

method parse
{
	($path) = @_;

	$path = Path::Tiny::path($path);

	try {
		return $self->parse_file;
	}
	catch {
		if ( $encoding and /does not map to Unicode/ ) {
			$log->warnf(
				'failed decoding file %s as %s, will try iso-8859-1',
				$path, $encoding->name
			);
			$log->debugf( 'decoding error: %s', $_ );
			try {
				$encoding = find_encoding('iso-8859-1');
				return $self->parse_file;
			}
			catch {
				if (/does not map to Unicode/) {
					$log->warnf(
						'failed decoding file %s as iso-8859-1, will try raw',
						$path
					);
					$log->debugf( 'decoding error: %s', $_ );
					$encoding = undef;
					return $self->parse_file;
				}
				else {
					die $log->fatalf( 'unknown error: %s', $_ );
				}
			}
		}
		else {
			die $log->fatalf( 'unknown error: %s', $_ );
		}
	}
}

method parse_file
{
	# TODO: stop reuse slots across files, and drop this hack
	$content    = undef;
	$license    = undef;
	$copyrights = undef;

	if ( $top_lines == 0 ) {
		$license    = $self->parse_license;
		$copyrights = copyright( $self->content_cleaned );
	}
	else {
		$license    = $self->parse_license;
		$copyrights = copyright_optimistic( $self->content_cleaned );
		if ( $offset and not $copyrights and $license eq 'UNKNOWN' ) {

			# TODO: stop reuse slots across files, and drop this hack
			$tail_content = undef;

			$license    = $self->parse_license;
			$copyrights = copyright_optimistic( $self->content_cleaned );
		}
		$fh->close;
	}

	return ( $license, $copyrights );
}

method content
{
	if ( $top_lines == 0 ) {
		return $content
			if defined($content);

		if ( not defined($encoding) ) {
			$log->debugf( 'reading whole file %s as raw bytes', $path );
			$content = $path->slurp_raw;
		}
		else {
			my $id = $encoding->name;
			$log->debugf( 'decoding whole file %s as %s', $path, $id );
			$content = $path->slurp( { binmode => ":encoding($id)" } );
		}
		$log->trace("----- content -----\n$content----- end content -----")
			if $log->is_trace;
	}
	elsif ( not defined($license) or not defined($copyrights) ) {

		# TODO: distinguish header from full content
		return $content
			if defined($content);

		$content = '';

		if ( not defined($encoding) ) {
			$log->debugf( 'reading part(s) of file %s as raw bytes', $path );
			$fh = $path->openr_raw;
		}
		else {
			my $id = $encoding->name;
			$log->debugf( 'decoding part(s) of file %s as %s', $path, $id );
			$fh = $path->openr(":encoding($id)");
		}

		while ( my $line = $fh->getline ) {
			last if ( $fh->input_line_number > $top_lines );
			$content .= $line;
		}
		$log->trace("----- header -----\n$content----- end header -----")
			if $log->is_trace;

		if ($end_bytes) {
			my $position = $fh->tell;           # see IO::Seekable
			my $filesize = $path->stat->size;
			if ( $position >= $filesize - $end_bytes ) {    # header overlaps
				if ( $position < $filesize ) {
					$log->debugf(
						'tail offset set to %s (end of header)',
						$position
					);
					$offset = $position;
				}
				elsif ( $position = $filesize ) {
					$log->debug('header end matches file size');
					$offset = 0;
				}
				else {
					$log->error('header end beyond file size');
					$offset = 0;
				}
			}
			elsif ( $position > 0 ) {
				$offset = $filesize - $end_bytes;
				$log->debugf(
					'tail offset set to %s',
					$offset
				);
			}
			elsif ( $position < 0 ) {
				$log->error('header end could not be resolved');
				$offset = 0;
			}
			else {
				$log->error('header end oddly at beginning of file');
				$offset = 0;
			}
		}
	}
	elsif ($offset) {

		# TODO: distinguish tail from full content
		return $content
			if defined($tail_content);

		$tail_content = '';
		$fh->seek( $offset, SEEK_SET );    # see IO::Seekable
		$tail_content .= join( '', $fh->getlines );
		$log->trace("----- tail -----\n$tail_content----- end tail -----")
			if $log->is_trace;

		$content = $tail_content;
	}
	else {
		$log->errorf(
			'tail offset not usable: %s',
			$offset
		);
		return '';
	}

	# TODO: distinguish comment-mangled content from pristine content
	local $_ = $content or return '';

	# Remove generic comments: look for 4 or more lines beginning with
	# regular comment pattern and trim it. Fall back to old algorithm
	# if no such pattern found.
	my @matches = m/^[ \t]*([^a-zA-Z0-9\s]{1,3})[ \t]+\S/mg;
	if ( @matches >= 4 ) {
		my $comment_re = qr/^[ \t]*[\Q$matches[0]\E]{1,3}[ \t]*/m;
		s/$comment_re//g;
	}

	my @wordmatches = m/^[ \t]*(dnl|REM|COMMENT)[ \t]+\S/mg;
	if ( @wordmatches >= 4 ) {
		my $comment_re = qr/^[ \t]*\Q$wordmatches[0]\E[ \t]*/m;
		s/$comment_re//g;
	}

	# Remove other side of "boxed" comments
	s/[ \t]*[*#][ \t]*$//gm;

	# Remove Fortran comments
	s/^[cC]$//gm;
	s/^[cC] //gm;

	# Remove C / C++ comments
	s#(\*/|/\*|(?<!:)//)##g;

	# Strip escaped newline
	s/\s*\\n\s*/ /g;

	$content = $_;

	return $content;
}

my $html_xml_tags_re = qr/<\/?(?:p|br|ref)(?:\s[^>]*)?>/i;

# clean cruft
method content_cleaned
{
	local $_ = $self->content or return '';

	# strip common html and xml tags
	s/$html_xml_tags_re//g;

	# TODO: decode latin1/UTF-8/HTML data instead
	s/\xcb\x97|\xe2\x80[\x90-\x95|\xe2\x81\x83|\xe2\x88\x92|\xef\x89\xa3|\xef\xbc\x8d]|[&](?:ndash|mdash|horbar|minus|[#](?:727|820[8-9]|821[0-3]|8259|8722|65123|65293|x727|z201[0-5]|x2043|x2212|xFE63|xFF0D))[;]/-/gm;
	s/\x58\xa9|\xc2\xa9|\xe2\x92\x9e|\xe2\x92\xb8|\xe2\x93\x92|\xf0\x9f\x84\x92|\xf0\x9f\x84\xab|\xf0\x9f\x85\x92|[&](?:copy|[#](?:169|9374|9400|9426|127250|127275|127314|x0A9|x249E|x24b8|x24D2|x0F112|x0F12B|x0F152))[;]/©/gm;

	# TODO: decode nroff files specifically instead
	s/\\//gm;    # de-cruft nroff files

	return $_;
}

# clean cruft and whitespace
method content_extracleaned
{
	local $_ = $self->content or return '';

	# strip trailing dash, assuming it is soft-wrap
	# (example: disclaimers in GNU autotools file "install-sh")
	s/-\r?\n//g;

	# strip common html and xml tags
	s/$html_xml_tags_re//g;

	tr/\t\r\n/ /;

	# this also removes quotes
	tr% A-Za-z.,:@;0-9\(\)/-%%cd;
	tr/ //s;

	return $_;
}

my $any           = '[A-Za-z_][A-Za-z0-9_]*';
my $str           = '[A-Za-z][A-Za-z0-9_]*';
my $re_prop_attrs = qr/
	\A(?'prop'$str)\.alt(?:
		\.org\.(?'org'$str)|
		\.version\.(?'version'$str)|
		\.since\.date_(?'since_date'\d{8})|
		\.until\.date_(?'until_date'\d{8})|
		\.synth\.$any|
		(?'other'\.$any)
	)*\z/x;

method best_value
{
	my ( $hashref, @props ) = @_;
	my $value;

	PROPERTY:
	for my $prop (@props) {
		for my $org (@$shortname_scheme) {
			for ( keys %$hashref ) {
				/$re_prop_attrs/;
				next unless $+{prop} and $+{prop} eq $prop;
				next unless $+{org}  and $+{org} eq $org;
				next if $+{version};
				next if $+{other};
				next if $+{until_date};

				$value = $hashref->{$_};
				last PROPERTY;
			}
		}
		$value ||= $hashref->{$prop};
	}

	return $value;
}

my $type_re
	= qr/^type:([a-z][a-z0-9_]*)(?::([a-z][a-z0-9_]*))?(?::([a-z][a-z0-9_]*))?/;

our %RE;
my ( %L, @RE_EXCEPTION, @RE_LICENSE, @RE_NAME );

method init_licensepatterns
{
	# reuse if already resolved
	return %L if exists $L{re_trait};

	Regexp::Pattern->import(
		're',
		'License::*' => (
			@OPT_RE2,
			subject             => 'trait',
			-prefix             => 'EXCEPTION_',
			-has_tag_matching   => '^type:trait:exception(?:\z|:)',
			-lacks_tag_matching => '^type:trait:exception:prefix(?:\z|:)',
		),
		'License::*' => (
			@OPT_RE2,
			capture             => 'named',
			subject             => 'trait',
			-prefix             => 'TRAIT_',
			-has_tag_matching   => '^type:trait(?:\z|:)',
			-lacks_tag_matching => '^type:trait:exception(?!:prefix)(?:\z|:)',
		),
		'License::version' => (
			@OPT_RE2,
			capture    => 'named',
			subject    => 'trait',
			anchorleft => 1,
			-prefix    => 'ANCHORLEFT_NAMED_',
		),
		'License::version_later' => (
			@OPT_RE2,
			capture    => 'named',
			subject    => 'trait',
			anchorleft => 1,
			-prefix    => 'ANCHORLEFT_NAMED_',
		),
		'License::any_of' => (
			subject => 'trait',
			-prefix => 'LOCAL_TRAIT_',
		),
		'License::by_fsf' => (
			subject => 'trait',
			-prefix => 'LOCAL_TRAIT_',
		),
		'License::fsf_unlimited' => (
			subject => 'trait',
			-prefix => 'LOCAL_TRAIT_',
		),
		'License::fsf_unlimited_retention' => (
			subject => 'trait',
			-prefix => 'LOCAL_TRAIT_',
		),
		'License::licensed_under' => (
			subject => 'trait',
			-prefix => 'LOCAL_TRAIT_',
		),
		'License::or_at_option' => (
			subject => 'trait',
			-prefix => 'LOCAL_TRAIT_',
		),
		'License::version' => (
			capture => 'numbered',
			subject => 'trait',
			-prefix => 'LOCAL_TRAIT_KEEP_',
		),
		'License::version_numberstring' => (
			capture => 'numbered',
			subject => 'trait',
			-prefix => 'LOCAL_TRAIT_KEEP_',
		),
		'License::apache' => (
			subject => 'name',
			-prefix => 'LOCAL_NAME_',
		),
		'License::gpl' => (
			subject => 'name',
			-prefix => 'LOCAL_NAME_',
		),
		'License::lgpl' => (
			subject => 'name',
			-prefix => 'LOCAL_NAME_',
		),
		'License::mit' => (
			subject => 'name',
			-prefix => 'LOCAL_NAME_',
		),
		'License::*' => (
			@OPT_RE2,
			subject             => 'name',
			-prefix             => 'NAME_',
			anchorleft          => 1,
			-lacks_tag_matching => '^type:trait(?:\z|:)',
		),
		'License::*' => (
			@OPT_RE2,
			subject             => 'grant',
			-prefix             => 'GRANT_',
			-lacks_tag_matching => '^type:trait(?:\z|:)',
		),
		'License::*' => (
			@OPT_RE2,
			subject             => 'license',
			-prefix             => 'LICENSE_',
			-lacks_tag_matching => '^type:trait(?:\z|:)',
		),
	);

	@RE_EXCEPTION = sort map /^EXCEPTION_(.*)/, keys(%RE);
	@RE_LICENSE   = sort map /^LICENSE_(.*)/,   keys(%RE);
	@RE_NAME      = sort map /^NAME_(.*)/,      keys(%RE);

	foreach my $key ( grep {/^[a-z]/} keys(%Regexp::Pattern::License::RE) ) {
		my $val = $Regexp::Pattern::License::RE{$key};
		$L{name}{$key} = $self->best_value( $val, 'name' ) || $key;
		$L{caption}{$key}
			= $self->best_value( $val, 'caption' ) || $val->{name} || $key;
		foreach ( @{ $val->{tags} } ) {
			/$type_re/ or next;
			$L{type}{$1}{$key} = 1;
			if ( $2 and $1 eq 'singleversion' ) {
				$L{series}{$key} = $2;
			}
			if ( $2 and $1 eq 'usage' ) {
				$L{usage}{$key} = $2;
			}

			# TODO: simplify when Regexp::Pattern::License v3.9.0 is required
			if ( $3 and $1 eq 'trait' ) {
				if ( substr( $key, 0, 14 ) eq 'except_prefix_' ) {
					$L{TRAITS_exception_prefix}{$key} = undef;
				}
				else {
					$L{"TRAITS_$2_$3"}{$key} = undef;
				}
			}
		}
	}

	# FIXME: drop when perl doesn't mysteriously  freak out over it
	foreach (qw(any_of)) {
		$L{re_trait}{$_} = '';
	}

	#<<<  do not let perltidy touch this (keep long regex on one line)
	$L{multi_1} = qr/$RE{LOCAL_TRAIT_licensed_under}$RE{LOCAL_TRAIT_any_of}(?:[^.]|\.\S)*$RE{LOCAL_NAME_lgpl}$RE{LOCAL_TRAIT_KEEP_version}?/i;
	$L{multi_2} = qr/$RE{LOCAL_TRAIT_licensed_under}$RE{LOCAL_TRAIT_any_of}(?:[^.]|\.\S)*$RE{LOCAL_NAME_gpl}$RE{LOCAL_TRAIT_KEEP_version}?/i;
	$L{lgpl_5} = qr/$RE{LOCAL_TRAIT_licensed_under}$RE{LOCAL_NAME_lgpl}(?:$RE{LOCAL_TRAIT_by_fsf})?[,;:]?(?: either)? ?$RE{LOCAL_TRAIT_KEEP_version_numberstring},? $RE{LOCAL_TRAIT_or_at_option} $RE{LOCAL_TRAIT_KEEP_version_numberstring}/i;
	$L{gpl_7} = qr/either $RE{LOCAL_NAME_gpl}$RE{LOCAL_TRAIT_KEEP_version}?(?: \((?:the )?"?GPL"?\))?, or $RE{LOCAL_NAME_lgpl}$RE{LOCAL_TRAIT_KEEP_version}?/i;
	$L{bsd_1} = qr/THIS SOFTWARE IS PROVIDED (?:BY (?:\S+ ){1,15})?AS IS AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY/;
	$L{apache_1} = qr/$RE{LOCAL_NAME_apache}$RE{LOCAL_TRAIT_KEEP_version}?(?:(?: or)? [^ ,]*?apache[^ ,]*| \([^(),]+\))*,? or $RE{LOCAL_NAME_gpl}$RE{LOCAL_TRAIT_KEEP_version}?/i;
	$L{apache_2} = qr/$RE{LOCAL_NAME_apache}$RE{LOCAL_TRAIT_KEEP_version}?(?:(?: or)? [^ ,]*?apache[^ ,]*| \([^(),]\))*,? or(?: the)? bsd(?:[ -](\d)-clause)?\b/i;
	$L{apache_4} = qr/$RE{LOCAL_NAME_apache}$RE{LOCAL_TRAIT_KEEP_version}?(?:(?: or)? [^ ,]*?apache[^ ,]*| \([^(),]\))*,? or $RE{LOCAL_NAME_mit}\b/i;
	$L{fsful} = qr/This (\w+)(?: (?:file|script))? is free software; $RE{LOCAL_TRAIT_fsf_unlimited}/i;
	$L{fsfullr} = qr/This (\w+)(?: (?:file|script))?  is free software; $RE{LOCAL_TRAIT_fsf_unlimited_retention}/i;
	$L{trailing_space} = qr/\s+$/;
	$L{LEFTANCHOR_version_of} = qr/^ of /;
	#>>>
}

# license objects where atomic scan must always be applied
my %L_grant_stepwise_incomplete = (

	# usage

	# singleversion
	apache_2 => 1,

	# versioned
	gpl  => 1,
	lgpl => 1,

	# other
	mit_new       => 1,    # misdetects ambiguous "MIT X11" grant
	public_domain => 1,
);

# license objects where stepwise scan cannot be skipped
my %L_grant_atomic_incomplete = (
	afl_1_1    => 1,
	afl_1_2    => 1,
	afl_2      => 1,
	afl_2_1    => 1,
	afl_3      => 1,
	apache_1_1 => 1,
	artistic_1 => 1,
	artistic_2 => 1,
	bsl_1      => 1,
	cc_by_2_5  => 1,
	cc_by_sa   => 1,
	cpl_1      => 1,
	mpl        => 1,
	mpl_1      => 1,
	mpl_1_1    => 1,
	mpl_2      => 1,
	openssl    => 1,
	postgresql => 1,
	zpl_2_1    => 1,
);

# scan for grants first stepwise and if not found then also atomic
# flip either of these flags to test stepwise/atomic pattern coverage
my $skip_stepwise = 0;
my $force_atomic  = 0;

my $contains_bsd2_re = qr/^license:contains:license:bsd_2_clause/;
my @L_contains_bsd   = grep {
	$Regexp::Pattern::License::RE{$_}{tags}
		and grep /$contains_bsd2_re/,
		@{ $Regexp::Pattern::License::RE{$_}{tags} }
} keys(%Regexp::Pattern::License::RE);

my $id2patterns_re = qr/(.*)(?:_(\d+(?:\.\d+)*)(_or_later)?)?/;

method parse_license
{
	my $licensetext = $self->content_extracleaned;

	$self->init_licensepatterns;

	my @L_type_usage         = sort keys %{ $L{type}{usage} };
	my @L_type_singleversion = sort keys %{ $L{type}{singleversion} };
	my @L_type_versioned     = sort keys %{ $L{type}{versioned} };
	my @L_type_unversioned   = sort keys %{ $L{type}{unversioned} };
	my @L_type_combo         = sort keys %{ $L{type}{combo} };
	my @L_type_group         = sort keys %{ $L{type}{group} };

	my $license = "";
	my @spdx_gplver;

	my @agpl = qw(agpl agpl_1 agpl_2 agpl_3);
	my @gpl  = qw(gpl gpl_1 gpl_2 gpl_3);
	my @lgpl = qw(lgpl lgpl_2 lgpl_2_1 lgpl_3);

	my $coverage = Array::IntSpan->new();
	my %match;
	my ( %grant, %license );

   # @clues, @expressions, and @exceptions contains DEP-5 or SPDX identifiers,
   # and @flaws contains non-SPDX notes.
	my ( @clues, @expressions, @exceptions, @flaws );

	my $patterns2id = sub {
		my ( $id, $ver ) = @_;
		return $id
			unless ($ver);
		$_ = $ver;
		s/\.0$//g;
		s/\./_/g;
		return "${id}_$_";
	};
	my $id2patterns = sub {
		return $_[0] =~ /$id2patterns_re/;
	};
	my $gen_license = sub {
		my ( $id, $v, $later, $id2, $v2, $later2 ) = @_;
		my @spdx;
		my $name = $L{name}{$id}    || $id;
		my $desc = $L{caption}{$id} || $id;
		if ($v) {
			push @spdx, $later ? "$name-$v+" : "$name-$v";
			$v .= ' or later' if ($later);
		}
		else {
			push @spdx, $name;
		}
		my ( $name2, $desc2 );
		if ($id2) {
			$name2 = $L{name}{$id2}    || $id2;
			$desc2 = $L{caption}{$id2} || $id2;
			if ($v2) {
				push @spdx, $later2 ? "$name2-$v2+" : "$name2-$v2";
				$v2 .= ' or later' if ($later2);
			}
			else {
				push @spdx, $name2;
			}
		}
		my $legacy = join(
			' ',
			$desc,
			$v     ? "(v$v)"     : (),
			$desc2 ? "or $desc2" : (),
			$v2    ? "(v$v2)"    : (),
		);
		my $expr = join( ' or ', sort @spdx );
		push @expressions, Licensing->new( name => $expr );
		$license = join( ' ', $L{caption}{$legacy} || $legacy, $license );
	};

	# fulltext
	$log->trace('scan for license fulltext');
	my %pos_license;
	foreach my $id (@RE_LICENSE) {
		next unless ( $RE{"LICENSE_$id"} );
		while ( $licensetext =~ /$RE{"LICENSE_$id"}/g ) {
			$pos_license{ $-[0] }{$id} = Trait->new(
				name  => "license($id)",
				begin => $-[0],
				end   => $+[0],
				file  => $self,
			);
		}
	}

	foreach my $trait ( keys %{ $L{TRAITS_exception_prefix} } ) {

		next unless ( $licensetext =~ /$RE{"TRAIT_$trait"}/ );
		while ( $licensetext =~ /$RE{"TRAIT_$trait"}/g ) {
			next
				if (
				defined(
					$coverage->get_range( $-[0], $+[0] )->get_element(0)
				)
				);
			push @clues,
				Trait->new(
				name  => $trait,
				begin => $-[0],
				end   => $+[0],
				file  => $self,
				);
		}
	}
	foreach my $pos ( sort { $a <=> $b } keys %pos_license ) {

		# pick longest or most specific among matched license fulltexts
		my @licenses = nsort_by { $pos_license{$pos}{$_}->end }
		grep { $pos_license{$pos}{$_} ? $pos_license{$pos}{$_}->end : () } (
			@L_type_group,
			@L_type_combo,
			@L_type_unversioned,
			@L_type_versioned,
			@L_type_singleversion,
			@L_type_usage,
		);
		my $license = pop @licenses;
		next unless ($license);
		next
			if defined(
			$coverage->get_range( $pos, $pos_license{$pos}{$license}->end )
				->get_element(0) );
		$coverage->set_range(
			$pos_license{$pos}{$license}->begin,
			$pos_license{$pos}{$license}->end,
			$pos_license{$pos}{$license}
		);
		$license{$license} = 1;
	}

	# grant, stepwise
	$log->trace('scan stepwise for license grant');
	foreach my $trait ( keys %{ $L{TRAITS_grant_prefix} } ) {

		while ( $licensetext =~ /$RE{"TRAIT_$trait"}/g ) {
			next
				if (
				defined(
					$coverage->get_range( $-[0], $+[0] )->get_element(0)
				)
				);
			push @clues,
				Trait->new(
				name  => $trait,
				begin => $-[0],
				end   => $+[0],
				file  => $self,
				);
		}
	}
	LICENSED_UNDER:
	foreach my $licensed_under (
		sort { $a->end <=> $b->end }
		grep { exists $L{TRAITS_grant_prefix}{ $_->name } } @clues
		)
	{
		my $pos = $licensed_under->end;

		# possible grant names
		my @grant_types = (
			@L_type_combo,
			@L_type_unversioned,
			@L_type_versioned,
			@L_type_singleversion,
			@L_type_usage,
		);

		# optional grant version
		my ( $version, $later );

		# scan for prepended version
		substr( $licensetext, $pos ) =~ $RE{ANCHORLEFT_NAMED_version};
		if ( $+{version_number} ) {
			push @clues,
				Trait->new(
				name  => 'version',
				begin => $pos + $-[0],
				end   => $pos + $+[0],
				file  => $self,
				);
			$version = $+{version_number};
			if ( $+{version_later} ) {
				push @clues,
					Trait->new(
					name  => 'or_later',
					begin => $pos + $-[2],
					end   => $pos + $+[2],
					file  => $self,
					);
				$later = $+{version_later};
			}
			if (substr( $licensetext, $pos + $+[0] )
				=~ $L{LEFTANCHOR_version_of} )
			{
				push @clues,
					Trait->new(
					name  => 'version_of',
					begin => $pos + $-[0],
					end   => $pos + $+[0],
					file  => $self,
					);
				$pos += $+[0];
				@grant_types = @L_type_versioned;
			}
			else {
				$version = '';
			}
		}

		# scan for name
		foreach my $id (@RE_NAME) {
			if ( substr( $licensetext, $pos ) =~ $RE{"NAME_$id"} ) {
				$match{$id}{name}{ $pos + $-[0] } = Trait->new(
					name  => "name($id)",
					begin => $pos + $-[0],
					end   => $pos + $+[0],
					file  => $self,
				);
			}
		}

		# pick longest matched license name
		# TODO: include all of most specific type when more are longest
		my @names = nsort_by { $match{$_}{name}{$pos}->end }
		grep { $match{$_} and $match{$_}{name} and $match{$_}{name}{$pos} }
			@grant_types;
		my $name = pop @names;
		if (    $name
			and $match{$name}{name}{$pos}
			and !defined(
				$coverage->get_range( $pos, $match{$name}{name}{$pos}->end )
					->get_element(0)
			)
			and ( !$skip_stepwise or $L_grant_atomic_incomplete{$name} )
			)
		{
			my $pos_end = $pos = $match{$name}{name}{$pos}->end;

			# may include version
			if ( !$version and grep { $_ eq $name } @L_type_versioned ) {
				substr( $licensetext, $pos ) =~ $RE{ANCHORLEFT_NAMED_version};
				if ( $+{version_number} ) {
					push @clues, Trait->new(
						name  => 'version',
						begin => $pos + $-[0],
						end   => $pos + $+[0],
						file  => $self,
					);
					$version = $+{version_number};
					$pos_end = $pos + $+[1];
					if ( $+{version_later} ) {
						push @clues, Trait->new(
							name  => 'or_later',
							begin => $pos + $-[2],
							end   => $pos + $+[2],
							file  => $self,
						);
						$later   = $+{version_later};
						$pos_end = $pos + $+[2];
					}
				}
			}
			elsif ( !$version and grep { $_ eq $name } @L_type_singleversion )
			{
				substr( $licensetext, $pos )
					=~ $RE{ANCHORLEFT_NAMED_version_later};
				if ( $+{version_later} ) {
					push @clues, Trait->new(
						name  => 'or_later',
						begin => $pos + $-[1],
						end   => $pos + $+[1],
						file  => $self,
					);
					$later   = $+{version_later};
					$pos_end = $pos + $+[1];
				}
			}
			if ($version) {
				$version =~ s/(?:\.0)+$//;
				$version =~ s/\./_/g;
				$name .= "_$version";
			}
			if ($later) {
				my $latername = "${name}_or_later";
				push @clues, Trait->new(
					name  => $latername,
					begin => $licensed_under->begin,
					end   => $pos_end,
					file  => $self,
				);
				$grant{$latername} = $clues[-1];
				next LICENSED_UNDER if grep { $grant{$_} } @RE_NAME;
			}
			$grant{$name} = Trait->new(
				name  => "grant($name)",
				begin => $licensed_under->begin,
				end   => $pos_end,
				file  => $self,
			);
			push @clues, $grant{$name};
		}
	}

	# GNU oddities
	if ( grep { $match{$_}{name} } @agpl, @gpl, @lgpl ) {
		$log->trace('scan for GNU oddities');

		# address in AGPL/GPL/LGPL
		while ( $licensetext =~ /$RE{TRAIT_addr_fsf}/g ) {
			foreach (
				qw(addr_fsf_franklin_steet addr_fsf_mass addr_fsf_temple))
			{
				if ( defined $+{$_} ) {
					push @flaws, Flaw->new(
						id    => $Regexp::Pattern::License::RE{$_},
						begin => $-[0],
						end   => $+[0],
						file  => $self,
					);
				}
			}
		}
	}

	# exceptions
	# TODO: conditionally limit to AGPL/GPL/LGPL
	foreach (@RE_EXCEPTION) {
		if ( $licensetext =~ $RE{"EXCEPTION_$_"} ) {
			my $exception = Exception->new(
				id    => $Regexp::Pattern::License::RE{$_},
				begin => $-[0],
				end   => $+[0],
				file  => $self,
			);
			$coverage->set_range( $-[0], $+[0], $exception );
			push @exceptions, $exception;
		}
	}

	# oddities
	$log->trace('scan for oddities');

	# generated file
	if ( $licensetext =~ $RE{TRAIT_generated} ) {
		push @flaws, Flaw->new(
			id    => $Regexp::Pattern::License::RE{generated},
			begin => $-[0],
			end   => $+[0],
			file  => $self,
		);
	}

	# multi-licensing
	my @multilicenses;

	# LGPL, dual-licensed
	# FIXME: add test covering this pattern
	if ( grep { $match{$_}{name} } @lgpl ) {
		$log->trace('scan for LGPL dual-license grant');
		if ( $licensetext =~ $L{multi_1} ) {
			my $meta = Trait->new(
				name  => 'grant(multi#1)',
				begin => $-[0],
				end   => $+[0],
				file  => $self,
			);
			$log->tracef(
				'detected custom pattern multi#1: %s %s %s: %s [%s]',
				'lgpl', $1, $2, $-[0], $path
			);
			push @multilicenses, 'lgpl', $1, $2;
		}
	}

	# GPL, dual-licensed
	# FIXME: add test covering this pattern
	if ( grep { $match{$_}{name} } @gpl ) {
		$log->trace('scan for GPL dual-license grant');
		if ( $licensetext =~ $L{multi_2} ) {
			$log->tracef(
				'detected custom pattern multi#2: %s %s %s: %s [%s]',
				'gpl', $1, $2, $-[0], $path
			);
			push @multilicenses, 'gpl', $1, $2;
		}
	}

	$gen_license->(@multilicenses) if (@multilicenses);

	# LGPL
	if ( grep { $match{$_}{name} } @lgpl ) {
		$log->trace('scan for LGPL fulltext/grant');

		# LGPL, dual versions last
		if ( $licensetext =~ $L{lgpl_5} ) {
			my $grant = Trait->new(
				name  => 'grant(lgpl#5)',
				begin => $-[0],
				end   => $+[0],
				file  => $self,
			);
			$license = "LGPL (v$1 or v$2) $license";
			my $expr = "LGPL-$1 or LGPL-$2";
			push @expressions,
				Grant->new(
				name  => $expr,
				begin => $grant->begin,
				end   => $grant->end,
				file  => $grant->file,
				);
			$match{ 'lgpl_' . $1 =~ tr/./_/r }{custom} = 1;
			$match{ 'lgpl_' . $2 =~ tr/./_/r }{custom} = 1;
			$match{lgpl}{custom} = 1;
		}
	}

	# GPL or LGPL
	if ( grep { $match{$_}{name} } @gpl ) {
		$log->trace('scan for GPL or LGPL dual-license grant');
		if ( $licensetext =~ $L{gpl_7} ) {
			my $grant = Trait->new(
				name  => "grant(gpl#7)",
				begin => $-[0],
				end   => $+[0],
				file  => $self,
			);
			$gen_license->( 'gpl', $1, $2, 'lgpl', $3, $4 );
			$match{gpl}{custom}  = 1;
			$match{lgpl}{custom} = 1;
		}
	}

	# BSD
	if ( grep { $match{$_}{name} } @L_contains_bsd
		and $licensetext =~ $L{bsd_1} )
	{
		$log->trace('scan for BSD fulltext');
		my $grant = Trait->new(
			name  => 'license(bsd#1)',
			begin => $-[0],
			end   => $+[0],
			file  => $self,
		);
		for ($licensetext) {
			next if ( $license{bsd_4_clause} );
			if ( $licensetext =~ $RE{TRAIT_clause_advertising} ) {
				my $grant = Trait->new(
					name  => 'clause_advertising',
					begin => $-[0],
					end   => $+[0],
					file  => $self,
				);
				$gen_license->('bsd_4_clause');
				next;
			}
			next if ( $license{bsd_3_clause} );
			if ( $licensetext =~ $RE{TRAIT_clause_non_endorsement} ) {
				my $grant = Trait->new(
					name  => 'clause_non_endorsement',
					begin => $-[0],
					end   => $+[0],
					file  => $self,
				);
				$gen_license->('bsd_3_clause');
				next;
			}
			next if ( $license{bsd_2_clause} );
			if ( $licensetext =~ $RE{TRAIT_clause_reproduction} ) {
				next
					if (
					defined(
						$coverage->get_range( $-[0], $+[0] )->get_element(0)
					)
					);
				my $grant = Trait->new(
					name  => 'clause_reproduction',
					begin => $-[0],
					end   => $+[0],
					file  => $self,
				);
				$gen_license->('bsd_2_clause');
				next;
			}
			$gen_license->('bsd');
		}
	}

	# Apache dual-licensed with GPL/BSD/MIT
	if ( $match{apache}{name} ) {
		$log->trace('scan for Apache license grant');
		for ($licensetext) {
			if ( $licensetext =~ $L{apache_1} ) {
				my $grant = Trait->new(
					name  => 'grant(apache#1)',
					begin => $-[0],
					end   => $+[0],
					file  => $self,
				);
				$gen_license->( 'apache', $1, $2, 'gpl', $3, $4 );
				$match{ $patterns2id->( 'apache', $1 ) }{custom} = 1;
				next;
			}
			if ( $licensetext =~ $L{apache_2} ) {
				my $grant = Trait->new(
					name  => 'grant(apache#2)',
					begin => $-[0],
					end   => $+[0],
					file  => $self,
				);
				$gen_license->(
					'apache', $1, $2,
					$3 ? "bsd_${3}_clause" : ''
				);
				$match{ $patterns2id->( 'apache', $1 ) }{custom} = 1;
				next;
			}
			if ( $licensetext =~ $L{apache_4} ) {
				my $grant = Trait->new(
					name  => 'grant(apache#4)',
					begin => $-[0],
					end   => $+[0],
					file  => $self,
				);
				$gen_license->( 'apache', $1, $2, 'mit', $3, $4 );
				$match{ $patterns2id->( 'apache', $1 ) }{custom} = 1;
				next;
			}
		}
	}

	# FSFUL
	# FIXME: add test covering this pattern
	$log->trace('scan for FSFUL fulltext');
	if ( not $license{fsful} ) {
		if ( $licensetext =~ $L{fsful} ) {
			my $grant = Trait->new(
				name  => 'grant(fsful#1)',
				begin => $-[0],
				end   => $+[0],
				file  => $self,
			);
			$license = "FSF Unlimited ($1 derivation) $license";
			my $expr = "FSFUL~$1";
			push @expressions,
				Fulltext->new(
				name  => $expr,
				begin => $grant->begin,
				end   => $grant->end,
				file  => $grant->file,
				);
			$match{fsful}{custom} = 1;
		}
	}

	# FSFULLR
	# FIXME: add test covering this pattern
	$log->trace('scan for FSFULLR fulltext');
	if ( not $license{fsfullr} ) {
		if ( $licensetext =~ $L{fsfullr} ) {
			my $grant = Trait->new(
				name  => 'grant(fsfullr#1)',
				begin => $-[0],
				end   => $+[0],
				file  => $self,
			);
			$license
				= "FSF Unlimited (with Retention, $1 derivation) $license";
			my $expr = "FSFULLR~$1";
			push @expressions,
				Fulltext->new(
				name  => $expr,
				begin => $grant->begin,
				end   => $grant->end,
				file  => $grant->file,
				);
			$match{fsfullr}{custom} = 1;
		}
	}

	# usage
	$log->trace('scan atomic for singleversion usage license grant');
	foreach my $id (@L_type_usage) {
		next if ( $match{$id}{custom} );
		if ( !$grant{$id}
			and ( $L_grant_stepwise_incomplete{$id} or $force_atomic ) )
		{
			if ( $licensetext =~ $RE{"GRANT_$id"} ) {
				my $grant = Trait->new(
					name  => "grant($id)",
					begin => $-[0],
					end   => $+[0],
					file  => $self,
				);
				unless (
					defined(
						$coverage->get_range( $-[0], $+[0] )->get_element(0)
					)
					)
				{
					$grant{$id} = Grant->new(
						name  => $id,
						begin => $grant->begin,
						end   => $grant->end,
						file  => $grant->file,
					);
				}
			}
		}

		if ( $grant{$id} ) {
			$coverage->set_range(
				$grant{$id}->begin, $grant{$id}->end,
				$grant{$id}
			);
			$gen_license->( $id2patterns->($id) );

			# skip singleversion and unversioned equivalents
			if ( $L{usage}{$id} ) {
				$log->tracef(
					'flagged license object: %s [%s]',
					$id, $path
				);
				$match{ $L{usage}{$id} }{custom} = 1;
				if ( $L{series}{ $L{usage}{$id} } ) {
					$log->tracef(
						'flagged license object: %s [%s]',
						$L{usage}{$id}, $path
					);
					$match{ $L{series}{ $L{usage}{$id} } }{custom} = 1;
				}
			}
		}
	}

	# singleversion
	$log->trace('scan atomic for singleversion license grant');
	foreach my $id (@L_type_singleversion) {
		if (    !$license{$id}
			and !$grant{$id}
			and !$match{$id}{custom}
			and ( $L_grant_stepwise_incomplete{$id} or $force_atomic ) )
		{
			if ( $licensetext =~ $RE{"GRANT_$id"} ) {
				my $grant = Trait->new(
					name  => "grant($id)",
					begin => $-[0],
					end   => $+[0],
					file  => $self,
				);
				unless (
					defined(
						$coverage->get_range( $-[0], $+[0] )->get_element(0)
					)
					)
				{
					$grant{$id} = Grant->new(
						name  => $id,
						begin => $grant->begin,
						end   => $grant->end,
						file  => $grant->file,
					);
				}
			}
		}

		if ( $license{$id} or $grant{$id} ) {
			$coverage->set_range(
				$grant{$id}->begin, $grant{$id}->end,
				$grant{$id}
			) if $grant{$id};
			$gen_license->( $id2patterns->($id) )
				unless ( $match{$id}{custom} );

			# skip unversioned equivalent
			if ( $L{series}{$id} ) {
				$log->tracef(
					'flagged license object: %s [%s]',
					$id, $path
				);
				$match{ $L{series}{$id} }{custom} = 1;
			}
		}
	}

	# versioned
	$log->trace('scan atomic for versioned license grant');
	foreach my $id (@L_type_versioned) {
		next if ( $match{$id}{custom} );

		# skip name part of another name detected as grant
		# TODO: use less brittle method than name of clue
		next
			if ( $id eq 'cc_by'
			and grep { $_->name eq 'grant(cc_by_sa_3)' } @clues );

		# skip embedded or referenced licenses
		next if ( $license{rpsl_1} and grep { $id eq $_ } qw(mpl python) );

		next if ( $license{$id} );
		if ( !$grant{$id}
			and ( $L_grant_stepwise_incomplete{$id} or $force_atomic ) )
		{
			if ( $RE{"GRANT_$id"} ) {
				if ( $licensetext =~ $RE{"GRANT_$id"} ) {
					my $grant = Trait->new(
						name  => "grant($id)",
						begin => $-[0],
						end   => $+[0],
						file  => $self,
					);
					unless (
						defined(
							$coverage->get_range( $-[0], $+[0] )
								->get_element(0)
						)
						)
					{
						$grant{$id} = Grant->new(
							name  => $id,
							begin => $grant->begin,
							end   => $grant->end,
							file  => $grant->file,
						);
					}
				}
			}
		}

		if ( $grant{$id} ) {
			$coverage->set_range(
				$grant{$id}->begin, $grant{$id}->end,
				$grant{$id}
			);
			$gen_license->($id);
		}
	}

	# other
	# TODO: add @L_type_group
	$log->trace('scan atomic for misc fulltext/grant');
	foreach my $id ( @L_type_unversioned, @L_type_combo ) {
		next if ( !$license{$id} and $match{$id}{custom} );

		next
			unless ( $license{$id}
			or $grant{$id}
			or $L_grant_stepwise_incomplete{$id}
			or $force_atomic );

		# skip embedded or referenced licenses
		next if ( $license{caldera}        and $id eq 'bsd' );
		next if ( $license{cube}           and $id eq 'zlib' );
		next if ( $license{dsdp}           and $id eq 'ntp' );
		next if ( $license{mit_cmu}        and $id eq 'ntp_disclaimer' );
		next if ( $license{ntp_disclaimer} and $id eq 'ntp' );

		if (    !$license{$id}
			and !$grant{$id}
			and $licensetext =~ $RE{"GRANT_$id"} )
		{
			my $grant = Trait->new(
				name  => "grant($id)",
				begin => $-[0],
				end   => $+[0],
				file  => $self,
			);
			unless (
				defined(
					$coverage->get_range( $-[0], $+[0] )->get_element(0)
				)
				)
			{
				$grant{$id} = Grant->new(
					name  => $id,
					begin => $grant->begin,
					end   => $grant->end,
					file  => $grant->file,
				);
			}
		}
		if ( $license{$id} or $grant{$id} ) {
			$coverage->set_range(
				$grant{$id}->begin, $grant{$id}->end,
				$grant{$id}
			) if $grant{$id};
			$gen_license->($id);
		}
	}

	$license =~ s/$L{trailing_space}//;
	my $expr = join( ' and/or ', sort map { $_->name } @expressions );
	$expr ||= 'UNKNOWN';
	if (@exceptions) {
		$expr = "($expr)"
			if ( @expressions > 1 );
		$expr .= ' with ' . join(
			'_AND_',
			sort map { $self->best_value( $_->id, 'name' ) } @exceptions
		) . ' exception';
	}
	if (@flaws) {
		$license .= ' [' . join(
			', ',
			sort map { $self->best_value( $_->id, qw(caption name) ) } @flaws
		) . ']';
	}
	$log->infof(
		'resolved license expression: %s [%s]', $expr,
		$path
	);
	return ( @$shortname_scheme ? $expr : $license ) || 'UNKNOWN';
}

=encoding UTF-8

=head1 AUTHOR

Jonas Smedegaard C<< <dr@jones.dk> >>

=head1 COPYRIGHT AND LICENSE

This program is based on the script "licensecheck" from the KDE SDK,
originally introduced by Stefan Westerfeld C<< <stefan@space.twc.de> >>.

  Copyright © 2007, 2008 Adam D. Barratt

  Copyright © 2012 Francesco Poli

  Copyright © 2016-2021 Jonas Smedegaard

  Copyright © 2017-2021 Purism SPC

This program is free software:
you can redistribute it and/or modify it
under the terms of the GNU Affero General Public License
as published by the Free Software Foundation,
either version 3, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY;
without even the implied warranty
of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU Affero General Public License for more details.

You should have received a copy
of the GNU Affero General Public License along with this program.
If not, see <https://www.gnu.org/licenses/>.

=cut

1;
