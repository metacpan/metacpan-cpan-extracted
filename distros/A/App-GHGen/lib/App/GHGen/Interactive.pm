package App::GHGen::Interactive;

use v5.36;
use strict;
use warnings;
use Term::ANSIColor qw(colored);

use Exporter 'import';
our @EXPORT_OK = qw(
	prompt_yes_no
	prompt_choice
	prompt_multiselect
	prompt_text
	customize_workflow
);

our $VERSION = '0.06';

=head1 NAME

App::GHGen::Interactive - Interactive workflow customization

=head1 SYNOPSIS

    use App::GHGen::Interactive qw(customize_workflow);

    my $config = customize_workflow('perl');
    # Returns hash of user choices

=encoding utf-8

=head1 FUNCTIONS

=head2 prompt_yes_no($question, $default)

Prompt the user for a yes/no answer and return a boolean.

=head3 Purpose

Print C<$question> followed by a bracket hint (C<[Y/n]> or C<[y/N]>),
read one line from STDIN, and return C<1> for yes or C<0> for no.  An
empty response uses C<$default>.

=head3 Arguments

=over 4

=item C<$question> (Str, required)

The question text to display.

=item C<$default> (Str, optional, default C<'y'>)

The default answer when the user presses Enter without typing.
Must be C<'y'> or C<'n'>.

=back

=head3 Returns

C<1> when the answer is affirmative (C<y> or C<yes>, case-insensitive) or
when the empty response maps to a C<'y'> default.

C<0> when the answer is negative (C<n> or C<no>, case-insensitive) or
when the empty response maps to an C<'n'> default.

=head3 Side Effects

Reads one line from STDIN; prints to STDOUT.

=head3 Usage Example

    my $ok = prompt_yes_no("Enable coverage?", 'y');

=head3 API SPECIFICATION

=head4 Input

    {
        question => { type => 'scalar', required => 1 },
        default  => { type => 'scalar', default  => 'y' },
    }

=head4 Output

    { type => 'scalar' }   # 1 or 0

=head3 FORMAL SPECIFICATION

    prompt_yes_no : ℤ* × {'y','n'} → 𝔹

    answer ≔ chomp(readline(STDIN))
    result ≔
        answer =~ /^y(es)?$/i → 1
        answer =~ /^n(o)?$/i  → 0
        answer = ""           → default = 'y' → 1  |  default = 'n' → 0

=cut

sub prompt_yes_no($question, $default = 'y') {
	my $prompt = $default eq 'y' ? '[Y/n]' : '[y/N]';
	print "$question $prompt: ";
	chomp(my $answer = <STDIN>);

	return 1 if $answer =~ /^y(es)?$/i;
	return 0 if $answer =~ /^n(o)?$/i;
	return $default eq 'y' ? 1 : 0;
}

=head2 prompt_choice($question, $choices, $default)

Prompt the user to select one item from a numbered list.

=head3 Purpose

Display C<$question> followed by a numbered list of C<$choices>, read one
line from STDIN, and return the zero-based index of the selected item.

=head3 Arguments

=over 4

=item C<$question> (Str, required)

The selection prompt text.

=item C<$choices> (ArrayRef[Str], required)

The available options, displayed numbered from 1.

=item C<$default> (Int, optional, default C<0>)

Zero-based index of the pre-selected option shown in the prompt.

=back

=head3 Returns

A zero-based integer index.  Returns C<$default> when the user presses Enter
without input or when the input is out of range (less than 1 or greater than
the number of choices).

=head3 Side Effects

Reads one line from STDIN; prints to STDOUT.

=head3 Usage Example

    my $idx = prompt_choice("Package manager?", ['npm','yarn','pnpm'], 0);

=head3 API SPECIFICATION

=head4 Input

    {
        question => { type => 'scalar',  required => 1 },
        choices  => { type => 'arrayref', required => 1 },
        default  => { type => 'scalar',  default  => 0 },
    }

=head4 Output

    { type => 'scalar' }   # integer 0 .. |choices|-1

=head3 FORMAL SPECIFICATION

    prompt_choice : ℤ* × seq ℤ* × ℕ → ℕ

    answer ≔ chomp(readline(STDIN))
    result ≔
        answer = ""                       → default
        answer ∈ ℕ ∧ 1 ≤ answer ≤ |choices| → answer − 1
        otherwise                         → default

=cut

