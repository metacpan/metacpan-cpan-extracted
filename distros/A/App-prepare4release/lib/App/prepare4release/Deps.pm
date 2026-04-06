package App::prepare4release::Deps;

our $VERSION = '0.03';

use 5.010;
use strict;
use warnings;
use utf8;

use Carp qw(croak);
use File::Find ();
use File::Spec ();

# Optional: used to skip core modules without an explicit minimum version.
sub _have_corelist {
	state $ok = eval { require Module::CoreList; 1 };
	return $ok;
}

sub _perl_numeric_for_corelist {
	my ( $class, $mf_content, $config, $version_from_path ) = @_;
	$config = {} unless ref $config eq 'HASH';

	my $raw = $config->{min_perl_version} // $config->{perl_min};
	if ( defined $raw && length $raw ) {
		return $class->_perl_num_from_any($raw);
	}
	if ( ref $mf_content eq 'SCALAR' || defined $mf_content ) {
		my $s = ref $mf_content eq 'SCALAR' ? $$mf_content : $mf_content;
		if ( $s =~ /MIN_PERL_VERSION\s*=>\s*['"]([^'"]+)['"]/ ) {
			return $class->_perl_num_from_any($1);
		}
	}
	if ( defined $version_from_path && -e $version_from_path ) {
		open my $fh, '<:encoding(UTF-8)', $version_from_path or return '5.010000';
		while ( my $line = <$fh> ) {
			if ( $line =~ /^\s*use\s+v([0-9.]+)\s*;/ ) {
				close $fh;
				return $class->_perl_num_from_any( 'v' . $1 );
			}
			if ( $line =~ /^\s*use\s+([0-9][0-9_\.]+)\s*;/ ) {
				close $fh;
				return $class->_perl_num_from_any($1);
			}
		}
		close $fh;
	}
	return '5.010000';
}

sub _perl_num_from_any {
	my ( $class, $v ) = @_;
	return '5.010000' unless defined $v && length $v;
	require version;
	my $ver = eval { version->parse($v) };
	return '5.010000' unless $ver;
	return $ver->numify;
}

sub _skip_use_module {
	my ( $class, $m ) = @_;
	return 1 unless defined $m && length $m;
	return 1 if $m =~ /^v?5\.\d+/;
	return 1 if $m eq 'perl';
	my %pragma = map { $_ => 1 } qw(
		strict warnings utf8 feature experimental subs mro overload
		vars integer English autodie lib constant deprecate
		open sigtrap sort attrs bytes charnames locale
		namespaces tie filetest indirect
	);
	return 1 if $pragma{$m};
	return 0;
}

sub _strip_pod {
	my ( $class, $text ) = @_;
	$text =~ s{^=[a-z][a-z]*\b.*?^=cut\b}{}gms;
	return $text;
}

