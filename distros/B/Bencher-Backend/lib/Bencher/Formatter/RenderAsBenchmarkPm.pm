package Bencher::Formatter::RenderAsBenchmarkPm;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-23'; # DATE
our $DIST = 'Bencher-Backend'; # DIST
our $VERSION = '1.057'; # VERSION

use 5.010001;
use strict;
use warnings;

use parent qw(Bencher::Formatter);

use Role::Tiny::With;
with 'Bencher::Role::ResultRenderer';

sub render_result {
    require Text::Table::More;

    my ($self, $envres) = @_;

    # because underscored keys were removed; we want _succint_name back.
    my $items = $envres->[2];
    Bencher::Backend::_set_item_names($items);
    my @item_names;
    my %legends; # key = succinct_name
    for my $it (@$items) {
        push @item_names, $it->{_succinct_name};
        $legends{$it->{_succinct_name}} =
            join(" ", map {"$_=$it->{$_}"} grep { !/^_/ && !/^(errors|pct_|rate|samples|time)/ } sort keys %$it);
    }

    my @rows;
    push @rows, [
        # column names
        "", # item name
        "Rate",
        @item_names,
    ];
    for my $i (0..$#{$items}) {
        my $it = $items->[$i];
        push @rows, [
            $it->{_succinct_name},
            (defined($it->{rate}) ? "$it->{rate}/s" : sprintf("%.1f/s", 1/$it->{time})),
        ];
        for my $j (0..$#{$items}) {
            my $pct;
            if ($i == $j) {
                $pct = "--";
            } else {
                if ($items->[$j]{time} < $it->{time}) {
                    # item i is slower than item j by N percent
                    $pct = -(1 - $items->[$j]{time} / $it->{time}) * 100;
                } else {
                    # item i is faster than item j by N percent
                    $pct = ($items->[$j]{time} / $it->{time} -1) * 100;
                }
                $pct = sprintf("%d%%", $pct);
            }
            push @{ $rows[-1] }, $pct;
        }
    }

    my $rres = ''; # render result

    $rres .= Text::Table::More::table(
        rows => \@rows,
        border_style=>'ASCII::None',
        align => 'right',
        col_attrs => [
            [0, {align=>'left'}],
        ],
    );
    $rres .= "\n";
    $rres .= "Legends:\n";
    for (sort keys %legends) {
        $rres .= "  " . $_ . ": " . $legends{$_} . "\n";
    }

    $rres;
}

1;
# ABSTRACT: Scale time to make it convenient

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Formatter::RenderAsBenchmarkPm - Scale time to make it convenient

=head1 VERSION

This document describes version 1.057 of Bencher::Formatter::RenderAsBenchmarkPm (from Perl distribution Bencher-Backend), released on 2021-07-23.

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
