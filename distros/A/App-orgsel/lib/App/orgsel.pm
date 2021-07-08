package App::orgsel;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-03'; # DATE
our $DIST = 'App-orgsel'; # DIST
our $VERSION = '0.014'; # VERSION

use 5.010001;
use strict;
use warnings;

use App::CSelUtils;

our %SPEC;

$SPEC{orgsel} = {
    v => 1.1,
    summary => 'Select Org document elements using CSel (CSS-selector-like) syntax',
    args => {
        %App::CSelUtils::foosel_args_common,
    },
};
sub orgsel {
     App::CSelUtils::foosel(
        @_,

        code_read_tree => sub {
            require Org::Parser;
            my $args = shift;

            my $parser = Org::Parser->new;
            my $doc;
            if ($args->{file} eq '-') {
                binmode STDIN, ":encoding(utf8)";
                $doc = $parser->parse(join "", <>);
            } else {
                local $ENV{PERL_ORG_PARSER_CACHE} = $ENV{PERL_ORG_PARSER_CACHE} // 1;
                $doc = $parser->parse_file($args->{file});
            }
        },

        csel_opts => {class_prefixes=>["Org::Element"]},

        code_transform_node_actions => sub {
            my $args = shift;

            for my $action (@{$args->{node_actions}}) {
                if ($action eq 'dump') {
                    $action = 'dump:as_string';
                }
            }
        },
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

This document describes version 0.014 of App::orgsel (from Perl distribution App-orgsel), released on 2021-07-03.

=head1 SYNOPSIS

=head1 FUNCTIONS


=head2 orgsel

Usage:

 orgsel(%args) -> [$status_code, $reason, $payload, \%result_meta]

Select Org document elements using CSel (CSS-selector-like) syntax.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<expr> => I<str>

=item * B<file> => I<filename> (default: "-")

=item * B<node_actions> => I<array[str]> (default: ["print_as_string"])

Specify action(s) to perform on matching nodes.

Each action can be one of the following:

=over

=item * C<count> will print the number of matching nodes.

=item * C<print_method> will call on or more of the node object's methods and print the
result. Example:

print_method:as_string

=item * C<dump> will show a indented text representation of the node and its
descendants. Each line will print information about a single node: its class,
followed by the value of one or more attributes. You can specify which
attributes to use in a dot-separated syntax, e.g.:

dump:tag.id.class

which will result in a node printed like this:

HTML::Element tag=p id=undef class=undef

=back

By default, if no attributes are specified, C<id> is used. If the node class does
not support the attribute, or if the value of the attribute is undef, then
C<undef> is shown.

=over

=item * C<eval> will execute Perl code for each matching node. The Perl code will be
called with arguments: C<($node)>. For convenience, C<$_> is also locally set to
the matching node. Example in L<htmlsel> you can add this action:

eval:'print $_->tag'

which will print the tag name for each matching L<HTML::Element> node.

=back

=item * B<node_actions_on_descendants> => I<str> (default: "")

Specify how descendants should be actioned upon.

This option sets how node action is performed (See C<node_actions> option).

When set to '' (the default), then only matching nodes are actioned upon.

When set to 'descendants_depth_first', then after each matching node is actioned
upon by an action, the descendants of the matching node are also actioned, in
depth-first order. This option is sometimes necessary e.g. when your node's
C<as_string()> method shows a node's string representation that does not include
its descendants.

=item * B<select_action> => I<str> (default: "csel")

Specify how we should select nodes.

The default is C<csel>, which will select nodes from the tree using the CSel
expression. Note that the root node itself is not included. For more details on
CSel expression, refer to L<Data::CSel>.

C<root> will return a single node which is the root node.


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

This software is copyright (c) 2021, 2020, 2019, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
