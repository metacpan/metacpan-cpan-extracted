package App::orgsel;

our $DATE = '2016-09-01'; # DATE
our $VERSION = '0.006'; # VERSION

use 5.010001;
use strict;
use warnings;

use App::CSelUtils;
use Scalar::Util qw(refaddr);

our %SPEC;

$SPEC{orgsel} = {
    v => 1.1,
    summary => 'Select Org document elements using CSel (CSS-selector-like) syntax',
    args => {
        %App::CSelUtils::foosel_common_args,
        %App::CSelUtils::foosel_tree_action_args,
    },
};
sub orgsel {
    my %args = @_;

    # parse first so we can bail early on error without having to read the input
    require Data::CSel;
    my $expr = $args{expr};
    Data::CSel::parse_csel($expr)
          or return [400, "Invalid CSel expression '$expr'"];

    require Org::Parser;
    my $parser = Org::Parser->new;

    my $doc;
    if ($args{file} eq '-') {
        binmode STDIN, ":utf8";
        $doc = $parser->parse(join "", <>);
    } else {
        local $ENV{PERL_ORG_PARSER_CACHE} = $ENV{PERL_ORG_PARSER_CACHE} // 1;
        $doc = $parser->parse_file($args{file});
    }

    my @matches = Data::CSel::csel(
        {class_prefixes=>["Org::Element"]}, $expr, $doc);

    # skip root node itself
    @matches = grep { refaddr($_) ne refaddr($doc) } @matches
        unless @matches <= 1;

    App::CSelUtils::do_actions_on_nodes(
        nodes   => \@matches,
        actions => $args{actions},
    );
}

1;
# ABSTRACT: Select Org document elements using CSel (CSS-selector-like) syntax

__END__

=pod

=encoding UTF-8

=head1 NAME

App::orgsel - Select Org document elements using CSel (CSS-selector-like) syntax

=head1 VERSION

This document describes version 0.006 of App::orgsel (from Perl distribution App-orgsel), released on 2016-09-01.

=head1 SYNOPSIS

=head1 FUNCTIONS


=head2 orgsel(%args) -> [status, msg, result, meta]

Select Org document elements using CSel (CSS-selector-like) syntax.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<actions> => I<array[str]> (default: ["print_as_string"])

Specify action(s) to perform on matching nodes.

=item * B<expr>* => I<str>

=item * B<file> => I<str> (default: "-")

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

Please visit the project's homepage at L<https://metacpan.org/release/App-orgsel>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-orgsel>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-orgsel>

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
