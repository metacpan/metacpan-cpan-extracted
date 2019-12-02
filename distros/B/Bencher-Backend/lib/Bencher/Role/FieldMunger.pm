package Bencher::Role::FieldMunger;

our $DATE = '2019-12-02'; # DATE
our $VERSION = '1.046'; # VERSION

use 5.010;
use strict;
use warnings;

use Role::Tiny;

sub add_field {
    my ($self, $envres, $name, $opts, $code) = @_;

    $code->();

    my $ff = $envres->[3]{'table.fields'};
    my $fu = $envres->[3]{'table.field_units'};
    my $fa = $envres->[3]{'table.field_aligns'};

    my $pos = 0;
    for my $i (0..$#{$ff}) {
        if ($opts->{after} && $ff->[$i] eq $opts->{after}) {
            $pos = $i+1;
            last;
        }
        if ($opts->{before} && $ff->[$i] eq $opts->{before}) {
            $pos = $i;
            last;
        }
    }

    splice @$ff, $pos, 0, $name;
    if ($fu) {
        my $unit;
        if ($opts->{unit}) {
            $unit = $opts->{unit};
        } elsif ($opts->{unit_of}) {
            for my $i (0..$#{$ff}) {
                if ($ff->[$i] eq $opts->{unit_of}) {
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
}

sub delete_fields {
    my ($self, $envres, @names) = @_;

    for my $name (@names) {
        for my $row (@{$envres->[2]}) {
            delete $row->{$name};
        }
    }

    my $ff = $envres->[3]{'table.fields'};
    my $fu = $envres->[3]{'table.field_units'};
    my $fa = $envres->[3]{'table.field_aligns'};

    for my $i (reverse 0..$#{$ff}) {
        if (grep {$ff->[$i] eq $_} @names) {
            splice @$ff, $i, 1;
            splice @$fu, $i, 1 if $fu && @$fu > $i;
            splice @$fa, $i, 1 if $fa && @$fa > $i;
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

This document describes version 1.046 of Bencher::Role::FieldMunger (from Perl distribution Bencher-Backend), released on 2019-12-02.

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

This software is copyright (c) 2019, 2018, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
