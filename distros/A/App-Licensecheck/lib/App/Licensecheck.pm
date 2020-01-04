package App::Licensecheck;

use utf8;
use strictures 2;
use autodie;

use version;
use Path::Iterator::Rule;
use Path::Tiny;
use Fcntl qw/:seek/;
use Encode;
use Regexp::Pattern;
use Regexp::Pattern::License 3.1.94;
use String::Copyright 0.003 {
	format => sub { join ' ', $_->[0] || (), $_->[1] || () }
};
use String::Copyright 0.003 {
	threshold_after => 5,
	format          => sub { join ' ', $_->[0] || (), $_->[1] || () },
	},
	'copyright' => { -as => 'copyright_optimistic' };

use Moo;
with qw(MooX::Role::Logger);

use experimental "switch";
use namespace::clean;

=head1 NAME

App::Licensecheck - functions for a simple license checker for source files

=head1 VERSION

Version v3.0.38

=cut

our $VERSION = version->declare("v3.0.38");

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
		clause_advertising clause_non_endorsement clause_reproduction
		fsf_unlimited fsf_unlimited_retention
		version_later version_later_postfix)
		)
	{
		my $re = re( "License::$trait", subject => 'trait' );
		$list{re_trait}{$trait} = ref($re) ? $re : qr/$re/;
	}
	for my $trait (qw(version version_numberstring)) {
		my $re = re(
			"License::$trait", subject => 'trait',
			capture => 'numbered'
		);
		$list{re_trait_keep}{$trait} = ref($re) ? $re : qr/$re/;
	}

	#<<<  do not let perltidy touch this (keep long regex on one line)
	$list{re_grant_license}{local}{version_agpl_gpl}{1} = qr/$list{re_trait_keep}{version_numberstring}(?:[.,])? (?:\(?only\)?.? )?(?:of $list{re_name}{gnu}|(as )?published by the Free Software Foundation)/i;
	$list{re_grant_license}{local}{version_agpl_gpl}{2} = qr/$list{re_name}{gnu}\b[;,] $list{re_trait_keep}{version_numberstring}\b[.,]? /i;
	$list{re_grant_license}{local}{version_agpl_gpl}{3} = qr/either $list{re_trait_keep}{version_numberstring},? $list{re_trait}{version_later_postfix}/;
	$list{re_grant_license}{local}{version_agpl_gpl}{4} = qr/GPL as published by the Free Software Foundation, $list{re_trait_keep}{version_numberstring}/i;
	$list{re_grant_license}{local}{address_agpl_gpl_lgpl}{1} = qr/(?:675 Mass Ave|59 Temple Place|51 Franklin Steet|02139|02111-1307)/i;
	$list{re_grant_license}{local}{exception_agpl_gpl_lgpl}{1} = qr/permission (?:is (also granted|given))? to link (the code of )?this program with (any edition of )?(Qt|the Qt library)/i;
	$list{re_grant_license}{local}{generated}{1} = qr/unless such copies or derivative works are solely in the form of machine-executable object code generated by a source language processor/;
	$list{re_grant_license}{local}{generated}{2} = qr/(All changes made in this file will be lost|DO NOT ((?:HAND )?EDIT|delete this file|modify)|edit the original|Generated (automatically|by|from|data|with)|generated.*file|auto[- ]generated)/i;
	$list{re_grant_license}{local}{multi}{1} = qr/$list{re_trait}{licensed_under}$list{re_trait}{any_of}(?:[^.]|\.\S)*$list{re_name}{lgpl}$list{re_trait_keep}{version}?/i;
	$list{re_grant_license}{local}{multi}{2} = qr/$list{re_trait}{licensed_under}$list{re_trait}{any_of}(?:[^.]|\.\S)*$list{re_name}{gpl}$list{re_trait_keep}{version}?/i;
	$list{re_grant_license}{local}{lgpl}{1} = qr/$list{re_trait}{licensed_under}$list{re_trait}{any_of}(?:[^.]|\.\S)*$list{re_name}{lgpl}$list{re_trait_keep}{version}?/i;
	$list{re_grant_license}{local}{lgpl}{2} = qr/either $list{re_name}{afl}$list{re_trait_keep}{version}, or $list{re_name}{lgpl}$list{re_trait_keep}{version}?/i;
	$list{re_grant_license}{local}{lgpl}{3} = qr/either $list{re_name}{gpl}$list{re_trait_keep}{version}?(?: \((?:the )?"?GPL"?\))?, or $list{re_name}{lgpl}/i;
	$list{re_grant_license}{local}{lgpl}{4} = qr/$list{re_trait}{licensed_under}$list{re_trait_keep}{version}? of $list{re_name}{lgpl}/i;
	$list{re_grant_license}{local}{lgpl}{5} = qr/$list{re_trait}{licensed_under}$list{re_name}{lgpl}\b[,;:]?(?: either)? ?$list{re_trait_keep}{version_numberstring},? $list{re_trait}{or_at_option} $list{re_trait_keep}{version_numberstring}/i;
	$list{re_grant_license}{local}{lgpl}{6} = qr/$list{re_trait}{licensed_under}$list{re_name}{lgpl}(?:[,;:]?(?: either)?$list{re_trait_keep}{version}?)?/i;
	$list{re_grant_license}{local}{agpl}{1} = qr/$list{re_trait}{licensed_under}$list{re_name}{agpl}/i;
	$list{re_grant_license}{local}{agpl}{2} = qr/(?:signe la|means the) GNU Affero General Public License/i;
	$list{re_grant_license}{local}{agpl}{3} = qr/GNU Affero General Public License into/i;
	$list{re_grant_license}{local}{agpl}{4} = qr/means either the GNU/i;
	$list{re_grant_license}{local}{agpl}{5} = qr/AFFERO GENERAL PUBLIC LICENSE$list{re_trait_keep}{version}?/i;
	$list{re_grant_license}{local}{gpl}{1} = qr/Copyright \(C\) (?:19|yy)yy <?name of author>?\s+This program is free software/;
	$list{re_grant_license}{local}{gpl}{2} = qr/under the GNU GPL,? with none of the additional permissions of this License/;
	$list{re_grant_license}{local}{gpl}{3} = qr/GNU Affero General Public License/;
	$list{re_grant_license}{local}{gpl}{4} = qr/Terms of the Perl programming language system itself/;
	$list{re_grant_license}{local}{gpl}{5} = qr/COMPATIBILITY WITH THE GPL LICENSE/i;
	$list{re_grant_license}{local}{gpl}{6} = qr/$list{re_trait}{licensed_under}$list{re_trait}{any_of}(?:[^.]|\.\S)*$list{re_name}{gpl}$list{re_trait_keep}{version}?/i;
	$list{re_grant_license}{local}{gpl}{7} = qr/either $list{re_name}{gpl}$list{re_trait_keep}{version}?(?: \((?:the )?"?GPL"?\))?, or $list{re_name}{lgpl}$list{re_trait_keep}{version}?/i;
	$list{re_grant_license}{local}{gpl}{8} = qr/$list{re_trait}{licensed_under}(?:version \S+ (?:\(?only\)? )?of )?$list{re_name}{gpl}/i;
	$list{re_grant_license}{local}{gpl}{9} = qr/$list{re_trait}{licensed_under}(?:version \S+ (?:\(?only\)? )?of )?$list{re_name}{gpl}$list{re_trait_keep}{version}?/i;
	foreach my $id ( sort keys %{ $list{family}{cc} } ) {
		$list{re_grant_license}{local}{cc}{1}{$id} = qr/$list{re_name}{$id}$list{re_trait_keep}{version_numberstring} or $list{re_trait_keep}{version_numberstring}/i;
		$list{re_grant_license}{local}{cc}{2}{$id} = qr/$list{re_name}{$id}$list{re_trait_keep}{version}(?:,? (?:and|or) (?:the )?(?:GNU )?([AL]?GPL)-?$list{re_trait_keep}{version})?/i;
	}
	$list{re_grant_license}{local}{bsd}{1} = qr/THIS SOFTWARE IS PROVIDED .*AS IS AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY/;
	$list{re_grant_license}{local}{bsd}{2} = qr/$list{re_trait}{clause_advertising}/i;
	$list{re_grant_license}{local}{bsd}{3} = qr/$list{re_trait}{clause_non_endorsement}/i;
	$list{re_grant_license}{local}{bsd}{4} = qr/$list{re_trait}{clause_reproduction}/i;
	$list{re_grant_license}{local}{bsd}{5} = qr/licen[sc]e:? ?bsd-(\d)-clause/i;
	$list{re_grant_license}{local}{bsd}{6} = qr/licen[sc]e:? ?bsd\b/i;
	$list{re_grant_license}{local}{apache}{1} = qr/$list{re_name}{apache}$list{re_trait_keep}{version}?(?:(?: or)? [^ ,]*?apache[^ ,]*| \([^(),]+\))*,? or $list{re_name}{gpl}$list{re_trait_keep}{version}?/i;
	$list{re_grant_license}{local}{apache}{2} = qr/$list{re_name}{apache}$list{re_trait_keep}{version}?(?:(?: or)? [^ ,]*?apache[^ ,]*| \([^(),]\))*,? or(?: the)? bsd(?:[ -](\d)-clause)?\b/i;
	$list{re_grant_license}{local}{apache}{4} = qr/$list{re_name}{apache}$list{re_trait_keep}{version}?(?:(?: or)? [^ ,]*?apache[^ ,]*| \([^(),]\))*,? or $list{re_name}{mit}\b/i;
	$list{re_grant_license}{local}{fsful}{1} = qr/This (\w+)(?: (?:file|script))? is free software; $list{re_trait}{fsf_unlimited}/i;
	$list{re_grant_license}{local}{fsfullr}{1} = qr/This (\w+)(?: (?:file|script))?  is free software; $list{re_trait}{fsf_unlimited_retention}/i;
	$list{re_grant_license}{local}{php}{1} = qr/$list{re_trait}{licensed_under}$list{re_trait_keep}{version_numberstring} of the PHP license/;
	$list{re_grant_license}{local}{pd}{1} = qr/$list{re_grant_license}{public_domain}/;
	foreach my $id ( sort keys %{ $list{type}{versioned} } ) {
		$list{re_grant_license}{local}{versioned}{$id} = qr/$list{re_name}{$id}$list{re_trait_keep}{version}?/;
	}
	$list{re_grant_license}{local}{trailing_space} = qr/\s+$/;
	#>>>

	return %list;
}

