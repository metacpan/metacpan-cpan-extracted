package App::ShowPERLANCARSampleHTMLTree;

our $DATE = '2016-04-12'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use PERLANCAR::HTML::Tree::Examples qw(gen_sample_data);

our %SPEC;

$SPEC{show_perlancar_sample_html_tree} = {
    v => 1.1,
    summary => 'Show sample HTML from PERLANCAR::HTML::Tree::Examples',
    args => {
        size => {
            schema => $PERLANCAR::HTML::Tree::Examples::SPEC{gen_sample_data}{args}{size}{schema},
            req => 1,
            pos => 0,
        },
    },
    result_naked => 1,
    'cmdline.skip_format' => 1,
};
sub show_perlancar_sample_html_tree {
    my %args = @_;

    gen_sample_data(size => $args{size});
}

1;
# ABSTRACT: Show sample HTML from PERLANCAR::HTML::Tree::Examples

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ShowPERLANCARSampleHTMLTree - Show sample HTML from PERLANCAR::HTML::Tree::Examples

=head1 VERSION

This document describes version 0.002 of App::ShowPERLANCARSampleHTMLTree (from Perl distribution App-ShowPERLANCARSampleHTMLTree), released on 2016-04-12.

=head1 FUNCTIONS


=head2 show_perlancar_sample_html_tree(%args) -> any

Show sample HTML from PERLANCAR::HTML::Tree::Examples.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<size>* => I<str>

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-ShowPERLANCARSampleHTMLTree>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ShowPERLANCARSampleHTMLTree>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ShowPERLANCARSampleHTMLTree>

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
