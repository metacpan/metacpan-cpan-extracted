package App::BPOMUtils::Additives;

use 5.010001;
use strict;
use warnings;

use Capture::Tiny 'capture_stderr';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-01'; # DATE
our $DIST = 'App-BPOMUtils-Additives'; # DIST
our $VERSION = '0.002'; # VERSION

our %SPEC;

our %args_common = (
    quantity => {
        # schema => 'physical::mass*', # XXX Perinci::Sub::GetArgs::Argv is not smart enough to coerce from string
        schema => 'str*',
        req => 1,
        pos => 0,
    },
    to_unit => {
        # schema => 'physical::unit', # IU hasn't been added
        schema => 'str*',
        pos => 1,
    },
);

$SPEC{convert_benzoate_unit} = {
    v => 1.1,
    summary => 'Convert a benzoate quantity from one unit to another',
    description => <<'_',

If target unit is not specified, will show all known conversions.

_
    args => {
        %args_common,
    },
    examples => [
        {args=>{quantity=>'ppm'}, summary=>'Show all possible conversions'},
        {args=>{quantity=>'250 ppm', to_unit=>'ppm-as-benzoic-acid'}, summary=>'Convert from ppm (as sodium benzoate) to ppm (as benzoic acid)'},
    ],
};
sub convert_benzoate_unit {
    require Physics::Unit;

    Physics::Unit::InitUnit(
        ['ppm'], '1 mg/kg',
        ['ppm-as-sodium-benzoate'], '1 mg/kg',
        ['ppm-as-potassium-benzoate'], '0.959326321395287 mg/kg', # potassium benzoate's molecular weight = 150.22
        ['ppm-as-benzoic-acid'], '1.18006878480183 mg/kg', # benzoic acid's molecular weight = 122.12, sodium benzoate's molecular weight = 144.11
    );

    my %args = @_;
    my $quantity = Physics::Unit->new($args{quantity});
    return [412, "Must be a Dimensionless quantity"] unless $quantity->type eq 'Dimensionless';

    if ($args{to_unit}) {
        my $new_amount = $quantity->convert($args{to_unit});
        return [200, "OK", $new_amount];
    } else {
        my @rows;
        for my $u (
            'ppm',
            'ppm-as-benzoic-acid',
            'ppm-as-sodium-benzoate',
            'ppm-as-potassium-benzoate',
        ) {
            push @rows, {
                unit => $u,
                amount => $quantity->convert($u),
            };
        }
        [200, "OK", \@rows];
    }
}

1;
# ABSTRACT: Utilities related to food additives in BPOM

__END__

=pod

=encoding UTF-8

=head1 NAME

App::BPOMUtils::Additives - Utilities related to food additives in BPOM

=head1 VERSION

This document describes version 0.002 of App::BPOMUtils::Additives (from Perl distribution App-BPOMUtils-Additives), released on 2023-02-01.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<convert-benzoate-unit>

=back

=head1 FUNCTIONS


=head2 convert_benzoate_unit

Usage:

 convert_benzoate_unit(%args) -> [$status_code, $reason, $payload, \%result_meta]

Convert a benzoate quantity from one unit to another.

Examples:

=over

=item * Show all possible conversions:

 convert_benzoate_unit(quantity => "ppm");

Result:

 [
   200,
   "OK",
   [
     { amount => 1, unit => "ppm" },
     { amount => 0.847408229824443, unit => "ppm-as-benzoic-acid" },
     { amount => 1, unit => "ppm-as-sodium-benzoate" },
     { amount => 1.04239816806606, unit => "ppm-as-potassium-benzoate" },
   ],
   {},
 ]

=item * Convert from ppm (as sodium benzoate) to ppm (as benzoic acid):

 convert_benzoate_unit(quantity => "250 ppm", to_unit => "ppm-as-benzoic-acid");

Result:

 [200, "OK", 211.852057456111, {}]

=back

If target unit is not specified, will show all known conversions.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<quantity>* => I<str>

(No description)

=item * B<to_unit> => I<str>

(No description)


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

Please visit the project's homepage at L<https://metacpan.org/release/App-BPOMUtils-Additives>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-BPOMUtils-Additives>.

=head1 SEE ALSO

L<App::BPOMUtils>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-BPOMUtils-Additives>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
