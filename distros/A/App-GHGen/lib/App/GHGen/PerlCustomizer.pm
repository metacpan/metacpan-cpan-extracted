package App::GHGen::PerlCustomizer;

use v5.36;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
	detect_perl_requirements
	generate_custom_perl_workflow
);

our $VERSION = '0.01';

=head1 NAME

App::GHGen::PerlCustomizer - Customize Perl workflows based on project requirements

=head1 SYNOPSIS

    use App::GHGen::PerlCustomizer qw(detect_perl_requirements);
    
    my $requirements = detect_perl_requirements();
    # Returns: { min_version => '5.036', has_cpanfile => 1, ... }

=head1 FUNCTIONS

=head2 detect_perl_requirements()

Detect Perl version requirements from cpanfile, Makefile.PL, or dist.ini.

=cut

sub detect_perl_requirements() {
    my %reqs = (
        min_version => undef,
        has_cpanfile => 0,
        has_makefile_pl => 0,
        has_dist_ini => 0,
        has_build_pl => 0,
    );
    
    # Check for dependency files
    use Path::Tiny;
    $reqs{has_cpanfile} = path('cpanfile')->exists;
    $reqs{has_makefile_pl} = path('Makefile.PL')->exists;
    $reqs{has_dist_ini} = path('dist.ini')->exists;
    $reqs{has_build_pl} = path('Build.PL')->exists;
    
    # Try to detect minimum Perl version
    if ($reqs{has_cpanfile}) {
        my $content = path('cpanfile')->slurp_utf8;
        if ($content =~ /requires\s+['"]perl['"],?\s+['"]([0-9.]+)['"]/) {
            $reqs{min_version} = $1;
        }
    }
    
    if (!$reqs{min_version} && $reqs{has_makefile_pl}) {
        my $content = path('Makefile.PL')->slurp_utf8;
        if ($content =~ /MIN_PERL_VERSION\s*=>\s*['"]([0-9.]+)['"]/) {
            $reqs{min_version} = $1;
        }
    }
    
    return \%reqs;
}

=head2 generate_custom_perl_workflow($options)

Generate a customized Perl workflow based on options hash.

Options:
  - perl_versions: Array ref of explicit Perl versions (e.g., ['5.40', '5.38'])
  - min_perl_version: Minimum Perl version (e.g., '5.036')
  - max_perl_version: Maximum Perl version to test (e.g., '5.40')
  - os: Array ref of operating systems ['ubuntu', 'macos', 'windows']
  - enable_critic: Boolean
  - enable_coverage: Boolean

If perl_versions is provided, it takes precedence over min/max versions.

=cut

sub generate_custom_perl_workflow($opts = {}) {
    my $min_version = $opts->{min_perl_version} // '5.36';
    my $max_version = $opts->{max_perl_version} // '5.40';
    my @os = @{$opts->{os} // ['ubuntu-latest', 'macos-latest', 'windows-latest']};
    my $enable_critic = $opts->{enable_critic} // 1;
    my $enable_coverage = $opts->{enable_coverage} // 1;
    
    # Generate Perl version list - use explicit list if provided, otherwise min/max
    my @perl_versions;
    if ($opts->{perl_versions} && @{$opts->{perl_versions}}) {
        @perl_versions = @{$opts->{perl_versions}};
    } else {
        @perl_versions = _get_perl_versions($min_version, $max_version);
    }
    
    my $yaml = "---\n";
    $yaml .= "name: Perl CI\n\n";
    $yaml .= "'on':\n";
    $yaml .= "  push:\n";
    $yaml .= "    branches:\n";
    $yaml .= "      - main\n";
    $yaml .= "      - master\n";
    $yaml .= "  pull_request:\n";
    $yaml .= "    branches:\n";
    $yaml .= "      - main\n";
    $yaml .= "      - master\n\n";
    
    $yaml .= "concurrency:\n";
    $yaml .= "  group: \${{ github.workflow }}-\${{ github.ref }}\n";
    $yaml .= "  cancel-in-progress: true\n\n";
    
    $yaml .= "permissions:\n";
    $yaml .= "  contents: read\n\n";
    
    $yaml .= "jobs:\n";
    $yaml .= "  test:\n";
    $yaml .= "    runs-on: \${{ matrix.os }}\n";
    $yaml .= "    strategy:\n";
    $yaml .= "      fail-fast: false\n";
    $yaml .= "      matrix:\n";
    $yaml .= "        os:\n";
    for my $os (@os) {
        $yaml .= "          - $os\n";
    }
    $yaml .= "        perl:\n";
    for my $version (@perl_versions) {
        $yaml .= "          - '$version'\n";
    }
    $yaml .= "    name: Perl \${{ matrix.perl }} on \${{ matrix.os }}\n";
    $yaml .= "    env:\n";
    $yaml .= "      AUTOMATED_TESTING: 1\n";
    $yaml .= "      NO_NETWORK_TESTING: 1\n";
    $yaml .= "      NONINTERACTIVE_TESTING: 1\n";
    $yaml .= "    steps:\n";
    $yaml .= "      - uses: actions/checkout\@v6\n\n";
    
    $yaml .= "      - name: Setup Perl\n";
    $yaml .= "        uses: shogo82148/actions-setup-perl\@v1\n";
    $yaml .= "        with:\n";
    $yaml .= "          perl-version: \${{ matrix.perl }}\n\n";
    
    $yaml .= "      - name: Cache CPAN modules\n";
    $yaml .= "        uses: actions/cache\@v5\n";
    $yaml .= "        with:\n";
    $yaml .= "          path: ~/perl5\n";
    $yaml .= "          key: \${{ runner.os }}-\${{ matrix.perl }}-\${{ hashFiles('cpanfile') }}\n";
    $yaml .= "          restore-keys: |\n";
    $yaml .= "            \${{ runner.os }}-\${{ matrix.perl }}-\n\n";
    
    $yaml .= "      - name: Install cpanm and local::lib\n";
    $yaml .= "        if: runner.os != 'Windows'\n";
    $yaml .= "        run: cpanm --notest --local-lib=~/perl5 local::lib\n\n";
    
    $yaml .= "      - name: Install cpanm and local::lib (Windows)\n";
    $yaml .= "        if: runner.os == 'Windows'\n";
    $yaml .= "        run: cpanm --notest App::cpanminus local::lib\n\n";
    
    $yaml .= "      - name: Install dependencies\n";
    $yaml .= "        if: runner.os != 'Windows'\n";
    $yaml .= "        shell: bash\n";
    $yaml .= "        run: |\n";
    $yaml .= "          eval \$(perl -I ~/perl5/lib/perl5 -Mlocal::lib)\n";
    $yaml .= "          cpanm --notest --installdeps .\n\n";
    
    $yaml .= "      - name: Install dependencies (Windows)\n";
    $yaml .= "        if: runner.os == 'Windows'\n";
    $yaml .= "        shell: cmd\n";
    $yaml .= "        run: |\n";
    $yaml .= "          \@echo off\n";
    $yaml .= "          set \"PATH=%USERPROFILE%\\perl5\\bin;%PATH%\"\n";
    $yaml .= "          set \"PERL5LIB=%USERPROFILE%\\perl5\\lib\\perl5\"\n";
    $yaml .= "          cpanm --notest --installdeps .\n\n";
    
    $yaml .= "      - name: Run tests\n";
    $yaml .= "        if: runner.os != 'Windows'\n";
    $yaml .= "        shell: bash\n";
    $yaml .= "        run: |\n";
    $yaml .= "          eval \$(perl -I ~/perl5/lib/perl5 -Mlocal::lib)\n";
    $yaml .= "          prove -lr t/\n\n";
    
    $yaml .= "      - name: Run tests (Windows)\n";
    $yaml .= "        if: runner.os == 'Windows'\n";
    $yaml .= "        shell: cmd\n";
    $yaml .= "        run: |\n";
    $yaml .= "          \@echo off\n";
    $yaml .= "          set \"PATH=%USERPROFILE%\\perl5\\bin;%PATH%\"\n";
    $yaml .= "          set \"PERL5LIB=%USERPROFILE%\\perl5\\lib\\perl5\"\n";
    $yaml .= "          prove -lr t/\n\n";
    
    if ($enable_critic) {
        my $latest = $perl_versions[-1];
        $yaml .= "      - name: Run Perl::Critic\n";
        $yaml .= "        if: matrix.perl == '$latest' && matrix.os == 'ubuntu-latest'\n";
        $yaml .= "        continue-on-error: true\n";
        $yaml .= "        run: |\n";
        $yaml .= "          eval \$(perl -I ~/perl5/lib/perl5 -Mlocal::lib)\n";
        $yaml .= "          cpanm --notest Perl::Critic\n";
        $yaml .= "          perlcritic --severity 3 lib/ || true\n";
        $yaml .= "        shell: bash\n\n";
    }
    
    if ($enable_coverage) {
        my $latest = $perl_versions[-1];
        $yaml .= "      - name: Test coverage\n";
        $yaml .= "        if: matrix.perl == '$latest' && matrix.os == 'ubuntu-latest'\n";
        $yaml .= "        run: |\n";
        $yaml .= "          eval \$(perl -I ~/perl5/lib/perl5 -Mlocal::lib)\n";
        $yaml .= "          cpanm --notest Devel::Cover\n";
        $yaml .= "          cover -delete\n";
        $yaml .= "          HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t/\n";
        $yaml .= "          cover\n";
        $yaml .= "        shell: bash\n";
    }
    
    return $yaml;
}

sub _get_perl_versions($min, $max) {
    # All available Perl versions in descending order
    my @all_versions = qw(5.40 5.38 5.36 5.34 5.32 5.30 5.28 5.26 5.24 5.22);
    
    # Normalize version strings for comparison
    my $min_normalized = _normalize_version($min);
    my $max_normalized = _normalize_version($max);
    
    my @selected;
    for my $version (@all_versions) {
        my $v_normalized = _normalize_version($version);
        if ($v_normalized >= $min_normalized && $v_normalized <= $max_normalized) {
            push @selected, $version;
        }
    }
    
    return reverse @selected;  # Return in ascending order
}

sub _normalize_version($version) {
	# Convert "5.036" or "5.36" to comparable number
	$version =~ s/^v?//;
	my @parts = split /\./, $version;
	return sprintf("%d.%03d", $parts[0] // 5, $parts[1] // 0);
}

=head1 AUTHOR

Nigel Horne E<lt>njh@nigelhorne.comE<gt>

L<https://github.com/nigelhorne>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
