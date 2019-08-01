package App::ppisel;

our $DATE = '2019-07-29'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use App::CSelUtils;
use Scalar::Util qw(blessed);

our %SPEC;

$SPEC{ppisel} = {
    v => 1.1,
    summary => 'Select PPI::Element nodes using CSel syntax',
    args => {
        %App::CSelUtils::foosel_args_common,
    },
};
sub ppisel {
    App::CSelUtils::foosel(
        @_,
        code_read_tree => sub {
            my $args = shift;

            my $src;
            if ($args->{file} eq '-') {
                binmode STDIN, ":encoding(utf8)";
                $src = join "", <>;
            } else {
                require File::Slurper;
                $src = File::Slurper::read_text($args->{file});
            }
            require PPI;
            my $doc = PPI::Document->new(\$src);

          PATCH: {
                last if $App::ppisel::patch_handle;
                require Module::Patch;
                $App::ppisel::patch_handle = Module::Patch::patch_package(
                    'PPI::Element', [
                        {
                            action   => 'add',
                            sub_name => 'children',
                            code     => sub {
                                $_[0]->{children} // [];
                            },
                        },
                    ], # patch actions
                ); # patch_package()
            } # PATCH
            $doc;
        }, # code_read_tree

        csel_opts => {class_prefixes=>['PPI::Token', 'PPI']},

        code_transform_node_actions => sub {
            my $args = shift;

            for my $action (@{$args->{node_actions}}) {
                if ($action eq 'print' || $action eq 'print_as_string') {
                    $action = 'print_method:content';
                } elsif ($action eq 'dump') {
                    $action = 'dump:content';
                }
            }
        }, # code_transform_node_actions
    );
}

1;
# ABSTRACT: Select PPI::Element nodes using CSel syntax

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ppisel - Select PPI::Element nodes using CSel syntax

=head1 VERSION

This document describes version 0.001 of App::ppisel (from Perl distribution App-ppisel), released on 2019-07-29.

=head1 SYNOPSIS

=head1 FUNCTIONS


=head2 ppisel

Usage:

 ppisel(%args) -> [status, msg, payload, meta]

Select PPI::Element nodes using CSel syntax.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<expr> => I<str>

=item * B<file> => I<str> (default: "-")

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

=back

which will result in a node printed like this:

 HTML::Element tag=p id=undef class=undef

By default, if no attributes are specified, C<id> is used. If the node class does
not support the attribute, or if the value of the attribute is undef, then
C<undef> is shown.

=item * B<select_action> => I<str> (default: "csel")

Specify how we should select nodes.

The default is C<csel>, which will select nodes from the tree using the CSel
expression. Note that the root node itself is not included. For more details on
CSel expression, refer to L<Data::CSel>.

C<root> will return a single node which is the root node.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-ppisel>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ppisel>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ppisel>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
