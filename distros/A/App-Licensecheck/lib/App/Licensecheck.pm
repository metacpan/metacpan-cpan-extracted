package App::Licensecheck;

use utf8;
use strictures 2;
use autodie;

use version;
use Path::Iterator::Rule;
use Path::Tiny;
use Fcntl qw/:seek/;
use Encode;
use Regexp::Pattern::License;
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

Version v3.0.31

=cut

our $VERSION = version->declare("v3.0.31");

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

my $under_terms_of
	= qr/(?:(?:Licensed|released) under|(?:according to|under) the (?:conditions|terms) of)/i;
my $any_of       = qr/(?:any|one or more) of the following/i;
my $or_option_re = qr/(?:and|or)(?: ?\(?at your (?:choice|option)\)?)?/i;

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

	if ( $self->lines == 0 ) {
		return ( $self->parse_file($file) );
	}
	else {
		return ( $self->parse_lines($file) );
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
		$self->parse_license( clean_cruft_and_spaces($cleaned_content) )
			|| "UNKNOWN",
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

	my $license
		= $self->parse_license( clean_cruft_and_spaces($cleaned_content) );
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
		$license
			= $self->parse_license( clean_cruft_and_spaces($cleaned_tail) );
	}

	$fh->close;
	return ( $license || "UNKNOWN", $copyrights );
}

