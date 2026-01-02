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

our $VERSION = '0.01';

=head1 NAME

App::GHGen::Interactive - Interactive workflow customization

=head1 SYNOPSIS

    use App::GHGen::Interactive qw(customize_workflow);

    my $config = customize_workflow('perl');
    # Returns hash of user choices

=head1 FUNCTIONS

=head2 prompt_yes_no($question, $default)

Prompt for yes/no answer. Default is 'y' or 'n'.

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

Prompt user to select one option from a list.

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

Prompt user to select multiple options. Returns array ref of selected items.

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

Prompt for text input.

=cut

sub prompt_text($question, $default = '') {
    my $prompt = $default ? "[$default]" : '';
    print "$question $prompt: ";
    chomp(my $answer = <STDIN>);

    return $answer eq '' ? $default : $answer;
}

=head2 customize_workflow($type)

Interactive customization for a specific workflow type.
Returns hash of configuration options.

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
        "Push images on pull requests?",
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

	my $build_dir = prompt_text("Build output directory", './public');
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

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
