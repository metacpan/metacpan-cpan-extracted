package Bencher::Role::FieldMunger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-10'; # DATE
our $DIST = 'Bencher-Backend'; # DIST
our $VERSION = '1.053'; # VERSION

use 5.010;
use strict;
use warnings;

use Role::Tiny;

sub add_field {
    my ($self, $envres, $name, $opts, $code) = @_;

    $code->();

    my $fs = $envres->[3]{'table.fields'};
    my $fu = $envres->[3]{'table.field_units'};
    my $fa = $envres->[3]{'table.field_aligns'};
    my $ff = $envres->[3]{'table.field_formats'};

    my $pos = 0;
    for my $i (0..$#{$fs}) {
        if ($opts->{after} && $fs->[$i] eq $opts->{after}) {
            $pos = $i+1;
            last;
        }
        if ($opts->{before} && $fs->[$i] eq $opts->{before}) {
            $pos = $i;
            last;
        }
    }

    splice @$fs, $pos, 0, $name;
    if ($fu) {
        my $unit;
        if ($opts->{unit}) {
            $unit = $opts->{unit};
        } elsif ($opts->{unit_of}) {
            for my $i (0..$#{$ff}) {
                if (($ff->[$i] // '') eq $opts->{unit_of}) {
                    $unit = $fu->[$i];
                    last;
                }
            }
        }
        splice @$fu, $pos, 0, $unit;
    }
    if ($fa) {
        my $align;
        if ($opts->{align}) {
            $align = $opts->{align};
        }
        splice @$fa, $pos, 0, $align;
    }
    if ($ff) {
        my $format;
        if ($opts->{format}) {
            $format = $opts->{format};
        }
        splice @$ff, $pos, 0, $format;
    }
}

sub delete_fields {
    my ($self, $envres, @names) = @_;

    for my $name (@names) {
        for my $row (@{$envres->[2]}) {
            delete $row->{$name};
        }
    }

    my $fs = $envres->[3]{'table.fields'};
    my $fu = $envres->[3]{'table.field_units'};
    my $fa = $envres->[3]{'table.field_aligns'};
    my $ff = $envres->[3]{'table.field_formats'};

    for my $i (reverse 0..$#{$fs}) {
        if (grep {$fs->[$i] eq $_} @names) {
            splice @$fs, $i, 1;
            splice @$fu, $i, 1 if $fu && @$fu > $i;
            splice @$fa, $i, 1 if $fa && @$fa > $i;
            splice @$ff, $i, 1 if $ff && @$ff > $i;
        }
    }
}

1;
# ABSTRACT: Field munger role

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Role::FieldMunger - Field munger role

=head1 VERSION

This document describes version 1.053 of Bencher::Role::FieldMunger (from Perl distribution Bencher-Backend), released on 2021-04-10.

=for Pod::Coverage .*

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Backend>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Backend>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Backend>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
