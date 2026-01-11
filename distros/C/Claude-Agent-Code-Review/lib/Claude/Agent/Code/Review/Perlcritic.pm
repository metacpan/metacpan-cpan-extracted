package Claude::Agent::Code::Review::Perlcritic;

use 5.020;
use strict;
use warnings;

use Claude::Agent::Code::Review::Issue;
use Claude::Agent::Code::Review::Options;
use Path::Tiny;

=head1 NAME

Claude::Agent::Code::Review::Perlcritic - Perl::Critic integration for deterministic code review

=head1 SYNOPSIS

    use Claude::Agent::Code::Review::Perlcritic;
    use Claude::Agent::Code::Review::Options;

    my $options = Claude::Agent::Code::Review::Options->new(
        perlcritic          => 1,
        perlcritic_severity => 3,
    );

    my @issues = Claude::Agent::Code::Review::Perlcritic->analyze(
        paths   => ['lib/'],
        options => $options,
    );

=head1 DESCRIPTION

Provides deterministic static analysis using Perl::Critic. Unlike AI-powered
review, perlcritic produces consistent results for the same code and configuration.

=head1 METHODS

=head2 analyze

    my @issues = Claude::Agent::Code::Review::Perlcritic->analyze(
        paths   => \@paths,
        options => $options,
    );

Runs perlcritic on the specified paths and returns an array of
L<Claude::Agent::Code::Review::Issue> objects.

=cut

sub analyze {
    my ($class, %args) = @_;

    my $paths   = $args{paths} // die "analyze() requires 'paths' argument";
    my $options = $args{options} // Claude::Agent::Code::Review::Options->new();

    # Require Perl::Critic at runtime
    eval { require Perl::Critic; 1 } or do {
        warn "Perl::Critic not available: $@";
        return ();
    };

    # Build critic configuration
    my %critic_args;
    my $severity = $options->perlcritic_severity // 4;
    $critic_args{'-severity'} = 0 + $severity;  # Force numeric context

    # Collect all files to analyze with path validation
    my $base_dir = path('.')->realpath;

    if ($options->perlcritic_profile && -f $options->perlcritic_profile) {
        # Validate profile path is within project directory (security)
        my $profile_path = eval { path($options->perlcritic_profile)->realpath };
        if ($profile_path && $base_dir->subsumes($profile_path)) {
            $critic_args{'-profile'} = $profile_path->stringify;
        }
    }

    my $critic = Perl::Critic->new(%critic_args);
    my @files;
    for my $path (@$paths) {
        if (-d $path) {
            # Validate directory is within base_dir before iterating (security)
            my $dir_real = eval { path($path)->realpath };
            next unless $dir_real && $base_dir->subsumes($dir_real);
            # Recursively find Perl files (.pl, .pm, .t, .psgi)
            my $iter = $dir_real->iterator({ recurse => 1 });
            while (my $file = $iter->()) {
                next unless $file->is_file && $file =~ /\.(?:p[lm]|t|psgi)$/;
                # Validate file is within base directory (security)
                my $real = eval { $file->realpath };
                next unless $real && $base_dir->subsumes($real);
                push @files, $file;
            }
        }
        elsif (-f $path) {
            my $file = path($path);
            # Validate file is within base directory (security)
            my $real = eval { $file->realpath };
            next unless $real && $base_dir->subsumes($real);
            push @files, $file;
        }
    }

    # Analyze each file
    my @issues;
    for my $file (@files) {
        my @violations = eval { $critic->critique("$file") };
        if ($@) {
            # Sanitize error message - remove potentially sensitive paths
            my $safe_error = $@;
            $safe_error =~ s/at \/.*? line \d+.*//s;
            $safe_error =~ s/\s+/ /g;
            $safe_error = substr($safe_error, 0, 100) if length($safe_error) > 100;
            # Report as an issue so it's visible in CI/CD (not just warn to stderr)
            my $error_issue = eval {
                Claude::Agent::Code::Review::Issue->new(
                    severity    => 'low',
                    category    => 'bugs',
                    file        => "$file",
                    line        => 1,
                    description => "Perl::Critic analysis failed: $safe_error",
                    explanation => "File could not be parsed by Perl::Critic. This may indicate a syntax error.",
                );
            };
            push @issues, $error_issue if $error_issue;
            next;
        }

        for my $violation (@violations) {
            my $pc_severity = $violation->severity;
            my $our_severity = _map_severity($pc_severity);
            my $category = _policy_to_category($violation->policy);

            my $issue = eval {
                Claude::Agent::Code::Review::Issue->new(
                    severity    => $our_severity,
                    category    => $category,
                    file        => "$file",
                    line        => $violation->line_number,
                    column      => $violation->column_number,
                    description => $violation->description,
                    explanation => "Perl::Critic policy: " . $violation->policy,
                );
            };

            push @issues, $issue if $issue;
        }
    }

    return @issues;
}

=head2 is_available

    if (Claude::Agent::Code::Review::Perlcritic->is_available) {
        # perlcritic is installed
    }

Returns true if Perl::Critic module is installed and available.

=cut

sub is_available {
    my ($class) = @_;
    return eval { require Perl::Critic; 1 } ? 1 : 0;
}

# Map perlcritic severity (1=gentle, 5=brutal) to our levels
sub _map_severity {
    my ($pc_severity) = @_;

    # perlcritic severity is inverted: 5 is most severe
    my %map = (
        5 => 'critical',
        4 => 'high',
        3 => 'medium',
        2 => 'low',
        1 => 'info',
    );

    return $map{$pc_severity} // 'medium';
}

# Map Perl::Critic policy names to our categories
sub _policy_to_category {
    my ($policy) = @_;

    return 'style' unless $policy;

    # Map based on policy namespace
    return 'security'       if $policy =~ /Security|InputOutput::RequireChecked/i;
    return 'bugs'           if $policy =~ /Bug|Error|Strict|RequireExplicit/i;
    return 'performance'    if $policy =~ /Perform|RegularExpressions::Prohibit/i;
    return 'maintainability' if $policy =~ /Complex|Subroutines::Prohibit|Modules::Require/i;
    return 'style';  # Default
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
