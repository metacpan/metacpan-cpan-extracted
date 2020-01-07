package App::Licensecheck;

use utf8;
use strictures 2;
use autodie;

use version;
use Log::Any ();
use Path::Iterator::Rule;
use Path::Tiny;
use Fcntl qw/:seek/;
use Encode;
use Regexp::Pattern 0.2.0 (
	're',
	'License::*' => (
		engine   => 'RE2',
		subject  => 'trait',
		-prefix  => 'TRAIT_',
		-has_tag => 'type:trait',
	),
	'License::licensed_under' => (
		subject => 'trait',
		-prefix => 'TRAIT_GLOBAL_',
	),
	'License::version' => (
		capture => 'numbered',
		subject => 'trait',
		-prefix => 'TRAIT_KEEP_',
	),
	'License::version_numberstring' => (
		capture => 'numbered',
		subject => 'trait',
		-prefix => 'TRAIT_KEEP_',
	),
	'License::*' => (
		engine     => 'RE2',
		subject    => 'name',
		-prefix    => 'NAME_',
		-lacks_tag => 'type:trait',
	),
	'License::*' => (
		subject    => 'name',
		-prefix    => 'NAME_GLOBAL_',
		-lacks_tag => 'type:trait',
	),
	'License::*' => (
		engine     => 'RE2',
		subject    => 'grant,license',
		-prefix    => 'GRANT_LICENSE_',
		-lacks_tag => 'type:trait',
	),
);

use Regexp::Pattern::License 3.1.96;
use String::Copyright 0.003 {
	format => sub { join ' ', $_->[0] || (), $_->[1] || () }
};
use String::Copyright 0.003 {
	threshold_after => 5,
	format          => sub { join ' ', $_->[0] || (), $_->[1] || () },
	},
	'copyright' => { -as => 'copyright_optimistic' };

use Moo;

use experimental "switch";
use namespace::clean;

=head1 NAME

App::Licensecheck - functions for a simple license checker for source files

=head1 VERSION

Version v3.0.39

=cut

our $VERSION = version->declare("v3.0.39");

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

my @RE_NAME              = sort map /^NAME_GLOBAL_(.*)/, keys(%RE);
my @L_family_cc          = sort keys %{ $L{family}{cc} };
my @L_type_singleversion = sort keys %{ $L{type}{singleversion} };
my @L_type_versioned     = sort keys %{ $L{type}{versioned} };
my @L_type_unversioned   = sort keys %{ $L{type}{unversioned} };
my @L_type_combo         = sort keys %{ $L{type}{combo} };
my @L_type_group         = sort keys %{ $L{type}{group} };

my @L_tidy
	= qw(afl aladdin apache artistic bsl cecill cecill_b cecill_c wtfpl wtfnmfpl);

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
			for ( $skipped->all( @paths, \%options ) ) {
				warn "skipped file $_\n";
			}
		}
		$rule->and( sub {/$check_re/} );
	}

	return $rule->all( @paths, \%options );
}

