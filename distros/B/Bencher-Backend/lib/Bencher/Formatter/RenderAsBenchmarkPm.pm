package Bencher::Formatter::RenderAsBenchmarkPm;

use 5.010001;
use strict;
use warnings;

use parent qw(Bencher::Formatter);

use Role::Tiny::With;
with 'Bencher::Role::ResultRenderer';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-11-29'; # DATE
our $DIST = 'Bencher-Backend'; # DIST
our $VERSION = '1.062'; # VERSION

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
            (defined($it->{rate}) ? "$it->{rate}/s" : sprintf("%.1f/s", 1000/$it->{time})),
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

This document describes version 1.062 of Bencher::Formatter::RenderAsBenchmarkPm (from Perl distribution Bencher-Backend), released on 2022-11-29.

=for Pod::Coverage .*

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Backend>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Backend>.

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

This software is copyright (c) 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Backend>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