sub prompt_choice($question, $choices, $default = 0) {
    say $question;
    for my $i (0 .. $#$choices) {
        my $marker = $i == $default ? colored(['green'], '→') : ' ';
        say "  $marker " . ($i + 1) . ". $choices->[$i]";
    }

    print "\nEnter number [" . ($default + 1) . "]: ";
    chomp(my $answer = <STDIN>);

    return $default if $answer eq '';
    return $answer - 1 if $answer =~ /^\d+$/ && $answer >= 1 && $answer <= @$choices;
    return $default;
}

=head2 prompt_multiselect($question, $options, $defaults)

Prompt the user to select zero or more items from a numbered list.

=head3 Purpose

Display C<$question> and a numbered list of C<$options>, accept
comma-separated numbers or the keyword C<all>, and return an array reference
of the selected option strings.

=head3 Arguments

=over 4

=item C<$question> (Str, required)

The multi-select prompt text.

=item C<$options> (ArrayRef[Str], required)

All available options, displayed numbered from 1.

=item C<$defaults> (ArrayRef[Str], optional, default C<[]>)

The pre-selected options (by value, not index).

=back

=head3 Returns

An array reference of selected option strings.  Possible values:

=over 4

=item *

The full C<$options> list when the user types C<all>.

=item *

A subset derived from the comma/space-separated numbers the user entered.

=item *

C<$defaults> when the user presses Enter without typing.

=back

=head3 Side Effects

Reads one line from STDIN; prints to STDOUT.

=head3 Usage Example

    my $sel = prompt_multiselect("OS?", ['ubuntu-latest','macos-latest','windows-latest'], []);

=head3 API SPECIFICATION

=head4 Input

    {
        question => { type => 'scalar',  required => 1 },
        options  => { type => 'arrayref', required => 1 },
        defaults => { type => 'arrayref', default  => [] },
    }

=head4 Output

    { type => 'arrayref' }

=head3 FORMAL SPECIFICATION

    prompt_multiselect : ℤ* × seq ℤ* × seq ℤ* → seq ℤ*

    answer ≔ chomp(readline(STDIN))
    result ≔
        answer = ""           → defaults
        answer =~ /^all$/i   → options
        otherwise            → [ options[n−1] ∣ n ∈ split(/[,\s]+/, answer), 1 ≤ n ≤ |options| ]
                                   ?? defaults (when result = ∅)

=cut

