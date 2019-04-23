package App::INIUtils::Common;

use 5.010001;
use strict;
use warnings;

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
            local $_ = $s; eval "package main; no strict; no warnings; $section"; die if $@;
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
                local $_ = $k; eval "package main; no strict; no warnings; $key"; die if $@;
                $k2 = $_ if $_ ne $k;
            }
            # map value
            my $v = $hash->{$k};
            my $v2 = $v;
            if (defined $value) {
                no warnings 'once';
                local $main::SECTION = $s;
                local $main::KEY     = $k;
                local $_ = $v; eval "package main; no strict; no warnings; $value"; die if $@;
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

This document describes version 0.033 of App::INIUtils::Common (from Perl distribution App-INIUtils), released on 2019-04-23.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-INIUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-INIUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-INIUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
