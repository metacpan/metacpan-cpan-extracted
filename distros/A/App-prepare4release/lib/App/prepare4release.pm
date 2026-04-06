package App::prepare4release;

use strict;
use warnings;
use utf8;

our $VERSION = '0.03';

use Carp qw(croak);
use Cwd qw(getcwd);
use File::Copy qw(copy);
use File::Find ();
use File::Path qw(make_path);
use File::Spec ();
use JSON::PP ();
use Pod::Usage qw(pod2usage);
use version ();

sub DEFAULT_CONFIG_FILENAME {'prepare4release.json'}

sub new {
	my ( $class, %arg ) = @_;
	my $self = bless {
		config_path => $arg{config_path},
		config      => $arg{config},
		opts        => $arg{opts} // {},
		identity    => $arg{identity} // {},
	}, $class;
	return $self;
}

# --- JSON "git" section ------------------------------------------------------

sub git_hash {
	my ( $class, $config ) = @_;
	$config = {} unless ref $config eq 'HASH';
	my $g = $config->{git};
	return {} unless ref $g eq 'HASH';
	return {%$g};
}

sub git_author {
	my ( $class, $config ) = @_;
	my $g = $class->git_hash($config);
	my $a = $g->{author};
	return $a if defined $a && length $a;
	return;
}

sub git_repo_name {
	my ( $class, $config ) = @_;
	my $g = $class->git_hash($config);
	my $r = $g->{repo};
	return $r if defined $r && length $r;
	return;
}