sub _scan_line_for_modules {
	my ( $class, $line, $out ) = @_;
	$out = [] unless ref $out eq 'ARRAY';

	# use v5.xx / use 5.xx
	return if $line =~ /^\s*use\s+v?[0-9]/;

	if ( $line =~ /^\s*use\s+parent\s+(.+)/ ) {
		my $rest = $1;
		if ( $rest =~ /qw\s*\(\s*([^)]*)\s*\)/ ) {
			my $inner = $1;
			for my $w ( split /\s+/, $inner ) {
				next unless $w =~ /^[\w:]+$/;
				push @{$out}, [ $w, undef ];
			}
		}
		elsif ( $rest =~ /['"]([\w:]+)['"]/ ) {
			push @{$out}, [ $1, undef ];
		}
		return;
	}

	if ( $line =~ /^\s*use\s+base\s+(.+)/ ) {
		my $rest = $1;
		if ( $rest =~ /qw\s*\(\s*([^)]*)\s*\)/ ) {
			for my $w ( split /\s+/, $1 ) {
				next unless $w =~ /^[\w:]+$/;
				push @{$out}, [ $w, undef ];
			}
		}
		elsif ( $rest =~ /['"]([\w:]+)['"]/ ) {
			push @{$out}, [ $1, undef ];
		}
		return;
	}

	if ( $line =~ /^\s*use\s+([\w:]+)\s+([\d._v]+)\s*;/ ) {
		my ( $m, $v ) = ( $1, $2 );
		return if $class->_skip_use_module($m);
		push @{$out}, [ $m, $v ];
		return;
	}

	if ( $line =~ /^\s*use\s+([\w:]+)\s+qw\s*\(/ ) {
		my $m = $1;
		return if $class->_skip_use_module($m);
		push @{$out}, [ $m, undef ];
		return;
	}

	if ( $line =~ /^\s*use\s+([\w:]+)\s*;/ ) {
		my $m = $1;
		return if $class->_skip_use_module($m);
		push @{$out}, [ $m, undef ];
		return;
	}

	if ( $line =~ /^\s*require\s+([\w:]+)\s*;/ ) {
		push @{$out}, [ $1, undef ];
		return;
	}

	return;
}

sub _scan_file_text {
	my ( $class, $text ) = @_;
	$text = $class->_strip_pod($text);
	my @hits;
	for my $line ( split /\n/, $text ) {
		next if $line =~ /^\s*#/;
		$class->_scan_line_for_modules( $line, \@hits );
	}
	return @hits;
}

sub _module_in_dist {
	my ( $class, $mod, $main ) = @_;
	return 0 unless defined $main && length $main;
	return 1 if $mod eq $main;
	return $mod =~ /^\Q$main\E::/;
}

sub _filter_core {
	my ( $class, $perl_num, $module, $want_ver ) = @_;
	return 0 unless _have_corelist();
	require Module::CoreList;
	return 0 unless Module::CoreList->can('is_core');
	my $is_core = eval { Module::CoreList::is_core( $module, undef, $perl_num ) };
	return 0 unless $is_core;
	return 1 if !defined $want_ver || $want_ver eq '';
	return 0;
}

sub _merge_ver {
	my ( $a, $b ) = @_;
	return $b unless defined $a && length $a;
	return $a unless defined $b && length $b;
	require version;
	my $va = eval { version->parse($a) };
	my $vb = eval { version->parse($b) };
	return $b unless $va && $vb;
	return $va >= $vb ? "$a" : "$b";
}

sub scan_distribution {
	my ( $class, $cwd, $identity, $scan_xt, $perl_num ) = @_;
	my $main = $identity->{module_name} // '';

	my @paths_runtime;
	my @paths_test;

	my $lib = File::Spec->catfile( $cwd, 'lib' );
	if ( -d $lib ) {
		File::Find::find(
			{
				no_chdir => 1,
				wanted   => sub {
					return unless -f && /\.pm\z/;
					push @paths_runtime, $File::Find::name;
				},
			},
			$lib
		);
	}

	for my $x (qw(bin maint)) {
		my $d = File::Spec->catfile( $cwd, $x );
		next unless -d $d;
		File::Find::find(
			{
				no_chdir => 1,
				wanted   => sub {
					return unless -f;
					return unless $x eq 'bin' || /\.pl\z/;
					push @paths_runtime, $File::Find::name;
				},
			},
			$d
		);
	}

	my $tr = File::Spec->catfile( $cwd, 't' );
	if ( -d $tr ) {
		File::Find::find(
			{
				no_chdir => 1,
				wanted   => sub {
					return unless -f && /\.t\z/;
					push @paths_test, $File::Find::name;
				},
			},
			$tr
		);
	}

	if ($scan_xt) {
		my $xr = File::Spec->catfile( $cwd, 'xt' );
		if ( -d $xr ) {
			File::Find::find(
				{
					no_chdir => 1,
					wanted   => sub {
						return unless -f && /\.t\z/;
						push @paths_test, $File::Find::name;
					},
				},
				$xr
			);
		}
	}

	my %runtime;
	my %test;

	for my $p (@paths_runtime) {
		open my $fh, '<:encoding(UTF-8)', $p or next;
		local $/;
		my $t = <$fh> // '';
		close $fh;
		for my $pair ( $class->_scan_file_text($t) ) {
			my ( $m, $v ) = @{$pair};
			next if $class->_module_in_dist( $m, $main );
			next if $class->_filter_core( $perl_num, $m, $v );
			my $cur = $runtime{$m};
			$runtime{$m} = defined $cur ? $class->_merge_ver( $cur, $v ) : ( $v // '0' );
		}
	}

	for my $p (@paths_test) {
		open my $fh, '<:encoding(UTF-8)', $p or next;
		local $/;
		my $t = <$fh> // '';
		close $fh;
		for my $pair ( $class->_scan_file_text($t) ) {
			my ( $m, $v ) = @{$pair};
			next if $class->_module_in_dist( $m, $main );
			next if $class->_filter_core( $perl_num, $m, $v );
			my $cur = $test{$m};
			$test{$m} = defined $cur ? $class->_merge_ver( $cur, $v ) : ( $v // '0' );
		}
	}

	# Runtime deps win for modules present in both (test file also uses JSON::PP).
	for my $m ( keys %runtime ) {
		delete $test{$m};
	}

	return ( \%runtime, \%test );
}

# Same algorithm as App::prepare4release::write_makefile_close_index (no circular load).
sub _write_makefile_close_index {
	my ( $class, $content ) = @_;
	my $start = index( $content, 'WriteMakefile(' );
	return if $start < 0;
	my $open = $start + length('WriteMakefile');
	my $depth  = 0;
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

sub _find_balanced_brace {
	my ( $class, $content, $open_brace_idx ) = @_;
	my $len = length $content;
	my $depth = 1;
	for ( my $i = $open_brace_idx + 1 ; $i < $len ; $i++ ) {
		my $c = substr( $content, $i, 1 );
		$depth++ if $c eq '{';
		$depth-- if $c eq '}';
		return $i if $depth == 0;
	}
	return;
}

sub _parse_makefile_hash_block {
	my ( $class, $inner ) = @_;
	my %h;
	while ( $inner =~ /^\s*['"]([^'"]+)['"]\s*=>\s*([^,\n]+)\s*,?/gm ) {
		my ( $k, $v ) = ( $1, $2 );
		$v =~ s/\A\s+|\s+\z//g;
		$v =~ s/\A['"]|['"]\z//g;
		$h{$k} = $v;
	}
	return \%h;
}

sub extract_makefile_hash {
	my ( $class, $content, $key ) = @_;
	return {} unless $content =~ /\b\Q$key\E\s*=>\s*\{/;
	my $ob = $+[0] - 1;
	my $cb = $class->_find_balanced_brace( $content, $ob );
	return {} unless defined $cb;
	my $inner = substr( $content, $ob + 1, $cb - $ob - 1 );
	return $class->_parse_makefile_hash_block($inner);
}

sub _format_hash_lines {
	my ( $class, $href, $indent ) = @_;
	$indent //= "\t";
	my @keys = sort keys %{$href};
	my @lines;
	for my $k (@keys) {
		my $v = $href->{$k};
		my $vs = $v =~ /^-?\d+(?:\.\d+)?\z/ ? $v : "'$v'";
		push @lines, "${indent}'$k' => $vs,";
	}
	return join "\n", @lines;
}

sub replace_makefile_hash {
	my ( $class, $content, $key, $href ) = @_;
	my $formatted = $class->_format_hash_lines($href);
	if ( $content =~ /\b\Q$key\E\s*=>\s*\{/ ) {
		my $start = $-[0];
		my $ob    = $+[0] - 1;
		my $cb    = $class->_find_balanced_brace( $content, $ob );
		croak "replace_makefile_hash: unbalanced $key" unless defined $cb;
		my $before = substr( $content, 0, $start );
		my $after  = substr( $content, $cb + 1 );
		my $tab    = "\t";
		my $block  = "\t$key => {\n$tab$formatted\n\t},";
		return $before . $block . $after;
	}

	# Insert before closing paren of WriteMakefile( ... )
	if ( $content !~ /\bWriteMakefile\s*\(/ ) {
		croak 'replace_makefile_hash: WriteMakefile( not found';
	}
	my $pair = $class->_write_makefile_close_index($content);
	croak 'replace_makefile_hash: could not find WriteMakefile closing )'
		unless $pair;
	my ( $wm_start, $close_idx ) = @{$pair};
	my $insert = <<"NEW";
\t$key => {
$formatted
\t},
NEW
	substr( $content, $close_idx, 0 ) = ",\n$insert";
	return $content;
}

sub merge_missing {
	my ( $class, $existing, $scanned ) = @_;
	$existing = {} unless ref $existing eq 'HASH';
	$scanned  = {} unless ref $scanned  eq 'HASH';
	my @add;
	for my $m ( sort keys %{$scanned} ) {
		next if exists $existing->{$m};
		push @add, $m;
		$existing->{$m} = $scanned->{$m};
	}
	return ( $existing, \@add );
}

sub _sync_cpanfile_lines {
	my ( $class, $path, $runtime, $test, $do_write ) = @_;
	open my $fh, '<:encoding(UTF-8)', $path or croak "Cannot read cpanfile: $!";
	local $/;
	my $text = <$fh> // '';
	close $fh;

	my %req;
	my %treq;
	while ( $text =~ /^\s*requires\s+['"]([^'"]+)['"]\s*,\s*([^;\n]+)\s*;/gm ) {
		$req{$1} = $2;
	}
	while ( $text =~ /^\s*test_requires\s+['"]([^'"]+)['"]\s*,\s*([^;\n]+)\s*;/gm ) {
		$treq{$1} = $2;
	}

	my @missing_r;
	my @missing_t;
	for my $m ( sort keys %{$runtime} ) {
		next if exists $req{$m};
		push @missing_r, $m;
		$req{$m} = $runtime->{$m} =~ /^-?\d+(?:\.\d+)?\z/ ? $runtime->{$m} : "'$runtime->{$m}'";
	}
	for my $m ( sort keys %{$test} ) {
		next if exists $treq{$m};
		push @missing_t, $m;
		$treq{$m} = $test->{$m} =~ /^-?\d+(?:\.\d+)?\z/ ? $test->{$m} : "'$test->{$m}'";
	}

	if ( !@missing_r && !@missing_t ) {
		return ( 0, $text );
	}

	if ( !$do_write ) {
		return ( 0, $text );
	}

	my $append = '';
	$append .= "\n" if $text =~ /\S/ && $text !~ /\n\z/;
	for my $m ( sort @missing_r ) {
		my $v = $req{$m};
		$append .= "requires '$m', $v;\n";
	}
	for my $m ( sort @missing_t ) {
		my $v = $treq{$m};
		$append .= "test_requires '$m', $v;\n";
	}

	my $new = $text . $append;
	open my $out, '>:encoding(UTF-8)', $path or croak "Cannot write cpanfile: $!";
	print {$out} $new;
	close $out;
	return ( 1, $new );
}

sub apply {
	my ( $class, $cwd, $makefile_path, $mf_content, $identity, $config, $opts ) = @_;
	$config = {} unless ref $config eq 'HASH';
	my $dep_cfg = $config->{dependencies};
	$dep_cfg = {} unless ref $dep_cfg eq 'HASH';

	return ( $mf_content, 0 ) if $dep_cfg->{skip};

	my $scan_xt = $dep_cfg->{scan_xt};
	$scan_xt = 0 unless defined $scan_xt;

	my $sync = $opts->{sync_deps};
	$sync = $dep_cfg->{sync} if !defined $sync;
	$sync = 0 unless defined $sync;

	my $sync_cpan = $dep_cfg->{sync_cpanfile};
	$sync_cpan = 1 unless defined $sync_cpan;

	my $perl_num = $class->_perl_numeric_for_corelist(
		$mf_content, $config, $identity->{version_from_path} );

	my ( $runtime, $test ) = $class->scan_distribution(
		$cwd, $identity, $scan_xt, $perl_num );

	my $pr = $class->extract_makefile_hash( $mf_content, 'PREREQ_PM' );
	my $tr = $class->extract_makefile_hash( $mf_content, 'TEST_REQUIRES' );

	my ( $pr_merged, $pr_add ) = $class->merge_missing( {%$pr}, $runtime );
	my ( $tr_merged, $tr_add ) = $class->merge_missing( {%$tr}, $test );

	my @all = ( @{$pr_add}, @{$tr_add} );
	if ( !@all ) {
		return ( $mf_content, 0 );
	}

	my $verbose = $opts->{verbose};

	if ( !$sync ) {
		warn "[prepare4release] dependencies: "
			. scalar(@all)
			. " module(s) used in sources but missing from Makefile.PL: "
			. join( ', ', @all )
			. " (use --sync-deps or set \"dependencies\": { \"sync\": true } in prepare4release.json)\n";
		return ( $mf_content, 0 );
	}

	my $new = $mf_content;
	if ( @{$pr_add} ) {
		$new = $class->replace_makefile_hash( $new, 'PREREQ_PM', $pr_merged );
	}
	if ( @{$tr_add} ) {
		$new = $class->replace_makefile_hash( $new, 'TEST_REQUIRES', $tr_merged );
	}

	open my $out, '>:encoding(UTF-8)', $makefile_path
		or croak "Cannot write Makefile.PL: $!";
	print {$out} $new;
	close $out;

	warn "[prepare4release] Makefile.PL: added PREREQ_PM: "
		. join( ', ', @{$pr_add} ) . "\n"
		if $verbose && @{$pr_add};
	warn "[prepare4release] Makefile.PL: added TEST_REQUIRES: "
		. join( ', ', @{$tr_add} ) . "\n"
		if $verbose && @{$tr_add};

	my $cf = File::Spec->catfile( $cwd, 'cpanfile' );
	if ( -f $cf && $sync_cpan ) {
		my ( $changed, undef ) = $class->_sync_cpanfile_lines(
			$cf, $runtime, $test, 1 );
		warn "[prepare4release] cpanfile: appended missing requires/test_requires\n"
			if $verbose && $changed;
	}

	return ( $new, 1 );
}

1;

__END__

=head1 NAME

App::prepare4release::Deps - scan F<lib/>, F<bin/>, F<maint/>, F<t/> for C<use> and sync F<Makefile.PL> / F<cpanfile>

=head1 DESCRIPTION

This is a helper for L<App::prepare4release>. It performs a conservative static
scan (not a full Perl parser). Core modules are omitted when they ship with the
target Perl (see L<Module::CoreList>) unless a minimum version appears on the
C<use> line. Subpackages of the main distribution module are ignored.

=cut
