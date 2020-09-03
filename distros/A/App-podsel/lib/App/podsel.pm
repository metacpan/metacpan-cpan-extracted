package App::podsel;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-29'; # DATE
our $DIST = 'App-podsel'; # DIST
our $VERSION = '0.008'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use App::CSelUtils;
use Module::Patch qw(patch_package);

our %SPEC;

our @patch_handles;
sub _patch {
    my $mod = shift;
    my $add_empty_children = shift;
    (my $mod_pm = "$mod.pm") =~ s!::!/!g;
    require $mod_pm;
    push @patch_handles, patch_package($mod, [
        ({action => 'add', sub_name => 'children', code => sub { [] }}) x !!$add_empty_children,
        {action => 'add', sub_name => 'parent'  , code => sub { $_[0]{_parent} }},
    ]);
}

sub _set_parent {
    my ($node, $parent) = @_;
    $node->{_parent} //= $parent;
    if ($node->{children} && @{ $node->{children} }) {
        for (@{ $node->{children} }) {
            _set_parent($_, $node);
        }
    }
}

$SPEC{podsel} = {
    v => 1.1,
    summary => 'Select Pod::Elemental nodes using CSel syntax',
    args => {
        %App::CSelUtils::foosel_args_common,
        transforms => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'transform',
            summary => "Apply one or more Pod::Elemental::Transform's",
            schema => [
                'array*', {
                    of=>['str*', in=>['Pod5','Nester']],
                    #'x.perl.coerce_rules' => ['From_str::comma_sep'],
                }],
            cmdline_aliases => {
                t => {},
                5 => {is_flag=>1, summary=>'Shortcut for -t Pod5 -t Nester', code=>sub { push @{ $_[0]{transforms} }, 'Pod5', 'Nester' }},
            },
            description => <<'_',

**TRANSFORMS**

First of all, by default, the "stock" Pod::Elemental parser will be generic and
often not very helpful in parsing your typical POD (Perl 5 variant) documents.
You often want to add:

    -t Pod5 -t Nester

or -5 for short, which is equivalent to the above. Except in some simple cases.
See examples below.

The following are available transforms:

* Pod5

Equivalent to this:

    Pod::Elemental::Transformer::Pod5->new->transform_node($tree);

* Nester

Equivalent to this:

    my $nester;

    $nester = Pod::Elemental::Transformer::Nester->new({
        top_selector      => Pod::Elemental::Selectors::s_command('head3'),
        content_selectors => [
            Pod::Elemental::Selectors::s_command([ qw(head4) ]),
            Pod::Elemental::Selectors::s_flat(),
        ],
    });
    $nester->new->transform_node($tree);

    $nester = Pod::Elemental::Transformer::Nester->new({
        top_selector      => Pod::Elemental::Selectors::s_command('head2'),
        content_selectors => [
            Pod::Elemental::Selectors::s_command([ qw(head3 head4) ]),
            Pod::Elemental::Selectors::s_flat(),
        ],
    });
    $nester->new->transform_node($tree);

    $nester = Pod::Elemental::Transformer::Nester->new({
        top_selector      => Pod::Elemental::Selectors::s_command('head1'),
        content_selectors => [
            Pod::Elemental::Selectors::s_command([ qw(head2 head3 head4) ]),
            Pod::Elemental::Selectors::s_flat(),
        ],
    });
    $nester->new->transform_node($tree);

**EXAMPLES**

Note: <prog:pmpath> is a CLI utility that returns the path of a locally
installed Perl module. It's distributed in <pm:App::PMUtils> distribution.

Select all head1 commands (only print the command lines and not the content):

    % podsel `pmpath strict` 'Command[command=head1]'
    =head1 NAME

    =head1 SYNOPSIS

    =head1 DESCRIPTION

    =head1 HISTORY

Select all head1 commands that contain "SYN" in them (only print the command
lines and not the content):

    % podsel `pmpath strict` 'Command[command=head1][content =~ /synopsis/i]'
    =head1 SYNOPSIS

Select all head1 commands that contain "SYN" in them (but now also print the
content; note now the use of the `Nested` class selector and the `-5` flag to
create a nested document tree instead of a flat one):

    % podsel -5 `pmpath strict` 'Nested[command=head1][content =~ /synopsis/i]'
    =head1 SYNOPSIS

        use strict;

        use strict "vars";
        use strict "refs";
        use strict "subs";

        use strict;
        no strict "vars";

List of head commands in POD of <pm:List::Util>:

    % podsel `pmpath List::Util` 'Command[command =~ /head/]'
    =head1 NAME

    =head1 SYNOPSIS

    =head1 DESCRIPTION

    =head1 LIST-REDUCTION FUNCTIONS

    =head2 reduce

    =head2 reductions

    ...

    =head1 KEY/VALUE PAIR LIST FUNCTIONS

    =head2 pairs

    =head2 unpairs

    =head2 pairkeys

    =head2 pairvalues

    ...

List only key/value pair list functions and not list-reduction ones:

    % podsel -5 `pmpath List::Util` 'Nested[command=head1][content =~ /pair/i] Nested[command=head2]' --print-method content
    pairs
    unpairs
    pairkeys
    pairvalues
    pairgrep
    pairfirst
    pairmap

_
        },
    },
};
sub podsel {
    my %podsel_args = @_;

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
            require Pod::Elemental;
            my $doc = Pod::Elemental->read_string($src);

            for my $transform (@{ $podsel_args{transforms} // [] }) {
                if ($transform eq 'Pod5') {
                    log_trace "Transforming POD with Pod5 ...";
                    require Pod::Elemental::Transformer::Pod5;
                    Pod::Elemental::Transformer::Pod5->new->transform_node($doc);
                } elsif ($transform eq 'Nester') {
                    log_trace "Transforming POD with Nester ...";
                    require Pod::Elemental::Transformer::Nester;
                    require Pod::Elemental::Selectors;
                    my $t;

                    $t = Pod::Elemental::Transformer::Nester->new({
                        top_selector      => Pod::Elemental::Selectors::s_command('head3'),
                        content_selectors => [
                            Pod::Elemental::Selectors::s_command([ qw(head4) ]),
                            Pod::Elemental::Selectors::s_flat(),
                        ],
                    });
                    $t->transform_node($doc);

                    $t = Pod::Elemental::Transformer::Nester->new({
                        top_selector      => Pod::Elemental::Selectors::s_command('head2'),
                        content_selectors => [
                            Pod::Elemental::Selectors::s_command([ qw(head3 head4) ]),
                            Pod::Elemental::Selectors::s_flat(),
                        ],
                    });
                    $t->transform_node($doc);

                    if (1) {
                        $t = Pod::Elemental::Transformer::Nester->new({
                            top_selector      => Pod::Elemental::Selectors::s_command('head1'),
                            content_selectors => [
                                Pod::Elemental::Selectors::s_command([ qw(head2 head3 head4) ]),
                                Pod::Elemental::Selectors::s_flat(),
                            ],
                        });
                        $t->transform_node($doc);
                    }

                } else {
                    die "Unknown transform '$transform'";
                }
            }

          PATCH: {
                last if @patch_handles;
                _patch('Pod::Elemental::Document', 0);
                _patch('Pod::Elemental::Element::Generic::Command', 1);
                _patch('Pod::Elemental::Element::Generic::Blank', 1);
                _patch('Pod::Elemental::Element::Generic::Text', 1);
            }

            $doc;
        }, # code_read_tree

        csel_opts => {
            class_prefixes=>[
                'Pod::Elemental::Element::Generic',
                'Pod::Elemental::Element::Pod5',
                'Pod::Elemental::Element',
                'Pod::Elemental',
            ]},

        code_transform_node_actions => sub {
            my $args = shift;

            for my $action (@{$args->{node_actions}}) {
                if ($action eq 'print' || $action eq 'print_as_string') {
                    $action = 'print_method:as_pod_string';
                } elsif ($action eq 'dump') {
                    $action = 'dump:as_pod_string';
                }
            }
        }, # code_transform_node_actions
    );
}