sub git_server {
	my ( $class, $config ) = @_;
	my $g = $class->git_hash($config);
	my $s = $g->{server};
	if ( defined $s && length $s ) {
		$s =~ s{\Ahttps?://}{}i;
		$s =~ s{/\z}{};
		return $s;
	}
	return;
}

sub git_default_branch {
	my ( $class, $config ) = @_;
	my $g = $class->git_hash($config);
	my $b = $g->{default_branch};
	return $b if defined $b && length $b;
	return 'main';
}

# Returns ( $namespace_path, $short_repo_name ) where $namespace_path is
# C<group/project> or URL-derived path when C<git.repo> is enough on its own;
# otherwise ( undef, short name or undef for default from module ).
sub _git_path_segment_or_short_repo {
	my ( $class, $config ) = @_;
	my $raw = $class->git_repo_name($config);
	return ( undef, undef ) unless defined $raw && length $raw;

	if ( $raw =~ m{\Ahttps?://[^/]+/(.+?)\z}i ) {
		my $p = $1;
		$p =~ s{/\.git\z}{}i;
		return ( $p, undef );
	}
	if ( $raw =~ m{\Agit@([^:]+):(.+?)\z} ) {
		my $p = $2;
		$p =~ s{\.git\z}{};
		return ( $p, undef );
	}
	if ( $raw =~ m{/} ) {
		return ( $raw, undef );
	}
	return ( undef, $raw );
}

# --- Host / URLs -------------------------------------------------------------

sub effective_git_host {
	my ( $class, $opts, $config ) = @_;
	my $srv = $class->git_server($config);
	return $srv if defined $srv && length $srv;
	return 'gitlab.com' if $opts->{gitlab};
	return 'github.com';
}

sub https_base {
	my ( $class, $host ) = @_;
	$host =~ s{/\z}{};
	return "https://$host";
}

sub package_to_repo_default {
	my ( $class, $module_name ) = @_;
	croak 'module_name required' unless defined $module_name && length $module_name;
	( my $copy = $module_name ) =~ s/::/-/g;
	return 'perl-' . $copy;
}

sub module_repo {
	my ($self) = @_;
	my $cfg = $self->{config} // {};
	my $id  = $self->{identity} // {};
	my $mod = $id->{module_name};
	croak 'module_name is required to derive module_repo'
		unless defined $mod && length $mod;

	my ( $full, $short ) = __PACKAGE__->_git_path_segment_or_short_repo($cfg);
	return $full if defined $full && length $full;
	if ( defined $short && length $short ) {
		return $short;
	}
	return __PACKAGE__->package_to_repo_default($mod);
}

sub repository_path_segment {
	my ($self) = @_;
	my $cfg = $self->{config} // {};

	my ( $full, $short ) = __PACKAGE__->_git_path_segment_or_short_repo($cfg);
	if ( defined $full && length $full ) {
		return $full;
	}

	my $author = __PACKAGE__->git_author($cfg);
	croak 'git.author is required in prepare4release.json under "git" '
		. '(or set git.repo to namespace/project or a repository URL)'
		unless defined $author && length $author;

	my $repo;
	if ( defined $short && length $short ) {
		$repo = $short;
	}
	else {
		my $id = $self->{identity} // {};
		my $mod = $id->{module_name};
		croak 'module_name is required to derive repository path'
			unless defined $mod && length $mod;
		$repo = __PACKAGE__->package_to_repo_default($mod);
	}
	return "$author/$repo";
}

sub repository_web_url {
	my ($self) = @_;
	my $opts = $self->{opts} // {};
	my $cfg  = $self->{config} // {};
	my $base = __PACKAGE__->https_base(
		__PACKAGE__->effective_git_host( $opts, $cfg ) );
	return $base . '/' . $self->repository_path_segment;
}

sub repository_git_url {
	my ($self) = @_;
	return $self->repository_web_url . '.git';
}

sub bugtracker_url {
	my ($self) = @_;
	my $cfg = $self->{config} // {};
	if ( ref $cfg eq 'HASH' && defined $cfg->{bugtracker} && length $cfg->{bugtracker} ) {
		return $cfg->{bugtracker};
	}
	return $self->repository_web_url . '/issues';
}

# --- Makefile.PL discovery ---------------------------------------------------

sub makefile_pl_path {
	my ($class) = @_;
	my $cwd = getcwd();
	my $p = File::Spec->catfile( $cwd, 'Makefile.PL' );
	return -e $p ? $p : undef;
}

sub read_makefile_pl_snippets {
	my ( $class, $path ) = @_;
	open my $fh, '<:encoding(UTF-8)', $path
		or croak "Cannot open Makefile.PL '$path': $!";
	local $/;
	my $s = <$fh>;
	close $fh;

	my %out;
	if ( $s =~ /VERSION_FROM\s*=>\s*['"]([^'"]+)['"]/ ) {
		$out{version_from} = $1;
	}
	if ( $s =~ /NAME\s*=>\s*['"]([^'"]+)['"]/ ) {
		$out{name} = $1;
	}
	if ( $s =~ /LICENSE\s*=>\s*['"]([^'"]+)['"]/ ) {
		$out{license} = $1;
	}
	return ( $s, \%out );
}

sub find_lib_pm_files {
	my ( $class, $cwd ) = @_;
	my $lib = File::Spec->catfile( $cwd, 'lib' );
	return () unless -d $lib;
	my @files;
	File::Find::find(
		sub {
			return unless -f && /\.pm\z/;
			push @files, $File::Find::name;
		},
		$lib
	);
	return @files;
}

sub parse_pm_identity {
	my ( $class, $path ) = @_;
	open my $fh, '<:encoding(UTF-8)', $path
		or croak "Cannot open '$path': $!";
	my $pkg;
	my $ver;
	while ( my $line = <$fh> ) {
		if ( !$pkg && $line =~ /^\s*package\s+([\w:]+)\s*;/ ) {
			$pkg = $1;
		}
		if ( $line =~ /\$VERSION\s*=\s*([^;\s]+)\s*;/ ) {
			my $raw = $1;
			$raw =~ s/^(['"])(.*)\1\z/$2/s;
			$ver = $raw;
		}
	}
	close $fh;
	return ( $pkg, $ver );
}

sub resolve_identity {
	my ( $class, $cwd, $config, $mf_snippets ) = @_;
	$config = {} unless ref $config eq 'HASH';

	my $module_name = $config->{module_name};
	my $version     = $config->{version};
	my $dist_name   = $config->{dist_name};

	my $vf_rel = $mf_snippets->{version_from};
	my $vf_abs;
	if ($vf_rel) {
		$vf_abs = File::Spec->rel2abs( $vf_rel, $cwd );
	}

	if ( ( !$module_name || !length $module_name ) && $vf_abs && -e $vf_abs ) {
		my $v_from_file;
		( $module_name, $v_from_file ) = $class->parse_pm_identity($vf_abs);
		$version //= $v_from_file if defined $v_from_file;
	}

	if ( ( !$module_name || !length $module_name ) && $mf_snippets->{name} ) {
		$module_name = $mf_snippets->{name};
	}

	if ( ( !$module_name || !length $module_name ) ) {
		my @candidates = $class->find_lib_pm_files($cwd);
		for my $f ( sort @candidates ) {
			my ( $p, $v ) = $class->parse_pm_identity($f);
			if ($p) {
				$module_name = $p;
				$vf_abs = $f;
				$version //= $v if defined $v;
				last;
			}
		}
	}

	if ( $vf_abs && -e $vf_abs && !defined $version ) {
		my $v2;
		( undef, $v2 ) = $class->parse_pm_identity($vf_abs);
		$version = $v2 if defined $v2;
	}

	if ( !$dist_name && $module_name ) {
		( my $d = $module_name ) =~ s/::/-/g;
		$dist_name = $d;
	}

	return {
		module_name => $module_name,
		version     => $version,
		dist_name   => $dist_name,
		version_from_path => $vf_abs,
	};
}

# --- Makefile.PL patches -----------------------------------------------------

# Relative path (from dist root) to the generated, self-contained badge injector.
sub inject_readme_badges_relpath {'maint/inject-readme-badges.pl'}

# Standalone Perl (core only): no App::prepare4release at C<make README.md> time.
sub _inject_readme_badges_pl_template {
	return <<'P4R_INJECT_TMPL';
#!/usr/bin/env perl
# Generated by App::prepare4release — do not edit by hand. Re-run: prepare4release ...
use strict;
use warnings;
use utf8;

sub _readme_managed_badge_line_re {
	return qr{^\[!\[(?:License|Perl|CI|MetaCPAN package|CPAN version|CPAN testers)\]};
}

sub _strip_readme_badge_markdown_block {
	my ($text) = @_;
	$text =~ s{
		\s*<!--\s*PREPARE4RELEASE_BADGES\s*-->\s*
		.*?
		<!--\s*/PREPARE4RELEASE_BADGES\s*-->\s*
	}{}msx;

	my $re = _readme_managed_badge_line_re();
	my @lines = split /\n/, $text, -1;
	my $i = 0;
	while ( $i < @lines ) {
		if ( $lines[$i] =~ $re ) {
			my $start = $i;
			$i++;
			while ( $i < @lines && $lines[$i] =~ $re ) {
				$i++;
			}
			splice @lines, $start, $i - $start;
			$i = $start;
			next;
		}
		$i++;
	}
	return join "\n", @lines;
}

sub _insert_readme_badges_after_regen {
	my ( $text, $block ) = @_;
	if ( $text =~ /\A\x{FEFF}/ ) {
		$text =~ s/\A\x{FEFF}//;
	}
	my @lines = split /\n/, $text, -1;
	my $i = 0;
	while ( $i < @lines && $lines[$i] =~ /^\s*$/ ) {
		$i++;
	}
	if ( $i >= @lines ) {
		return $block . $text;
	}
	if ( $lines[$i] =~ /^#\s+NAME\s*$/i ) {
		my $prefix = join "\n", @lines[ 0 .. $i - 1 ];
		my $rest   = join "\n", @lines[ $i .. $#lines ];
		my $out = '';
		$out .= $prefix if length $prefix;
		$out .= "\n" if length $prefix;
		$out .= $block;
		$out .= $rest;
		return $out;
	}
	if ( $lines[$i] =~ /^#\s+/ ) {
		while ( $i < @lines && $lines[$i] =~ /^#\s+/ ) {
			$i++;
		}
		while ( $i < @lines && $lines[$i] =~ /^\s*$/ ) {
			$i++;
		}
		my $before = join "\n", @lines[ 0 .. $i - 1 ];
		my $after  = join "\n", @lines[ $i .. $#lines ];
		my $out = $before . "\n\n" . $block;
		$out .= $after if length $after;
		return $out;
	}
	return $block . $text;
}

sub badge_block {
	return <<'__P4R_BADGE_INNER__';
__P4R_BADGE_INNER_BODY__
__P4R_BADGE_INNER__
}

sub run {
	my $readme = 'README.md';
	open my $fh, '<:encoding(UTF-8)', $readme
		or die "Cannot open README.md: $!";
	local $/;
	my $text = <$fh> // '';
	close $fh;

	$text = _strip_readme_badge_markdown_block($text);
	my $inner = badge_block();
	my $block = $inner . "\n\n";
	my $new_text = _insert_readme_badges_after_regen( $text, $block );
	return if $new_text eq $text;

	open my $out, '>:encoding(UTF-8)', $readme
		or die "Cannot write README.md: $!";
	print {$out} $new_text;
	close $out;
	return;
}

run() if !caller;

1;
P4R_INJECT_TMPL
}

sub _render_inject_readme_badges_pl {
	my ( $class, $inner ) = @_;
	$inner = '' unless defined $inner;
	my $marker = '__P4R_BADGE_INNER_BODY__';
	croak "inject-readme-badges.pl: badge text must not contain $marker"
		if index( $inner, $marker ) >= 0;
	my $t = $class->_inject_readme_badges_pl_template;
	my $i = index( $t, $marker );
	croak 'inject-readme-badges.pl: template missing inner placeholder'
		if $i < 0;
	substr( $t, $i, length($marker), $inner );
	return $t;
}

sub write_inject_readme_badges_script {
	my ( $class, $cwd, $inner, $verbose ) = @_;
	my $rel  = $class->inject_readme_badges_relpath;
	my @segs = split qr{/}, $rel;
	my $file = pop @segs;
	my $path = File::Spec->catfile( $cwd, @segs, $file );
	make_path( File::Spec->catfile( $cwd, @segs ) ) if @segs;

	my $text = $class->_render_inject_readme_badges_pl($inner);
	open my $out, '>:encoding(UTF-8)', $path
		or croak "Cannot write '$path': $!";
	print {$out} $text;
	close $out;
	chmod 0755, $path or warn "[prepare4release] chmod 0755 '$path': $!\n";
	warn "[prepare4release] wrote $rel (standalone README badge injector)\n"
		if $verbose;
	return;
}

# Makefile fragment: pod2* then inject README shields via generated script (no App::pm dep).
sub _postamble_block {
	my ( $class, $opts ) = @_;
	$opts = {} unless ref $opts eq 'HASH';
	my $tab = "\t";
	my $want_pod2github = $opts->{github} || $opts->{gitlab};
	my $pod_cmd         = $want_pod2github ? 'pod2github' : 'pod2markdown';
	my $inj             = $class->inject_readme_badges_relpath;

	return <<"EOF";
# BEGIN PREPARE4RELEASE_POSTAMBLE
sub MY::postamble {
  return '' if !-e '.git';
  <<'PREPARE4RELEASE_POD2README';
pure_all :: README.md

README.md : \$(VERSION_FROM)
${tab}$pod_cmd \$< \$@
${tab}\$(PERL) $inj
PREPARE4RELEASE_POD2README
}
# END PREPARE4RELEASE_POSTAMBLE
EOF
}

sub makefile_has_pod2github {
	my ( $class, $content ) = @_;
	return $content =~ /pod2github\b/;
}

sub makefile_has_pod2markdown {
	my ( $class, $content ) = @_;
	return $content =~ /pod2markdown\b/;
}

sub _replace_marked_postamble_block {
	my ( $class, $content, $new_block ) = @_;
	return $content
		unless $content =~ /^\# BEGIN PREPARE4RELEASE_POSTAMBLE/m;
	my $out = $content;
	# Line endings: require \r?\n so CRLF files (common on Windows / some editors)
	# still match; a strict \n-only pattern leaves the block unchanged and pod2*
	# never updates.
	# No /x: it would strip spaces in "# BEGIN ..." and treat # as comments. The pattern
	# must be a single line: multiline s{}{} would include literal \n\t from this file.
	$out =~ s/^\# BEGIN PREPARE4RELEASE_POSTAMBLE\s*\r?\n.*?^\# END PREPARE4RELEASE_POSTAMBLE\s*\r?\n?/$new_block/ms;
	return $out;
}

sub _replace_legacy_my_postamble_heredoc {
	my ( $class, $content, $new_block ) = @_;
	my $re = qr/
		^sub \s+ MY::postamble \s* \{
		[\s\S]*?
		<<'(?:POD2README|PREPARE4RELEASE_POD2README)'
		[\s\S]*?
		^(?:POD2README|PREPARE4RELEASE_POD2README)\s*$
		\}
	/mx;
	my $out = $content;
	return $out unless $out =~ $re;
	$out =~ s/$re/$new_block/ms;
	return $out;
}

sub ensure_postamble {
	my ( $class, $content, $opts, $verbose ) = @_;
	$opts = {} unless ref $opts eq 'HASH';
	my $want_pod2github = $opts->{github} || $opts->{gitlab};
	my $new_block       = $class->_postamble_block($opts);

	if ( $content =~ /^\# BEGIN PREPARE4RELEASE_POSTAMBLE/m ) {
		my $updated = $class->_replace_marked_postamble_block( $content, $new_block );
		if ( $updated ne $content ) {
			warn "[prepare4release] Makefile.PL: updated PREPARE4RELEASE postamble (README badges + pod2*)\n"
				if $verbose;
		}
		return $updated;
	}

	my $legacy_try = $class->_replace_legacy_my_postamble_heredoc( $content, $new_block );
	if ( $legacy_try ne $content ) {
		warn "[prepare4release] Makefile.PL: upgraded MY::postamble to README badge hook\n"
			if $verbose;
		return $legacy_try;
	}

	if ( $content =~ /sub\s+MY::postamble\b/ ) {
		warn "[prepare4release] Makefile.PL: MY::postamble exists but required pod2* rule missing; not auto-merging\n"
			if $verbose;
		return $content;
	}

	if ($want_pod2github) {
		if ( $class->makefile_has_pod2github($content) ) {
			warn "[prepare4release] Makefile.PL: pod2github already present, skipping postamble\n"
				if $verbose;
			return $content;
		}
		if ( $class->makefile_has_pod2markdown($content) ) {
			warn "[prepare4release] Makefile.PL: pod2markdown present (not replacing with pod2github); skipping\n"
				if $verbose;
			return $content;
		}
	}
	else {
		if ( $class->makefile_has_pod2markdown($content) ) {
			warn "[prepare4release] Makefile.PL: pod2markdown already present, skipping postamble\n"
				if $verbose;
			return $content;
		}
		if ( $class->makefile_has_pod2github($content) ) {
			warn "[prepare4release] Makefile.PL: pod2github present (not replacing with pod2markdown); skipping\n"
				if $verbose;
			return $content;
		}
	}

	$content =~ s/\s*\z/\n/;
	return $content . "\n" . $new_block;
}

sub write_makefile_close_index {
	my ( $class, $content ) = @_;
	my $start = index( $content, 'WriteMakefile(' );
	return if $start < 0;
	my $open = $start + length('WriteMakefile');
	my $depth = 0;
	my $len = length $content;
	for ( my $i = $open ; $i < $len ; $i++ ) {
		my $c = substr( $content, $i, 1 );
		if ( $c eq '(' ) {
			$depth++;
		}
		elsif ( $c eq ')' ) {
			$depth--;
			if ( $depth == 0 ) {
				return [ $start, $i ];
			}
		}
	}
	return;
}

sub meta_merge_block {
	my ( $class, $repo_git_url, $repo_web, $bugtracker_web ) = @_;
	my $block = <<"META";
	META_MERGE       => {
		'meta-spec' => { version => 2 },
		resources   => {
			repository => {
				type => 'git',
				url  => '$repo_git_url',
				web  => '$repo_web',
			},
			bugtracker => {
				web => '$bugtracker_web',
			},
		},
	},
META
	return $block;
}

sub ensure_meta_merge {
	my ( $class, $content, $repo_git_url, $repo_web, $bugtracker_web, $verbose ) = @_;

	my $has_repo_urls = $content =~ /\Q$repo_git_url\E/s && $content =~ /\Q$repo_web\E/s;
	my $has_bug       = $content =~ /\Q$bugtracker_web\E/s;

	if ( $has_repo_urls && $has_bug ) {
		warn "[prepare4release] Makefile.PL: META_MERGE repository/bugtracker URLs already match, skipping\n"
			if $verbose;
		return $content;
	}

	if ( $content =~ /\bMETA_MERGE\b/ ) {
		$content = $class->_patch_meta_merge_block(
			$content, $repo_git_url, $repo_web, $bugtracker_web, $verbose
		);
		return $content;
	}

	my $meta = $class->meta_merge_block( $repo_git_url, $repo_web, $bugtracker_web );
	my $pair = $class->write_makefile_close_index($content);
	if ( !$pair ) {
		warn "[prepare4release] Makefile.PL: WriteMakefile( not found, cannot insert META_MERGE\n"
			if $verbose;
		return $content;
	}
	my ( $wm_start, $close_idx ) = @{$pair};
	substr( $content, $close_idx, 0 ) = ",\n" . $meta;
	return $content;
}

sub _patch_meta_merge_block {
	my ( $class, $content, $repo_git_url, $repo_web, $bugtracker_web, $verbose ) = @_;
	my $before = $content;

	if ( $content =~ s/(repository\s*=>\s*\{[^}]*?)(\burl\s*=>\s*)'[^']*'/${1}${2}'$repo_git_url'/s ) {
		1;
	}
	elsif ( $content =~ s/(repository\s*=>\s*\{[^}]*?)(\burl\s*=>\s*)"[^"]*"/${1}${2}"$repo_git_url"/s ) {
		1;
	}
	if ( $content =~ s/(repository\s*=>\s*\{[^}]*?)(\bweb\s*=>\s*)'[^']*'/${1}${2}'$repo_web'/s ) {
		1;
	}
	elsif ( $content =~ s/(repository\s*=>\s*\{[^}]*?)(\bweb\s*=>\s*)"[^"]*"/${1}${2}"$repo_web"/s ) {
		1;
	}

	if ( $content =~ /bugtracker\s*=>\s*\{/ ) {
		if ( $content =~ s/(bugtracker\s*=>\s*\{[^}]*?)(\bweb\s*=>\s*)'[^']*'/${1}${2}'$bugtracker_web'/s ) {
			1;
		}
		elsif ( $content =~ s/(bugtracker\s*=>\s*\{[^}]*?)(\bweb\s*=>\s*)"[^"]*"/${1}${2}"$bugtracker_web"/s ) {
			1;
		}
	}
	elsif ( $content =~ /(resources\s*=>\s*\{)/ ) {
		my $resources_head = $1;
		my $inj = <<"BUG";
			bugtracker => {
				web => '$bugtracker_web',
			},
BUG
		$content =~ s/\Q$resources_head\E/$resources_head\n$inj/s;
	}

	if ( $content ne $before ) {
		warn "[prepare4release] Makefile.PL: patched existing META_MERGE\n" if $verbose;
	}
	return $content;
}

sub _escape_makefile_single_quoted {
	my ( $class, $s ) = @_;
	$s =~ s/\\/\\\\/g;
	$s =~ s/'/\\'/g;
	return $s;
}

# Build ( MAKEMAKER_KEY => value ) from prepare4release.json root. Only keys
# present in the JSON are applied (empty strings are skipped).
sub makefile_scalar_keys_from_config {
	my ( $class, $config ) = @_;
	$config = {} unless ref $config eq 'HASH';
	my @out;    # [ key, string value ]

	for my $pair (
		[ author         => 'AUTHOR' ],
		[ abstract       => 'ABSTRACT' ],
		[ abstract_from  => 'ABSTRACT_FROM' ],
		[ license        => 'LICENSE' ],
	  )
	{
		my ( $json_key, $mm_key ) = @{$pair};
		next unless exists $config->{$json_key};
		my $v = $config->{$json_key};
		next unless defined $v && !ref $v && length $v;
		push @out, [ $mm_key, $v ];
	}

	if ( exists $config->{min_perl_version} ) {
		my $v = $config->{min_perl_version};
		if ( defined $v && !ref $v && length $v ) {
			push @out, [ 'MIN_PERL_VERSION', $v ];
		}
	}
	elsif ( exists $config->{perl_min} ) {
		my $v = $config->{perl_min};
		if ( defined $v && !ref $v && length $v ) {
			push @out, [ 'MIN_PERL_VERSION', $v ];
		}
	}

	if ( exists $config->{module_name} ) {
		my $v = $config->{module_name};
		if ( defined $v && !ref $v && length $v ) {
			push @out, [ 'NAME', $v ];
		}
	}
	elsif ( exists $config->{name} ) {
		my $v = $config->{name};
		if ( defined $v && !ref $v && length $v ) {
			push @out, [ 'NAME', $v ];
		}
	}

	if ( exists $config->{version_from} ) {
		my $v = $config->{version_from};
		if ( defined $v && !ref $v && length $v ) {
			push @out, [ 'VERSION_FROM', $v ];
		}
	}

	return @out;
}

sub _replace_write_makefile_scalar {
	my ( $class, $content, $mm_key, $value ) = @_;
	my $ev = $class->_escape_makefile_single_quoted($value);

	if ( $content =~ /\b\Q$mm_key\E\s*=>\s*'/ ) {
		$content =~ s/(\b\Q$mm_key\E\s*=>\s*)'(?:\\.|[^'\\])*'/${1}'$ev'/s;
		return ( $content, 1 );
	}
	if ( $content =~ /\b\Q$mm_key\E\s*=>\s*"/ ) {
		$content =~ s/(\b\Q$mm_key\E\s*=>\s*)"[^"]*"/${1}'$ev'/s;
		return ( $content, 1 );
	}
	my $pair = $class->write_makefile_close_index($content);
	if ($pair) {
		my $close_idx = $pair->[1];
		substr( $content, $close_idx, 0 ) = ",\n\t$mm_key => '$ev'";
		return ( $content, 1 );
	}
	return ( $content, 0 );
}