sub parse
{
	my $self = shift;
	my $file = path(shift);
	my $all  = $self->lines == 0;

	try {
		return $all
			? $self->parse_file($file)
			: $self->parse_lines($file);
	}
	catch {
		if ( $self->encoding and /does not map to Unicode/ ) {
			print
				"file $file cannot be read with $self->encoding; encoding, will try latin-1:\n$_"
				if $self->verbose;
			try {
				$self->encoding('latin-1');
				return $all
					? $self->parse_file($file)
					: $self->parse_lines($file);
			}
			catch {
				if (/does not map to Unicode/) {
					print
						"file $file cannot be read with latin-1; encoding, will try binary:\n$_"
						if $self->verbose;
					$self->encoding(undef);
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
	my $self = shift;
	my $file = path(shift);

	my $content;

	given ( $self->encoding ) {
		when (undef)  { $content = $file->slurp_raw }
		when ('utf8') { $content = $file->slurp_utf8 }
		default {
			$content
				= $file->slurp(
				{ binmode => sprintf ':encoding(%s)', $self->encoding->name }
				)
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
	my $self    = shift;
	my $file    = path(shift);
	my $content = '';

	my $fh;
	my $st = $file->stat;

	given ( $self->encoding ) {
		when (undef)  { $fh = $file->openr_raw }
		when ('utf8') { $fh = $file->openr_utf8 }
		default {
			$fh = $file->openr(
				sprintf ':encoding(%s)',
				$self->encoding->name
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
	s/^[cC] //gm;

	# Remove C / C++ comments
	s#(\*/|/[/*])##g;

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

	for my $key ( grep {/^[a-z]/} keys(%Regexp::Pattern::License::RE) ) {
		my $val = $Regexp::Pattern::License::RE{$key};
		for (@org) {
			$list{name}{$key}    ||= $val->{"name.alt.org.$_"};
			$list{caption}{$key} ||= $val->{"caption.alt.org.$_"};
		}
		$list{name}{$key}    ||= $val->{name}    || $key;
		$list{caption}{$key} ||= $val->{caption} || $val->{name} || $key;
		for ( @{ $val->{tags} } ) {
			/^(family|type):([a-z][a-z0-9_]*)(?::([a-z][a-z0-9_]*))?/;
			$list{family}{$2}{$key} = 1
				if ( $2 and $1 eq 'family' );
			$list{type}{$2}{$key} = 1
				if ( $2 and $1 eq 'type' );
			if ( $3 and $1 eq 'type' and $2 eq 'singleversion' ) {
				$list{series}{$key} = $3;
			}
		}
		for my $subject (qw(grant_license name)) {
			my $re = re( "License::$key", subject => $subject =~ tr/_/,/r )
				or next;
			$list{"re_$subject"}{$key} = ref($re) ? $re : qr/$re/;
		}
	}
	for my $trait (
		qw(any_of licensed_under or_at_option
		fsf_unlimited fsf_unlimited_retention
		version_later version_later_postfix)
		)
	{
		my $re = re( "License::$trait", subject => 'trait' );
		$list{re_trait}{$trait} = ref($re) ? $re : qr/$re/;
	}

	#<<<  do not let perltidy touch this (keep long regex on one line)
	$list{re_grant_license}{local}{version_agpl_gpl}{1} = qr/$RE{TRAIT_KEEP_version_numberstring}(?:[.,])? (?:\(?only\)?.? )?(?:of $list{re_name}{gnu}|(as )?published by the Free Software Foundation)/i;
	$list{re_grant_license}{local}{version_agpl_gpl}{2} = qr/$list{re_name}{gnu}\b[;,] $RE{TRAIT_KEEP_version_numberstring}\b[.,]? /i;
	$list{re_grant_license}{local}{version_agpl_gpl}{3} = qr/either $RE{TRAIT_KEEP_version_numberstring},? $list{re_trait}{version_later_postfix}/;
	$list{re_grant_license}{local}{version_agpl_gpl}{4} = qr/GPL as published by the Free Software Foundation, $RE{TRAIT_KEEP_version_numberstring}/i;
	$list{re_grant_license}{local}{address_agpl_gpl_lgpl}{1} = qr/(?:675 Mass Ave|59 Temple Place|51 Franklin Steet|02139|02111-1307)/i;
	$list{re_grant_license}{local}{exception_agpl_gpl_lgpl}{1} = qr/permission (?:is (also granted|given))? to link (the code of )?this program with (any edition of )?(Qt|the Qt library)/i;
	$list{re_grant_license}{local}{generated}{1} = qr/unless such copies or derivative works are solely in the form of machine-executable object code generated by a source language processor/;
	$list{re_grant_license}{local}{generated}{2} = qr/(All changes made in this file will be lost|DO NOT ((?:HAND )?EDIT|delete this file|modify)|edit the original|Generated (automatically|by|from|data|with)|generated.*file|auto[- ]generated)/i;
	$list{re_grant_license}{local}{multi}{1} = qr/$RE{TRAIT_GLOBAL_licensed_under}$list{re_trait}{any_of}(?:[^.]|\.\S)*$list{re_name}{lgpl}$RE{TRAIT_KEEP_version}?/i;
	$list{re_grant_license}{local}{multi}{2} = qr/$RE{TRAIT_GLOBAL_licensed_under}$list{re_trait}{any_of}(?:[^.]|\.\S)*$list{re_name}{gpl}$RE{TRAIT_KEEP_version}?/i;
	$list{re_grant_license}{local}{lgpl}{1} = qr/$RE{TRAIT_GLOBAL_licensed_under}$list{re_trait}{any_of}(?:[^.]|\.\S)*$list{re_name}{lgpl}$RE{TRAIT_KEEP_version}?/i;
	$list{re_grant_license}{local}{lgpl}{2} = qr/either $list{re_name}{afl}$RE{TRAIT_KEEP_version}, or $list{re_name}{lgpl}$RE{TRAIT_KEEP_version}?/i;
	$list{re_grant_license}{local}{lgpl}{3} = qr/either $list{re_name}{gpl}$RE{TRAIT_KEEP_version}?(?: \((?:the )?"?GPL"?\))?, or $list{re_name}{lgpl}/i;
	$list{re_grant_license}{local}{lgpl}{4} = qr/$RE{TRAIT_GLOBAL_licensed_under}$RE{TRAIT_KEEP_version}? of $list{re_name}{lgpl}/i;
	$list{re_grant_license}{local}{lgpl}{5} = qr/$RE{TRAIT_GLOBAL_licensed_under}$list{re_name}{lgpl}\b[,;:]?(?: either)? ?$RE{TRAIT_KEEP_version_numberstring},? $list{re_trait}{or_at_option} $RE{TRAIT_KEEP_version_numberstring}/i;
	$list{re_grant_license}{local}{lgpl}{6} = qr/$RE{TRAIT_GLOBAL_licensed_under}$list{re_name}{lgpl}(?:[,;:]?(?: either)?$RE{TRAIT_KEEP_version}?)?/i;
	$list{re_grant_license}{local}{agpl}{1} = qr/$RE{TRAIT_GLOBAL_licensed_under}$list{re_name}{agpl}/i;
	$list{re_grant_license}{local}{agpl}{2} = qr/(?:signe la|means the) GNU Affero General Public License/i;
	$list{re_grant_license}{local}{agpl}{3} = qr/GNU Affero General Public License into/i;
	$list{re_grant_license}{local}{agpl}{4} = qr/means either the GNU/i;
	$list{re_grant_license}{local}{agpl}{5} = qr/AFFERO GENERAL PUBLIC LICENSE$RE{TRAIT_KEEP_version}?/i;
	$list{re_grant_license}{local}{gpl}{1} = qr/Copyright \(C\) (?:19|yy)yy <?name of author>?\s+This program is free software/;
	$list{re_grant_license}{local}{gpl}{2} = qr/under the GNU GPL,? with none of the additional permissions of this License/;
	$list{re_grant_license}{local}{gpl}{3} = qr/GNU Affero General Public License/;
	$list{re_grant_license}{local}{gpl}{4} = qr/Terms of the Perl programming language system itself/;
	$list{re_grant_license}{local}{gpl}{5} = qr/COMPATIBILITY WITH THE GPL LICENSE/i;
	$list{re_grant_license}{local}{gpl}{6} = qr/$RE{TRAIT_GLOBAL_licensed_under}$list{re_trait}{any_of}(?:[^.]|\.\S)*$list{re_name}{gpl}$RE{TRAIT_KEEP_version}?/i;
	$list{re_grant_license}{local}{gpl}{7} = qr/either $list{re_name}{gpl}$RE{TRAIT_KEEP_version}?(?: \((?:the )?"?GPL"?\))?, or $list{re_name}{lgpl}$RE{TRAIT_KEEP_version}?/i;
	$list{re_grant_license}{local}{gpl}{8} = qr/$RE{TRAIT_GLOBAL_licensed_under}(?:version \S+ (?:\(?only\)? )?of )?$list{re_name}{gpl}/i;
	$list{re_grant_license}{local}{gpl}{9} = qr/$RE{TRAIT_GLOBAL_licensed_under}(?:version \S+ (?:\(?only\)? )?of )?$list{re_name}{gpl}$RE{TRAIT_KEEP_version}?/i;
	foreach my $id ( sort keys %{ $list{family}{cc} } ) {
		$list{re_grant_license}{local}{cc}{1}{$id} = qr/$list{re_name}{$id}$RE{TRAIT_KEEP_version_numberstring} or $RE{TRAIT_KEEP_version_numberstring}/i;
		$list{re_grant_license}{local}{cc}{2}{$id} = qr/$list{re_name}{$id}$RE{TRAIT_KEEP_version}(?:,? (?:and|or) (?:the )?(?:GNU )?([AL]?GPL)-?$RE{TRAIT_KEEP_version})?/i;
	}
	$list{re_grant_license}{local}{bsd}{1} = qr/THIS SOFTWARE IS PROVIDED .*AS IS AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY/;
	$list{re_grant_license}{local}{bsd}{5} = qr/licen[sc]e:? ?bsd-(\d)-clause/i;
	$list{re_grant_license}{local}{bsd}{6} = qr/licen[sc]e:? ?bsd\b/i;
	$list{re_grant_license}{local}{apache}{1} = qr/$list{re_name}{apache}$RE{TRAIT_KEEP_version}?(?:(?: or)? [^ ,]*?apache[^ ,]*| \([^(),]+\))*,? or $list{re_name}{gpl}$RE{TRAIT_KEEP_version}?/i;
	$list{re_grant_license}{local}{apache}{2} = qr/$list{re_name}{apache}$RE{TRAIT_KEEP_version}?(?:(?: or)? [^ ,]*?apache[^ ,]*| \([^(),]\))*,? or(?: the)? bsd(?:[ -](\d)-clause)?\b/i;
	$list{re_grant_license}{local}{apache}{4} = qr/$list{re_name}{apache}$RE{TRAIT_KEEP_version}?(?:(?: or)? [^ ,]*?apache[^ ,]*| \([^(),]\))*,? or $list{re_name}{mit}\b/i;
	$list{re_grant_license}{local}{fsful}{1} = qr/This (\w+)(?: (?:file|script))? is free software; $list{re_trait}{fsf_unlimited}/i;
	$list{re_grant_license}{local}{fsfullr}{1} = qr/This (\w+)(?: (?:file|script))?  is free software; $list{re_trait}{fsf_unlimited_retention}/i;
	$list{re_grant_license}{local}{php}{1} = qr/$RE{TRAIT_GLOBAL_licensed_under}$RE{TRAIT_KEEP_version_numberstring} of the PHP license/;
	$list{re_grant_license}{local}{pd}{1} = qr/$list{re_grant_license}{public_domain}/;
	foreach my $id ( sort keys %{ $list{type}{versioned} } ) {
		$list{re_grant_license}{local}{versioned}{$id} = qr/$list{re_name}{$id}$RE{TRAIT_KEEP_version}?/;
	}
	$list{re_grant_license}{local}{trailing_space} = qr/\s+$/;
	#>>>

	return %list;
}

sub parse_license
{
	my ( $self, $licensetext, $file, $position ) = @_;

	my $gplver    = "";
	my $extrainfo = "";
	my $license   = "";
	my @spdx_gplver;

	my @agpl = qw(agpl agpl_1 agpl_2 agpl_3);
	my @gpl  = qw(gpl gpl_1 gpl_2 gpl_3);
	my @lgpl = qw(lgpl lgpl_2 lgpl_2_1 lgpl_3);

	my %match;
	my ( %pos, %grant, %license );

  # @spdx_license contains identifiers from https://spdx.org/licenses/
  # it would be more efficient to store license info only in this
  # array and then convert it to legacy formulation, but there are
  # corner case (like extrainfo) that would not fit. So the old storage scheme
  # is kept with the new (spdx/dep-5) scheme to keep backward compat.
	my @spdx_license;
	my $spdx_extra;
	my $gen_spdx = sub {
		my @ret
			= @spdx_gplver ? ( map { "$_[0]-$_"; } @spdx_gplver ) : ( $_[0] );
		push @ret, $spdx_extra if $spdx_extra;
		return @ret;
	};
	my $id2spdx = sub {
		return $Regexp::Pattern::License::RE{ $_[0] }{'name.alt.org.spdx'}
			|| $Regexp::Pattern::License::RE{ $_[0] }{name};
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
		my $expr = join( ' or ', @spdx );
		$self->log->debugf(
			'collected license expression: %s [%s]',
			$expr, $file
		);
		push @spdx_license, $expr;
		$license = join( ' ', $L{caption}{$legacy} || $legacy, $license );
	};

	for my $trait (qw(licensed_under)) {
		next unless ( $licensetext =~ /$RE{"TRAIT_$trait"}/ );
		while ( $licensetext =~ /$RE{"TRAIT_GLOBAL_$trait"}/g ) {
			$self->log->tracef(
				'located license trait "%s": %s [%s]',
				$trait, $-[0], $file
			);
			$match{_}{$trait}{ $-[0] } = $+[0];
		}
	}
	for my $id (@RE_NAME) {
		next unless ( $licensetext =~ /$RE{"NAME_$id"}/ );
		while ( $licensetext =~ /$RE{"NAME_GLOBAL_$id"}/g ) {
			$self->log->tracef(
				'located license name: %s: %s [%s]',
				$id, $-[0], $file
			);
			$match{$id}{name}{ $-[0] } = $+[0];
		}
	}

	# step-wise grant detection
	LICENSED_UNDER:
	for my $pos ( values %{ $match{_}{licensed_under} } ) {

		# pick longest matched license name
		my ($name)
			= sort { $match{$a}{name}{$pos} <=> $match{$b}{name}{$pos} }
			grep   { $match{$_}{name}{$pos} } @L_type_versioned,
			@L_type_unversioned, @L_type_combo, @L_type_group;
		next unless ( $name and $match{$name}{name}{$pos} );
		next unless ( grep { $_ eq $name } @L_tidy );

		# TODO: maybe drop this optimization to cover combo licenses
		next if ( $match{$name}{grant} );

		my $pos2;

		GRANT:
		for ($name) {
			$pos2 = $match{$name}{name}{$pos};

			# may include version
			if ( grep { $_ eq $name } @L_type_versioned ) {
				if (substr( $licensetext, $pos2 )
					=~ /^$RE{TRAIT_KEEP_version}/ )
				{
					$self->log->tracef(
						'located license version: %s: %s [%s]',
						$1, $pos2, $file
					);
					$pos2 += $+[0];
					my $version = $1;
					$version =~ s/(?:\.0)+$//;
					$_ .= "_$version";
					if ($2) {
						$self->log->tracef(
							'located license trait "%s": %s: %s [%s]',
							'or_later', $2, $-[0], $file
						);
						$_ .= "_or_later";
					}
				}
				$self->log->tracef(
					'located license grant: %s: %s [%s]',
					$_, $pos, $file
				);
				$pos{$pos}{$_} = 1;
			}
		}
	}
	for my $pos ( keys %pos ) {
		my @name = keys %{ $pos{$pos} };
		for my $name (@name) {
			$self->log->tracef(
				'flagged license grant: %s: %s [%s]',
				$name, $pos, $file
			);
			$grant{$name} = 1;
		}
	}

	if ( grep { $match{$_}{name} } @agpl, @gpl ) {

		# version of AGPL/GPL
		given ($licensetext) {
			when ( $L{re_grant_license}{local}{version_agpl_gpl}{1} ) {
				$self->log->tracef(
					'detected custom pattern version_agpl_gpl#1: %s: %s [%s]',
					$1, $-[0], $file
				);
				$gplver      = " (v$1)";
				@spdx_gplver = ($1)
			}
			when ( $L{re_grant_license}{local}{version_agpl_gpl}{2} ) {
				$self->log->tracef(
					'detected custom pattern version_agpl_gpl#2: %s: %s [%s]',
					$1, $-[0], $file
				);
				$gplver      = " (v$1)";
				@spdx_gplver = ($1);
			}
			when ( $L{re_grant_license}{local}{version_agpl_gpl}{3} ) {
				$self->log->tracef(
					'detected custom pattern version_agpl_gpl#3: %s: %s [%s]',
					$1, $-[0], $file
				);
				$gplver      = " (v$1 or later)";
				@spdx_gplver = ( $1 . '+' );
			}
			when ( $L{re_grant_license}{local}{version_agpl_gpl}{4} ) {
				$self->log->tracef(
					'detected custom pattern version_agpl_gpl#4: %s: %s [%s]',
					$1, $-[0], $file
				);
				$gplver      = " (v$1)";
				@spdx_gplver = ($1)
			}
		}
	}

	if ( grep { $match{$_}{name} } @agpl, @gpl, @lgpl ) {

		# address in AGPL/GPL/LGPL
		given ($licensetext) {
			when ( $L{re_grant_license}{local}{address_agpl_gpl_lgpl}{1} ) {
				$self->log->tracef(
					'detected custom pattern address_agpl_gpl_lgpl#1: %s [%s]',
					$-[0], $file
				);
				$extrainfo = " (with incorrect FSF address)$extrainfo";
			}
		}

		# exception for AGPL/GPL/LGPL
		given ($licensetext) {
			when ( $L{re_grant_license}{local}{exception_agpl_gpl_lgpl}{1} ) {
				$self->log->tracef(
					'detected custom pattern exception_agpl_gpl_lgpl#1: %s [%s]',
					$-[0], $file
				);
				$extrainfo  = " (with Qt exception)$extrainfo";
				$spdx_extra = 'with Qt exception';
			}
		}
	}

	# generated file
	given ($licensetext) {

		# exclude blurb found in boost license text
		when ( $L{re_grant_license}{local}{generated}{1} ) {
			$self->log->tracef(
				'detected and skipped custom pattern generated#1: %s [%s]',
				$-[0], $file
			);
			break;
		}
		when ( $L{re_grant_license}{local}{generated}{2} ) {
			$self->log->tracef(
				'detected custom pattern generated#2: %s [%s]',
				$-[0], $file
			);
			$license = "GENERATED FILE";
		}
	}

	# multi-licensing
	my @multilicenses;

	# same sentence
	if ( grep { $match{$_}{name} } @lgpl ) {
		if ( $licensetext =~ $L{re_grant_license}{local}{multi}{1} ) {
			$self->log->tracef(
				'detected custom pattern multi#1: %s %s %s: %s [%s]',
				'lgpl', $1, $2, $-[0], $file
			);
			push @multilicenses, 'lgpl', $1, $2;
		}
	}
	if ( grep { $match{$_}{name} } @gpl ) {
		if ( $licensetext =~ $L{re_grant_license}{local}{multi}{2} ) {
			$self->log->tracef(
				'detected custom pattern multi#2: %s %s %s: %s [%s]',
				'gpl', $1, $2, $-[0], $file
			);
			push @multilicenses, 'gpl', $1, $2;
		}
	}
	$gen_license->(@multilicenses) if (@multilicenses);

	if ( grep { $match{$_}{name} } @lgpl ) {

		# LGPL
		given ($licensetext) {

			# LGPL, among several
			when ( $L{re_grant_license}{local}{lgpl}{1} ) {
				$self->log->tracef(
					'detected and skipped custom pattern lgpl#1: %s [%s]',
					$-[0], $file
				);
				break;    # handled in multi-licensing loop
			}

			# AFL or LGPL
			when ( $L{re_grant_license}{local}{lgpl}{2} ) {
				$self->log->tracef(
					'detected and skipped custom pattern lgpl#2: %s [%s]',
					$-[0], $file
				);
				break;    # handled in AFL loop
			}

			# GPL or LGPL
			when ( $L{re_grant_license}{local}{lgpl}{3} ) {
				$self->log->tracef(
					'detected and skipped custom pattern lgpl#3: %s [%s]',
					$-[0], $file
				);
				break;    # handled in GPL loop
			}

			# LGPL, version first
			when ( $L{re_grant_license}{local}{lgpl}{4} ) {
				$self->log->tracef(
					'detected custom pattern lgpl#4: %s %s %s: %s [%s]',
					'lgpl', $1, $2, $-[0], $file
				);
				$gen_license->( 'lgpl', $1, $2 );
			}

			# LGPL, dual versions last
			when ( $L{re_grant_license}{local}{lgpl}{5} ) {
				$self->log->tracef(
					'detected custom pattern lgpl#5: %s %s %s: %s [%s]',
					'lgpl', $1, $2, $-[0], $file
				);
				$license = "LGPL (v$1 or v$2) $license";
				my $expr = "LGPL-$1 or LGPL-$2";
				$self->log->debugf(
					'collected license expression: %s [%s]',
					$expr, $file
				);
				push @spdx_license, $expr;
			}

			# LGPL, version last
			when ( $L{re_grant_license}{local}{lgpl}{6} ) {
				$self->log->tracef(
					'detected custom pattern lgpl#6: %s %s %s: %s [%s]',
					'lgpl', $1, $2, $-[0], $file
				);
				$gen_license->( 'lgpl', $1, $2 );
			}
		}
		$self->log->tracef( 'flagged license objects: lgpl afl [%s]', $file );
		$match{lgpl}{custom} = 1;
		$match{afl}{custom}  = 1;
	}

	if ( grep { $match{$_}{name} } @agpl ) {

		# AGPL
		given ($licensetext) {
			when ( $L{re_grant_license}{local}{agpl}{1} ) {
				$self->log->tracef(
					'detected custom pattern agpl#1: %s: %s [%s]',
					'agpl', $-[0], $file
				);
				$license = "AGPL$gplver$extrainfo $license";
				my @expr = $gen_spdx->('AGPL');
				$self->log->debugf(
					'collected license expression: %s [%s]',
					[@expr], $file
				);
				push @spdx_license, @expr;
			}

			# exclude CeCILL-2.1 license
			when ( $L{re_grant_license}{local}{agpl}{2} ) {
				$self->log->tracef(
					'detected and skipped custom pattern agpl#2: %s [%s]',
					$-[0], $file
				);
				break;
			}

			# exclude GPL-3 license
			when ( $L{re_grant_license}{local}{agpl}{3} ) {
				$self->log->tracef(
					'detected and skipped custom pattern agpl#3: %s [%s]',
					$-[0], $file
				);
				break;
			}

			# exclude MPL-2.0 license
			when ( $L{re_grant_license}{local}{agpl}{4} ) {
				$self->log->tracef(
					'detected and skipped custom pattern agpl#4: %s [%s]',
					$-[0], $file
				);
				break;
			}
			when ( $L{re_grant_license}{local}{agpl}{5} ) {
				$self->log->tracef(
					'detected custom pattern agpl#6: agpl %s %s: %s [%s]',
					$1, $2, $-[0], $file
				);
				$gen_license->( 'agpl', $1, $2 );
			}
		}
		$self->log->tracef( 'flagged license object: agpl [%s]', $file );
		$match{agpl}{custom} = 1;
	}

	if ( grep { $match{$_}{name} } @gpl ) {

		# GPL
		given ($licensetext) {

			# exclude GPL fulltext (rarely if ever used as grant)
			when ( $L{re_grant_license}{local}{gpl}{1} ) {
				$self->log->tracef(
					'detected and skipped custom pattern gpl#1: %s [%s]',
					$-[0], $file
				);
				break;
			}

			# exclude LGPL-3 fulltext (rarely if ever used as grant)
			when ( $L{re_grant_license}{local}{gpl}{2} ) {
				$self->log->tracef(
					'detected and skipped custom pattern gpl#2: %s [%s]',
					$-[0], $file
				);
				break;
			}

			# exclude AGPL-3 license
			when ( $L{re_grant_license}{local}{gpl}{3} ) {
				$self->log->tracef(
					'detected and skipped custom pattern gpl#3: %s [%s]',
					$-[0], $file
				);
				break;
			}

			# exclude Perl combo license
			when ( $L{re_grant_license}{local}{gpl}{4} ) {
				$self->log->tracef(
					'detected and skipped custom pattern gpl#4: %s [%s]',
					$-[0], $file
				);
				break;
			}

			# exclude CeCILL-1.1 license
			when ( $L{re_grant_license}{local}{gpl}{5} ) {
				$self->log->tracef(
					'detected and skipped custom pattern gpl#5: %s [%s]',
					$-[0], $file
				);
				break;
			}

			# GPL, among several
			when ( $L{re_grant_license}{local}{gpl}{6} ) {
				$self->log->tracef(
					'detected and skipped custom pattern gpl#6: %s [%s]',
					$-[0], $file
				);
				break;    # handled in multi-licensing loop
			}

			# GPL or LGPL
			when ( $L{re_grant_license}{local}{gpl}{7} ) {
				$self->log->tracef(
					'detected custom pattern agpl#7: %s %s %s %s %s %s %s %s: %s [%s]',
					'gpl', $1, $2, 'lgpl', $3, $4, $-[0], $file
				);
				$gen_license->( 'gpl', $1, $2, 'lgpl', $3, $4 );
			}
			if ( $gplver or $extrainfo ) {
				when ( $L{re_grant_license}{local}{gpl}{8} ) {
					$self->log->tracef(
						'detected custom pattern gpl#8: %s: %s [%s]',
						'gpl', $-[0], $file
					);
					$license = "GPL$gplver$extrainfo $license";
					my $expr = join ' ', $gen_spdx->('GPL');
					$self->log->debugf(
						'collected license expression: %s [%s]',
						$expr, $file
					);
					push @spdx_license, $expr;
				}
			}
			when ( $L{re_grant_license}{local}{gpl}{9} ) {
				$self->log->tracef(
					'detected custom pattern gpl#9: %s %s %s: %s [%s]',
					'gpl', $1, $2, $-[0], $file
				);
				$gen_license->( 'gpl', $1, $2 );
			}
		}
		$self->log->tracef( 'flagged license object: gpl [%s]', $file );
		$match{gpl}{custom} = 1;
	}

	# CC
	given ($licensetext) {
		foreach my $id (@L_family_cc) {
			next unless ( $match{$id}{name} );
			when ( $L{re_grant_license}{local}{cc}{1}{$id} ) {
				$self->log->tracef(
					'detected custom pattern cc#1: %s %s %s: %s [%s]',
					$id, $1, $2, $-[0], $file
				);
				$license = "$L{caption}{$id} (v$1 or v$2) $license";
				my $expr = "$L{name}{$id}-$1 or $L{name}{$id}-$2";
				$self->log->debugf(
					'collected license expression: %s [%s]',
					$expr, $file
				);
				push @spdx_license, $expr;
			}
			when ( $L{re_grant_license}{local}{cc}{2}{$id} ) {
				$self->log->tracef(
					'detected custom pattern cc#2: %s %s %s %s %s: %s [%s]',
					$id, $1, $2, $3, $4, $-[0], $file
				);
				$gen_license->( $id, $1, $2, $3, $4 );
			}
		}
	}
	for my $id (
		qw(cc_by cc_by_nc cc_by_nc_nd cc_by_nc_sa cc_by_nd cc_by_sa cc_cc0 cc_nc cc_nd cc_sa cc_sp)
		)
	{
		$match{$id}{custom} = 1;
		for ( $L{members}{$id} ? @{ $L{members}{$id} } : () ) {
			$match{$_}{custom} = 1;
		}
	}

	# BSD
	if ( $licensetext =~ $L{re_grant_license}{local}{bsd}{1} ) {
		$self->log->tracef(
			'detected custom pattern bsd#1: %s [%s]', $-[0],
			$file
		);
		given ($licensetext) {
			when ( $RE{TRAIT_clause_advertising} ) {
				$self->log->tracef(
					'detected custom pattern bsd#2: %s: %s [%s]',
					'bsd_4_clause', $-[0], $file
				);
				$gen_license->('bsd_4_clause');
			}
			when ( $RE{TRAIT_clause_non_endorsement} ) {
				$self->log->tracef(
					'detected custom pattern bsd#3: %s: %s [%s]',
					'bsd_3_clause', $-[0], $file
				);
				$gen_license->('bsd_3_clause');
			}
			when ( $RE{TRAIT_clause_reproduction} ) {
				$self->log->tracef(
					'detected custom pattern bsd#4: %s: %s [%s]',
					'bsd_2_clause', $-[0], $file
				);
				$gen_license->('bsd_2_clause');
			}
			default {
				$gen_license->('bsd');
			}
		}
	}
	elsif ( $licensetext =~ $L{re_grant_license}{local}{bsd}{5} ) {
		$self->log->tracef(
			'detected custom pattern bsd#5: bsd_%s_clause: %s [%s]',
			$1, $-[0], $file
		);
		$gen_license->("bsd_${1}_clause");
	}
	elsif ( $licensetext =~ $L{re_grant_license}{local}{bsd}{6} ) {
		$self->log->tracef(
			'detected custom pattern bsd#6: %s: %s [%s]',
			'bsd', $-[0], $file
		);
		$gen_license->('bsd');
	}
	$self->log->tracef(
		'flagged license objects: bsd_2_clause bsd_3_clause bsd_4_clause [%s]',
		$file
	);
	$match{$_}{custom} = 1 for (qw(bsd_2_clause bsd_3_clause bsd_4_clause));

	# Apache
	given ($licensetext) {
		if ( $match{apache}{name} ) {
			when ( $L{re_grant_license}{local}{apache}{1} ) {
				$self->log->tracef(
					'detected custom pattern apache#1: %s %s %s %s %s %s: %s [%s]',
					'apache', $1, $2, 'gpl', $3, $4, $-[0], $file
				);
				$gen_license->( 'apache', $1, $2, 'gpl', $3, $4 );
			}
			when ( $L{re_grant_license}{local}{apache}{2} ) {
				$self->log->tracef(
					'detected custom pattern apache#2: %s %s %s bsd_%s_clause: %s [%s]',
					'apache', $1, $2, $3, $-[0], $file
				);
				$gen_license->( 'apache', $1, $2, "bsd_${3}_clause" );
			}
			when ( $L{re_grant_license}{local}{apache}{4} ) {
				$self->log->tracef(
					'detected custom pattern apache#4: %s %s %s: %s [%s]',
					'mit', $3, $4, $-[0], $file
				);
				$gen_license->( 'mit', $3, $4 );
			}
		}
	}
	$self->log->tracef( 'flagged license object: apache [%s]', $file );
	$match{apache}{custom} = 1;

	# FSFUL
	given ($licensetext) {
		when ( $RE{GRANT_LICENSE_fsful} ) {
			$self->log->tracef(
				'detected grant/license: %s: %s [%s]',
				'fsful', $-[0], $file
			);
			$gen_license->('fsful');
		}
		when ( $L{re_grant_license}{local}{fsful}{1} ) {
			$self->log->tracef(
				'collected custom pattern fsful#1: %s: %s [%s]',
				'fsful', $-[0], $file
			);
			$license = "FSF Unlimited ($1 derivation) $license";
			my $expr = "FSFUL~$1";
			$self->log->debugf(
				'collected license expression: %s [%s]',
				$expr, $file
			);
			push @spdx_license, $expr;
		}
	}
	$self->log->tracef( 'flagged license object: fsful [%s]', $file );
	$match{fsful}{custom} = 1;

	# FSFULLR
	given ($licensetext) {
		when ( $RE{GRANT_LICENSE_fsfullr} ) {
			$self->log->tracef(
				'detected grant/license: %s: %s [%s]',
				'fsfullr', $-[0], $file
			);
			$gen_license->('fsfullr');
		}
		when ( $L{re_grant_license}{local}{fsfullr}{1} ) {
			$self->log->tracef(
				'collected custom pattern fsfullr#1: %s: %s [%s]',
				'fsfullr', $-[0], $file
			);
			$license
				= "FSF Unlimited (with Retention, $1 derivation) $license";
			my $expr = "FSFULLR~$1";
			$self->log->debugf(
				'collected license expression: %s [%s]',
				$expr, $file
			);
			push @spdx_license, $expr;
		}
	}
	$self->log->tracef( 'flagged license object: fsfullr [%s]', $file );
	$match{fsfullr}{custom} = 1;

	# JSON
	given ($licensetext) {
		when ( $RE{GRANT_LICENSE_json} ) {
			$self->log->tracef(
				'detected grant/license: %s: %s [%s]',
				'json', $-[0], $file
			);
			$gen_license->('JSON');
		}
	}

	# PHP
	given ($licensetext) {
		when ( $L{re_grant_license}{local}{php}{1} ) {
			$self->log->tracef(
				'detected custom pattern php#1: %s: %s [%s]',
				'PHP', $-[0], $file
			);
			$gen_license->( 'PHP', $1 );
		}
	}

	# public-domain
	given ($licensetext) {
		when ( $L{re_grant_license}{local}{pd}{1} ) {
			$self->log->tracef(
				'detected custom pattern pd#1: %s: %s [%s]',
				'public_domain', $-[0], $file
			);
			$gen_license->('public_domain');
		}
	}
	$self->log->tracef( 'flagged license object: public_domain [%s]', $file );
	$match{public_domain}{custom} = 1;

	# singleversion
	foreach my $id (@L_type_singleversion) {
		next if ( $match{$id}{custom} );

		if ( grep { $_ ne $id } @L_tidy ) {
			if ( $licensetext =~ $RE{"GRANT_LICENSE_$id"} ) {
				$self->log->tracef(
					'detected and flagged grant/license: %s [%s]',
					$id, $-[0], $file
				);
				$grant{$id} = 1;
			}
		}

		if ( $grant{$id} ) {
			$gen_license->($id);

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
	foreach my $id (@L_type_versioned) {
		next if ( $match{$id}{custom} );
		next if ( grep { $_ eq $id } @L_tidy );

		# skip embedded or referenced licenses
		if ( grep { $id eq $_ } qw(mpl python) ) {
			if ( $licensetext =~ $RE{GRANT_LICENSE_rpsl} ) {
				$self->log->tracef(
					'detected and skipped grant/license: %s [%s]',
					'rpsl', $-[0], $file
				);
				next;
			}
		}

		# FIXME: match grant (not name)
		if ( $match{$id}{name} ) {
			if ( $licensetext =~ $L{re_grant_license}{local}{versioned}{$id} )
			{
				$self->log->tracef(
					'detected and flagged custom pattern versioned: %s %s %s: [%s]',
					$id, $1, $2, $-[0], $file
				);
				$gen_license->( $id, $1, $2 );
				$match{$id}{custom} = 1;
			}
		}
		next if ( $match{$id}{custom} );
		if ( $RE{"GRANT_LICENSE_$id"} ) {
			if ( $licensetext =~ $RE{"GRANT_LICENSE_$id"} ) {
				$self->log->tracef(
					'detected grant/license: %s: [%s]',
					$id, $-[0], $file
				);
				$gen_license->($id);
			}
		}
	}

	# other
	foreach my $id ( @L_type_unversioned, @L_type_combo ) {
		next if ( $match{$id}{custom} );
		next if ( grep { $_ eq $id } @L_tidy );

		# skip embedded or referenced licenses
		if ( grep { $id eq $_ } qw(zlib) ) {
			if ( $licensetext =~ $RE{"GRANT_LICENSE_cube"} ) {
				$self->log->tracef(
					'skipped grant/license: %s: [%s]',
					'cube', $-[0], $file
				);
				next;
			}
		}
		if ( grep { $id eq $_ } qw(ntp) ) {
			if ( $licensetext =~ $RE{"GRANT_LICENSE_ntp_disclaimer"} ) {
				$self->log->tracef(
					'skipped grant/license: %s: [%s]',
					'ntp_disclaimer', $-[0], $file
				);
				next;
			}
			if ( $licensetext =~ $RE{"GRANT_LICENSE_dsdp"} ) {
				$self->log->tracef(
					'skipped grant/license: %s: [%s]',
					'dsdp', $-[0], $file
				);
				next;
			}
		}
		if ( grep { $id eq $_ } qw(ntp_disclaimer) ) {
			if ( $licensetext =~ $RE{"GRANT_LICENSE_mit_cmu"} ) {
				$self->log->tracef(
					'skipped grant/license: %s: [%s]',
					'mit_cmu', $-[0], $file
				);
				next;
			}
		}

		if ( $licensetext =~ $RE{"GRANT_LICENSE_$id"} ) {
			$self->log->tracef(
				'detected grant/license: %s: [%s]',
				$id, $-[0], $file
			);
			$gen_license->($id);
		}
	}

	# Remove trailing spaces.
	$license =~ s/$L{re_grant_license}{local}{trailing_space}//;
	my $expr = join( ' and/or ', sort @spdx_license );
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

  Copyright © 2016 Jonas Smedegaard

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any
later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program. If not, see <https://www.gnu.org/licenses/>.

=cut

1;
