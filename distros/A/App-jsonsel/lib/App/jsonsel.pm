package App::jsonsel;

our $DATE = '2020-04-29'; # DATE
our $VERSION = '0.007'; # VERSION

use 5.010001;
use strict;
use warnings;

use App::CSelUtils;

our %SPEC;

sub _encode_json {
    state $json = do {
        require JSON::MaybeXS;
        JSON::MaybeXS->new(allow_nonref=>1, canonical=>1);
    };
    $json->encode($_[0]);
}

sub _decode_json {
    state $json = do {
        require JSON::MaybeXS;
        JSON::MaybeXS->new(allow_nonref=>1, canonical=>1);
    };
    $json->decode($_[0]);
}

$SPEC{jsonsel} = {
    v => 1.1,
    summary => 'Select JSON elements using CSel (CSS-selector-like) syntax',
    args => {
        %App::CSelUtils::foosel_args_common,
    },
};
sub jsonsel {
    require JSON::MaybeXS;

    App::CSelUtils::foosel(
        @_,

        code_read_tree => sub {
            my $args = shift;
            my $data;
            if ($args->{file} eq '-') {
                binmode STDIN, ":encoding(utf8)";
                $data = _decode_json(join "", <>);
            } else {
                require File::Slurper;
                $data = _decode_json(File::Slurper::read_text($args->{file}));
            }

            require Data::CSel::WrapStruct;
            my $tree = Data::CSel::WrapStruct::wrap_struct($data);
            $tree;
        },

        csel_opts => {class_prefixes=>['Data::CSel::WrapStruct']},

        code_transform_node_actions => sub {
            my $args = shift;

            for my $action (@{ $args->{node_actions} }) {
                if ($action eq 'print' || $action eq 'print_as_string') {
                    $action = 'print_func_or_meth:meth:value.func:App::jsonsel::_encode_json';
                } elsif ($action eq 'dump') {
                    $action = 'dump:value';
                }
            }
        },
    );
}

1;
# ABSTRACT: Select JSON elements using CSel (CSS-selector-like) syntax

__END__

=pod

=encoding UTF-8

=head1 NAME

App::jsonsel - Select JSON elements using CSel (CSS-selector-like) syntax

=head1 VERSION

This document describes version 0.007 of App::jsonsel (from Perl distribution App-jsonsel), released on 2020-04-29.

=head1 SYNOPSIS

=head1 FUNCTIONS


=head2 jsonsel

Usage:

 jsonsel(%args) -> [status, msg, payload, meta]

Select JSON elements using CSel (CSS-selector-like) syntax.

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

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-jsonsel>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-jsonsel>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-jsonsel>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