sub prompt_multiselect($question, $options, $defaults = []) {
    say $question;
    say colored(['cyan'], "(Enter numbers separated by commas, or 'all')");

    my %is_default = map { $_ => 1 } @$defaults;

    for my $i (0 .. $#$options) {
        my $marker = $is_default{$options->[$i]} ? colored(['green'], '✓') : ' ';
        say "  $marker " . ($i + 1) . ". $options->[$i]";
    }

    print "\nEnter choices [" . join(',', map { $_+1 } 0..$#$defaults) . "]: ";
    chomp(my $answer = <STDIN>);

    return $defaults if $answer eq '';

    if ($answer =~ /^all$/i) {
        return $options;
    }

    my @selected;
    for my $num (split /[,\s]+/, $answer) {
        if ($num =~ /^\d+$/ && $num >= 1 && $num <= @$options) {
            push @selected, $options->[$num - 1];
        }
    }

    return @selected ? \@selected : $defaults;
}

=head2 prompt_text($question, $default)

Prompt the user for a free-form text answer.

=head3 Purpose

Display C<$question> optionally followed by C<[$default]>, read one line
from STDIN, and return the user's answer or C<$default> when empty.

=head3 Arguments

=over 4

=item C<$question> (Str, required)

The prompt text.

=item C<$default> (Str, optional, default C<''>)

Returned as-is when the user presses Enter without typing anything.

=back

=head3 Returns

The trimmed line the user typed, or C<$default> when the input is empty.

=head3 Side Effects

Reads one line from STDIN; prints to STDOUT.

=head3 Usage Example

    my $name = prompt_text("Project name", 'my-project');

=head3 API SPECIFICATION

=head4 Input

    {
        question => { type => 'scalar', required => 1 },
        default  => { type => 'scalar', default  => '' },
    }

=head4 Output

    { type => 'scalar' }

=head3 FORMAL SPECIFICATION

    prompt_text : ℤ* × ℤ* → ℤ*

    answer ≔ chomp(readline(STDIN))
    result ≔ answer = "" → default  |  otherwise → answer

=cut

sub prompt_text($question, $default = '') {
    my $prompt = $default ? "[$default]" : '';
    print "$question $prompt: ";
    chomp(my $answer = <STDIN>);

    return $answer eq '' ? $default : $answer;
}

=head2 customize_workflow($type)

Drive an interactive customization session for the given workflow type.

=head3 Purpose

Display a series of prompts relevant to C<$type> and collect user preferences.
Dispatches to a private C<_customize_*> helper; returns an empty hash when
the type is not supported.

=head3 Arguments

=over 4

=item C<$type> (Str, required)

The workflow type to customise.  Supported: C<perl>, C<node>, C<python>,
C<rust>, C<go>, C<ruby>, C<docker>, C<static>.

=back

=head3 Returns

A hash reference of configuration key/value pairs collected from the user.
Returns an empty hash reference (C<{}>) when C<$type> is not recognised.

=head3 Side Effects

Reads multiple lines from STDIN; prints to STDOUT.

=head3 Usage Example

    my $config = customize_workflow('perl');
    # $config->{enable_critic}, $config->{perl_versions}, etc.

=head3 API SPECIFICATION

=head4 Input

    { type => { type => 'scalar', required => 1 } }

=head4 Output

    { type => 'hashref' }   # empty or populated with type-specific keys

=head3 FORMAL SPECIFICATION

    SupportedCustomTypes ≔ { perl, node, python, rust, go, ruby, docker, static }

    customize_workflow : ℤ* → Config

    t ∈ SupportedCustomTypes → _customize_t()
    t ∉ SupportedCustomTypes → {}

=cut

sub customize_workflow($type) {
    say '';
    say colored(['bold cyan'], "=== Workflow Customization: " . uc($type) . " ===");
    say '';

    my %dispatch = (
        perl   => \&_customize_perl,
        node   => \&_customize_node,
        python => \&_customize_python,
        rust   => \&_customize_rust,
        go     => \&_customize_go,
        ruby   => \&_customize_ruby,
        docker => \&_customize_docker,
        static => \&_customize_static,
    );

    if (exists $dispatch{$type}) {
        return $dispatch{$type}->();
    }

    return {};
}

sub _customize_perl() {
    my %config;

    # Perl versions
    say colored(['bold'], "Perl Versions to Test:");
    my @all_versions = qw(5.40 5.38 5.36 5.34 5.32 5.30 5.28 5.26 5.24 5.22);
    my @default_versions = qw(5.40 5.38 5.36);

    $config{perl_versions} = prompt_multiselect(
        "Which Perl versions?",
        \@all_versions,
        \@default_versions
    );
    say '';

    # Operating systems
    say colored(['bold'], "Operating Systems:");
    my @all_os = ('ubuntu-latest', 'macos-latest', 'windows-latest');
    my @default_os = @all_os;

    $config{os} = prompt_multiselect(
        "Which operating systems?",
        \@all_os,
        \@default_os
    );
    say '';

    # Code quality
    say colored(['bold'], "Code Quality Tools:");
    $config{enable_linter} = prompt_yes_no(
        "Enable syntax linting (perl -c on all matrix cells)?",
        'y'
    );
    say '';

    $config{enable_linter_unused} = prompt_yes_no(
        "Enable unused-variable check (warnings::unused, latest+ubuntu only)?",
        'n'
    );
    say '';

    $config{enable_critic} = prompt_yes_no(
        "Enable Perl::Critic?",
        'y'
    );
    say '';

    # Coverage
    $config{enable_coverage} = prompt_yes_no(
        "Enable test coverage (Devel::Cover)?",
        'y'
    );
    say '';

    # Branches
    say colored(['bold'], "Branch Configuration:");
    my $branches = prompt_text(
        "Branches to run on (comma-separated)",
        'main,master'
    );
    $config{branches} = [split /,\s*/, $branches];
    say '';

    return \%config;
}

sub _customize_node() {
    my %config;

    # Node versions
    say colored(['bold'], "Node.js Versions to Test:");
    my @all_versions = qw(18.x 20.x 22.x 23.x);
    my @default_versions = qw(20.x 22.x);

    $config{node_versions} = prompt_multiselect(
        "Which Node.js versions?",
        \@all_versions,
        \@default_versions
    );
    say '';

    # Package manager
    say colored(['bold'], "Package Manager:");
    my $pm_choice = prompt_choice(
        "Which package manager?",
        ['npm', 'yarn', 'pnpm'],
        0
    );
    $config{package_manager} = ['npm', 'yarn', 'pnpm']->[$pm_choice];
    say '';

    # Linting
    $config{enable_lint} = prompt_yes_no(
        "Enable linting?",
        'y'
    );
    say '';

    # Build step
    $config{enable_build} = prompt_yes_no(
        "Enable build step?",
        'y'
    );
    say '';

    # Branches
    my $branches = prompt_text(
        "Branches to run on (comma-separated)",
        'main,develop'
    );
    $config{branches} = [split /,\s*/, $branches];
    say '';

    return \%config;
}

sub _customize_python() {
    my %config;

    # Python versions
    say colored(['bold'], "Python Versions to Test:");
    my @all_versions = qw(3.9 3.10 3.11 3.12 3.13);
    my @default_versions = qw(3.11 3.12);

    $config{python_versions} = prompt_multiselect(
        "Which Python versions?",
        \@all_versions,
        \@default_versions
    );
    say '';

    # Linting
    say colored(['bold'], "Code Quality:");
    $config{enable_flake8} = prompt_yes_no(
        "Enable flake8 linting?",
        'y'
    );
    say '';

    $config{enable_black} = prompt_yes_no(
        "Enable black formatter check?",
        'n'
    );
    say '';

    # Coverage
    $config{enable_coverage} = prompt_yes_no(
        "Enable test coverage?",
        'y'
    );
    say '';

    # Branches
    my $branches = prompt_text(
        "Branches to run on (comma-separated)",
        'main,develop'
    );
    $config{branches} = [split /,\s*/, $branches];
    say '';

    return \%config;
}

sub _customize_rust() {
    my %config;

    say colored(['bold'], "Rust Workflow Options:");

    $config{enable_fmt} = prompt_yes_no(
        "Enable formatting check (cargo fmt)?",
        'y'
    );
    say '';

    $config{enable_clippy} = prompt_yes_no(
        "Enable clippy linting?",
        'y'
    );
    say '';

    $config{enable_release} = prompt_yes_no(
        "Build release binary?",
        'y'
    );
    say '';

    my $branches = prompt_text(
        "Branches to run on (comma-separated)",
        'main'
    );
    $config{branches} = [split /,\s*/, $branches];
    say '';

    return \%config;
}

sub _customize_go() {
    my %config;

    say colored(['bold'], "Go Workflow Options:");

    my $go_version = prompt_text(
        "Go version",
        '1.22'
    );
    $config{go_version} = $go_version;
    say '';

    $config{enable_vet} = prompt_yes_no(
        "Enable go vet?",
        'y'
    );
    say '';

    $config{enable_race} = prompt_yes_no(
        "Enable race detector?",
        'y'
    );
    say '';

    $config{enable_coverage} = prompt_yes_no(
        "Enable test coverage?",
        'y'
    );
    say '';

    my $branches = prompt_text(
        "Branches to run on (comma-separated)",
        'main'
    );
    $config{branches} = [split /,\s*/, $branches];
    say '';

    return \%config;
}

sub _customize_ruby() {
    my %config;

    say colored(['bold'], "Ruby Versions to Test:");
    my @all_versions = qw(3.1 3.2 3.3);
    my @default_versions = qw(3.2 3.3);

    $config{ruby_versions} = prompt_multiselect(
        "Which Ruby versions?",
        \@all_versions,
        \@default_versions
    );
    say '';

    my $branches = prompt_text(
        "Branches to run on (comma-separated)",
        'main'
    );
    $config{branches} = [split /,\s*/, $branches];
    say '';

    return \%config;
}

sub _customize_docker() {
    my %config;

    say colored(['bold'], "Docker Workflow Options:");

    my $image_name = prompt_text(
        "Docker image name (user/image)",
        'your-username/your-image'
    );
    $config{image_name} = $image_name;
    say '';

	$config{push_on_pr} = prompt_yes_no(
		'Push images on pull requests?',
		'n'
	);
	say '';

	my $branches = prompt_text(
		"Branches to run on (comma-separated)",
		'main'
	);
	$config{branches} = [split /,\s*/, $branches];
	say '';

	return \%config;
}

sub _customize_static() {
	my %config;

	say colored(['bold'], "Static Site Deployment:");

	my $build_dir = prompt_text('Build output directory', './public');
	$config{build_dir} = $build_dir;
	say '';

	my $build_command = prompt_text("Build command", 'npm run build');
	$config{build_command} = $build_command;
	say '';

	return \%config;
}

=head1 AUTHOR

Nigel Horne E<lt>njh@nigelhorne.comE<gt>

L<https://github.com/nigelhorne>

=head1 COPYRIGHT AND LICENSE

Copyright 2025-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
