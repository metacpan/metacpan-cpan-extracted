package App::GHGen::Detector;

use v5.36;
use strict;
use warnings;

use Path::Tiny;

use Exporter 'import';
our @EXPORT_OK = qw(
	detect_project_type
	get_project_indicators
);

our $VERSION = '0.06';

=head1 NAME

App::GHGen::Detector - Detect project type from repository contents

=head1 SYNOPSIS

	use App::GHGen::Detector qw(detect_project_type);

	my $type = detect_project_type();
	# Returns: 'perl', 'node', 'python', etc.

=head1 FUNCTIONS

=head2 detect_project_type()

Detect the project type by examining indicator files in the current directory.

=head3 Purpose

Score the current working directory against ten known project types
(perl, node, python, rust, go, ruby, php, java, cpp, docker) and return
the highest-scoring type.

=head3 Arguments

None.

=head3 Returns

In scalar context: the type string (e.g. C<'perl'>) of the best match, or
C<undef> when no type scores above zero.

In list context: a list of C<{ type => Str, score => Int, indicators => [] }>
hash references sorted by descending score.

=head3 Side Effects

Reads the filesystem; results depend on the current working directory.

=head3 Usage Example

    use App::GHGen::Detector qw(detect_project_type);
    my $type = detect_project_type();
    say $type // 'unknown';

=head3 API SPECIFICATION

=head4 Input

    # No parameters.

=head4 Output (scalar context)

    { type => 'scalar' }   # may be undef

=head4 Output (list context)

    { type => 'array', element => { type => 'hashref' } }

=head3 FORMAL SPECIFICATION

    detect_project_type : → ℤ* ∪ { ⊥ } | seq Detection

    Detection ≔ { type: ProjectType, score: ℕ, indicators: seq ℤ* }
    detections ≔ [ { type: t, score: score(t) } ∣ t ∈ Types, score(t) > 0 ]
    ranked     ≔ sort desc-score detections

    scalar context: ranked = ∅ → ⊥  |  ranked ≠ ∅ → ranked[0].type
    list context:   ranked

=cut

sub detect_project_type() {
	my @detections;

	# Check for each project type
	for my $type (qw(perl node python rust go ruby php java cpp docker)) {
		my $detector = "_detect_$type";
		my $score = __PACKAGE__->can($detector)->();
		push @detections, { type => $type, score => $score, indicators => [] } if $score > 0;
	}

	# Sort by score (highest first)
	@detections = sort { $b->{score} <=> $a->{score} } @detections;

	return undef unless @detections;
	return wantarray ? @detections : $detections[0]->{type};
}

=head2 get_project_indicators($type)

Return the indicator file patterns associated with a given project type.

=head3 Purpose

Provide a human-readable or programmatic list of the files and patterns that
the detector uses to score each project type.

=head3 Arguments

=over 4

=item C<$type> (Str, optional)

A project type string such as C<'perl'>, C<'node'>, C<'python'>, etc.
When omitted or C<undef>, the full indicator table is returned.

=back

=head3 Returns

When C<$type> is given and known: an array reference of strings (file names /
glob patterns).

When C<$type> is C<undef> or omitted: a hash reference mapping every known
type to its indicator list.

When C<$type> is given but unknown: C<undef>.

=head3 Side Effects

None.  Pure lookup function.

=head3 Usage Example

    my $indicators = get_project_indicators('perl');
    say for @$indicators;

    my $all = get_project_indicators();
    for my $type (sort keys %$all) {
        say "$type: " . join(', ', @{$all->{$type}});
    }

=head3 API SPECIFICATION

=head4 Input

    { type => { type => 'scalar', optional => 1 } }

=head4 Output

    known type  → { type => 'arrayref' }
    all types   → { type => 'hashref'  }
    unknown type → undef

=head3 FORMAL SPECIFICATION

    get_project_indicators : ℤ* ∪ { ⊥ } → seq ℤ* ∪ (ℤ* → seq ℤ*) ∪ { ⊥ }

    t given ∧ t ∈ KnownTypes → indicators[t]      (ArrayRef)
    t given ∧ t ∉ KnownTypes → ⊥                  (undef)
    t absent                  → indicators          (HashRef of all types)

