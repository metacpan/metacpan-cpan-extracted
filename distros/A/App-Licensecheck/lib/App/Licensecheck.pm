package App::Licensecheck;

use utf8;
use strictures;
use autodie;

use version;
use Log::Any qw($log);
use List::SomeUtils qw(nsort_by);
use Path::Iterator::Rule;
use Path::Tiny;
use Try::Tiny;
use Fcntl qw(:seek);
use Encode;
use Array::IntSpan;
use Regexp::Pattern::License 3.1.102;
use Regexp::Pattern 0.2.12 (
	're',
	'License::*' => (
		engine              => 'RE2',
		subject             => 'trait',
		-prefix             => 'TRAIT_',
		-has_tag_matching   => '^type:trait(?:\z|:)',
		-lacks_tag_matching => '^type:trait:exception(?:\z|:)',
	),
	'License::version' => (
		engine     => 'RE2',
		capture    => 'named',
		subject    => 'trait',
		anchorleft => 1,
		-prefix    => 'ANCHORLEFT_NAMED_',
	),
	'License::licensed_under' => (
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
	'License::*' => (
		engine              => 'RE2',
		subject             => 'name',
		-prefix             => 'NAME_',
		-lacks_tag_matching => '^type:trait(?:\z|:)',
	),
	'License::*' => (
		engine              => 'RE2',
		subject             => 'grant',
		-prefix             => 'GRANT_',
		-lacks_tag_matching => '^type:trait(?:\z|:)',
	),
	'License::*' => (
		engine              => 'RE2',
		subject             => 'license',
		-prefix             => 'LICENSE_',
		-lacks_tag_matching => '^type:trait(?:\z|:)',
	),
);
use String::Copyright 0.003 {
	format => sub { join ' ', $_->[0] || (), $_->[1] || () }
};
use String::Copyright 0.003 {
	threshold_after => 5,
	format          => sub { join ' ', $_->[0] || (), $_->[1] || () },
	},
	'copyright' => { -as => 'copyright_optimistic' };

use Moo;
use MooX::Struct File => [
	qw( $path! $content! ),
	BUILDARGS => sub {
		$log->tracef( 'examining file: %s', ${ $_[1] }[0] );
		return MooX::Struct::BUILDARGS(@_);
	},
	TO_STRING => sub { $_[0]->path->stringify }
	],
	Thing => [
	qw( $name! +begin! +end! $file ),
	BUILDARGS => sub {
		$log->tracef( 'detected something: %s: %d-%d', @{ $_[1] } );
		return MooX::Struct::BUILDARGS(@_);
	}
	],
	Trait => [
	-extends  => ['Thing'],
	BUILDARGS => sub {
		$log->tracef(
			'located trait: %s: %d-%d "%s"',
			@{ $_[1] }[ 0 .. 2 ],
			${ $_[1] }[3]
			? substr(
				${ $_[1] }[3]->content, ${ $_[1] }[1],
				${ $_[1] }[2] - ${ $_[1] }[1]
				)
			: ()
		);
		return MooX::Struct::BUILDARGS(@_);
	}
	],
	Licensing => [
	-extends  => ['Thing'], qw(@traits),
	BUILDARGS => sub {
		$log->debugf( 'collected some licensing: %s: %d-%d', @{ $_[1] } );
		return MooX::Struct::BUILDARGS(@_);
	}
	],
	Fulltext => [
	-extends  => ['Licensing'],
	BUILDARGS => sub {
		$log->debugf( 'collected fulltext: %s: %d-%d', @{ $_[1] } );
		return MooX::Struct::BUILDARGS(@_);
	}
	],
	Grant => [
	-extends  => ['Licensing'],
	BUILDARGS => sub {
		$log->debugf(
			'collected grant: %s: %d-%d "%s"',
			@{ $_[1] }[ 0 .. 2 ],
			${ $_[1] }[3]
			? substr(
				${ $_[1] }[3]->content, ${ $_[1] }[1],
				${ $_[1] }[2] - ${ $_[1] }[1]
				)
			: ()
		);
		return MooX::Struct::BUILDARGS(@_);
	}
	];

use experimental qw(switch);
use namespace::clean;

=head1 NAME

App::Licensecheck - functions for a simple license checker for source files

=head1 VERSION

Version v3.0.46

=cut

our $VERSION = version->declare('v3.0.46');

=head1 SYNOPSIS

    use App::Licensecheck;

    my $app = App::Licensecheck->new;

    $app->lines(0); # Speedup parsing - our file is not huge

    printf "License: %s\nCopyright: %s\n", $app->parse( 'some-file' );

=head1 DESCRIPTION

L<App::Licensecheck> is the core of L<licensecheck> script
to check for licenses of source files.
See the script for casual usage.

=cut

# TODO: make naming scheme configurable
my %L = licensepatterns(qw(debian spdx));

my @RE_LICENSE = sort map /^LICENSE_(.*)/, keys(%RE);
my @RE_NAME    = sort map /^NAME_(.*)/,    keys(%RE);
my @L_family_cc          = sort keys %{ $L{family}{cc} };
my @L_type_singleversion = sort keys %{ $L{type}{singleversion} };
my @L_type_versioned     = sort keys %{ $L{type}{versioned} };
my @L_type_unversioned   = sort keys %{ $L{type}{unversioned} };
my @L_type_combo         = sort keys %{ $L{type}{combo} };
my @L_type_group         = sort keys %{ $L{type}{group} };

my @L_contains_bsd = grep {
	$Regexp::Pattern::License::RE{$_}{tags}
		and grep /^license:contains:license:bsd_2_clause/,
		@{ $Regexp::Pattern::License::RE{$_}{tags} }
} keys(%Regexp::Pattern::License::RE);

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

has log => (
	is      => 'ro',
	default => sub { Log::Any->get_logger },
);

has check_regex => (
	is     => 'rw',
	lazy   => 1,
	coerce => sub {
		my $value = shift;
		return qr/$default_check_regex/x
			if $value eq 'common source files';
		return $value if ref $value eq 'Regexp';
		return qr/$value/;
	},
	default => sub {qr/$default_check_regex/x},
);

has ignore_regex => (
	is     => 'rw',
	lazy   => 1,
	coerce => sub {
		my $value = shift;
		return qr/$default_ignore_regex/x
			if $value eq 'some backup and VCS files';
		return $value if ref $value eq 'Regexp';
		return qr/$value/;
	},
	default => sub {qr/$default_ignore_regex/x},
);

has recursive => (
	is => 'rw',
);

has lines => (
	is      => 'rw',
	default => sub {60},
);

has tail => (
	is      => 'rw',
	default => sub {5000},    # roughly 60 lines of 80 chars
);

has encoding => (
	is     => 'rw',
	coerce => sub {
		find_encoding( $_[0] ) unless ref( $_[0] ) eq 'OBJECT';
	},
);

has verbose => (
	is => 'rw',
);

has skipped => (
	is => 'rw',
);

has deb_fmt => (
	is      => 'rw',
	lazy    => 1,
	default => sub { $_[0]->deb_machine },
);

has deb_machine => (
	is => 'rw',
);

sub find
{
	my ( $self, @paths ) = @_;

	my $check_re  = $self->check_regex;
	my $ignore_re = $self->ignore_regex;
	my $rule      = Path::Iterator::Rule->new;
	my %options   = (
		follow_symlinks => 0,
	);

	$rule->max_depth(1)
		unless $self->recursive;
	$rule->not( sub {/$ignore_re/} );
	$rule->file->nonempty;

	if ( @paths >> 1 ) {
		if ( $self->skipped ) {
			my $skipped = $rule->clone->not( sub {/$check_re/} );
			foreach ( $skipped->all( @paths, \%options ) ) {
				warn "skipped file $_\n";
			}
		}
		$rule->and( sub {/$check_re/} );
	}

	return $rule->all( @paths, \%options );
}

sub parse
{
	my $self     = shift;
	my $file     = path(shift);
	my $encoding = $self->encoding;
	my $all      = $self->lines == 0;

	try {
		return $all
			? $self->parse_file( $file, $encoding )
			: $self->parse_lines( $file, $encoding );
	}
	catch {
		if ( $encoding and /does not map to Unicode/ ) {
			print
				"file $file cannot be read with $encoding->name encoding, will try iso-8859-1:\n$_"
				if $self->verbose;
			try {
				$encoding = find_encoding('iso-8859-1');
				return $all
					? $self->parse_file( $file, $encoding )
					: $self->parse_lines( $file, $encoding );
			}
			catch {
				if (/does not map to Unicode/) {
					print
						"file $file cannot be read with iso-8859-1 encoding, will try binary:\n$_"
						if $self->verbose;
					return $all
						? $self->parse_file($file)
						: $self->parse_lines($file);
				}
				else {
					die $_;
				}
			}
		}
		else {
			die $_;
		}
	}
}

sub parse_file
{
	my $self     = shift;
	my $file     = path(shift);
	my $encoding = shift || undef;

	my $content;

	given ($encoding) {
		when (undef)  { $content = $file->slurp_raw }
		when ('utf8') { $content = $file->slurp_utf8 }
		default {
			$content
				= $file->slurp(
				{ binmode => sprintf ':encoding(%s)', $encoding->name } )
		}
	}
	print qq(----- $file content -----\n$content----- end content -----\n\n)
		if $self->verbose;

	my $cleaned_content = clean_comments($content);

	return (
		$self->parse_license(
			clean_cruft_and_spaces($cleaned_content), $file, 0
		),
		copyright( clean_cruft($cleaned_content) ),
	);
}

sub parse_lines
{
	my $self     = shift;
	my $file     = path(shift);
	my $encoding = shift || undef;
	my $content  = '';

	my $fh;
	my $st = $file->stat;

	given ($encoding) {
		when (undef)  { $fh = $file->openr_raw }
		when ('utf8') { $fh = $file->openr_utf8 }
		default {
			$fh = $file->openr(
				sprintf ':encoding(%s)',
				$encoding->name
			)
		}
	}

	while ( my $line = $fh->getline ) {
		last if ( $fh->input_line_number > $self->lines );
		$content .= $line;
	}
	print qq(----- $file header -----\n$content----- end header -----\n\n)
		if $self->verbose;

	my $cleaned_content = clean_comments($content);

	my $license = $self->parse_license(
		clean_cruft_and_spaces($cleaned_content),
		$file, 0
	);
	my $copyrights = copyright_optimistic( clean_cruft($cleaned_content) );

	if ( not $copyrights and $license eq 'UNKNOWN' ) {
		my $position = $fh->tell;                 # See IO::Seekable
		my $jump     = $st->size - $self->tail;
		$jump = $position if $jump < $position;

		my $tail = '';
		if ( $self->tail and $jump < $st->size ) {
			$fh->seek( $jump, SEEK_SET );         # also IO::Seekable
			$tail .= join( '', $fh->getlines );
		}
		print qq(----- $file tail -----\n$tail----- end tail -----\n\n)
			if $self->verbose;

		my $cleaned_tail = clean_comments($tail);

		$copyrights = copyright_optimistic( clean_cruft($cleaned_tail) );
		$license    = $self->parse_license(
			clean_cruft_and_spaces($cleaned_tail),
			$file, $jump
		);
	}

	$fh->close;
	return ( $license, $copyrights );
}

sub clean_comments
{
	local $_ = shift or return q{};

	# Remove generic comments: look for 4 or more lines beginning with
	# regular comment pattern and trim it. Fall back to old algorithm
	# if no such pattern found.
	my @matches = m/^[ \t]*([^a-zA-Z0-9\s]{1,3})[ \t]+\S/mg;
	if ( @matches >= 4 ) {
		my $comment_re = qr/[ \t]*[\Q$matches[0]\E]{1,3}[ \t]*/;
		s/^$comment_re//mg;
	}

	my @wordmatches = m/^[ \t]*(dnl|REM|COMMENT)[ \t]+\S/mg;
	if ( @wordmatches >= 4 ) {
		my $comment_re = qr/[ \t]*\Q$wordmatches[0]\E[ \t]*/;
		s/^$comment_re//mg;
	}

	# Remove other side of "boxed" comments
	s/[ \t]*[*#][ \t]*$//gm;

	# Remove Fortran comments
	s/^[cC]$//gm;
	s/^[cC] //gm;

	# Remove C / C++ comments
	s#(\*/|/[/*])##g;

	# Strip escaped newline
	s/\s*\\n\s*/ /g;

	return $_;
}

sub clean_cruft
{
	local $_ = shift or return q{};

	# TODO: decode latin1/UTF-8/HTML data instead
	s/\xcb\x97|\xe2\x80[\x90-\x95|\xe2\x81\x83|\xe2\x88\x92|\xef\x89\xa3|\xef\xbc\x8d]|[&](?:ndash|mdash|horbar|minus|[#](?:727|820[8-9]|821[0-3]|8259|8722|65123|65293|x727|z201[0-5]|x2043|x2212|xFE63|xFF0D))[;]/-/gm;
	s/\x58\xa9|\xc2\xa9|\xe2\x92\x9e|\xe2\x92\xb8|\xe2\x93\x92|\xf0\x9f\x84\x92|\xf0\x9f\x84\xab|\xf0\x9f\x85\x92|[&](?:copy|[#](?:169|9374|9400|9426|127250|127275|127314|x0A9|x249E|x24b8|x24D2|x0F112|x0F12B|x0F152))[;]/©/gm;

	# TODO: decode nroff files specifically instead
	s/\\//gm;    # de-cruft nroff files

	return $_;
}

sub clean_cruft_and_spaces
{
	local $_ = shift or return q{};

	tr/\t\r\n/ /;

	# this also removes quotes
	tr% A-Za-z.,@;0-9\(\)/-%%cd;
	tr/ //s;

	return $_;
}

sub licensepatterns
{
	my @org = @_;

	my %list;

	foreach my $key ( grep {/^[a-z]/} keys(%Regexp::Pattern::License::RE) ) {
		my $val = $Regexp::Pattern::License::RE{$key};
		foreach (@org) {
			$list{name}{$key}    ||= $val->{"name.alt.org.$_"};
			$list{caption}{$key} ||= $val->{"caption.alt.org.$_"};
		}
		$list{name}{$key}    ||= $val->{name}    || $key;
		$list{caption}{$key} ||= $val->{caption} || $val->{name} || $key;
		foreach ( @{ $val->{tags} } ) {
			/^(family|type):([a-z][a-z0-9_]*)(?::([a-z][a-z0-9_]*))?/;
			$list{family}{$2}{$key} = 1
				if ( $2 and $1 eq 'family' );
			$list{type}{$2}{$key} = 1
				if ( $2 and $1 eq 'type' );
			if ( $3 and $1 eq 'type' and $2 eq 'singleversion' ) {
				$list{series}{$key} = $3;
			}
		}
		foreach my $subject (qw(grant_license name)) {
			my $re = re( "License::$key", subject => $subject =~ tr/_/,/r )
				or next;
			$list{"re_$subject"}{$key} = ref($re) ? $re : qr/$re/;
		}
	}
	foreach my $trait (
		qw(any_of or_at_option
		fsf_unlimited fsf_unlimited_retention
		version_later_postfix)
		)
	{
		my $re = re( "License::$trait", subject => 'trait' );
		$list{re_trait}{$trait} = ref($re) ? $re : qr/$re/;
	}

	#<<<  do not let perltidy touch this (keep long regex on one line)
	$list{re_grant_license}{local}{version_gnu_or_later}{1} = qr/(?:(?:either )?\b|GPL)$RE{LOCAL_TRAIT_KEEP_version_numberstring},? $list{re_trait}{version_later_postfix}/;
	$list{re_grant_license}{local}{version_gnu}{1} = qr/$RE{LOCAL_TRAIT_KEEP_version_numberstring}(?:[.,])? (?:\(?only\)?.? )?(?:of $list{re_name}{gnu}|(as )?published by the Free Software Foundation)/i;
	$list{re_grant_license}{local}{version_gnu}{2} = qr/$list{re_name}{gnu}(?:[;,] )?$RE{LOCAL_TRAIT_KEEP_version_numberstring}/i;
	$list{re_grant_license}{local}{version_gnu}{3} = qr/GPL as published by the Free Software Foundation, $RE{LOCAL_TRAIT_KEEP_version_numberstring}/i;
	$list{re_grant_license}{local}{address_agpl_gpl_lgpl}{1} = qr/(?:675 Mass Ave|59 Temple Place|51 Franklin Steet|02139|02111-1307)/i;
	$list{re_grant_license}{local}{exception_agpl_gpl_lgpl}{1} = qr/permission (?:is (also granted|given))? to link (the code of )?this program with (any edition of )?(Qt|the Qt library)/i;
	$list{re_grant_license}{local}{generated}{2} = qr/(All changes made in this file will be lost|DO NOT ((?:HAND )?EDIT|delete this file|modify)|edit the original|Generated (automatically|by|from|data|with)|generated.*file|auto[- ]generated)/i;
	$list{re_grant_license}{local}{multi}{1} = qr/$RE{LOCAL_TRAIT_licensed_under}$list{re_trait}{any_of}(?:[^.]|\.\S)*$list{re_name}{lgpl}$RE{LOCAL_TRAIT_KEEP_version}?/i;
	$list{re_grant_license}{local}{multi}{2} = qr/$RE{LOCAL_TRAIT_licensed_under}$list{re_trait}{any_of}(?:[^.]|\.\S)*$list{re_name}{gpl}$RE{LOCAL_TRAIT_KEEP_version}?/i;
	$list{re_grant_license}{local}{lgpl}{4} = qr/$RE{LOCAL_TRAIT_licensed_under}$RE{LOCAL_TRAIT_KEEP_version}? of $list{re_name}{lgpl}/i;
	$list{re_grant_license}{local}{lgpl}{5} = qr/$RE{LOCAL_TRAIT_licensed_under}$list{re_name}{lgpl}\b[,;:]?(?: either)? ?$RE{LOCAL_TRAIT_KEEP_version_numberstring},? $list{re_trait}{or_at_option} $RE{LOCAL_TRAIT_KEEP_version_numberstring}/i;
	$list{re_grant_license}{local}{lgpl}{6} = qr/$RE{LOCAL_TRAIT_licensed_under}$list{re_name}{lgpl}(?:[,;:]?(?: either)?$RE{LOCAL_TRAIT_KEEP_version}?)?/i;
	$list{re_grant_license}{local}{gpl}{4} = qr/Terms of the Perl programming language system itself/;
	$list{re_grant_license}{local}{gpl}{7} = qr/either $list{re_name}{gpl}$RE{LOCAL_TRAIT_KEEP_version}?(?: \((?:the )?"?GPL"?\))?, or $list{re_name}{lgpl}$RE{LOCAL_TRAIT_KEEP_version}?/i;
	$list{re_grant_license}{local}{gpl}{8} = qr/$RE{LOCAL_TRAIT_licensed_under}(?:version \S+ (?:\(?only\)? )?of )?$list{re_name}{gpl}/i;
	$list{re_grant_license}{local}{gpl}{9} = qr/$RE{LOCAL_TRAIT_licensed_under}(?:version \S+ (?:\(?only\)? )?of )?$list{re_name}{gpl}$RE{LOCAL_TRAIT_KEEP_version}?/i;
	$list{re_grant_license}{local}{bsd}{1} = qr/THIS SOFTWARE IS PROVIDED (?:BY (?:\S+ ){1,15})?AS IS AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY/;
	$list{re_grant_license}{local}{apache}{1} = qr/$list{re_name}{apache}$RE{LOCAL_TRAIT_KEEP_version}?(?:(?: or)? [^ ,]*?apache[^ ,]*| \([^(),]+\))*,? or $list{re_name}{gpl}$RE{LOCAL_TRAIT_KEEP_version}?/i;
	$list{re_grant_license}{local}{apache}{2} = qr/$list{re_name}{apache}$RE{LOCAL_TRAIT_KEEP_version}?(?:(?: or)? [^ ,]*?apache[^ ,]*| \([^(),]\))*,? or(?: the)? bsd(?:[ -](\d)-clause)?\b/i;
	$list{re_grant_license}{local}{apache}{4} = qr/$list{re_name}{apache}$RE{LOCAL_TRAIT_KEEP_version}?(?:(?: or)? [^ ,]*?apache[^ ,]*| \([^(),]\))*,? or $list{re_name}{mit}\b/i;
	$list{re_grant_license}{local}{fsful}{1} = qr/This (\w+)(?: (?:file|script))? is free software; $list{re_trait}{fsf_unlimited}/i;
	$list{re_grant_license}{local}{fsfullr}{1} = qr/This (\w+)(?: (?:file|script))?  is free software; $list{re_trait}{fsf_unlimited_retention}/i;
	$list{re_grant_license}{local}{php}{1} = qr/$RE{LOCAL_TRAIT_licensed_under}$RE{LOCAL_TRAIT_KEEP_version_numberstring} of the PHP license/;
	foreach my $id ( sort keys %{ $list{type}{versioned} } ) {
		$list{re_grant_license}{local}{versioned}{$id} = qr/$RE{LOCAL_TRAIT_licensed_under}$list{re_name}{$id}$RE{LOCAL_TRAIT_KEEP_version}?/;
	}
	$list{re_grant_license}{local}{trailing_space} = qr/\s+$/;
	$list{re_license}{local}{gpl_1}{1} = qr/<?name of author>?\s+This program is free software; you can redistribute it and\/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 1/;
	$list{re_license}{local}{gpl_2}{1} = qr/<?name of author>?\s+This program is free software; you can redistribute it and\/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2/;
	$list{re_license}{local}{gpl_3}{1} = qr/<?name of author>?\s+This program is free software:? you can redistribute it and\/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3/;
	#>>>

	return %list;
}

# grant pattern can be auto-skipped only stepwise, atomic scan is mandatory
my %L_grant_stepwise_incomplete = (

	# singleversion
	agpl_3     => 1,
	apache_2   => 1,
	cecill_2_1 => 1,

	# versioned
	agpl => 1,
	cddl => 1,
	epl  => 1,
	gfdl => 1,
	gpl  => 1,
	lgpl => 1,
	qpl  => 1,

	# other
	curl          => 1,
	ftl           => 1,
	isc           => 1,
	llgpl         => 1,
	mit_new       => 1,
	perl          => 1,
	public_domain => 1,
	zlib          => 1,
);

# grant pattern can be auto-skipped for only one of stepwise or atomic
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

# grant pattern cannot be auto-skipped, neither stepwise nor atomic
my %L_grant_incomplete = (
	gpl => 1,
);

# auto-skip by default; enable to test pattern coverage
my $force_stepwise = 0;
my $force_atomic   = 0;

sub parse_license
{
	my ( $self, $licensetext, $path, $position ) = @_;

	my $file = File [ $path, $licensetext ];

	my $gplver    = "";
	my $extrainfo = "";
	my $license   = "";
	my @spdx_gplver;

	my @agpl = qw(agpl agpl_1 agpl_2 agpl_3);
	my @gpl  = qw(gpl gpl_1 gpl_2 gpl_3);
	my @lgpl = qw(lgpl lgpl_2 lgpl_2_1 lgpl_3);

	my $coverage = Array::IntSpan->new();
	my %match;
	my ( %grant, %license );

  # @clues and @expressions contains DEP-5 or SPDX identifiers
  # it would be more efficient to store license info only in this
  # array and then convert it to legacy formulation, but there are
  # corner case (like extrainfo) that would not fit. So the old storage scheme
  # is kept with the new (SPDX/DEP-5) scheme to keep backward compat.
	my ( @clues, @expressions );

	my $spdx_extra;
	my $gen_spdx = sub {
		my @ret
			= @spdx_gplver ? ( map { "$_[0]-$_"; } @spdx_gplver ) : ( $_[0] );
		push @ret, $spdx_extra if $spdx_extra;
		return @ret;
	};
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
		return $_[0] =~ /(.*)(?:_(\d+(?:\.\d+)*)(_or_laster)?)?/;
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
		push @expressions, Licensing [ $expr, -1, -1 ];
		$license = join( ' ', $L{caption}{$legacy} || $legacy, $license );
	};

	# fulltext
	$self->log->tracef('scan for fulltext license');
	my %pos_license;
	foreach my $id (@RE_LICENSE) {
		next unless ( $RE{"LICENSE_$id"} );
		while ( $licensetext =~ /$RE{"LICENSE_$id"}/g ) {
			$pos_license{ $-[0] }{$id}
				= Trait [ "license($id)", $-[0], $+[0], $file ];
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
		);
		my $license = pop @licenses;
		next unless ($license);
		next
			if defined(
			$coverage->get_range( $pos, $pos_license{$pos}{$license}->end )
				->get_element(0) );
		$coverage->set_range(
			@{ $pos_license{$pos}{$license}->TO_ARRAY }[ 1, 2 ], $license );
		$license{$license} = 1;
	}

	foreach my $trait (qw(license_label_trove license_label licensed_under)) {
		while ( $licensetext =~ /$RE{"TRAIT_$trait"}/g ) {
			next
				if (
				defined(
					$coverage->get_range( $-[0], $+[0] )->get_element(0)
				)
				);
			push @clues, Trait [ $trait, $-[0], $+[0], $file ];
		}
	}

	# grant, stepwise
	$self->log->tracef('stepwise scan for grant');
	LICENSED_UNDER:
	foreach my $pos (
		(   sort { $a <=> $b } map { $_->end }
			grep { $_->name eq 'license_label_trove' } @clues
		),
		(   sort { $a <=> $b } map { $_->end }
			grep { $_->name eq 'license_label' } @clues
			),
		(   sort { $a <=> $b } map { $_->end }
			grep { $_->name eq 'licensed_under' } @clues
			),
		)
	{
		my $pos_begin = $pos;

		# possible grant names
		my @grant_types = (
			@L_type_combo,
			@L_type_unversioned,
			@L_type_versioned,
			@L_type_singleversion,
		);

		# optional grant version
		my ( $version, $later );

		# scan for prepended version
		substr( $licensetext, $pos ) =~ $RE{ANCHORLEFT_NAMED_version};
		if ( $+{version_number} ) {
			push @clues,
				Trait [ 'version', $pos + $-[0], $pos + $+[0], $file ];
			$version = $+{version_number};
			if ( $+{version_later} ) {
				push @clues,
					Trait [ 'or_later', $pos + $-[2], $pos + $+[2], $file ];
				$later = $+{version_later};
			}
			$pos         = $pos + $+[0];
			@grant_types = @L_type_versioned;
		}

		# scan for name
		foreach my $id (@RE_NAME) {
			if ( substr( $licensetext, $pos, 200 ) =~ $RE{"NAME_$id"} ) {
				$match{$id}{name}{ $pos + $-[0] } = Trait [
					"name($id)", $pos + $-[0], $pos + $+[0],
					$file
				];
			}
		}

		# pick longest matched license name
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
			and ( $force_stepwise or $L_grant_atomic_incomplete{$name} )
			and !$L_grant_incomplete{$name}
			)
		{
			my $pos_end = $pos = $match{$name}{name}{$pos}->end;

			# may include version
			if ( !$version and grep { $_ eq $name } @L_type_versioned ) {
				substr( $licensetext, $pos ) =~ $RE{ANCHORLEFT_NAMED_version};
				if ( $+{version_number} ) {
					push @clues, Trait [
						'version',
						$pos + $-[0], $pos + $+[0], $file
					];
					$version = $+{version_number};
					$pos_end = $pos + $+[1];
					if ( $+{version_later} ) {
						push @clues, Trait [
							'or_later',
							$pos + $-[2], $pos + $+[2], $file
						];
						$later   = $+{version_later};
						$pos_end = $pos + $+[2];
					}
				}
			}
			if ($version) {
				$version =~ s/(?:\.0)+$//;
				$name .= "_$version";
			}
			if ($later) {
				my $latername = "${name}_or_later";
				push @clues, Trait [ $latername, $pos_begin, $pos_end ];
				$grant{$latername} = 1;
				next LICENSED_UNDER if grep { $grant{$_} } @RE_NAME;
			}
			$grant{$name}
				= Trait [ "grant($name)", $pos_begin, $pos_end, $file ];
			push @clues, $grant{$name};
		}
	}

	# GPL version
	if ( grep { $match{$_}{name} } @gpl ) {
		$self->log->tracef('custom scan for GPL version');
		given ($licensetext) {
			when ( $L{re_grant_license}{local}{version_gnu_or_later}{1} ) {
				my $ver = Trait [
					'version(gnu_or_later#1)', $-[0], $+[0],
					$file
				];
				$gplver      = " (v$1 or later)";
				@spdx_gplver = ( $1 . '+' );
			}
			when ( $L{re_grant_license}{local}{version_gnu}{1} ) {
				my $ver = Trait [ 'version(gnu#1)', $-[0], $+[0], $file ];
				$gplver      = " (v$1)";
				@spdx_gplver = ($1);
			}
			when ( $L{re_grant_license}{local}{version_gnu}{2} ) {
				my $ver = Trait [ 'version(gnu#2)', $-[0], $+[0], $file ];
				$gplver      = " (v$1)";
				@spdx_gplver = ($1);
			}

			# FIXME: add test covering this pattern
			when ( $L{re_grant_license}{local}{version_gnu}{3} ) {
				$self->log->tracef(
					'detected custom pattern version_gnu#3: %s: %s [%s]',
					$1, $-[0], $file
				);
				$gplver      = " (v$1)";
				@spdx_gplver = ($1)
			}
		}
	}

	# GNU oddities
	if ( grep { $match{$_}{name} } @agpl, @gpl, @lgpl ) {
		$self->log->tracef('custom scan for GNU oddities');

		# address in AGPL/GPL/LGPL
		given ($licensetext) {
			when ( $L{re_grant_license}{local}{address_agpl_gpl_lgpl}{1} ) {
				my $flaw
					= Trait [ 'flaw(agpl_gpl_lgpl#1)', $-[0], $+[0], $file ];
				$extrainfo = " (with incorrect FSF address)$extrainfo";
			}
		}

		# exception for AGPL/GPL/LGPL
		given ($licensetext) {
			when ( $L{re_grant_license}{local}{exception_agpl_gpl_lgpl}{1} ) {
				my $exception = Trait [
					'exception(agpl_gpl_lgpl#1)', $-[0], $+[0],
					$file
				];
				$extrainfo  = " (with Qt exception)$extrainfo";
				$spdx_extra = 'with Qt exception';
			}
		}
	}

	# oddities
	$self->log->tracef('custom scan for oddities');
	given ($licensetext) {

		# generated file
		break if ( $license{bsl_1} );
		when ( $L{re_grant_license}{local}{generated}{2} ) {
			my $meta = Trait [ 'GENERATED FILE', $-[0], $+[0], $file ];
			$license = $meta->name;
		}
	}

	# multi-licensing
	my @multilicenses;

	# LGPL, dual-licensed
	# FIXME: add test covering this pattern
	if ( grep { $match{$_}{name} } @lgpl ) {
		$self->log->tracef('custom scan for LGPL dual-license grant');
		if ( $licensetext =~ $L{re_grant_license}{local}{multi}{1} ) {
			my $meta = Trait [ 'grant(multi#1)', $-[0], $+[0], $file ];
			$self->log->tracef(
				'detected custom pattern multi#1: %s %s %s: %s [%s]',
				'lgpl', $1, $2, $-[0], $file
			);
			push @multilicenses, 'lgpl', $1, $2;
		}
	}

	# GPL, dual-licensed
	# FIXME: add test covering this pattern
	if ( grep { $match{$_}{name} } @gpl ) {
		$self->log->tracef('custom scan for GPL dual-license grant');
		if ( $licensetext =~ $L{re_grant_license}{local}{multi}{2} ) {
			$self->log->tracef(
				'detected custom pattern multi#2: %s %s %s: %s [%s]',
				'gpl', $1, $2, $-[0], $file
			);
			push @multilicenses, 'gpl', $1, $2;
		}
	}

	$gen_license->(@multilicenses) if (@multilicenses);

	# GPL fulltext
	if ( grep { $match{$_}{name} } @gpl ) {
		$self->log->tracef('custom scan for GPL fulltext');
		given ($licensetext) {
			when ( $L{re_license}{local}{gpl_3}{1} ) {
				my $fulltext
					= Trait [ "license(gpl_3#1)", $-[0], $+[0], $file ];
				$coverage->set_range( $-[0], $+[0], $license );
				$license{gpl_3} = 1;
			}
			when ( $L{re_license}{local}{gpl_2}{1} ) {
				my $fulltext
					= Trait [ "license(gpl_2#1)", $-[0], $+[0], $file ];
				$coverage->set_range( $-[0], $+[0], $license );
				$license{gpl_2} = 1;
			}
			when ( $L{re_license}{local}{gpl_1}{1} ) {
				my $fulltext
					= Trait [ "license(gpl_1#1)", $-[0], $+[0], $file ];
				$coverage->set_range( $-[0], $+[0], $license );
				$license{gpl_1} = 1;
			}
		}
	}

	# LGPL
	if ( grep { $match{$_}{name} } @lgpl ) {
		$self->log->tracef('custom scan for LGPL fulltext/grant');
		given ($licensetext) {

			# LGPL, version first
			# FIXME: add test covering this pattern
			when ( $L{re_grant_license}{local}{lgpl}{4} ) {
				$self->log->tracef(
					'detected custom pattern lgpl#4: %s %s %s: %s [%s]',
					'lgpl', $1, $2, $-[0], $file
				);
				$gen_license->( 'lgpl', $1, $2 );
				$match{lgpl}{custom} = 1;
			}

			# LGPL, dual versions last
			when ( $L{re_grant_license}{local}{lgpl}{5} ) {
				my $grant = Trait [ 'grant(lgpl#5)', $-[0], $+[0], $file ];
				$license = "LGPL (v$1 or v$2) $license";
				my $expr = "LGPL-$1 or LGPL-$2";
				push @expressions,
					Grant [ $expr, @{ $grant->TO_ARRAY }[ 1 .. 3 ] ];
				$match{lgpl}{custom} = 1;
			}

			if ( $license{gpl_2} ) {
				$match{lgpl}{custom} = 1;
				break;
			}

			# LGPL, version last
			when ( $L{re_grant_license}{local}{lgpl}{6} ) {
				my $grant = Trait [ "grant(lgpl#6)", $-[0], $+[0], $file ];
				$gen_license->( 'lgpl', $1, $2 );
				$match{lgpl}{custom} = 1;
			}
		}
	}

	# AGPL
	if ( grep { $match{$_}{name} } @agpl ) {
		$self->log->tracef('custom scan for AGPL fulltext/grant');
		given ($licensetext) {
			when ( !!$grant{agpl} ) {
				my $expr = join ' ', $gen_spdx->('AGPL');
				break if ( $license{agpl_3} and $expr eq 'AGPL-3' );
				$license = "AGPL$gplver$extrainfo $license";
				push @expressions,
					Grant [ $expr, @{ $grant{agpl}->TO_ARRAY }[ 1 .. 3 ] ];
				$match{agpl}{custom} = 1;
			}
			break if ( $license{cecill_2_1} );
			break if ( $license{gpl_3} );
			break if ( $license{mpl_2} );

			# FIXME: add test covering this pattern
			when ( $L{re_grant_license}{local}{agpl}{5} ) {
				$self->log->tracef(
					'detected custom pattern agpl#5: agpl %s %s: %s [%s]',
					$1, $2, $-[0], $file
				);
				$gen_license->( 'agpl', $1, $2 );
				$match{agpl}{custom} = 1;
			}
		}
	}

	# GPL
	if ( grep { $match{$_}{name} } @gpl ) {
		$self->log->tracef('custom scan for GPL fulltext/grant');
		given ($licensetext) {
			if ( grep { $license{$_} or $grant{$_} } @agpl, @gpl ) {
				$match{gpl}{custom} = 1;
				break;
			}

			# exclude Perl combo license
			when ( $L{re_grant_license}{local}{gpl}{4} ) {
				$self->log->tracef(
					'detected and skipped custom pattern gpl#4: %s [%s]',
					$-[0], $file
				);
				$match{gpl}{custom} = 1;
				break;
			}

			# GPL or LGPL
			when ( $L{re_grant_license}{local}{gpl}{7} ) {
				my $grant = Trait [ "grant(gpl#7)", $-[0], $+[0], $file ];
				$gen_license->( 'gpl', $1, $2, 'lgpl', $3, $4 );
				$match{gpl}{custom} = 1;
			}
			if ( $gplver or $extrainfo ) {
				when ( $L{re_grant_license}{local}{gpl}{8} ) {
					my $grant = Trait [ "grant(gpl#8)", $-[0], $+[0], $file ];
					$license = "GPL$gplver$extrainfo $license";
					my $expr = join ' ', $gen_spdx->('GPL');
					push @expressions,
						Grant [ $expr, @{ $grant->TO_ARRAY }[ 1 .. 3 ] ];
					$match{gpl}{custom} = 1;
				}
			}
			break if ( $license{cecill_1_1} );
			when ( $L{re_grant_license}{local}{gpl}{9} ) {
				my $grant = Trait [ "grant(gpl#9)", $-[0], $+[0], $file ];
				$gen_license->( 'gpl', $1, $2 );
				$match{gpl}{custom} = 1;
			}
		}
	}

	# BSD
	if ( grep { $match{$_}{name} } @L_contains_bsd
		and $licensetext =~ $L{re_grant_license}{local}{bsd}{1} )
	{
		$self->log->tracef('custom scan for BSD fulltext');
		my $grant = Trait [ 'license(bsd#1)', $-[0], $+[0], $file ];
		given ($licensetext) {
			break if ( $license{bsd_4_clause} );
			when ( $RE{TRAIT_clause_advertising} ) {
				my $grant
					= Trait [ 'clause_advertising', $-[0], $+[0], $file ];
				$gen_license->('bsd_4_clause');
			}
			break if ( $license{bsd_3_clause} );
			when ( $RE{TRAIT_clause_non_endorsement} ) {
				my $grant
					= Trait [ 'clause_non_endorsement', $-[0], $+[0], $file ];
				$gen_license->('bsd_3_clause');
			}
			break if ( $license{bsd_2_clause} );
			when ( $RE{TRAIT_clause_reproduction} ) {
				my $grant
					= Trait [ 'clause_reproduction', $-[0], $+[0], $file ];
				$gen_license->('bsd_2_clause');
			}
			default {
				$gen_license->('bsd');
			}
		}
	}

	# Apache dual-licensed with GPL/BSD/MIT
	if ( $match{apache}{name} ) {
		$self->log->tracef('custom scan for Apache grant');
		given ($licensetext) {
			when ( $L{re_grant_license}{local}{apache}{1} ) {
				my $grant = Trait [ 'grant(apache#1)', $-[0], $+[0], $file ];
				$gen_license->( 'apache', $1, $2, 'gpl', $3, $4 );
				$match{ $patterns2id->( 'apache', $1 ) }{custom} = 1;
			}
			when ( $L{re_grant_license}{local}{apache}{2} ) {
				my $grant = Trait [ 'grant(apache#2)', $-[0], $+[0], $file ];
				$gen_license->( 'apache', $1, $2, "bsd_${3}_clause" );
				$match{ $patterns2id->( 'apache', $1 ) }{custom} = 1;
			}
			when ( $L{re_grant_license}{local}{apache}{4} ) {
				my $grant = Trait [ 'grant(apache#4)', $-[0], $+[0], $file ];
				$gen_license->( 'apache', $1, $2, 'mit', $3, $4 );
				$match{ $patterns2id->( 'apache', $1 ) }{custom} = 1;
			}
		}
	}

	# FSFUL
	# FIXME: add test covering this pattern
	$self->log->tracef('custom scan for FSFUL fulltext');
	given ($licensetext) {
		break if ( $license{fsful} );
		when ( $L{re_grant_license}{local}{fsful}{1} ) {
			my $grant = Trait [ 'grant(fsful#1)', $-[0], $+[0], $file ];
			$license = "FSF Unlimited ($1 derivation) $license";
			my $expr = "FSFUL~$1";
			push @expressions,
				Fulltext [ $expr, @{ $grant->TO_ARRAY }[ 1 .. 3 ] ];
			$match{fsful}{custom} = 1;
		}
	}

	# FSFULLR
	# FIXME: add test covering this pattern
	$self->log->tracef('custom scan for FSFULLR fulltext');
	given ($licensetext) {
		break if ( $license{fsfullr} );
		when ( $L{re_grant_license}{local}{fsfullr}{1} ) {
			my $grant = Trait [ 'grant(fsfullr#1)', $-[0], $+[0], $file ];
			$license
				= "FSF Unlimited (with Retention, $1 derivation) $license";
			my $expr = "FSFULLR~$1";
			push @expressions,
				Fulltext [ $expr, @{ $grant->TO_ARRAY }[ 1 .. 3 ] ];
			$match{fsfullr}{custom} = 1;
		}
	}

	# PHP
	# FIXME: add test covering this pattern
	$self->log->tracef('custom scan for PHP grant');
	given ($licensetext) {
		when ( $L{re_grant_license}{local}{php}{1} ) {
			my $grant = Trait [ 'grant(php#1)', $-[0], $+[0], $file ];
			$gen_license->( 'PHP', $1 );
		}
	}

	# singleversion
	$self->log->tracef('atomic scan for singleversion grant');
	foreach my $id (@L_type_singleversion) {
		next if ( $match{$id}{custom} );

		if (    !$license{$id}
			and !$grant{$id}
			and ( $L_grant_stepwise_incomplete{$id} or $force_atomic ) )
		{
			if ( $licensetext =~ $RE{"GRANT_$id"} ) {
				my $grant = Trait [ "grant($id)", $-[0], $+[0], $file ];
				unless (
					defined(
						$coverage->get_range( $-[0], $+[0] )->get_element(0)
					)
					)
				{
					$grant{$id}
						= Grant [ $id, @{ $grant->TO_ARRAY }[ 1 .. 3 ] ];
				}
			}
		}

		if ( $license{$id} or $grant{$id} ) {
			$gen_license->( $id2patterns->($id) );

			# skip unversioned equivalent
			if ( $L{series}{$id} ) {
				$self->log->tracef(
					'flagged license object: %s [%s]',
					$id, $file
				);
				$match{ $L{series}{$id} }{custom} = 1;
			}
		}
	}

	# versioned
	$self->log->tracef('atomic scan for versioned grant');
	foreach my $id (@L_type_versioned) {
		next if ( $match{$id}{custom} );

		next unless ( $L_grant_stepwise_incomplete{$id} or $force_atomic );

		# skip name part of another name detected as grant
		# TODO: use less brittle method than name of clue
		next
			if ( $id eq 'cc_by'
			and grep { $_->name eq 'grant(cc_by_sa_3)' } @clues );

		# skip embedded or referenced licenses
		next if ( $license{rpsl_1} and grep { $id eq $_ } qw(mpl python) );
		if ( $match{$id}{name} ) {
			if ( $licensetext =~ $L{re_grant_license}{local}{versioned}{$id} )
			{
				my $grant = Trait [ "grant($id)", $-[0], $+[0], $file ];
				$gen_license->( $id, $1, $2 );
				$match{$id}{custom} = 1;
			}
		}
		next if ( $match{$id}{custom} );
		next if ( $license{$id} );
		if ( $RE{"GRANT_$id"} ) {
			if ( $licensetext =~ $RE{"GRANT_$id"} ) {
				my $grant = Trait [ "grant($id)", $-[0], $+[0], $file ];
				unless (
					defined(
						$coverage->get_range( $-[0], $+[0] )->get_element(0)
					)
					)
				{
					$gen_license->($id);
				}
			}
		}
	}

	# other
	$self->log->tracef('atomic scan for misc fulltext/grant');
	foreach my $id ( @L_type_unversioned, @L_type_combo, @L_type_group ) {
		next if ( !$license{$id} and $match{$id}{custom} );

		next
			unless ( $license{$id}
			or $grant{$id}
			or $L_grant_stepwise_incomplete{$id}
			or $force_atomic );

		# skip embedded or referenced licenses
		next if ( $license{cube}           and $id eq 'zlib' );
		next if ( $license{dsdp}           and $id eq 'ntp' );
		next if ( $license{mit_cmu}        and $id eq 'ntp_disclaimer' );
		next if ( $license{ntp_disclaimer} and $id eq 'ntp' );

		if (    !$license{$id}
			and !$grant{$id}
			and $licensetext =~ $RE{"GRANT_$id"} )
		{
			my $grant = Trait [ "grant($id)", $-[0], $+[0], $file ];
			unless (
				defined(
					$coverage->get_range( $-[0], $+[0] )->get_element(0)
				)
				)
			{
				$grant{$id} = Grant [ $id, @{ $grant->TO_ARRAY }[ 1 .. 3 ] ];
			}
		}
		if ( $license{$id} or $grant{$id} ) {
			$gen_license->($id);
		}
	}

	# Remove trailing spaces.
	$license =~ s/$L{re_grant_license}{local}{trailing_space}//;
	my $expr = join( ' and/or ', sort map { $_->name } @expressions );
	$self->log->infof(
		'resolved license expression: %s [%s]', $expr,
		$file
	);
	return ( $self->deb_fmt ? $expr : $license ) || 'UNKNOWN';
}

=encoding UTF-8

=head1 AUTHOR

Jonas Smedegaard C<< <dr@jones.dk> >>

=head1 COPYRIGHT AND LICENSE

This program is based on the script "licensecheck" from the KDE SDK,
originally introduced by Stefan Westerfeld C<< <stefan@space.twc.de> >>.

  Copyright © 2007, 2008 Adam D. Barratt

  Copyright © 2012 Francesco Poli

  Copyright © 2016-2020 Jonas Smedegaard

  Copyright © 2017-2020 Purism SPC

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
