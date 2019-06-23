package Perinci::CmdLine::depak;

our $DATE = '2019-06-20'; # DATE
our $VERSION = '0.581'; # VERSION

use 5.010;
use Log::ger;
use parent qw(Perinci::CmdLine::Lite);

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

This document describes version 0.581 of Perinci::CmdLine::depak (from Perl distribution App-depak), released on 2019-06-20.

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

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-depak>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