# EXE_FILES => [ 'bin/foo', ... ] — value is Perl list, not a quoted string.
sub _replace_write_makefile_exe_files {
	my ( $class, $content, $paths ) = @_;
	$paths = [] unless ref $paths eq 'ARRAY';
	my $list = join ', ', map { qq{'$_'} } @{$paths};
	my $expr = "[$list]";

	if ( $content =~ /\bEXE_FILES\s*=>\s*\[/ ) {
		$content =~ s/(\bEXE_FILES\s*=>\s*)\[[^\]]*\]/${1}$expr/s;
		return ( $content, 1 );
	}
	my $pair = $class->write_makefile_close_index($content);
	if ($pair) {
		my $close_idx = $pair->[1];
		substr( $content, $close_idx, 0 ) = ",\n\tEXE_FILES => $expr";
		return ( $content, 1 );
	}
	return ( $content, 0 );
}

sub ensure_makefile_metadata_from_config {
	my ( $class, $makefile_path, $content, $config, $verbose ) = @_;
	$config = {} unless ref $config eq 'HASH';

	my $new = $content;
	my $any = 0;

	for my $pair ( $class->makefile_scalar_keys_from_config($config) ) {
		my ( $mm_key, $val ) = @{$pair};
		my $ch;
		( $new, $ch ) = $class->_replace_write_makefile_scalar( $new, $mm_key, $val );
		$any ||= $ch;
		warn "[prepare4release] Makefile.PL: set $mm_key from prepare4release.json\n"
			if $verbose && $ch;
	}

	if ( exists $config->{exe_files} && ref $config->{exe_files} eq 'ARRAY' ) {
		my $ch;
		( $new, $ch ) = $class->_replace_write_makefile_exe_files( $new, $config->{exe_files} );
		$any ||= $ch;
		warn "[prepare4release] Makefile.PL: set EXE_FILES from prepare4release.json\n"
			if $verbose && $ch;
	}

	return ( $new, $any );
}

sub apply_makefile_patches {
	my ( $class, $makefile_path, $opts, $app, $verbose ) = @_;
	my ( $content, $snippets ) = $class->read_makefile_pl_snippets($makefile_path);

	my $new = $class->ensure_postamble( $content, $opts, $verbose );

	my $repo_git = $app->repository_git_url;
	my $repo_web = $app->repository_web_url;
	my $bug       = $app->bugtracker_url;

	$new = $class->ensure_meta_merge( $new, $repo_git, $repo_web, $bug, $verbose );

	if ( $new ne $content ) {
		open my $out, '>:encoding(UTF-8)', $makefile_path
			or croak "Cannot write Makefile.PL '$makefile_path': $!";
		print {$out} $new;
		close $out;
		warn "[prepare4release] Makefile.PL updated: $makefile_path\n" if $verbose;
	}
	elsif ($verbose) {
		warn "[prepare4release] Makefile.PL unchanged\n";
	}
	return;
}

# --- Perl version range + MetaCPAN -------------------------------------------

sub min_perl_version_from_makefile_content {
	my ( $class, $content ) = @_;
	return unless defined $content;
	if ( $content =~ /MIN_PERL_VERSION\s*=>\s*['"]([^'"]+)['"]/ ) {
		return $1;
	}
	return;
}

sub min_perl_version_from_pm_content {
	my ( $class, $content ) = @_;
	return unless defined $content;
	my @lines = split /\n/, $content;
	for my $line (@lines) {
		next if $line =~ /^\s*#/;
		if ( $line =~ /^\s*use\s+v5\.(\d+)\.(\d+)\s*;/ ) {
			return "v5.$1.$2";
		}
		if ( $line =~ /^\s*use\s+v5\.(\d+)\s*;/ ) {
			return "v5.$1.0";
		}
		if ( $line =~ /^\s*use\s+(5\.\d+)\s*;/ ) {
			my $v = eval { version->parse($1) };
			return $v->normal if $v;
		}
		if ( $line =~ /^\s*use\s+([0-9]+\.[0-9]+)\s*;/ ) {
			my $v = eval { version->parse($1) };
			return $v->normal if $v;
		}
	}
	return;
}

sub _minor_from_version_token {
	my ( $class, $token ) = @_;
	return unless defined $token && length $token;
	$token =~ s/\s+\z//;

	# v-string forms (always unambiguous)
	if ( $token =~ /^v5\.(\d+)\./ ) {
		return 0 + $1;
	}

	# Plain dotted: 5.16, 5.15.0, 5.10.1 — minor is the first component after "5."
	if ( $token =~ /^5\.(\d+)\.(\d+)(?:\.(\d+))?\z/ ) {
		return 0 + $1;
	}
	if ( $token =~ /^5\.(\d+)\z/ ) {
		my $mant = $1;
		# Packed mantissa (e.g. 5.008007): handled by version.pm below
		if ( length($mant) <= 4 && $mant !~ /\A0\d/ ) {
			return 0 + $mant;
		}
	}

	my $v = eval { version->parse($token) };
	return unless $v;
	my $n = $v->normal;
	if ( $n =~ /^v5\.(\d+)\./ ) {
		return 0 + $1;
	}
	# Decimal normals from version.pm (e.g. 5.016000). Use 0+$1 not int($1):
	# int("016") / sprintf "%d", "010" can follow legacy octal rules on older perls.
	if ( $n =~ /^5\.(\d{3})(\d{3})\z/ ) {
		return 0 + $1;
	}
	if ( $n =~ /^5\.(\d{3})/ ) {
		return 0 + $1;
	}
	return;
}

sub resolve_combined_min_perl {
	my ( $class, $makefile_content, $pm_path ) = @_;
	my @candidates;
	if ($makefile_content) {
		my $m = $class->min_perl_version_from_makefile_content($makefile_content);
		push @candidates, $m if defined $m;
	}
	if ( $pm_path && -e $pm_path ) {
		open my $fh, '<:encoding(UTF-8)', $pm_path
			or croak "Cannot open '$pm_path': $!";
		local $/;
		my $pm = <$fh>;
		close $fh;
		my $p = $class->min_perl_version_from_pm_content($pm);
		push @candidates, $p if defined $p;
	}
	return unless @candidates;

	my $max_req;
	for my $c (@candidates) {
		my $v = eval { version->parse($c) };
		next unless $v;
		$max_req = $v if !defined $max_req || $v > $max_req;
	}
	return unless $max_req;
	return $max_req->normal;
}

# Minimum Perl for README badge: prepare4release.json min_perl_version (or perl_min),
# else Makefile.PL MIN_PERL_VERSION, else combined makefile + main module (fallback).
sub resolve_min_perl_for_badge {
	my ( $class, $config, $makefile_content, $pm_path ) = @_;
	$config = {} unless ref $config eq 'HASH';

	my $raw = $config->{min_perl_version};
	$raw = $config->{perl_min}
		if !defined $raw || !length $raw;
	if ( defined $raw && length $raw ) {
		my $v = eval { version->parse($raw) };
		return $v->normal if $v;
	}

	my $mf = $class->min_perl_version_from_makefile_content($makefile_content);
	if ( defined $mf && length $mf ) {
		my $v = eval { version->parse($mf) };
		return $v->normal if $v;
	}

	return $class->resolve_combined_min_perl( $makefile_content, $pm_path );
}

# Turn MetaCPAN C<version> field into a matrix tag C<5.xx> (even minors elsewhere).
sub _metacpan_perl_version_to_ceiling_tag {
	my ( $class, $raw ) = @_;
	return unless defined $raw && length $raw;

	my $v = eval { version->parse($raw) };
	if ( !$v ) {
		( my $copy = $raw ) =~ s/\A\s*v//i;
		$v = eval { version->parse($copy) } if length $copy;
	}
	if ( !$v && $raw =~ /\Av?5\.(\d+)\.(\d+)/i ) {
		return sprintf( '5.%d', $1 );
	}

	return unless $v;

	my $n = $v->normal;
	if ( $n =~ /^v5\.(\d+)\./ ) {
		return sprintf( '5.%d', $1 );
	}
	if ( $n =~ /^v5\.(\d+)\z/ ) {
		return sprintf( '5.%d', $1 );
	}
	return;
}

