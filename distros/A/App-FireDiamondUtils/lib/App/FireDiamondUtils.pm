package App::FireDiamondUtils;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-03-29'; # DATE
our $DIST = 'App-FireDiamondUtils'; # DIST
our $VERSION = '0.002'; # VERSION

our %SPEC;

$SPEC{'show_fire_diamond_legends'} = {
    v => 1.1,
    summary => 'Show a table that explains the meaning of each number and symbol in the Fire Diamond notation',
    args => {
        detail => {
            summary => 'Show the longer explanation instead of just the meaning',
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
};
sub show_fire_diamond_legends {
    require Parse::FireDiamond;
    require Text::ANSITable;

    my %args = @_;

    my $t = Text::ANSITable->new;
    $t->columns(["Num/Sym", "Meaning", ( $args{detail} ? ("Explanation") : () )]);

    my $rownum = 0;

    $t->set_row_style($rownum, {fgcolor=>"000000", bgcolor=>"01b3f1"});
    $t->add_row(["", "HEALTH HAZARD", "", ( $args{detail} ? () : () )]);
    $rownum++;
    for my $num (sort {$a <=> $b} keys %Parse::FireDiamond::health_hazard_attrs) {
        $t->add_row([$num, $Parse::FireDiamond::health_hazard_attrs{$num}{meaning}, ( $args{detail} ? ($Parse::FireDiamond::health_hazard_attrs{$num}{explanation}) : () )]);
        $rownum++;
    }
    $t->add_row_separator;

    $t->set_row_style($rownum, {fgcolor=>"000000", bgcolor=>"ec1b2e"});
    $t->add_row(["", "FIRE HAZARD", "", ( $args{detail} ? () : () )]);
    $rownum++;
    for my $num (sort {$a <=> $b} keys %Parse::FireDiamond::fire_hazard_attrs) {
        $t->add_row([$num, $Parse::FireDiamond::fire_hazard_attrs{$num}{meaning}, ( $args{detail} ? ($Parse::FireDiamond::fire_hazard_attrs{$num}{explanation}) : () )]);
        $rownum++;
    }
    $t->add_row_separator;

    $t->set_row_style($rownum, {fgcolor=>"000000", bgcolor=>"f2de01"});
    $t->add_row(["", "REACTIVITY", "", ( $args{detail} ? () : () )]);
    $rownum++;
    for my $num (sort {$a <=> $b} keys %Parse::FireDiamond::reactivity_attrs) {
        $t->add_row([$num, $Parse::FireDiamond::reactivity_attrs{$num}{meaning}, ( $args{detail} ? ($Parse::FireDiamond::reactivity_attrs{$num}{explanation}) : () )]);
        $rownum++;
    }
    $t->add_row_separator;

    $t->set_row_style($rownum, {fgcolor=>"000000", bgcolor=>"ffffff"});
    $t->add_row(["", "SPECIFIC HAZARDS", "", ( $args{detail} ? () : () )]);
    $rownum++;
    for my $num (sort keys %Parse::FireDiamond::specific_hazard_attrs) {
        $t->add_row([$num, $Parse::FireDiamond::specific_hazard_attrs{$num}{meaning}, ( $args{detail} ? ($Parse::FireDiamond::specific_hazard_attrs{$num}{explanation}) : () )]);
        $rownum++;
    }
    $t->add_row_separator;

    binmode(STDOUT, ":utf8"); ## no critic: InputOutput::RequireEncodingWithUTF8Layer
    print $t->draw;

    [200];
}

1;
# ABSTRACT: Utilities related to fire diamond (NFPA 704 standard)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::FireDiamondUtils - Utilities related to fire diamond (NFPA 704 standard)

=head1 VERSION

This document describes version 0.002 of App::FireDiamondUtils (from Perl distribution App-FireDiamondUtils), released on 2023-03-29.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<parse-fire-diamond-text-notation>

=item * L<show-fire-diamond-legends>

=back

=head1 FUNCTIONS


=head2 show_fire_diamond_legends

Usage:

 show_fire_diamond_legends(%args) -> [$status_code, $reason, $payload, \%result_meta]

Show a table that explains the meaning of each number and symbol in the Fire Diamond notation.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

Show the longer explanation instead of just the meaning.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-FireDiamondUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-FireDiamondUtils>.

=head1 SEE ALSO

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-FireDiamondUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