1;
# ABSTRACT: Select Pod::Elemental nodes using CSel syntax

__END__

=pod

=encoding UTF-8

=head1 NAME

App::podsel - Select Pod::Elemental nodes using CSel syntax

=head1 VERSION

This document describes version 0.008 of App::podsel (from Perl distribution App-podsel), released on 2020-04-29.

=head1 SYNOPSIS

=head1 FUNCTIONS


=head2 podsel

Usage:

 podsel(%args) -> [status, msg, payload, meta]

Select Pod::Elemental nodes using CSel syntax.

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

=item * B<transforms> => I<array[str]>

Apply one or more Pod::Elemental::Transform's.

B<TRANSFORMS>

First of all, by default, the "stock" Pod::Elemental parser will be generic and
often not very helpful in parsing your typical POD (Perl 5 variant) documents.
You often want to add:

 -t Pod5 -t Nester

or -5 for short, which is equivalent to the above. Except in some simple cases.
See examples below.

The following are available transforms:

=over

=item * Pod5

=back

Equivalent to this:

 Pod::Elemental::Transformer::Pod5->new->transform_node($tree);

=over

=item * Nester

=back

Equivalent to this:

 my $nester;
 
 $nester = Pod::Elemental::Transformer::Nester->new({
     top_selector      => Pod::Elemental::Selectors::s_command('head3'),
     content_selectors => [
         Pod::Elemental::Selectors::s_command([ qw(head4) ]),
         Pod::Elemental::Selectors::s_flat(),
     ],
 });
 $nester->new->transform_node($tree);
 
 $nester = Pod::Elemental::Transformer::Nester->new({
     top_selector      => Pod::Elemental::Selectors::s_command('head2'),
     content_selectors => [
         Pod::Elemental::Selectors::s_command([ qw(head3 head4) ]),
         Pod::Elemental::Selectors::s_flat(),
     ],
 });
 $nester->new->transform_node($tree);
 
 $nester = Pod::Elemental::Transformer::Nester->new({
     top_selector      => Pod::Elemental::Selectors::s_command('head1'),
     content_selectors => [
         Pod::Elemental::Selectors::s_command([ qw(head2 head3 head4) ]),
         Pod::Elemental::Selectors::s_flat(),
     ],
 });
 $nester->new->transform_node($tree);