sub fetch_latest_perl_release_version {
	my ($class) = @_;

	if ( defined $ENV{PREPARE4RELEASE_PERL_MAX} && length $ENV{PREPARE4RELEASE_PERL_MAX} ) {
		return $ENV{PREPARE4RELEASE_PERL_MAX};
	}

	eval { require HTTP::Tiny; 1 }
		or do {
			warn "[prepare4release] HTTP::Tiny not available; set PREPARE4RELEASE_PERL_MAX or install HTTP::Tiny\n";
			return '5.40';
		};

	# Latest release for distribution "perl" (not /release/_search sort=version:desc,
	# which can return ancient tarballs because Elasticsearch sort is not Perl order).
	my $url = 'https://fastapi.metacpan.org/v1/release/perl';
	my $http = HTTP::Tiny->new( timeout => 25 );
	my $res  = $http->get($url);
	if ( !$res->{success} || !$res->{content} ) {
		warn "[prepare4release] MetaCPAN GET /release/perl failed; using fallback 5.40\n";
		return '5.40';
	}

	my $data = eval { JSON::PP->new->decode( $res->{content} ) };
	if ( !$data || ref $data ne 'HASH' ) {
		warn "[prepare4release] MetaCPAN JSON decode failed; using fallback 5.40\n";
		return '5.40';
	}

	my $raw = $data->{version};
	if ( !defined $raw || !length $raw ) {
		warn "[prepare4release] MetaCPAN release has no version; using fallback 5.40\n";
		return '5.40';
	}

	my $tag = $class->_metacpan_perl_version_to_ceiling_tag($raw);
	if ( !defined $tag ) {
		warn "[prepare4release] Unexpected MetaCPAN version '$raw'; using fallback 5.40\n";
		return '5.40';
	}

	# Reject ancient bogus hits (e.g. old broken search API) or bad data.
	if ( $tag =~ /^5\.(\d+)\z/ && $1 < 10 ) {
		warn "[prepare4release] MetaCPAN ceiling '$tag' from '$raw' is below 5.10; using fallback 5.40\n";
		return '5.40';
	}

	return $tag;
}

sub perl_matrix_tags {
	my ( $class, $min_token, $max_token ) = @_;
	my $min_m = $class->_minor_from_version_token($min_token);
	my $max_m = $class->_minor_from_version_token($max_token);
	return () unless defined $min_m && defined $max_m;

	my $start = $min_m;
	$start++ if $start % 2;
	my $end = $max_m;
	$end-- if $end % 2;
	return () if $start > $end;

	my @tags;
	for ( my $m = $start ; $m <= $end ; $m += 2 ) {
		push @tags, sprintf( '5.%d', $m );
	}
	return @tags;
}

sub ci_apt_packages {
	my ( $class, $config ) = @_;
	$config = {} unless ref $config eq 'HASH';
	my $ci = $config->{ci};
	return () unless ref $ci eq 'HASH';
	my $apt = $ci->{apt_packages};
	return () unless ref $apt eq 'ARRAY';
	return grep { defined && length } @{$apt};
}