sub clean_comments
{
	local $_ = shift or return q{};

	# Remove generic comments: look for 4 or more lines beginning with
	# regular comment pattern and trim it. Fall back to old algorithm
	# if no such pattern found.
	my @matches = m/^[ \t]*([^a-zA-Z0-9\s]{1,3}|\bdnl\b|\bREM\b)[ \t]+\S/mg;
	if ( @matches >= 4 ) {
		my $comment_re = qr/[ \t]*[\Q$matches[0]\E]{1,3}[ \t]*/;
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
	my $org = shift;

	my %list;

	while ( my ( $key, $val ) = each %Regexp::Pattern::License::RE ) {
		if ($org) {
			$list{name}{$key}    = $val->{ 'name.alt.org.' . $org };
			$list{caption}{$key} = $val->{ 'caption.alt.org.' . $org };
		}
		$list{name}{$key} ||= $val->{name} || $key;
		$list{caption}{$key} ||= $val->{caption} || $val->{name} || $key;
		$list{re}{$key} = $val->{pat};
	}

	# TODO: use Regexp::Common
	$list{re}{version}{'-keep'}
		= qr/$list{re}{version_prefix}?($list{re}{version_number})/i;
	$list{re}{xgpl}{'-keep'} = qr/(?:the )?(?:GNU )?([AL]?GPL)/i;

	return %list;
}

sub parse_license
{
	my $self = shift;
	my ($licensetext) = @_;

	my $gplver    = "";
	my $extrainfo = "";
	my $license   = "";
	my @spdx_gplver;

	# TODO: make naming scheme configurable
	my %L = licensepatterns('debian');

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
		push @spdx_license, join( ' or ', @spdx );
		$license = join( ' ', $L{caption}{$legacy} || $legacy, $license );
	};

	#<<<  do not let perltidy touch this (keep long regex on one line)

	# version of AGPL/GPL
	given ($licensetext) {
		when ( /version ($L{re}{version_number})[.,]? (?:\(?only\)?.? )?(?:of $L{re}{gnu}|(as )?published by the Free Software Foundation)/i ) {
			$gplver      = " (v$1)";
			@spdx_gplver = ($1)
		}
		when ( /$L{re}{gnu}\b[;,] $L{re}{version}{-keep}\b[.,]? /i ) {
			$gplver      = " (v$1)";
			@spdx_gplver = ($1);
		}
		when ( /either $L{re}{version}{-keep}(?: of the License)?,? $L{re}{version_later_postfix}/ ) {
			$gplver      = " (v$1 or later)";
			@spdx_gplver = ( $1 . '+' );
		}
		when ( /GPL as published by the Free Software Foundation, version ($L{re}{version_number})/i ) {
			$gplver      = " (v$1)";
			@spdx_gplver = ($1)
		}
	}

	# address in AGPL/GPL/LGPL
	given ($licensetext) {
		when ( /(?:675 Mass Ave|59 Temple Place|51 Franklin Steet|02139|02111-1307)/i ) {
			$extrainfo = " (with incorrect FSF address)$extrainfo";
		}
	}

	# exception for AGPL/GPL/LGPL
	given ($licensetext) {
		when ( /permission (?:is (also granted|given))? to link (the code of )?this program with (any edition of )?(Qt|the Qt library)/i ) {
			$extrainfo  = " (with Qt exception)$extrainfo";
			$spdx_extra = 'with Qt exception';
		}
	}

	# generated file
	given ($licensetext) {
		# exclude blurb found in boost license text
		when ( /unless such copies or derivative works are solely in the form of machine-executable object code generated by a source language processor/ ) {
			break;
		}
		when ( /(All changes made in this file will be lost|DO NOT ((?:HAND )?EDIT|delete this file|modify)|edit the original|Generated (automatically|by|from|data|with)|generated.*file|auto[- ]generated)/i ) {
			$license = "GENERATED FILE";
		}
	}

	# multi-licensing
	given ($licensetext) {
		my @multilicenses;
		# same sentence
		when ( /$under_terms_of $any_of(?:[^.]|\.\S)* $L{re}{lgpl}(?:[,;:]? ?$L{re}{version}{-keep}(?: of the License)?($L{re}{version_later})?)?/i ) {
			push @multilicenses, 'lgpl', $1, $2;
			continue;
		}
		when ( /$under_terms_of $any_of(?:[^.]|\.\S)* $L{re}{gpl}(?:[,;:]? ?$L{re}{version}{-keep}(?: of the License)?($L{re}{version_later})?)?/i ) {
			push @multilicenses, 'gpl', $1, $2;
			continue;
		}
		$gen_license->( @multilicenses ) if (@multilicenses);
	}

	# LGPL
	given ($licensetext) {
		# LGPL, among several
		when ( /$under_terms_of $any_of(?:[^.]|\.\S)* $L{re}{lgpl}(?:[,;:]? ?$L{re}{version}{-keep}(?: of the License)?($L{re}{version_later})?)?/i ) {
			break; # handled in multi-licensing loop
		}
		# AFL or LGPL
		when ( /either $L{re}{afl}(?:[,;]? ?$L{re}{version}{-keep}(,? $L{re}{version_later_postfix})?)?, or $L{re}{lgpl}(?:[,;]? ?$L{re}{version}{-keep}(,? $L{re}{version_later_postfix})?)?/i ) {
			break; # handled in AFL loop
		}
		# GPL or LGPL
		when ( /either $L{re}{gpl}(?:[,;]? ?$L{re}{version}{-keep}(,? $L{re}{version_later_postfix})?)?(?: \((?:the )?"?GPL"?\))?, or $L{re}{lgpl}/i ) {
			break; # handled in GPL loop
		}
		# LGPL, version first
		when ( /$under_terms_of $L{re}{version}{-keep}( $L{re}{version_later_postfix})? of $L{re}{lgpl}/i ) {
			$gen_license->( 'lgpl', $1, $2 );
		}
		# LGPL, dual versions last
		when ( /$under_terms_of $L{re}{lgpl}\b[,;:]?(?: either)? ?$L{re}{version}{-keep}(?: of the License)?,? $or_option_re $L{re}{version}{-keep}/i ) {
			$license = "LGPL (v$1 or v$2) $license";
			push @spdx_license, "LGPL-$1 or LGPL-$2";
		}
		# LGPL, version last
		when ( /$under_terms_of $L{re}{lgpl}(?:[,;:]?(?: either)? ?$L{re}{version}{-keep}(?: of the License)?($L{re}{version_later})?)?/i ) {
			$gen_license->( 'lgpl', $1, $2 );
		}
	}

	# AGPL
	given ($licensetext) {
		when ( /is free software.? you can redistribute (it|them) and[ \/]or modify (it|them) under the terms of $L{re}{agpl}/i ) {
			$license = "AGPL$gplver$extrainfo $license";
			push @spdx_license, $gen_spdx->('AGPL');
		}
		# exclude CeCILL-2.1 license
		when ( /(?:signe la|means the) GNU Affero General Public License/i ) {
			break;
		}
		# exclude GPL-3 license
		when ( /GNU Affero General Public License into/i ) {
			break;
		}
		# exclude MPL-2.0 license
		when ( /means either ([^.]+$L{re}{version_number})+, the GNU Affero General Public License/i ) {
			break;
		}
		when ( /AFFERO GENERAL PUBLIC LICENSE(?:,? $L{re}{version}{-keep}(,? $L{re}{version_later_postfix})?)?/i ) {
			$gen_license->( 'agpl', $1, $2 );
		}
	}

	# GPL
	given ($licensetext) {
		# exclude GPL fulltext (rarely if ever used as grant)
		when ( /Copyright \(C\) (?:19|yy)yy <?name of author>?\s+This program is free software/ ) {
			break;
		}
		# exclude LGPL-3 fulltext (rarely if ever used as grant)
		when ( /under the GNU GPL,? with none of the additional permissions of this License/ ) {
			break;
		}
		# exclude AGPL-3 license
		when ( /GNU Affero General Public License/ ) {
			break;
		}
		# exclude Perl combo license
		when ( /Terms of the Perl programming language system itself/ ) {
			break;
		}
		# exclude CeCILL-1.1 license
		when ( /COMPATIBILITY WITH THE GPL LICENSE/i ) {
			break;
		}
		# GPL, among several
		when ( /$under_terms_of $any_of(?:[^.]|\.\S)* $L{re}{gpl}(?:[,;:]? ?$L{re}{version}{-keep}(?: of the License)?($L{re}{version_later})?)?/i ) {
			break; # handled in multi-licensing loop
		}
		# GPL or LGPL
		when ( /either $L{re}{gpl}(?:[,;]? ?$L{re}{version}{-keep}(,? $L{re}{version_later_postfix})?)?(?: \((?:the )?"?GPL"?\))?, or $L{re}{lgpl}(?:[,;]? ?$L{re}{version}{-keep}(,? $L{re}{version_later_postfix})?)?/i ) {
			$gen_license->( 'gpl', $1, $2, 'lgpl', $3, $4 );
		}
		if ( $gplver or $extrainfo ) {
			when ( /under (?:the terms of )?(?:version \S+ (?:\(?only\)? )?of )?$L{re}{gpl}/i ) {
				$license = "GPL$gplver$extrainfo $license";
				push @spdx_license, $gen_spdx->('GPL');
			}
		}
		when ( /under (?:the terms of )?(?:version \S+ (?:\(?only\)? )?of )?$L{re}{gpl}(?:,? $L{re}{version}{-keep}(,? $L{re}{version_later_postfix})?)?/i ) {
			$gen_license->( 'gpl', $1, $2 );
		}
	}

	# CC
	given ($licensetext) {
		foreach my $id (qw<cc_by cc_by_nc cc_by_nc_nd cc_by_nc_sa cc_by_nd cc_by_sa cc_cc0>) {
			when ( /$L{re}{$id}(?i: version)? ($L{re}{version_number}) or ($L{re}{version_number})/i ) {
				$license = "$L{caption}{$id} (v$1 or v$2) $license";
				push @spdx_license, "$L{name}{$id}-$1 or $L{name}{$id}-$1";
			}
			when ( /$L{re}{$id}(?: $L{re}{version}{-keep}?)(?: License)?($L{re}{version_later})?(?:,? (?:and|or) $L{re}{xgpl}{-keep}(?:-?($L{re}{version_number})(,? $L{re}{version_later_postfix})?)?)?/i ) {
				$gen_license->( $id, $1, $2, $3, $4 );
			}
		}
	}

	# NTP
	given ($licensetext) {
		when ( /$L{re}{dsdp}/) {
			$gen_license->('dsdp');
		}
		when ( /$L{re}{ntp_disclaimer}/) {
			$gen_license->('ntp_disclaimer');
		}
		when ( /$L{re}{ntp}/) {
			$gen_license->('ntp');
		}
	}

	# BSD
	if ( $licensetext =~ /THIS SOFTWARE IS PROVIDED .*AS IS AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY/ ) {
		given ($licensetext) {
			when ( /$L{re}{clause_advertising}/i ) {
				$gen_license->('bsd_4_clause');
			}
			when ( /$L{re}{clause_non_endorsement}/i ) {
				$gen_license->('bsd_3_clause');
			}
			when ( /$L{re}{clause_reproduction}/i ) {
				$gen_license->('bsd_2_clause');
			}
			default {
				$gen_license->('bsd');
			}
		}
	}
	elsif ( $licensetext =~ /licen[sc]e:? ?bsd-(\d)-clause/i ) {
		$gen_license->("bsd_${1}_clause");
	}
	elsif ( $licensetext =~ /licen[sc]e:? ?bsd\b/i ) {
		$gen_license->('bsd');
	}

	# Artistic
	given ($licensetext) {
		when ( /$L{re}{perl}/ ) {
			$gen_license->('perl');
		}
		when ( /$L{re}{artistic_2}/ ) {
			$gen_license->('artistic_2');
		}
		when ( /$L{re}{artistic}(?:,? $L{re}{version}{-keep}(,? $L{re}{version_later_postfix})?)?/ ) {
			$gen_license->('artistic', $1, $2);
		}
	}

	# Apache
	given ($licensetext) {

		# skip referenced license
		when (/$L{re}{rpsl}/) {
			break;
		}

		when ( /$L{re}{apache}(?:,? $L{re}{version}{-keep}(,? $L{re}{version_later_postfix})?)?(?:(?: or)? [^ ,]*?apache[^ ,]*| \([^(),]+\))*,? or $L{re}{gpl}(?: $L{re}{version}{-keep}(,? $L{re}{version_later_postfix})?)?/i ) {
			$gen_license->( 'apache', $1, $2, 'gpl', $3, $4 );
		}
		when ( /$L{re}{apache}(?:,? $L{re}{version}{-keep}(,? $L{re}{version_later_postfix})?)?(?:(?: or)? [^ ,]*?apache[^ ,]*| \([^(),]\))*,? or(?: the)? bsd(?:[ -](\d)-clause)?\b/i ) {
			$gen_license->( 'apache', $1, $2, "bsd_${3}_clause" );
		}
		when ( /$L{re}{apache}(?:,? $L{re}{version}{-keep}(,? $L{re}{version_later_postfix})?)?(?:(?: or)? [^ ,]*?apache[^ ,]*| \([^(),]\))*,? or $L{re}{mit_new}\b/i ) {
			$gen_license->( 'apache', $1, $2, 'mit_new', $3, $4 );
		}
		when ( /$L{re}{apache}(?:,? $L{re}{version}{-keep}(,? $L{re}{version_later_postfix})?)?(?:(?: or)? [^ ,]*?apache[^ ,]*| \([^(),]\))*,? or $L{re}{mit}\b/i ) {
			$gen_license->( 'apache', $1, $2, 'mit', $3, $4 );
		}
		when ( /$L{re}{apache}(?:,? $L{re}{version}{-keep}(,? $L{re}{version_later_postfix})?)?/i ) {
			$gen_license->( 'apache', $1, $2 );
		}
		when ( m<https?www.apache.org/licenses(?:/LICENSE-($L{re}{version_number}))?>i ) {
			$gen_license->( 'apache', $1 );
		}
	}

	# FSFUL
	given ($licensetext) {
		when ( /$L{re}{fsful}/i ) {
			$gen_license->('fsful');
		}
		when ( /This (\w+)(?: (?:file|script))? is free software; $L{re}{fsf_unlimited}/i ) {
			$license = "FSF Unlimited ($1 derivation) $license";
			push @spdx_license, "FSFUL~$1";
		}
	}

	# FSFULLR
	given ($licensetext) {
		when ( /$L{re}{fsfullr}/i ) {
			$gen_license->('fsfullr');
		}
		when ( /This (\w+)(?: (?:file|script))?  is free software; $L{re}{fsf_unlimited_retention}/i ) {
			$license = "FSF Unlimited (with Retention, $1 derivation) $license";
			push @spdx_license, "FSFULLR~$1";
		}
	}

	# JSON
	given ($licensetext) {
		when ( /The Software shall be used for Good, not Evil/ ) {
			$gen_license->('JSON');
		}
	}

	# PHP
	given ($licensetext) {
		when ( /This source file is subject to version ($L{re}{version_number}) of the PHP license/ ) {
			$gen_license->( 'PHP', $1 );
		}
	}

	# CECILL
	given ($licensetext) {
		when ( /$L{re}{cecill_1}/ ) {
			$gen_license->('cecill_1');
		}
		when ( /$L{re}{cecill_1_1}/ ) {
			$gen_license->('cecill_1_1');
		}
		when ( /$L{re}{cecill_2}/ ) {
			$gen_license->('cecill_2');
		}
		when ( /$L{re}{cecill_2_1}/ ) {
			$gen_license->('cecill_2_1');
		}
		when ( /$L{re}{cecill_b}/ ) {
			$gen_license->('cecill_b');
		}
		when ( /$L{re}{cecill_c}/ ) {
			$gen_license->('cecill_c');
		}
		when ( /$L{re}{cecill}(?:(?:-|\s*$L{re}{version_prefix})($L{re}{version_number}))?/ ) {
			$gen_license->( 'cecill', $1 );
		}
	}

	# CDDL
	given ($licensetext) {
		when ( /$L{re}{cddl}(?:,?\s+$L{re}{version}{-keep})?/ ) {
			$gen_license->( 'cddl', $1 );
		}
	}

	# public-domain
	given ($licensetext) {
		when ( /is in $L{re}{public_domain}/i ) {
			$gen_license->('public_domain');
		}
	}

	given ($licensetext) {
		# AFL or LGPL
		when ( /either $L{re}{afl}(?:,? ?$L{re}{version}{-keep}(,? $L{re}{version_later_postfix})?)?, or $L{re}{lgpl}(?:,? ?$L{re}{version}{-keep}(,? $L{re}{version_later_postfix})?)?/i ) {
			$gen_license->( 'afl', $1, $2, 'lgpl', $3, $4 );
		}
		# AFL
		when ( /Licensed under $L{re}{afl}(?: $L{re}{version}{-keep})?/ ) {
			$gen_license->( 'afl', $1 );
		}
	}

	# EPL
	given ($licensetext) {
		when ( /$L{re}{epl}(?:[ ,-]+$L{re}{version}{-keep}(,? $L{re}{version_later_postfix})?)?/ ) {
			$gen_license->( 'epl', $1, $2 );
		}
	}

	# BSL
	given ($licensetext) {
		when ( /Permission is hereby granted, free of charge, to any person or organization obtaining a copy of the software and accompanying documentation covered by this license \(the Software\)/ ) {
			$gen_license->('BSL');
		}
		when ( /Boost Software License(?:[ ,-]+ $L{re}{version}{-keep})?/i ) {
			$gen_license->( 'BSL', $1, $2 );
		}
	}
	#>>>

	given ($licensetext) {

		# simple-versioned
		foreach my $id (qw<mpl ofl python qpl rpsl sgi_b wtfpl>) {
			when (/$L{re}{$id}\W*\(?$L{re}{version}{-keep}\)?/) {

				# skip referenced license
				if ( 'mpl' eq $id and $licensetext =~ /$L{re}{rpsl}/ ) {
					continue;
				}

				$gen_license->( $id, $1 );
				continue;
			}
		}

		# unversioned
		foreach my $id (
			qw(
			adobe_2006 adobe_glyph aladdin apafml
			beerware cube curl eurosym fsfap ftl icu isc libpng llgpl
			mit_advertising mit_cmu mit_cmu_warranty
			mit_enna mit_feh mit_new mit_old
			mit_oldstyle mit_oldstyle_disclaimer mit_oldstyle_permission
			ms_pl ms_rl postgresql unicode_strict unicode_tou
			zlib zlib_acknowledgement)
			)
		{
			when (/$L{re}{$id}/) {

				# skip embedded license
				if ( 'zlib' eq $id and $licensetext =~ /$L{re}{cube}/ ) {
					continue;
				}
				$gen_license->($id);
				continue;
			}
		}
	}

	# Remove trailing spaces.
	$license =~ s/\s+$//;
	return $self->deb_fmt ? join( ' and/or ', sort @spdx_license ) : $license;
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
