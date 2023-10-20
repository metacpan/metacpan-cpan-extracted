package Perinci::CmdLine::depak;

use 5.010;
use strict;
use Log::ger;
use parent qw(Perinci::CmdLine::Lite);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-07-11'; # DATE
our $DIST = 'App-depak'; # DIST
our $VERSION = '0.586'; # VERSION

sub hook_before_read_config_file {
    my ($self, $r) = @_;

    if (defined $r->{config_profile}) {
        log_trace("[pericmd-depak] Using config profile '%s' (predefined)",
                     $r->{config_profile});
        return;
    }

    # this is a hack, not proper cmdline arg parsing like in parse_argv().

    my $input_file;
    my $in_args;
    for my $i (0..$#ARGV) {
        my $arg = $ARGV[$i];
        if ($arg eq '--') {
            $in_args++;
            next;
        }
        if ($arg =~ /^-/ && !$in_args) {
            if ($arg =~ /^(-i|--input-file)$/ && $i < $#ARGV) {
                $input_file = $ARGV[$i+1];
                last;
            }
        }
        if ($in_args) {
            $input_file = $arg;
            last;
        }
    }

    unless (defined $input_file) {
        log_trace("[pericmd-depak] Not selecting config profile (no input file defined)");
        return;
    }

    require File::Spec;
    my ($vol, $dir, $name) = File::Spec->splitpath($input_file);
    log_trace("[pericmd-depak] Selecting config profile '%s' (from input file)", $name);
    $r->{config_profile} = $name;
    $r->{ignore_missing_config_profile_section} = 1;
}

1;
# ABSTRACT: Subclass of Perinci::CmdLine::Lite to set config_profile default

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::depak - Subclass of Perinci::CmdLine::Lite to set config_profile default

=head1 VERSION

This document describes version 0.586 of Perinci::CmdLine::depak (from Perl distribution App-depak), released on 2023-07-11.

=head1 DESCRIPTION

This subclass sets default config_profile to the name of input script, for
convenience. So for example:

 % depak -i ~/proj/Bar-Baz/bin/bar

will automatically set config_profile to C<bar>, as if you had written:

 % depak -i ~/proj/Bar-Baz/bin/bar --config-profile bar

Of course, you can explicitly set C<--config-profile> to something else to
override this.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-depak>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-depak>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-depak>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
