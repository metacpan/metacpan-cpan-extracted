package App::INIUtils::Common;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-06-24'; # DATE
our $DIST = 'App-INIUtils'; # DIST
our $VERSION = '0.035'; # VERSION

our %args_grep = (
    section => {
        schema => 'str*',
    },
    key => {
        schema => 'str*',
    },
    value => {
        schema => 'str*',
    },
    ignore_case => {
        schema => 'bool*',
        cmdline_aliases => {i=>{}},
    },
    invert_match => {
        schema => 'bool*',
        cmdline_aliases => {v=>{}},
    },
    invert_match_section => {
        schema => 'bool*',
    },
    invert_match_key => {
        schema => 'bool*',
    },
    invert_match_value => {
        schema => 'bool*',
    },
);

our %args_map = (
    section => {
        schema => 'str*',
    },
    key => {
        schema => 'str*',
    },
    value => {
        schema => 'str*',
    },
);

sub map_hoh {
    my %args = @_;

    my $section = $args{section};
    my $key     = $args{key};
    my $value   = $args{value};

    my $hoh = $args{hoh};
    my $new_hoh = {};
    for my $s (sort keys %$hoh) {
        # map section
        my $s2 = $s;
        if (defined $section) {
            local $_ = $s; eval "package main; no strict; no warnings; $section"; die if $@; ## no critic: BuiltinFunctions::ProhibitStringyEval
            $s2 = $_ if $_ ne $s;
        }

        $new_hoh->{$s2} = {};

        my $hash = $hoh->{$s};
        for my $k (sort keys %$hash) {
            my $k2 = $k;
            # map key
            if (defined $key) {
                no warnings 'once';
                local $main::SECTION = $s;
                local $_ = $k; eval "package main; no strict; no warnings; $key"; die if $@; ## no critic: BuiltinFunctions::ProhibitStringyEval
                $k2 = $_ if $_ ne $k;
            }
            # map value
            my $v = $hash->{$k};
            my $v2 = $v;
            if (defined $value) {
                no warnings 'once';
                local $main::SECTION = $s;
                local $main::KEY     = $k;
                local $_ = $v; eval "package main; no strict; no warnings; $value"; die if $@; ## no critic: BuiltinFunctions::ProhibitStringyEval
                $v2 = $_ if $_ ne $v;
            }

            $new_hoh->{$s2}{$k2} = $v2;
        }
    }
    $new_hoh;
}

sub hoh_as_ini {
    my $hoh = shift;
    join(
        "",
        map {
            my $s = $_;
            my $hash = $hoh->{$s};
            join(
                "",
                "[$s]\n",
                map {
                    "$_=$hash->{$_}\n"
                } sort keys %$hash,
            );
        } sort keys %$hoh
    );
}

1;
# ABSTRACT: Routines common between App::INIUtils and App::IODUtils

__END__

=pod

=encoding UTF-8

=head1 NAME

App::INIUtils::Common - Routines common between App::INIUtils and App::IODUtils

=head1 VERSION

This document describes version 0.035 of App::INIUtils::Common (from Perl distribution App-INIUtils), released on 2024-06-24.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-INIUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-INIUtils>.

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

This software is copyright (c) 2024, 2019, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-INIUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