sub _log_license
{
	my ( $self, $action, $thing, $extra ) = @_;
	if ( $self->_logger->is_trace() ) {
		$self->_logger->trace( "license text $action: $thing", ($extra) );
	}
	else {
		$self->_logger->debug("license text $action: $thing");
	}
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
		$self->_log_license( 'collected', $expr, { path => "$file" } )
			if ( $self->_logger->is_debug() );
		push @spdx_license, $expr;
		$license = join( ' ', $L{caption}{$legacy} || $legacy, $license );
	};

	for my $trait (qw(licensed_under)) {
		while ( $licensetext =~ /$L{re_trait}{$trait}/g ) {
			$match{_}{$trait}{ $-[0] } = $+[0];
		}
	}
	for my $id ( keys %{ $L{re_name} } ) {
		while ( $licensetext =~ /$L{re_name}{$id}/g ) {
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
					=~ /^$L{re_trait_keep}{version}/ )
				{
					$pos2 += $+[0];
					my $version = $1;
					$version =~ s/(?:\.0)+$//;
					$_ .= "_$version";
					if ($2) {
						$_ .= "_or_later";
					}
				}
				$pos{$pos}{$_} = 1;
			}
		}
	}
	for my $pos ( keys %pos ) {
		my @name = keys %{ $pos{$pos} };
		for my $name (@name) {
			$grant{$name} = 1;
		}
	}

	if ( grep { $match{$_}{name} } @agpl, @gpl ) {

		# version of AGPL/GPL
		given ($licensetext) {
			when ( $L{re_grant_license}{local}{version_agpl_gpl}{1} ) {
				$gplver      = " (v$1)";
				@spdx_gplver = ($1)
			}
			when ( $L{re_grant_license}{local}{version_agpl_gpl}{2} ) {
				$gplver      = " (v$1)";
				@spdx_gplver = ($1);
			}
			when ( $L{re_grant_license}{local}{version_agpl_gpl}{3} ) {
				$gplver      = " (v$1 or later)";
				@spdx_gplver = ( $1 . '+' );
			}
			when ( $L{re_grant_license}{local}{version_agpl_gpl}{4} ) {
				$gplver      = " (v$1)";
				@spdx_gplver = ($1)
			}
		}
	}

	if ( grep { $match{$_}{name} } @agpl, @gpl, @lgpl ) {

		# address in AGPL/GPL/LGPL
		given ($licensetext) {
			when ( $L{re_grant_license}{local}{address_agpl_gpl_lgpl}{1} ) {
				$extrainfo = " (with incorrect FSF address)$extrainfo";
			}
		}

		# exception for AGPL/GPL/LGPL
		given ($licensetext) {
			when ( $L{re_grant_license}{local}{exception_agpl_gpl_lgpl}{1} ) {
				$extrainfo  = " (with Qt exception)$extrainfo";
				$spdx_extra = 'with Qt exception';
			}
		}
	}

	# generated file
	given ($licensetext) {

		# exclude blurb found in boost license text
		when ( $L{re_grant_license}{local}{generated}{1} ) {
			break;
		}
		when ( $L{re_grant_license}{local}{generated}{2} ) {
			$license = "GENERATED FILE";
		}
	}

	# multi-licensing
	my @multilicenses;

	# same sentence
	if ( grep { $match{$_}{name} } @lgpl ) {
		if ( $licensetext =~ $L{re_grant_license}{local}{multi}{1} ) {
			push @multilicenses, 'lgpl', $1, $2;
		}
	}
	if ( grep { $match{$_}{name} } @gpl ) {
		if ( $licensetext =~ $L{re_grant_license}{local}{multi}{2} ) {
			push @multilicenses, 'gpl', $1, $2;
		}
	}
	$gen_license->(@multilicenses) if (@multilicenses);

	if ( grep { $match{$_}{name} } @lgpl ) {

		# LGPL
		given ($licensetext) {

			# LGPL, among several
			when ( $L{re_grant_license}{local}{lgpl}{1} ) {
				break;    # handled in multi-licensing loop
			}

			# AFL or LGPL
			when ( $L{re_grant_license}{local}{lgpl}{2} ) {
				break;    # handled in AFL loop
			}

			# GPL or LGPL
			when ( $L{re_grant_license}{local}{lgpl}{3} ) {
				break;    # handled in GPL loop
			}

			# LGPL, version first
			when ( $L{re_grant_license}{local}{lgpl}{4} ) {
				$gen_license->( 'lgpl', $1, $2 );
			}

			# LGPL, dual versions last
			when ( $L{re_grant_license}{local}{lgpl}{5} ) {
				$license = "LGPL (v$1 or v$2) $license";
				push @spdx_license, "LGPL-$1 or LGPL-$2";
			}

			# LGPL, version last
			when ( $L{re_grant_license}{local}{lgpl}{6} ) {
				$gen_license->( 'lgpl', $1, $2 );
			}
		}
		$match{lgpl}{custom} = 1;
		$match{afl}{custom}  = 1;
	}

	if ( grep { $match{$_}{name} } @agpl ) {

		# AGPL
		given ($licensetext) {
			when ( $L{re_grant_license}{local}{agpl}{1} ) {
				$license = "AGPL$gplver$extrainfo $license";
				push @spdx_license, $gen_spdx->('AGPL');
			}

			# exclude CeCILL-2.1 license
			when ( $L{re_grant_license}{local}{agpl}{2} ) {
				break;
			}

			# exclude GPL-3 license
			when ( $L{re_grant_license}{local}{agpl}{3} ) {
				break;
			}

			# exclude MPL-2.0 license
			when ( $L{re_grant_license}{local}{agpl}{4} ) {
				break;
			}
			when ( $L{re_grant_license}{local}{agpl}{5} ) {
				$gen_license->( 'agpl', $1, $2 );
			}
		}
		$match{agpl}{custom} = 1;
	}

	if ( grep { $match{$_}{name} } @gpl ) {

		# GPL
		given ($licensetext) {

			# exclude GPL fulltext (rarely if ever used as grant)
			when ( $L{re_grant_license}{local}{gpl}{1} ) {
				break;
			}

			# exclude LGPL-3 fulltext (rarely if ever used as grant)
			when ( $L{re_grant_license}{local}{gpl}{2} ) {
				break;
			}

			# exclude AGPL-3 license
			when ( $L{re_grant_license}{local}{gpl}{3} ) {
				break;
			}

			# exclude Perl combo license
			when ( $L{re_grant_license}{local}{gpl}{4} ) {
				break;
			}

			# exclude CeCILL-1.1 license
			when ( $L{re_grant_license}{local}{gpl}{5} ) {
				break;
			}

			# GPL, among several
			when ( $L{re_grant_license}{local}{gpl}{6} ) {
				break;    # handled in multi-licensing loop
			}

			# GPL or LGPL
			when ( $L{re_grant_license}{local}{gpl}{7} ) {
				$gen_license->( 'gpl', $1, $2, 'lgpl', $3, $4 );
			}
			if ( $gplver or $extrainfo ) {
				when ( $L{re_grant_license}{local}{gpl}{8} ) {
					$license = "GPL$gplver$extrainfo $license";
					my $expr = join ' ', $gen_spdx->('GPL');
					$self->_log_license(
						'collected', $expr,
						{ path => "$file" }
					) if ( $self->_logger->is_debug() );
					push @spdx_license, $expr;
				}
			}
			when ( $L{re_grant_license}{local}{gpl}{9} ) {
				$gen_license->( 'gpl', $1, $2 );
			}
		}
		$match{gpl}{custom} = 1;
	}

	# CC
	given ($licensetext) {
		foreach my $id (@L_family_cc) {
			next unless ( $match{$id}{name} );
			when ( $L{re_grant_license}{local}{cc}{1}{$id} ) {
				$license = "$L{caption}{$id} (v$1 or v$2) $license";
				my $expr = "$L{name}{$id}-$1 or $L{name}{$id}-$2";
				$self->_log_license( 'collected', $expr, { path => "$file" } )
					if ( $self->_logger->is_debug() );
				push @spdx_license, $expr;
			}
			when ( $L{re_grant_license}{local}{cc}{2}{$id} ) {
				$gen_license->( $id, $1, $2, $3, $4 );
			}
		}
	}
	$match{$_}{custom} = 1
		for (
		qw(cc_by cc_by_nc cc_by_nc_nd cc_by_nc_sa cc_by_nd cc_by_sa cc_cc0 cc_sp)
		);

	# BSD
	if ( $licensetext =~ $L{re_grant_license}{local}{bsd}{1} ) {
		given ($licensetext) {
			when ( $L{re_grant_license}{local}{bsd}{2} ) {
				$gen_license->('bsd_4_clause');
			}
			when ( $L{re_grant_license}{local}{bsd}{3} ) {
				$gen_license->('bsd_3_clause');
			}
			when ( $L{re_grant_license}{local}{bsd}{4} ) {
				$gen_license->('bsd_2_clause');
			}
			default {
				$gen_license->('bsd');
			}
		}
	}
	elsif ( $licensetext =~ $L{re_grant_license}{local}{bsd}{5} ) {
		$gen_license->("bsd_${1}_clause");
	}
	elsif ( $licensetext =~ $L{re_grant_license}{local}{bsd}{6} ) {
		$gen_license->('bsd');
	}
	$match{$_}{custom} = 1 for (qw(bsd_2_clause bsd_3_clause bsd_4_clause));

	# Apache
	given ($licensetext) {
		if ( $match{apache}{name} ) {
			when ( $L{re_grant_license}{local}{apache}{1} ) {
				$gen_license->( 'apache', $1, $2, 'gpl', $3, $4 );
			}
			when ( $L{re_grant_license}{local}{apache}{2} ) {
				$gen_license->( 'apache', $1, $2, "bsd_${3}_clause" );
			}
			when ( $L{re_grant_license}{local}{apache}{4} ) {
				$gen_license->( 'mit', $3, $4 );
			}
		}
	}
	$match{apache}{custom} = 1;

	# FSFUL
	given ($licensetext) {
		when ( $L{re_grant_license}{fsful} ) {
			$gen_license->('fsful');
		}
		when ( $L{re_grant_license}{local}{fsful}{1} ) {
			$license = "FSF Unlimited ($1 derivation) $license";
			my $expr = "FSFUL~$1";
			$self->_log_license( 'collected', $expr, { path => "$file" } )
				if ( $self->_logger->is_debug() );
			push @spdx_license, $expr;
		}
	}
	$match{fsful}{custom} = 1;

	# FSFULLR
	given ($licensetext) {
		when ( $L{re_grant_license}{fsfullr} ) {
			$gen_license->('fsfullr');
		}
		when ( $L{re_grant_license}{local}{fsfullr}{1} ) {
			$license
				= "FSF Unlimited (with Retention, $1 derivation) $license";
			my $expr = "FSFULLR~$1";
			$self->_log_license( 'collected', $expr, { path => "$file" } )
				if ( $self->_logger->is_debug() );
			push @spdx_license, $expr;
		}
	}
	$match{fsfullr}{custom} = 1;

	# JSON
	given ($licensetext) {
		when ( $L{re_grant_license}{json} ) {
			$gen_license->('JSON');
		}
	}

	# PHP
	given ($licensetext) {
		when ( $L{re_grant_license}{local}{php}{1} ) {
			$gen_license->( 'PHP', $1 );
		}
	}

	# public-domain
	given ($licensetext) {
		when ( $L{re_grant_license}{local}{pd}{1} ) {
			$gen_license->('public_domain');
		}
	}
	$match{public_domain}{custom} = 1;

	# singleversion
	foreach my $id (@L_type_singleversion) {
		next if ( $match{$id}{custom} );

		if ( grep { $_ ne $id } @L_tidy ) {
			if ( $licensetext =~ $L{re_grant_license}{$id} ) {
				$grant{$id} = 1;
			}
		}

		if ( $grant{$id} ) {
			$gen_license->($id);

			# skip unversioned equivalent
			$match{ $L{series}{$id} }{custom} = 1
				if ( $L{series}{$id} );
		}
	}

	# versioned
	foreach my $id (@L_type_versioned) {
		next if ( $match{$id}{custom} );
		next if ( grep { $_ eq $id } @L_tidy );

		# skip embedded or referenced licenses
		if ( grep { $id eq $_ } qw(mpl python) ) {
			next if $licensetext =~ $L{re_grant_license}{rpsl};
		}

		# FIXME: match grant (not name)
		if ( $match{$id}{name} ) {
			if ( $licensetext =~ $L{re_grant_license}{local}{versioned}{$id} )
			{
				$gen_license->( $id, $1, $2 );
				$match{$id}{custom} = 1;
			}
		}
		next if ( $match{$id}{custom} );
		if ( $L{re_grant_license}{$id} ) {
			if ( $licensetext =~ $L{re_grant_license}{$id} ) {
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
			next if $licensetext =~ $L{re_grant_license}{cube};
		}
		if ( grep { $id eq $_ } qw(ntp) ) {
			next if $licensetext =~ $L{re_grant_license}{ntp_disclaimer};
			next if $licensetext =~ $L{re_grant_license}{dsdp};
		}
		if ( grep { $id eq $_ } qw(ntp_disclaimer) ) {
			next if $licensetext =~ $L{re_grant_license}{mit_cmu};
		}

		if ( $licensetext =~ $L{re_grant_license}{$id} ) {
			$gen_license->($id);
		}
	}

	# Remove trailing spaces.
	$license =~ s/$L{re_grant_license}{local}{trailing_space}//;
	my $expr = join( ' and/or ', sort @spdx_license );
	$self->_log_license( 'resolved', $expr, { path => "$file" } )
		if ( $self->_logger->is_debug() );
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
