package App::PermuteNamed;

our $DATE = '2017-01-29'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{permute_named} = {
    v => 1.1,
    summary => 'Permute multiple-valued key-value pairs',
    description => <<'_',

This is a CLI for `Permute::Named::*` module (currently using
`Permute::Named::Iter`).

To enter a pair with multiple values, you enter a comma-separated list with the
first element is the key name and the rest are values.

The return will be array of hashes.

_
    args => {
        aoaos => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'aos',
            schema => ['array*', {
                min_len => 2,
                of => ['array*', {
                    min_len => 1,
                    of => 'str*',
                    'x.perl.coerce_rules' => ['str_comma_sep']
                }],
            }],
            req => 1,
            pos => 0,
            greedy => 1,
        },
        separator => {
            summary => 'Separator character to use',
            schema => 'str*',
            cmdline_aliases => {s => {}},
        },
    },
    examples => [
        {
            argv => ['bool,0,1','x,foo,bar,baz'],
        },
        {
            src => '[[prog]] bool,0,1 x,foo,bar,baz --format json-pretty --naked-res',
            src_plang => 'bash',
            summary => 'Like previous example, but outputs JSON',
        },
    ],
};
sub permute_named {
    require Permute::Named::Iter;

    my %args = @_;
    my $sep = $args{separator};

    my @fields;
    my @permute;
    for my $aos (@{$args{aoaos}}) {
        my $k = shift @$aos;
        push @permute, $k, $aos;
        push @fields, $k
    }

    my $resmeta = {};
    my $iter = Permute::Named::Iter::permute_named_iter(@permute);
    my @res;
    while (my $h = $iter->()) {
        if (defined $sep) {
            push @res, join($sep, @{$h}{@fields});
        } else {
            push @res, $h;
        }
    }

    unless (defined $sep) {
        $resmeta->{'table.fields'} = \@fields;
    }

    [200, "OK", \@res, $resmeta];
}

1;
# ABSTRACT: Permute multiple-valued key-value pairs

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PermuteNamed - Permute multiple-valued key-value pairs

=head1 VERSION

This document describes version 0.003 of App::PermuteNamed (from Perl distribution App-PermuteNamed), released on 2017-01-29.

=head1 FUNCTIONS


=head2 permute_named(%args) -> [status, msg, result, meta]

Permute multiple-valued key-value pairs.

Examples:

=over

=item * Example #1:

 permute_named( aoaos => ["bool,0,1", "x,foo,bar,baz"]);

Result:

 [
   200,
   "OK",
   [
     { bool => 0, x => "foo" },
     { bool => 0, x => "bar" },
     { bool => 0, x => "baz" },
     { bool => 1, x => "foo" },
     { bool => 1, x => "bar" },
     { bool => 1, x => "baz" },
   ],
   { "table.fields" => ["bool", "x"] },
 ]

=back

This is a CLI for C<Permute::Named::*> module (currently using
C<Permute::Named::Iter>).

To enter a pair with multiple values, you enter a comma-separated list with the
first element is the key name and the rest are values.

The return will be array of hashes.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<aoaos>* => I<array[array[str]]>

=item * B<separator> => I<str>

Separator character to use.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-PermuteNamed>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-PermuteNamed>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-PermuteNamed>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Permute::Named>, L<Permute::Named::Iter>, L<PERLANCAR::Permute::Named>.

L<Set::Product>, L<Set::CrossProduct> (see more similar modules in the POD of
Set::Product) and CLI scripts <cross>, L<cross-pericmd>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