=cut

sub get_project_indicators($type = undef) {
	my %indicators = (
		perl => [
			'cpanfile', 'dist.ini', 'Makefile.PL', 'Build.PL',
			'lib/*.pm', 't/*.t', 'META.json', 'META.yml'
		],
		node => [
			'package.json', 'package-lock.json', 'yarn.lock',
			'node_modules/', 'tsconfig.json', '.npmrc'
		],
		python => [
			'requirements.txt', 'setup.py', 'pyproject.toml',
			'Pipfile', 'poetry.lock', 'setup.cfg', 'tox.ini'
		],
		rust => [
			'Cargo.toml', 'Cargo.lock', 'src/main.rs',
			'src/lib.rs', 'rust-toolchain.toml'
		],
		go => [
			'go.mod', 'go.sum', 'main.go', '*.go'
		],
		ruby => [
			'Gemfile', 'Gemfile.lock', 'Rakefile',
			'.ruby-version', 'config.ru'
		],
		php => [
			'composer.json', 'composer.lock', 'phpunit.xml',
			'phpunit.xml.dist', 'src/', 'tests/'
		],
		java => [
			'pom.xml', 'build.gradle', 'build.gradle.kts',
			'gradlew', 'mvnw', 'src/main/java/'
		],
		cpp => [
			'CMakeLists.txt', 'Makefile', 'configure.ac',
			'*.cpp', '*.hpp', '*.cc', '*.h'
		],
		c => [
			'CMakeLists.txt', 'Makefile', 'configure.ac',
			'*.c', '*.h',
		],
		docker => [
			'Dockerfile', 'docker-compose.yml', 'docker-compose.yaml',
			'.dockerignore'
		],
	);

	return $type ? $indicators{$type} : \%indicators;
}

# Detection functions - return a score (0 = not detected, higher = more confident)

sub _detect_perl() {
	my $score = 0;

	# Strong indicators
	$score += 10 if path('cpanfile')->exists;
	$score += 10 if path('dist.ini')->exists;
	$score += 8 if path('Makefile.PL')->exists;
	$score += 8  if path('Build.PL')->exists;

	# Medium indicators
	$score += 5  if path('META.json')->exists;
	$score += 5  if path('META.yml')->exists;

	# Weak indicators
	$score += 3  if path('lib')->exists && path('lib')->is_dir;
	$score += 2  if path('t')->exists && path('t')->is_dir;

	# Check for .pm files in lib/
	if (path('lib')->exists) {
		my @pm_files = path('lib')->children(qr/\.pm$/);
		$score += 2 if @pm_files > 0;
	}

	# Check for .t files in t/
	if (path('t')->exists) {
		my @t_files = path('t')->children(qr/\.t$/);
		$score += 1 if @t_files > 0;
	}

	return $score;
}

sub _detect_node() {
	my $score = 0;

	# Strong indicators
	$score += 15 if path('package.json')->exists;
	$score += 8  if path('package-lock.json')->exists;
	$score += 8  if path('yarn.lock')->exists;
	$score += 7  if path('pnpm-lock.yaml')->exists;

	# Medium indicators
	$score += 5  if path('node_modules')->exists && path('node_modules')->is_dir;
	$score += 4  if path('tsconfig.json')->exists;
	$score += 3  if path('.npmrc')->exists;

	# Weak indicators
	$score += 2  if path('src')->exists && path('src')->is_dir;

	return $score;
}

sub _detect_python() {
	my $score = 0;

	# Strong indicators
	$score += 12 if path('requirements.txt')->exists;
	$score += 12 if path('setup.py')->exists;
	$score += 12 if path('pyproject.toml')->exists;
	$score += 10 if path('Pipfile')->exists;
	$score += 8  if path('poetry.lock')->exists;

	# Medium indicators
	$score += 5  if path('setup.cfg')->exists;
	$score += 4  if path('tox.ini')->exists;
	$score += 3  if path('.python-version')->exists;

	# Weak indicators
	$score += 2  if path('venv')->exists || path('.venv')->exists;

	# Check for .py files
	my @py_files = path('.')->children(qr/\.py$/);
	$score += 2 if @py_files > 0;

	return $score;
}