sub scan_files_for_alien_hints {
	my ( $class, $cwd ) = @_;
	my @texts;
	for my $f (qw(Makefile.PL cpanfile Build.PL)) {
		my $p = File::Spec->catfile( $cwd, $f );
		next unless -e $p;
		open my $fh, '<:encoding(UTF-8)', $p or next;
		local $/;
		push @texts, ( <$fh> // '' );
		close $fh;
	}
	my $blob = join "\n", @texts;
	my %seen;
	while ( $blob =~ /\bAlien::([A-Za-z0-9_:]+)/g ) {
		$seen{$1} = 1;
	}
	return sort keys %seen;
}

sub render_github_ci_yml {
	my ( $class, $perl_versions, $apt_packages ) = @_;
	my @perl = ref $perl_versions eq 'ARRAY' ? @{$perl_versions} : ();
	my @apt  = ref $apt_packages   eq 'ARRAY' ? @{$apt_packages}   : ();

	my $matrix = join ', ', map { qq{'$_'} } @perl;
	my $apt_yaml = '';
	if (@apt) {
		my $list = join ' ', @apt;
		$apt_yaml = <<"APT";

      - name: Install system packages (apt)
        run: sudo apt-get update && sudo apt-get install -y $list
APT
	}

	return <<"YML";
# Generated by App::prepare4release -- matrix from MIN_PERL_VERSION / use v5.x and latest stable from MetaCPAN
name: CI

on:
  push:
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        perl-version: [$matrix]

    steps:
      - uses: actions/checkout\@v4

      - name: Set up Perl
        uses: shogo82148/actions-setup-perl\@v1
        with:
          perl-version: \${{ matrix.perl-version }}
$apt_yaml
      - name: Install dependencies (cpanm)
        run: |
          curl -sL https://cpanmin.us | perl - App::cpanminus
          perl Makefile.PL
          cpanm --notest --installdeps .
          cpanm --notest Test2::Suite~0.000139

      - name: Run tests
        run: prove -lr t
YML
}

sub render_gitlab_ci_yml {
	my ( $class, $perl_versions, $apt_packages ) = @_;
	my @perl = ref $perl_versions eq 'ARRAY' ? @{$perl_versions} : ();
	my @apt  = ref $apt_packages   eq 'ARRAY' ? @{$apt_packages}   : ();

	my $matrix_list = join ', ', map { qq{'$_'} } @perl;

	my $apt_lines = '';
	if (@apt) {
		my $list = join ' ', @apt;
		$apt_lines = "    - apt-get install -y -qq $list\n";
	}

	return <<"YML";
# Generated by App::prepare4release -- matrix from MIN_PERL_VERSION / use v5.x and latest stable from MetaCPAN
stages:
  - test

test:
  stage: test
  parallel:
    matrix:
      - PERL_VERSION: [$matrix_list]
  image: perl:\${PERL_VERSION}
  before_script:
    - apt-get update -qq
$apt_lines    - curl -sL https://cpanmin.us | perl - App::cpanminus
    - perl Makefile.PL
    - cpanm --notest --installdeps .
    - cpanm --notest Test2::Suite~0.000139
  script:
    - prove -lr t
YML
}

sub ensure_github_workflow {
	my ( $class, $root, $yaml, $verbose ) = @_;
	my $dir = File::Spec->catfile( $root, '.github', 'workflows' );
	my $path = File::Spec->catfile( $dir, 'ci.yml' );
	if ( -e $path ) {
		warn "[prepare4release] $path already exists, skipping\n" if $verbose;
		return;
	}
	make_path($dir);
	open my $out, '>:encoding(UTF-8)', $path
		or croak "Cannot write $path: $!";
	print {$out} $yaml;
	close $out;
	warn "[prepare4release] wrote $path\n" if $verbose;
	return;
}

sub ensure_gitlab_ci {
	my ( $class, $root, $yaml, $verbose ) = @_;
	my $path = File::Spec->catfile( $root, '.gitlab-ci.yml' );
	if ( -e $path ) {
		warn "[prepare4release] $path already exists, skipping\n" if $verbose;
		return;
	}
	open my $out, '>:encoding(UTF-8)', $path
		or croak "Cannot write $path: $!";
	print {$out} $yaml;
	close $out;
	warn "[prepare4release] wrote $path\n" if $verbose;
	return;
}

sub apply_ci_files {
	my ( $class, $cwd, $opts, $config, $makefile_content, $identity, $verbose ) = @_;

	my $min = $class->resolve_combined_min_perl( $makefile_content,
		$identity->{version_from_path} );
	if ( !$min ) {
		$min = 'v5.10.0';
		warn "[prepare4release] no MIN_PERL_VERSION/use v5 found; assuming v5.10.0 as matrix floor\n"
			if $verbose;
	}

	my $max = $class->fetch_latest_perl_release_version;
	my @matrix = $class->perl_matrix_tags( $min, $max );
	if ( !@matrix ) {
		warn "[prepare4release] empty Perl matrix; skipping CI file generation\n";
		return;
	}

	if ($verbose) {
		warn "[prepare4release] Perl CI matrix: " . join( ', ', @matrix ) . "\n";
		my @alien = $class->scan_files_for_alien_hints($cwd);
		if (@alien) {
			warn "[prepare4release] Alien::* modules seen in Makefile.PL/cpanfile: "
				. join( ', ', @alien )
				. " -- add ci.apt_packages in prepare4release.json if system libs are needed\n";
		}
	}

	my $apt = [ $class->ci_apt_packages($config) ];

	if ( $opts->{github} ) {
		my $yml = $class->render_github_ci_yml( \@matrix, $apt );
		$class->ensure_github_workflow( $cwd, $yml, $verbose );
	}

	if ( $opts->{gitlab} ) {
		my $yml = $class->render_gitlab_ci_yml( \@matrix, $apt );
		$class->ensure_gitlab_ci( $cwd, $yml, $verbose );
	}

	return;
}

# --- POD badges + xt/author -------------------------------------------------

sub _uri_escape_path {
	my ($s) = @_;
	$s =~ s/([^A-Za-z0-9_.~-])/sprintf( '%%%02X', ord($1) )/eg;
	return $s;
}

sub cpan_dist_name_from_identity {
	my ( $class, $identity ) = @_;
	my $d = $identity->{dist_name};
	return $d if defined $d && length $d;
	my $m = $identity->{module_name};
	croak 'dist_name / module_name required' unless defined $m && length $m;
	( my $copy = $m ) =~ s/::/-/g;
	return $copy;
}

sub repology_metacpan_badge_url {
	my ( $class, $dist ) = @_;
	my $slug = lc $dist;
	$slug =~ s/\s+/-/g;
	my $pkg = 'perl:' . $slug;
	my $enc = _uri_escape_path($pkg);
	return "https://repology.org/badge/version-for-repo/metacpan/$enc.svg";
}

sub license_badge_info {
	my ( $class, $license_key ) = @_;
	$license_key = 'perl' unless defined $license_key && length $license_key;
	my %h = (
		perl    => [ 'Perl%205', 'https://dev.perl.org/licenses/' ],
		perl_5  => [ 'Perl%205', 'https://dev.perl.org/licenses/' ],
		apache_2 =>
			[ 'Apache%202.0', 'https://www.apache.org/licenses/LICENSE-2.0' ],
		artistic_2 =>
			[ 'Artistic%202.0', 'https://opensource.org/licenses/Artistic-2.0' ],
		mit => [ 'MIT', 'https://opensource.org/licenses/MIT' ],
		gpl_3 => [ 'GPL%203', 'https://www.gnu.org/licenses/gpl-3.0.html' ],
		lgpl_3 =>
			[ 'LGPL%203', 'https://www.gnu.org/licenses/lgpl-3.0.html' ],
		bsd => [ 'BSD%203--Clause', 'https://opensource.org/licenses/BSD-3-Clause' ],
	);
	if ( my $p = $h{$license_key} ) {
		return @{$p};
	}
	( 'License', 'https://opensource.org/licenses/' );
}

sub infer_license_key_from_text {
	my ( $class, $t ) = @_;
	return unless defined $t && length $t;
	return 'perl' if $t =~ /The\s+Perl\s+5\s+License/i;
	return 'perl' if $t =~ /same\s+terms\s+as\s+Perl\s+5/i;
	return 'perl' if $t =~ /same\s+terms\s+as\s+Perl\s+itself/i;
	return 'perl' if $t =~ /\bPerl\s+5\s+license\b/i;
	return 'perl' if $t =~ /\bArtistic\s+and\s+GPL\b/i && $t =~ /Perl/i;
	return 'artistic_2' if $t =~ /Artistic\s+License\s*2/i;
	return 'apache_2' if $t =~ /Apache\s+License[^\n]*Version\s+2\.0/i;
	return 'mit' if $t =~ /\bMIT\s+License\b/i;
	return 'gpl_3' if $t =~ /GNU\s+GENERAL\s+PUBLIC\s+LICENSE[^\n]*Version\s+3/i;
	return 'lgpl_3' if $t =~ /GNU\s+LESSER\s+GENERAL\s+PUBLIC\s+LICENSE[^\n]*Version\s+3/i;
	return 'bsd' if $t =~ /BSD\s+3-Clause/i;
	return;
}

sub infer_license_key_from_license_file {
	my ( $class, $path ) = @_;
	open my $fh, '<:encoding(UTF-8)', $path or return;
	local $/;
	my $t = <$fh> // '';
	close $fh;
	return $class->infer_license_key_from_text($t);
}

sub license_file_blob_url {
	my ( $class, $app, $opts, $branch ) = @_;
	my $web = $app->repository_web_url;
	$branch =~ s{/}{%2F}g;
	if ( $opts->{gitlab} ) {
		return "$web/-/blob/$branch/LICENSE";
	}
	return "$web/blob/$branch/LICENSE";
}

# Shield label + link: official license URL, or repo LICENSE blob with --github/--gitlab.
sub license_badge_label_and_href {
	my ( $class, $cwd, $opts, $app, $mf_snippets ) = @_;
	my $cfg = $app->{config} // {};

	my $license_path = File::Spec->catfile( $cwd, 'LICENSE' );
	my $key = $mf_snippets->{license};
	$key = 'perl' unless defined $key && length $key;

	if ( -f $license_path ) {
		my $infer = $class->infer_license_key_from_license_file($license_path);
		$key = $infer if defined $infer;
	}

	my ( $lbl, $official_href ) = $class->license_badge_info($key);

	if ( -f $license_path && ( $opts->{github} || $opts->{gitlab} ) ) {
		my $branch = $class->git_default_branch($cfg);
		my $blob = $class->license_file_blob_url( $app, $opts, $branch );
		return ( $lbl, $blob );
	}

	return ( $lbl, $official_href );
}

sub perl_min_badge_label {
	my ( $class, $min_normal ) = @_;
	return '5.10%2B' unless defined $min_normal && length $min_normal;
	my $v = eval { version->parse($min_normal) };
	return '5.10%2B' unless $v;
	my $n = $v->normal;
	return '5.10%2B' unless $n =~ /^v5\.(\d+)/;
	my $minor = $1;
	return _uri_escape_path("5.$minor+");
}

sub _pod_badge_markdown_line {
	my ( $invocant, $alt, $img_url, $link_url ) = @_;
	return "[![$alt]($img_url)]($link_url)";
}

# GitLab pipeline badge host: git.server, else host from git.repo URL, else gitlab.com
sub gitlab_ci_badge_host {
	my ( $class, $app ) = @_;
	my $cfg = $app->{config} // {};
	my $h = $class->git_server($cfg);
	if ( defined $h && length $h ) {
		return $h;
	}
	my $raw = $class->git_repo_name($cfg);
	if ( defined $raw && $raw =~ m{\Ahttps?://([^/]+)}i ) {
		return $1;
	}
	if ( defined $raw && $raw =~ m{\Agit@([^:]+):} ) {
		return $1;
	}
	return 'gitlab.com';
}

sub gitlab_ci_badge_urls {
	my ( $class, $app ) = @_;
	my $host = $class->gitlab_ci_badge_host($app);
	$host =~ s{\Ahttps?://}{}i;
	$host =~ s{/\z}{};
	my $seg = $app->repository_path_segment;
	my $web  = "https://$host/$seg";
	my $pipe = "$web/badges/main/pipeline.svg";
	my $link = "$web/-/pipelines";
	return ( $pipe, $link );
}

sub build_pod_badge_markdown {
	my ( $class, $cwd, $app, $opts, $cpan, $mf_snippets, $identity, $min_normal )
		= @_;

	my $dist = $class->cpan_dist_name_from_identity($identity);
	my $mod  = $identity->{module_name};
	my $mod_url = $mod;
	$mod_url =~ s/::/\//g;

	my ( $lic_label, $lic_href ) =
		$class->license_badge_label_and_href( $cwd, $opts, $app, $mf_snippets );
	my $perl_lbl = $class->perl_min_badge_label($min_normal);

	my @rows;

	push @rows,
		$class->_pod_badge_markdown_line(
		'License',
		"https://img.shields.io/badge/license-$lic_label-blue.svg",
		$lic_href
		);

	push @rows,
		$class->_pod_badge_markdown_line(
		'Perl',
		"https://img.shields.io/badge/perl-$perl_lbl-blue.svg",
		'https://www.perl.org/'
		);

	if ( $opts->{github} ) {
		my $seg = $app->repository_path_segment;
		my $ci_img =
			"https://github.com/$seg/actions/workflows/ci.yml/badge.svg";
		my $ci_url =
			"https://github.com/$seg/actions/workflows/ci.yml";
		push @rows, $class->_pod_badge_markdown_line( 'CI', $ci_img, $ci_url );
	}
	elsif ( $opts->{gitlab} ) {
		my ( $ci_img, $ci_url ) = $class->gitlab_ci_badge_urls($app);
		push @rows, $class->_pod_badge_markdown_line( 'CI', $ci_img, $ci_url );
	}

	if ($cpan) {
		my $rep_b = $class->repology_metacpan_badge_url($dist);
		my $rep_l = "https://repology.org/project/perl%3A"
			. _uri_escape_path( lc $dist ) . '/versions';
		push @rows,
			$class->_pod_badge_markdown_line(
			'MetaCPAN package', $rep_b, $rep_l );

		my $fury = "https://badge.fury.io/pl/$dist.svg";
		my $meta = "https://metacpan.org/pod/$mod_url";
		push @rows,
			$class->_pod_badge_markdown_line( 'CPAN version', $fury, $meta );

		my $cpants   = "https://cpants.cpanauthors.org/dist/$dist.svg";
		my $cpants_l = "https://cpants.cpanauthors.org/dist/$dist";
		push @rows,
			$class->_pod_badge_markdown_line( 'CPAN testers', $cpants,
			$cpants_l );
	}

	return join "\n", @rows;
}

sub split_pm_code_and_pod {
	my ( $class, $path ) = @_;
	open my $fh, '<:encoding(UTF-8)', $path
		or croak "Cannot open '$path': $!";
	local $/;
	my $all = <$fh> // '';
	close $fh;

	if ( $all =~ /\n__END__\s*\r?\n(.*)\z/s ) {
		my $code = $`;
		return ( $code, $1 );
	}
	return ( $all, '' );
}

sub _find_exe_in_path {
	my ( $class, $name ) = @_;
	for my $dir ( split /:/, $ENV{PATH} ) {
		next unless defined $dir && length $dir;
		my $p = File::Spec->catfile( $dir, $name );
		return $p if -x $p && !-d $p;
	}
	return;
}

sub regenerate_readme_md {
	my ( $class, $cwd, $opts, $identity, $verbose ) = @_;
	my $vf = $identity->{version_from_path};
	return 0 unless $vf && -f $vf;

	my $readme = File::Spec->catfile( $cwd, 'README.md' );
	my $makefile = File::Spec->catfile( $cwd, 'Makefile' );

	if ( -f $makefile ) {
		my $qdir = $cwd;
		$qdir =~ s/'/'\\''/g;
		if ( system("make -C '$qdir' README.md 2>/dev/null") == 0 ) {
			warn "[prepare4release] regenerated README.md via make\n" if $verbose;
			return 1;
		}
	}

	my $tool = ( $opts->{github} || $opts->{gitlab} ) ? 'pod2github' : 'pod2markdown';
	my $exe = $class->_find_exe_in_path($tool);
	if ( !$exe ) {
		warn "[prepare4release] $tool not in PATH; skipping README regeneration\n"
			if $verbose;
		return 0;
	}
	if ( system( $exe, $vf, $readme ) != 0 ) {
		warn "[prepare4release] $tool failed; skipping README regeneration\n"
			if $verbose;
		return 0;
	}
	warn "[prepare4release] regenerated README.md via $tool\n" if $verbose;
	return 1;
}

sub _insert_readme_badges_after_regen {
	my ( $class, $text, $block ) = @_;
	if ( $text =~ /\A\x{FEFF}/ ) {
		$text =~ s/\A\x{FEFF}//;
	}
	my @lines = split /\n/, $text, -1;
	my $i = 0;
	while ( $i < @lines && $lines[$i] =~ /^\s*$/ ) {
		$i++;
	}
	if ( $i >= @lines ) {
		return $block . $text;
	}
	if ( $lines[$i] =~ /^#\s+NAME\s*$/i ) {
		my $prefix = join "\n", @lines[ 0 .. $i - 1 ];
		my $rest   = join "\n", @lines[ $i .. $#lines ];
		my $out = '';
		$out .= $prefix if length $prefix;
		$out .= "\n" if length $prefix;
		$out .= $block;
		$out .= $rest;
		return $out;
	}
	if ( $lines[$i] =~ /^#\s+/ ) {
		while ( $i < @lines && $lines[$i] =~ /^#\s+/ ) {
			$i++;
		}
		while ( $i < @lines && $lines[$i] =~ /^\s*$/ ) {
			$i++;
		}
		my $before = join "\n", @lines[ 0 .. $i - 1 ];
		my $after  = join "\n", @lines[ $i .. $#lines ];
		my $out = $before . "\n\n" . $block;
		$out .= $after if length $after;
		return $out;
	}
	return $block . $text;
}

# Prefix of each shield line we inject (alt text); avoids brittle full-line URL matching.
sub _readme_managed_badge_line_re {
	qr{^\[!\[(?:License|Perl|CI|MetaCPAN package|CPAN version|CPAN testers)\]};
}

sub _strip_readme_badge_markdown_block {
	my ( $class, $text ) = @_;
	$text =~ s{
		\s*<!--\s*PREPARE4RELEASE_BADGES\s*-->\s*
		.*?
		<!--\s*/PREPARE4RELEASE_BADGES\s*-->\s*
	}{}msx;

	my $re = $class->_readme_managed_badge_line_re;
	my @lines = split /\n/, $text, -1;
	my $i = 0;
	while ( $i < @lines ) {
		if ( $lines[$i] =~ $re ) {
			my $start = $i;
			$i++;
			while ( $i < @lines && $lines[$i] =~ $re ) {
				$i++;
			}
			splice @lines, $start, $i - $start;
			$i = $start;
			next;
		}
		$i++;
	}
	return join "\n", @lines;
}

sub apply_readme_badges {
	my ( $class, $cwd, $opts, $app, $mf_content, $mf_snippets, $identity,
		$verbose, $inner_override )
		= @_;

	my $readme = File::Spec->catfile( $cwd, 'README.md' );
	if ( !-f $readme ) {
		warn "[prepare4release] README.md missing; skipping README badges\n"
			if $verbose;
		return;
	}

	my $vf = $identity->{version_from_path};
	if ( !$vf || !-e $vf ) {
		warn "[prepare4release] no VERSION_FROM path; skipping README badges\n"
			if $verbose;
		return;
	}

	my $inner;
	if ( defined $inner_override ) {
		$inner = $inner_override;
	}
	else {
		my $min = $class->resolve_min_perl_for_badge(
			$app->{config} // {}, $mf_content, $vf );
		$min = 'v5.10.0' unless defined $min && length $min;

		$inner = $class->build_pod_badge_markdown(
			$cwd, $app, $opts, $opts->{cpan} ? 1 : 0,
			$mf_snippets, $identity, $min
		);
	}

	open my $fh, '<:encoding(UTF-8)', $readme
		or croak "Cannot open README.md '$readme': $!";
	local $/;
	my $text = <$fh> // '';
	close $fh;

	$text = $class->_strip_readme_badge_markdown_block($text);

	# Trailing "\n\n" = mandatory blank line after the last badge line.
	my $block = $inner . "\n\n";

	my $new_text = $class->_insert_readme_badges_after_regen( $text, $block );
	return if $new_text eq $text;

	open my $out, '>:encoding(UTF-8)', $readme
		or croak "Cannot write README.md '$readme': $!";
	print {$out} $new_text;
	close $out;
	warn "[prepare4release] updated README badges in $readme\n" if $verbose;
	return;
}

sub strip_pod_badges_from_version_from {
	my ( $class, $vf, $verbose ) = @_;
	return unless $vf && -f $vf;

	my ( $code, $pod ) = $class->split_pm_code_and_pod($vf);
	return unless length $pod;
	return unless $pod =~ /PREPARE4RELEASE_BADGES/;

	my $new_pod = $pod;
	$new_pod =~ s{
		(?:^=begin\s+html\s*\R)?
		\s*<!--\s*PREPARE4RELEASE_BADGES\s*-->\s*
		.*?
		<!--\s*/PREPARE4RELEASE_BADGES\s*-->\s*
		(?:\R=end\s+html\s*)?
	}{}msx;

	return if $new_pod eq $pod;

	my $out = $code . "\n__END__\n" . $new_pod;
	open my $out_fh, '>:encoding(UTF-8)', $vf
		or croak "Cannot write '$vf': $!";
	print {$out_fh} $out;
	close $out_fh;
	warn "[prepare4release] removed legacy POD badge block from $vf\n" if $verbose;
	return;
}

sub list_files_for_eol_xt {
	my ( $class, $cwd ) = @_;
	my @out;

	for my $f (qw(Makefile.PL Build.PL cpanfile prepare4release.json)) {
		my $p = File::Spec->catfile( $cwd, $f );
		push @out, $f if -f $p;
	}

	push @out, map { File::Spec->abs2rel( $_, $cwd ) }
		$class->find_lib_pm_files($cwd);

	my $bin = File::Spec->catfile( $cwd, 'bin' );
	if ( -d $bin ) {
		opendir my $dh, $bin or croak "opendir bin: $!";
		while ( my $e = readdir $dh ) {
			next if $e =~ /^\./;
			my $rel = File::Spec->catfile( 'bin', $e );
			push @out, $rel if -f File::Spec->catfile( $cwd, $rel );
		}
		closedir $dh;
	}

	for my $td (qw(t xt)) {
		my $root = File::Spec->catfile( $cwd, $td );
		next unless -d $root;
		File::Find::find(
			{
				no_chdir => 1,
				wanted   => sub {
					return unless -f;
					return unless $File::Find::name =~ /\.(t|pm|pl)\z/;
					push @out, File::Spec->abs2rel( $File::Find::name, $cwd );
				},
			},
			$root
		);
	}

	my %seen;
	@out = grep { !$seen{$_}++ } sort @out;
	return @out;
}

sub ensure_xt_author_tests {
	my ( $class, $cwd, $verbose ) = @_;

	my $xtd = File::Spec->catfile( $cwd, 'xt', 'author' );
	make_path($xtd);

	my $pod_xt = File::Spec->catfile( $xtd, 'pod.t' );
	if ( !-e $pod_xt ) {
		my $body = <<'XT';
#!perl
use strict;
use warnings;
use Test2::V1;
use Test2::Tools::Basic qw(skip_all);

BEGIN {
	eval {
		require Test::Pod;
		Test::Pod->import;
		1;
	} or skip_all 'Test::Pod is required for author tests';
}

all_pod_files_ok();
XT
		$class->_write_if_absent( $pod_xt, $body, $verbose );
	}

	my $pc_xt = File::Spec->catfile( $xtd, 'pod-coverage.t' );
	if ( !-e $pc_xt ) {
		my $body = <<'XT';
#!perl
use strict;
use warnings;
use Test2::V1;
use Test2::Tools::Basic qw(skip_all);

BEGIN {
	eval {
		require Test::Pod::Coverage;
		Test::Pod::Coverage->import;
		1;
	} or skip_all 'Test::Pod::Coverage is required for author tests';
}

all_pod_coverage_ok();
XT
		$class->_write_if_absent( $pc_xt, $body, $verbose );
	}

	my @eol = $class->list_files_for_eol_xt($cwd);
	my $eol_xt = File::Spec->catfile( $xtd, 'eol.t' );
	if ( !-e $eol_xt ) {
		my $list = join "\n", map { '    ' . $_ } @eol;
		my $head = <<'EOL_HEAD';
#!perl
use strict;
use warnings;
use Test2::V1;
use Test2::Tools::Basic qw(skip_all done_testing);

BEGIN {
	eval {
		require Test::EOL;
		Test::EOL->import;
		1;
	} or skip_all 'Test::EOL is required for author tests';
}

my @files = qw(
EOL_HEAD
		my $tail = <<'EOL_TAIL';
);

eol_unix_ok($_) for @files;

done_testing;
EOL_TAIL
		my $body = $head . $list . $tail;
		$class->_write_if_absent( $eol_xt, $body, $verbose );
	}

	return;
}

sub _write_if_absent {
	my ( $class, $path, $body, $verbose ) = @_;
	open my $fh, '>:encoding(UTF-8)', $path
		or croak "Cannot write '$path': $!";
	print {$fh} $body;
	close $fh;
	warn "[prepare4release] wrote $path\n" if $verbose;
	return;
}

sub _collect_t_files {
	my ( $class, $cwd ) = @_;
	my @out;
	for my $root_name (qw(t xt)) {
		my $root = File::Spec->catfile( $cwd, $root_name );
		next unless -d $root;
		File::Find::find(
			{
				no_chdir => 1,
				wanted   => sub {
					return unless -f && /\.t\z/;
					push @out, File::Spec->abs2rel( $File::Find::name, $cwd );
				},
			},
			$root
		);
	}
	my %seen;
	@out = grep { !$seen{$_}++ } sort @out;
	return @out;
}

sub file_uses_legacy_assertion_framework {
	my ( $class, $path ) = @_;
	open my $fh, '<:encoding(UTF-8)', $path
		or return 0;
	while ( my $line = <$fh> ) {
		next if $line =~ /^\s*#/;
		next if $line =~ /^\s*=/;
		return 1 if $line =~ /^\s*use\s+Test::More\b/;
		return 1 if $line =~ /^\s*use\s+Test::Most\b/;
	}
	close $fh;
	return 0;
}

sub warn_legacy_test_frameworks {
	my ( $class, $cwd ) = @_;
	my %legacy_ok = map { $_ => 1 } qw(
		xt/author/cpants.t
		xt/author/pause-permissions.t
		xt/author/pod-coverage.t
		xt/author/version.t
	);
	my @bad;
	for my $rel ( $class->_collect_t_files($cwd) ) {
		my $abs = File::Spec->catfile( $cwd, $rel );
		next unless -f $abs;
		next if $legacy_ok{$rel};
		next unless $class->file_uses_legacy_assertion_framework($abs);
		push @bad, $rel;
	}
	return unless @bad;

	warn "[prepare4release] These test files appear to use a legacy assertion "
		. "framework (Test::More or Test::More-style Test::Most) instead of "
		. "Test2::*. Consider migrating to Test2::V1 or Test2::Tools::Spec. "
		. "Files: "
		. join( ', ', @bad )
		. "\n";
	return;
}

# --- Config load -------------------------------------------------------------

sub load_config_file {
	my ( $class, $path ) = @_;
	open my $fh, '<:encoding(UTF-8)', $path
		or croak "Cannot open '$path': $!";
	local $/;
	my $raw = <$fh>;
	close $fh;
	$raw = '' unless defined $raw;
	$raw =~ s/\A\s+|\s+\z//g;
	if ( $raw eq '' ) {
		return {};
	}
	my $json = JSON::PP->new->relaxed;
	my $data = eval { $json->decode($raw) };
	if ( $@ || !defined $data ) {
		my $err = $@ || 'decode returned undef';
		$err =~ s/\s+\z//;
		warn "[prepare4release] prepare4release.json: invalid JSON ($err); "
			. "treating as empty {}\n";
		return {};
	}
	if ( ref $data ne 'HASH' ) {
		warn "[prepare4release] prepare4release.json: top level must be a JSON object; "
			. "treating as empty {}\n";
		return {};
	}
	return $data;
}

sub resolve_config_path {
	my ( $class, $explicit ) = @_;
	return $explicit if defined $explicit && length $explicit;
	my $cwd = getcwd();
	return File::Spec->catfile( $cwd, $class->DEFAULT_CONFIG_FILENAME );
}

sub parse_argv {
	my ( $class, $argv ) = @_;
	$argv = [@ARGV] unless defined $argv;

	require Getopt::Long;
	Getopt::Long::Configure(qw(bundling no_ignore_case));

	my %opts;
	my $pod = $class->_pod_input_file;
	Getopt::Long::GetOptionsFromArray(
		$argv,
		'github'   => \$opts{github},
		'gitlab'   => \$opts{gitlab},
		'cpan'     => \$opts{cpan},
		'sync-deps!' => \$opts{sync_deps},
		'help|?'   => \$opts{help},
		'usage'    => \$opts{usage},
		'verbose'  => \$opts{verbose},
	) or pod2usage( -verbose => 0, -exitval => 2, -input => $pod );

	if ( $opts{help} ) {
		pod2usage( -verbose => 2, -input => $pod );
	}
	if ( $opts{usage} ) {
		pod2usage( -verbose => 0, -input => $pod );
	}

	if ( $opts{github} && $opts{gitlab} ) {
		croak 'Use only one of --github or --gitlab';
	}

	return \%opts;
}

sub _pod_input_file {
	require FindBin;
	return File::Spec->rel2abs( $FindBin::Script, $FindBin::RealBin );
}

# --- CPAN release prep (with --cpan) -----------------------------------------

# EU::MakeMaker / CPAN::Meta license keys -> normalized internal key.
sub _normalize_license_key_from_makefile {
	my ( $class, $raw ) = @_;
	$raw = '' unless defined $raw;
	$raw =~ s/\A\s+|\s+\z//g;
	return 'perl' if $raw eq '';

	( my $k = $raw ) =~ s/\A['"]|['"]\z//g;
	$k = lc $k;
	$k =~ s/\s+/_/g;

	my %alias = (
		'perl'        => 'perl',
		'perl_5'      => 'perl',
		'open_source' => 'perl',
		'artistic'    => 'perl',
		'apache'      => 'apache_2',
		'apache2'     => 'apache_2',
		'gpl'         => 'gpl_3',
		'lgpl'        => 'lgpl_3',
	);
	return $alias{$k} if exists $alias{$k};

	return $k
		if $k =~ /^(perl|apache_2|artistic_2|mit|gpl_3|lgpl_3|bsd)\z/;

	return 'perl';
}

# Official texts: perl = Artistic + COPYING from the perl5 tree (same as Perl itself).
sub _license_official_urls {
	my ( $class, $key ) = @_;
	if ( $key eq 'perl' ) {
		return (
			'https://raw.githubusercontent.com/Perl/perl5/master/Artistic',
			'https://raw.githubusercontent.com/Perl/perl5/master/Copying',
		);
	}
	my %single = (
		apache_2 => 'https://www.apache.org/licenses/LICENSE-2.0.txt',
		artistic_2 =>
			'https://www.opensource.org/licenses/Artistic-2.0',
		mit => 'https://www.opensource.org/licenses/MIT',
		gpl_3 => 'https://www.gnu.org/licenses/gpl-3.0.txt',
		lgpl_3 => 'https://www.gnu.org/licenses/lgpl-3.0.txt',
		bsd => 'https://www.opensource.org/licenses/BSD-3-Clause',
	);
	return ( $single{$key} ) if exists $single{$key};
	return;
}

sub _fetch_license_text_from_official_sources {
	my ( $class, $key, $verbose ) = @_;

	my @urls = $class->_license_official_urls($key);
	return unless @urls;

	require HTTP::Tiny;
	my $http = HTTP::Tiny->new( timeout => 30 );
	my @chunks;
	for my $url (@urls) {
		my $res = $http->get($url);
		if ( !$res->{success} || !$res->{content} ) {
			warn "[prepare4release] LICENSE fetch failed ($url): status="
				. ( $res->{status} // '?' ) . "\n"
				if $verbose;
			next;
		}
		my $body = $res->{content};
		next unless length $body > 50;
		push @chunks, $body;
	}
	return unless @chunks;

	my $text = join "\n\n" . ( '=' x 20 ) . "\n\n", @chunks;
	warn "[prepare4release] LICENSE fetched from official source(s) for key=$key\n"
		if $verbose;
	return $text;
}

sub _license_fallback_text {
	my ( $class, $key ) = @_;
	if ( $key eq 'perl' ) {
		return <<'LICENSE';
This software is free software; you can redistribute it and/or modify it
under the same terms as the Perl 5 programming language system itself.

The full text of the licenses (Artistic License and GNU General Public License)
is available at https://dev.perl.org/licenses/ and in the Perl source
distribution.
LICENSE
	}
	if ( $key eq 'mit' ) {
		return <<'LICENSE';
MIT License (text unavailable offline). See https://opensource.org/licenses/MIT
LICENSE
	}
	if ( $key eq 'apache_2' ) {
		return <<'LICENSE';
Apache License, Version 2.0 (text unavailable offline). See
https://www.apache.org/licenses/LICENSE-2.0
LICENSE
	}
	if ( $key eq 'artistic_2' ) {
		return <<'LICENSE';
Artistic License 2.0 (text unavailable offline). See
https://opensource.org/licenses/Artistic-2.0
LICENSE
	}
	if ( $key eq 'gpl_3' ) {
		return <<'LICENSE';
GNU General Public License version 3 (text unavailable offline). See
https://www.gnu.org/licenses/gpl-3.0.html
LICENSE
	}
	if ( $key eq 'lgpl_3' ) {
		return <<'LICENSE';
GNU Lesser General Public License version 3 (text unavailable offline). See
https://www.gnu.org/licenses/lgpl-3.0.html
LICENSE
	}
	if ( $key eq 'bsd' ) {
		return <<'LICENSE';
BSD 3-Clause License (text unavailable offline). See
https://opensource.org/licenses/BSD-3-Clause
LICENSE
	}
	return $class->_license_fallback_text('perl');
}

sub ensure_license_file {
	my ( $class, $cwd, $mf_snippets, $verbose ) = @_;
	my $lic = File::Spec->catfile( $cwd, 'LICENSE' );
	if ( -f $lic && -s $lic ) {
		warn "[prepare4release] LICENSE already present, skipping\n" if $verbose;
		return;
	}

	$mf_snippets = {} unless ref $mf_snippets eq 'HASH';
	my $raw_key = $mf_snippets->{license};
	my $key     = $class->_normalize_license_key_from_makefile($raw_key);
	warn "[prepare4release] LICENSE: Makefile.PL LICENSE="
		. ( defined $raw_key ? "'$raw_key'" : '(undef)' )
		. " -> normalized='$key'\n"
		if $verbose;

	my $text = $class->_fetch_license_text_from_official_sources( $key, $verbose );
	if ( !$text ) {
		$text = $class->_license_fallback_text($key);
		warn "[prepare4release] LICENSE: using built-in fallback for key=$key\n"
			if $verbose;
	}

	open my $fh, '>:encoding(UTF-8)', $lic
		or croak "Cannot write LICENSE '$lic': $!";
	print {$fh} $text;
	close $fh;
	return;
}

sub ensure_readme_stub_for_cpan {
	my ( $class, $cwd, $verbose ) = @_;
	my $readme = File::Spec->catfile( $cwd, 'README' );
	my $md     = File::Spec->catfile( $cwd, 'README.md' );
	if ( -f $readme ) {
		warn "[prepare4release] README already present, skipping stub\n" if $verbose;
		return;
	}
	if ( !-f $md ) {
		warn "[prepare4release] no README.md; not creating README stub\n"
			if $verbose;
		return;
	}

	my $body = <<'TXT';
This distribution documents itself in README.md (Markdown). Open README.md for
installation, usage, and configuration.
TXT
	open my $fh, '>:encoding(UTF-8)', $readme
		or croak "Cannot write README '$readme': $!";
	print {$fh} $body;
	close $fh;
	warn "[prepare4release] wrote README stub pointing to README.md\n" if $verbose;
	return;
}

sub default_manifest_skip_template {
	return <<'SKIP';
# Version control
\.git/
\.gitignore

# ExtUtils::MakeMaker / Module::Build
^Makefile$
^Makefile\.old$
^Makefile\.bak$
^MYMETA\.
^pm_to_blib$
^blib/
^_build/
^Build$
^MANIFEST\.bak$

# Coverage / local tooling
^cover_db/
^local/
^\.carton/
^\.prove$

# Profiling / debugging (Devel::NYTProf, etc.)
^nytprof/
nytprof\.out
^nytprof.*
^callgrind\.out
^cachegrind\.out
^\.perl-proverc$

# Release tarballs / make distdir (must not ship inside the next tarball)
\.tar\.gz$
\.zip$
^App-prepare4release-

# Editor / OS
^\.vscode/
^\.idea/
\.DS_Store$

# Author-only config in this dist (template lives in repo; not shipped)
^prepare4release\.json$
SKIP
}

sub ensure_manifest_skip_file {
	my ( $class, $cwd, $verbose ) = @_;
	my $path = File::Spec->catfile( $cwd, 'MANIFEST.SKIP' );
	if ( -f $path ) {
		warn "[prepare4release] MANIFEST.SKIP already exists, skipping template\n"
			if $verbose;
		return;
	}
	open my $fh, '>:encoding(UTF-8)', $path
		or croak "Cannot write MANIFEST.SKIP '$path': $!";
	print {$fh} $class->default_manifest_skip_template;
	close $fh;
	warn "[prepare4release] wrote default MANIFEST.SKIP\n" if $verbose;
	return;
}

sub apply_cpan_release_prep {
	my ( $class, $cwd, $mf_snippets, $verbose ) = @_;

	$class->ensure_license_file( $cwd, $mf_snippets, $verbose );
	$class->ensure_readme_stub_for_cpan( $cwd, $verbose );
	$class->ensure_manifest_skip_file( $cwd, $verbose );

	my $make = $ENV{MAKE} || 'make';

	my $rc = system( 'perl', 'Makefile.PL' );
	if ( $rc != 0 ) {
		croak 'perl Makefile.PL failed (exit ' . ( $rc >> 8 ) . ')';
	}
	warn "[prepare4release] perl Makefile.PL ok\n" if $verbose;

	# ExtUtils::MakeMaker writes MYMETA.*; many tools (e.g. Test::Kwalitee) expect
	# META.yml / META.json alongside Makefile.PL in the source tree.
	for my $pair ( [qw( MYMETA.yml META.yml )], [qw( MYMETA.json META.json )] ) {
		my ( $from, $to ) = @{$pair};
		my $fp = File::Spec->catfile( $cwd, $from );
		my $tp = File::Spec->catfile( $cwd, $to );
		next unless -f $fp;
		copy( $fp, $tp ) or croak "copy $from -> $to: $!";
		warn "[prepare4release] copied $from -> $to\n" if $verbose;
	}

	$rc = system( $make, 'manifest' );
	if ( $rc != 0 ) {
		croak 'make manifest failed (exit ' . ( $rc >> 8 ) . ')';
	}
	warn "[prepare4release] make manifest ok\n" if $verbose;

	return;
}

sub run {
	my ( $class, @argv ) = @_;
	my $opts = $class->parse_argv( \@argv );

	my $config_path = $class->resolve_config_path;
	-e $config_path
		or croak "Expected config file in current directory: $config_path";

	my $config = $class->load_config_file($config_path);
	my $cwd    = getcwd();

	my $mf = $class->makefile_pl_path;
	croak 'Makefile.PL not found in current directory' unless $mf;

	my ( $mf_content, $mf_snippets ) = $class->read_makefile_pl_snippets($mf);

	my ( $mf_meta, $meta_changed ) = $class->ensure_makefile_metadata_from_config(
		$mf, $mf_content, $config, $opts->{verbose} );
	if ($meta_changed) {
		open my $mout, '>:encoding(UTF-8)', $mf
			or croak "Cannot write Makefile.PL '$mf': $!";
		print {$mout} $mf_meta;
		close $mout;
		$mf_content = $mf_meta;
		( $mf_content, $mf_snippets ) = $class->read_makefile_pl_snippets($mf);
	}

	my $identity = $class->resolve_identity( $cwd, $config, $mf_snippets );

	my $app = $class->new(
		config_path => $config_path,
		config      => $config,
		opts        => $opts,
		identity    => $identity,
	);

	croak 'Could not resolve module_name (set module_name in prepare4release.json, or fix Makefile.PL VERSION_FROM / lib/)'
		unless $identity->{module_name};

	if ( $opts->{github} || $opts->{gitlab} ) {
		my ($full) = $class->_git_path_segment_or_short_repo($config);
		if ( !defined $full || !length $full ) {
			croak 'git.author is required in prepare4release.json under "git" when using --github or --gitlab '
				. '(unless git.repo is namespace/project or a repository URL)'
				unless $class->git_author($config);
		}
	}

	$class->warn_legacy_test_frameworks($cwd);

	if ( $opts->{verbose} ) {
		require Data::Dumper;
		local $Data::Dumper::Sortkeys = 1;
		warn "[prepare4release] config path: $config_path\n";
		warn "[prepare4release] options: "
			. Data::Dumper::Dumper($opts);
		warn "[prepare4release] config: "
			. Data::Dumper::Dumper($config);
		warn "[prepare4release] identity: "
			. Data::Dumper::Dumper($identity);
		warn "[prepare4release] git host: "
			. $class->effective_git_host( $opts, $config ) . "\n";
		warn "[prepare4release] repository web: " . $app->repository_web_url . "\n";
		warn "[prepare4release] repository git: " . $app->repository_git_url . "\n";
		warn "[prepare4release] bugtracker: " . $app->bugtracker_url . "\n";
	}

	require App::prepare4release::Deps;
	my $mf_deps_changed;
	( $mf_content, $mf_deps_changed ) = App::prepare4release::Deps->apply(
		$cwd, $mf, $mf_content, $identity, $config, $opts );
	if ($mf_deps_changed) {
		( $mf_content, $mf_snippets ) = $class->read_makefile_pl_snippets($mf);
	}

	$class->apply_makefile_patches( $mf, $opts, $app, $opts->{verbose} );

	if ( $opts->{github} || $opts->{gitlab} ) {
		$class->apply_ci_files(
			$cwd, $opts, $config, $mf_content, $identity,
			$opts->{verbose}
		);
	}

	my $min = $class->resolve_min_perl_for_badge(
		$app->{config} // {}, $mf_content, $identity->{version_from_path} );
	$min = 'v5.10.0' unless defined $min && length $min;

	my $readme_badge_inner = $class->build_pod_badge_markdown(
		$cwd, $app, $opts, $opts->{cpan} ? 1 : 0,
		$mf_snippets, $identity, $min
	);

	$class->write_inject_readme_badges_script(
		$cwd, $readme_badge_inner, $opts->{verbose} );

	$class->regenerate_readme_md( $cwd, $opts, $identity, $opts->{verbose} );

	$class->apply_readme_badges(
		$cwd, $opts, $app, $mf_content, $mf_snippets, $identity,
		$opts->{verbose}, $readme_badge_inner
	);

	$class->strip_pod_badges_from_version_from(
		$identity->{version_from_path}, $opts->{verbose} );

	$class->ensure_xt_author_tests( $cwd, $opts->{verbose} );

	if ( $opts->{cpan} ) {
		$class->apply_cpan_release_prep( $cwd, $mf_snippets, $opts->{verbose} );
	}

	return 0;
}

1;

__END__
=encoding UTF-8

=head1 NAME

App::prepare4release - prepare a Perl distribution for release

=head1 SYNOPSIS

  use App::prepare4release;
  App::prepare4release->run(@ARGV);

=head1 DESCRIPTION

Run from the distribution root (where F<prepare4release.json> and F<Makefile.PL>
live). The tool:

=over 4

=item *

Loads F<prepare4release.json> and resolves C<module_name> / C<version> / C<dist_name>
when omitted (from F<Makefile.PL> and the main F<.pm>). Invalid JSON logs a warning
and behaves like an empty object. Root keys such as C<author>, C<abstract>,
C<license>, C<min_perl_version>, C<module_name>, C<version_from>, and C<exe_files>
are copied into F<Makefile.PL> C<WriteMakefile(...)> when set (see L</CONFIGURATION FILE>).

=item *

Patches F<Makefile.PL>: C<META_MERGE> (C<repository> and C<bugtracker> URLs), and
a marked C<MY::postamble> block (between C<# BEGIN PREPARE4RELEASE_POSTAMBLE> and
C<# END PREPARE4RELEASE_POSTAMBLE>) that runs C<pod2github> when C<--github> or
C<--gitlab> was used (else C<pod2markdown>), then F<maint/inject-readme-badges.pl>
(a standalone Perl script regenerated each run, core modules only) so C<make README.md>
reapplies the same shields without depending on C<App::prepare4release>. The block
is refreshed on each run to match the current C<pod2*> choice; the script embeds the
frozen badge Markdown for the chosen C<--github> / C<--gitlab> / C<--cpan> flags.

=item *

When C<--github> or C<--gitlab> is set, ensures CI workflow files exist (see
L</Continuous integration>).

=item *

Regenerates F<README.md> from the F<VERSION_FROM> module (C<make README.md> when
F<Makefile> exists, otherwise C<pod2github> or C<pod2markdown>), then injects
Markdown shield lines (C<[![Alt](image)](link)>) into F<README.md> after the first
title block (runs of C<#> headings) or before C<# NAME> when that is the first
heading. The F<Makefile.PL> postamble runs F<maint/inject-readme-badges.pl> after
C<pod2github>/C<pod2markdown> so badges stay in sync without a runtime dependency
on this distribution. Strips any
legacy badge block from POD after C<__END__>. License and minimum Perl badges
are always added; with C<--cpan>, also Repology, CPAN version, and cpants. The
GitHub Actions CI badge is added only with C<--github>; the GitLab pipeline badge
only with C<--gitlab> (host from C<git.server>, else from C<git.repo> URL, else
C<gitlab.com>). License shield (always blue) uses the same key as ExtUtils::MakeMaker
(F<Makefile.PL> C<LICENSE>), or the type inferred from a root F<LICENSE> file when
present; the link is the repository F<LICENSE> blob when that file exists and
C<--github> or C<--gitlab> is set (branch from C<git.default_branch>, default
C<main>), otherwise the usual canonical license URL. Minimum Perl on the shield
comes from C<min_perl_version> / C<perl_min> in the JSON file, else
F<Makefile.PL> C<MIN_PERL_VERSION>, else the stricter of makefile and main module
(as for CI).

=item *

Creates author tests under F<xt/author/> when missing: C<pod.t> (L<Test::Pod>),
C<eol.t> (L<Test::EOL>), C<pod-coverage.t> (L<Test::Pod::Coverage>), using
L<Test2::V1>.

=item *

With C<--cpan>, after the steps above: ensures F<LICENSE> exists. The license
I<type> is taken from F<Makefile.PL> C<LICENSE> (via the same snippet scan as
elsewhere in this tool); if that is missing, I<perl> (same terms as Perl 5) is
assumed. The file text is downloaded from official upstream sources (for
C<perl>, the F<Artistic> and F<Copying> files from the Perl 5 repository; for
C<apache_2>, C<mit>, C<gpl_3>, etc., the canonical license URLs). If a fetch
fails, a short built-in fallback is written. If F<README> is missing but
F<README.md> exists, writes a short stub F<README> pointing readers to
F<README.md>. Creates a default F<MANIFEST.SKIP> when none is present (skipping
F<blib/>, F<cover_db/>, F<nytprof/>, tarballs, F<.git/>, etc.); runs
C<perl Makefile.PL>, copies F<MYMETA.*> to F<META.*>, and C<make manifest> so
F<MANIFEST> matches the tree for CPAN packaging.

=item *

Warns when any F<t/*.t> or F<xt/**/*.t> file starts with C<use Test::More> or
C<use Test::Most> (legacy assertion frameworks). Prefer L<Test2::V1> or
L<Test2::Tools::Spec>.

=item *

Scans F<lib/>, F<bin/>, F<maint/>, F<t/>, and optionally F<xt/> for C<use> /
C<require> and compares with C<PREREQ_PM> / C<TEST_REQUIRES> in F<Makefile.PL>.
Core modules for the target minimum Perl are skipped unless a minimum module
version is given on the C<use> line (see L<Module::CoreList>). By default only a
warning is printed; C<--sync-deps> or C<dependencies.sync> in
F<prepare4release.json> updates F<Makefile.PL> and appends to F<cpanfile> when
present. C<dependencies.skip> disables the check.

=back

=head1 README badge injector (F<maint/inject-readme-badges.pl>)

The C<MY::postamble> fragment cannot hold large, self-contained Perl I<sub>s:
C<ExtUtils::MakeMaker> expects that section to expand into Makefile rules, and
keeping badge logic only in F<Makefile.PL> would either duplicate a lot of text
or imply loading this distribution at C<make README.md> time. Instead,
C<prepare4release> writes F<maint/inject-readme-badges.pl>, a small, generated
program (core modules only) that strips prior shield lines and inserts the
frozen Markdown block computed on the last run (same flags as C<--github> /
C<--gitlab> / C<--cpan>). Downstream distributions should I<commit> that file
with the rest of the tree so C<make README.md> works in a clean clone and the
file is included in the CPAN tarball like any other tracked asset. Re-run
C<prepare4release> after changing repository URLs, license, or badge-related
options so the script and F<README.md> stay consistent. No runtime dependency on
C<App::prepare4release> is added to the target module.

=head1 CONFIGURATION FILE

File name: F<prepare4release.json> (in the distribution root).

An empty file or whitespace-only file is treated as an empty JSON object C<{}>.
Invalid JSON logs a warning and is treated as C<{}>.

=over 4

=item C<author>

Optional. Copied into F<Makefile.PL> C<AUTHOR> (distinct from C<git.author>).

=item C<abstract>

Optional. Copied into F<Makefile.PL> C<ABSTRACT>.

=item C<abstract_from>

Optional. Copied into F<Makefile.PL> C<ABSTRACT_FROM>.

=item C<license>

Optional. Copied into F<Makefile.PL> C<LICENSE>.

=item C<exe_files>

Optional. JSON array of paths; copied into F<Makefile.PL> C<EXE_FILES>.

=item C<module_name>

Optional. Perl package (e.g. C<My::Module>). If omitted, taken from the
C<VERSION_FROM> module's C<package> line, from C<NAME> in F<Makefile.PL>, or from
the first C<lib/**/*.pm> file. If set, also written to F<Makefile.PL> C<NAME>.

=item C<name>

Optional. Alternative to C<module_name> for F<Makefile.PL> C<NAME> when
C<module_name> is absent.

=item C<version_from>

Optional. Path written to F<Makefile.PL> C<VERSION_FROM> when set.

=item C<version>

Optional. If omitted, taken from C<$VERSION> in the resolved main module file.

=item C<dist_name>

Optional. Defaults to C<module_name> with C<::> replaced by hyphens.

=item C<min_perl_version>

Optional. Minimum Perl version string for the README C<Perl> badge (e.g. C<5.026>
or C<v5.26.0>). If set, also copied into F<Makefile.PL> C<MIN_PERL_VERSION>. If
omitted for the badge, C<MIN_PERL_VERSION> from F<Makefile.PL> is used, then the
combined makefile/module heuristic.

=item C<perl_min>

Optional alias for C<min_perl_version> (Makefile and badge).

=item C<bugtracker>

Optional bugtracker URL. If omitted, it is built as
C<< <repository web>/issues >> for the selected git host.

=item C<git>

Object (optional) with:

=over 8

=item C<author>

Required for C<--github> or C<--gitlab> unless C<git.repo> is a namespace path
(C<group/project>) or a repository URL. Otherwise required to build repository
URLs when C<git.repo> is only a short name or omitted.

=item C<repo>

Repository name, C<namespace/project> path, or C<https://...> / C<git@...>
URL. If omitted, defaults to C<perl-> plus C<module_name> with C<::> replaced
by hyphens.

=item C<server>

Optional hostname (e.g. C<gitlab.example.com>) for C<https://> links instead of
C<github.com> / C<gitlab.com>.

=item C<default_branch>

Optional branch name for F<LICENSE> blob links in the README badge (default
C<main>).

=back

=item C<ci>

Optional object:

=over 8

=item C<apt_packages>

Array of Debian package names (e.g. C<libssl-dev>) appended to the generated
GitHub Actions and GitLab CI C<apt-get install> steps. System libraries are not
inferrable reliably from CPAN metadata alone; list them here when XS or
C<Alien::*> needs OS packages.

=back

=item C<dependencies>

Optional object for L<App::prepare4release::Deps>:

=over 8

=item C<sync>

If true, merge missing prerequisites into F<Makefile.PL> / F<cpanfile> (same as
C<--sync-deps>).

=item C<skip>

If true, skip scanning.

=item C<scan_xt>

If true, include F<xt/**/*.t> in test prerequisites (default false).

=item C<sync_cpanfile>

If false, do not modify F<cpanfile> when C<sync> is true (default true).

=back

=back

=head1 Continuous integration

When C<--github> is set, if F<.github/workflows/ci.yml> does not exist it is
created. It runs C<prove -lr t> on an Ubuntu runner using
L<https://github.com/shogo82148/actions-setup-perl|shogo82148/actions-setup-perl>, with a
matrix of stable Perl releases from the stricter of F<Makefile.PL>
C<MIN_PERL_VERSION> and the main module's C<use v5...> / C<use 5...> line, up
to the latest stable Perl.

The ceiling is resolved at each run via the MetaCPAN FastAPI
C<GET /v1/release/perl> (latest C<perl> distribution release). The previous
C<release/_search sort=version:desc> query could return ancient tarballs because
Elasticsearch sort is not Perl version order. If the request fails, a fallback
(currently C<5.40>) is used. Override for tests or air-gapped use:

  PREPARE4RELEASE_PERL_MAX=5.40 prepare4release ...

Matrix entries use even minor versions only (C<5.10>, C<5.12>, …) between the
computed minimum and maximum.

When C<--gitlab> is set, if F<.gitlab-ci.yml> is missing it is created with a
C<parallel.matrix> over C<PERL_VERSION> and the official C<perl> Docker image.

Existing workflow files are never overwritten.

=head1 System dependencies (apt)

There is no robust automatic mapping from CPAN modules to Debian packages. The
tool scans F<Makefile.PL>, F<cpanfile>, and F<Build.PL> for C<Alien::...> names
and, with C<--verbose>, warns so you can add C<ci.apt_packages> manually.

=head1 ENVIRONMENT

=over 4

=item C<PREPARE4RELEASE_PERL_MAX>

If set, used as the matrix ceiling instead of querying MetaCPAN (useful for CI
of this tool or offline work).

=item C<RELEASE_TESTING>

If set to a true value, author tests under F<xt/> may run (see
F<xt/metacpan-live.t> for a live MetaCPAN request that validates
C<fetch_latest_perl_release_version>).

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) by the authors.

Same terms as Perl 5 itself.

=cut