B<EXAMPLES>

Note: L<pmpath> is a CLI utility that returns the path of a locally
installed Perl module. It's distributed in L<App::PMUtils> distribution.

Select all head1 commands (only print the command lines and not the content):

 % podsel C<pmpath strict> 'Command[command=head1]'
 =head1 NAME
 
 =head1 SYNOPSIS
 
 =head1 DESCRIPTION
 
 =head1 HISTORY

Select all head1 commands that contain "SYN" in them (only print the command
lines and not the content):

 % podsel C<pmpath strict> 'Command[command=head1][content =~ /synopsis/i]'
 =head1 SYNOPSIS

Select all head1 commands that contain "SYN" in them (but now also print the
content; note now the use of the C<Nested> class selector and the C<-5> flag to
create a nested document tree instead of a flat one):

 % podsel -5 C<pmpath strict> 'Nested[command=head1][content =~ /synopsis/i]'
 =head1 SYNOPSIS
 
     use strict;
 
     use strict "vars";
     use strict "refs";
     use strict "subs";
 
     use strict;
     no strict "vars";

List of head commands in POD of L<List::Util>:

 % podsel C<pmpath List::Util> 'Command[command =~ /head/]'
 =head1 NAME
 
 =head1 SYNOPSIS
 
 =head1 DESCRIPTION
 
 =head1 LIST-REDUCTION FUNCTIONS
 
 =head2 reduce
 
 =head2 reductions
 
 ...
 
 =head1 KEY/VALUE PAIR LIST FUNCTIONS
 
 =head2 pairs
 
 =head2 unpairs
 
 =head2 pairkeys
 
 =head2 pairvalues
 
 ...

List only key/value pair list functions and not list-reduction ones:

 % podsel -5 C<pmpath List::Util> 'Nested[command=head1][content =~ /pair/i] Nested[command=head2]' --print-method content
 pairs
 unpairs
 pairkeys
 pairvalues
 pairgrep
 pairfirst
 pairmap


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

Please visit the project's homepage at L<https://metacpan.org/release/App-podsel>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-podsel>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-podsel>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
