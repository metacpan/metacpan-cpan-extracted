package App::DumpPERLANCARSampleTree;

our $DATE = '2016-04-07'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use PERLANCAR::Tree::Examples qw(gen_sample_data);

our %SPEC;

$SPEC{dump_perlancar_sample_tree} = {
    v => 1.1,
    summary => 'Dump tree from PERLANCAR::Tree::Examples',
    args => {
        size => {
            schema => $PERLANCAR::Tree::Examples::SPEC{gen_sample_data}{args}{size}{schema},
            req => 1,
            pos => 0,
        },
        backend => {
            schema => $PERLANCAR::Tree::Examples::SPEC{gen_sample_data}{args}{backend}{schema},
        },
    },
    result_naked => 1,
    'cmdline.skip_format' => 1,
};
sub dump_perlancar_sample_tree {
    require Tree::Dump;

    my %args = @_;

    Tree::Dump::tdmp(gen_sample_data(
        size => $args{size},
        backend => $args{backend},
    ));
}

1;
# ABSTRACT: Dump tree from PERLANCAR::Tree::Examples

__END__

=pod

=encoding UTF-8

=head1 NAME

App::DumpPERLANCARSampleTree - Dump tree from PERLANCAR::Tree::Examples

=head1 VERSION

This document describes version 0.003 of App::DumpPERLANCARSampleTree (from Perl distribution App-DumpPERLANCARSampleTree), released on 2016-04-07.

=head1 FUNCTIONS


=head2 dump_perlancar_sample_tree(%args) -> any

Dump tree from PERLANCAR::Tree::Examples.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<backend> => I<str>

=item * B<size>* => I<str>

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-DumpPERLANCARSampleTree>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-DumpPERLANCARSampleTree>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-DumpPERLANCARSampleTree>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