sub _detect_rust() {
	my $score = 0;

	# Strong indicators
	$score += 15 if path('Cargo.toml')->exists;
	$score += 10 if path('Cargo.lock')->exists;

	# Medium indicators
	$score += 5  if path('src/main.rs')->exists;
	$score += 5  if path('src/lib.rs')->exists;
	$score += 3  if path('rust-toolchain.toml')->exists || path('rust-toolchain')->exists;

	# Weak indicators
	$score += 2  if path('target')->exists && path('target')->is_dir;

	return $score;
}

sub _detect_go() {
	my $score = 0;

	# Strong indicators
	$score += 15 if path('go.mod')->exists;
	$score += 10 if path('go.sum')->exists;

	# Medium indicators
	$score += 5  if path('main.go')->exists;

	# Check for .go files
	my @go_files = path('.')->children(qr/\.go$/);
	$score += 3 if @go_files > 0;
	$score += 1 if @go_files > 3;

	return $score;
}

sub _detect_ruby() {
	my $score = 0;

	# Strong indicators
	$score += 15 if path('Gemfile')->exists;
	$score += 10 if path('Gemfile.lock')->exists;

	# Medium indicators
	$score += 5  if path('Rakefile')->exists;
	$score += 4  if path('.ruby-version')->exists;
	$score += 3  if path('config.ru')->exists;

	# Check for .rb files
	my @rb_files = path('.')->children(qr/\.rb$/);
	$score += 2 if @rb_files > 0;

	return $score;
}

sub _detect_docker() {
	my $score = 0;

	# Strong indicators
	$score += 12 if path('Dockerfile')->exists;
	$score += 8  if path('docker-compose.yml')->exists;
	$score += 8  if path('docker-compose.yaml')->exists;

	# Medium indicators
	$score += 3  if path('.dockerignore')->exists;

	return $score;
}

sub _detect_php() {
	my $score = 0;

	# Strong indicators
	$score += 15 if path('composer.json')->exists;
	$score += 10 if path('composer.lock')->exists;

	# Medium indicators
	$score += 5  if path('phpunit.xml')->exists;
	$score += 5  if path('phpunit.xml.dist')->exists;
	$score += 3  if path('.php-version')->exists;

	# Weak indicators
	$score += 2  if path('src')->exists && path('src')->is_dir;
	$score += 2  if path('tests')->exists && path('tests')->is_dir;

	# Check for .php files
	my @php_files = path('.')->children(qr/\.php$/);
	$score += 2 if @php_files > 0;

	return $score;
}

sub _detect_java() {
	my $score = 0;

	# Strong indicators
	$score += 15 if path('pom.xml')->exists;
	$score += 15 if path('build.gradle')->exists;
	$score += 15 if path('build.gradle.kts')->exists;

	# Medium indicators
	$score += 5  if path('gradlew')->exists;
	$score += 5  if path('mvnw')->exists;
	$score += 4  if path('settings.gradle')->exists;
	$score += 4  if path('settings.gradle.kts')->exists;

	# Weak indicators
	$score += 3  if path('src/main/java')->exists;
	$score += 2  if path('src/test/java')->exists;

	# Check for .java files
	my @java_files = path('.')->children(qr/\.java$/);
	$score += 2 if @java_files > 0;

	return $score;
}

sub _detect_cpp() {
	my $score = 0;

	# Strong indicators
	$score += 12 if path('CMakeLists.txt')->exists;
	$score += 8  if path('Makefile')->exists;
	$score += 6  if path('configure.ac')->exists;
	$score += 6  if path('configure')->exists;

	# Medium indicators
	$score += 4  if path('meson.build')->exists;
	$score += 3  if path('.clang-format')->exists;

	# Check for C++ files
	my @cpp_files = path('.')->children(qr/\.(cpp|cc|cxx|hpp|hxx|h)$/);
	$score += 3 if @cpp_files > 0;
	$score += 2 if @cpp_files > 5;

	# Check for include directory
	$score += 2 if path('include')->exists && path('include')->is_dir;

	return $score;
}

=head1 AUTHOR

Nigel Horne E<lt>njh@nigelhorne.comE<gt>

L<https://github.com/nigelhorne>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
