package App::CrossPericmd;

our $DATE = '2016-09-26'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{cross} = {
    v => 1.1,
    summary => 'Output the cross product of two or more sets',
    description => <<'_',

This is more or less the same as the `cross` CLI on CPAN (from
`Set::CrossProduct`) except that this CLI is written using the
`Perinci::CmdLine` framework. It returns table data which might be more easily
consumed by other tools.

_
    args => {
        aoaos => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'aos',
            schema => ['array*', {
                min_len => 2,
                of => ['array*', {
                    of => 'str*',
                    'x.perl.coerce_rules' => ['str_comma_sep']
                }],
            }],
            req => 1,
            pos => 0,
            greedy => 1,
        },
    },
    examples => [
        {
            argv => ['1,2,3','4,5'],
        },
        {
            src => '[[prog]] 1,2,3 4,5 --json',
            src_plang => 'bash',
            summary => 'Same as previous example, but output JSON',
        },
        {
            src => '[[prog]] 1,2 foo,bar --format json-pretty --naked-res',
            src_plang => 'bash',
        },
    ],
    links => [
        {url=>'prog:cross', summary => 'The original script'},
        {url=>'prog:setop', summary => 'Can also do cross product aside from other set operations'},
    ],
};
sub cross {
    require Set::CrossProduct;

    my %args = @_;

    my $iter = Set::CrossProduct->new($args{aoaos});
    my @res;
    while (my $tuple = $iter->get) {
        push @res, $tuple;
    }

    [200, "OK", \@res];
}

1;
# ABSTRACT: Output the cross product of two or more sets

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CrossPericmd - Output the cross product of two or more sets

=head1 VERSION

This document describes version 0.002 of App::CrossPericmd (from Perl distribution App-CrossPericmd), released on 2016-09-26.

=head1 FUNCTIONS


=head2 cross(%args) -> [status, msg, result, meta]

Output the cross product of two or more sets.

Examples:

=over

=item * Example #1:

 cross( aoaos => ["1,2,3", "4,5"]);

Result:

 [200, "OK", [[1, 4], [1, 5], [2, 4], [2, 5], [3, 4], [3, 5]], {}]

=back

This is more or less the same as the C<cross> CLI on CPAN (from
C<Set::CrossProduct>) except that this CLI is written using the
C<Perinci::CmdLine> framework. It returns table data which might be more easily
consumed by other tools.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<aoaos>* => I<array[array[str]]>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-CrossPericmd>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CrossPericmd>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CrossPericmd>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO


L<cross>. The original script.

L<setop>. Can also do cross product aside from other set operations.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
