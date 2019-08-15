package App::htmlsel;

our $DATE = '2019-08-09'; # DATE
our $VERSION = '0.009'; # VERSION

use 5.010001;
use strict;
use warnings;

use App::CSelUtils;
use Scalar::Util qw(blessed);

our %SPEC;

$SPEC{htmlsel} = {
    v => 1.1,
    summary => 'Select HTML::Element nodes using CSel syntax',
    args => {
        %App::CSelUtils::foosel_args_common,
    },
};
sub htmlsel {
    App::CSelUtils::foosel(
        @_,
        code_read_tree => sub {
            my $args = shift;

            require HTML::TreeBuilder;
            my $content;
            if ($args->{file} eq '-') {
                binmode STDIN, ":encoding(utf8)";
                $content = join "", <STDIN>;
            } else {
                require File::Slurper;
                $content = File::Slurper::read_text($args->{file});
            }
            my $tree = HTML::TreeBuilder->new->parse_content($content);

          PATCH: {
                last if $App::htmlsel::patch_handle;
                require Module::Patch;
                $App::htmlsel::patch_handle = Module::Patch::patch_package(
                    'HTML::Element', [
                        {
                            action   => 'add',
                            sub_name => 'children',
                            code     => sub {
                                my @children =
                                    grep { blessed($_) && $_->isa('HTML::Element') }
                                    @{ $_[0]{_content} };
                                #use DD; dd \@children;
                                @children;
                            },
                        },
                        {
                            action   => 'add',
                            sub_name => 'class',
                            code     => sub {
                                $_[0]{class};
                            },
                        },
                    ], # patch actions
                ); # patch_package()
            } # PATCH
            $tree;
        }, # code_read_tree

        csel_opts => {class_prefixes=>['HTML']},

        code_transform_node_actions => sub {
            my $args = shift;

            for my $action (@{$args->{node_actions}}) {
                if ($action eq 'print' || $action eq 'print_as_string') {
                    $action = 'print_method:as_HTML';
                } elsif ($action eq 'dump') {
                    #$action = 'dump:tag.class.id';
                    $action = 'dump:as_HTML';
                }
            }
        }, # code_transform_actions
    );
}

1;
# ABSTRACT: Select HTML::Element nodes using CSel syntax

__END__

=pod

=encoding UTF-8

=head1 NAME

App::htmlsel - Select HTML::Element nodes using CSel syntax

=head1 VERSION

This document describes version 0.009 of App::htmlsel (from Perl distribution App-htmlsel), released on 2019-08-09.

=head1 SYNOPSIS

=head1 FUNCTIONS


=head2 htmlsel

Usage:

 htmlsel(%args) -> [status, msg, payload, meta]

Select HTML::Element nodes using CSel syntax.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-htmlsel>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-htmlsel>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-htmlsel>

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
