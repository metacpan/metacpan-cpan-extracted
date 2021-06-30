package App::CSelUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-27'; # DATE
our $DIST = 'App-CSelUtils'; # DIST
our $VERSION = '0.088'; # VERSION

use 5.010001;
use strict;
use warnings;

use Data::Dmp;
use Scalar::Util qw(refaddr);

our %SPEC;

# arguments for utilities like orgsel, htmlsel

our %foosel_args_common = (
    select_action => {
        summary => 'Specify how we should select nodes',
        schema => ['str*', in=>['csel', 'root']],
        default => 'csel',
        description => <<'_',

The default is `csel`, which will select nodes from the tree using the CSel
expression. Note that the root node itself is not included. For more details on
CSel expression, refer to <pm:Data::CSel>.

`root` will return a single node which is the root node.

_
        cmdline_aliases => {
            root => {is_flag=>1, summary=>'Shortcut for --select-action=root', code=>sub {$_[0]{select_action} = 'root'}},
        },
    },
    expr => {
        schema => 'str*',
        pos => 1,
    },
    file => {
        schema => 'filename*',
        pos => 0,
        default => '-',
    },
    node_actions => {
        summary => 'Specify action(s) to perform on matching nodes',
        'x.name.is_plural' => 1,
        schema => ['array*', {
            of => ['str*', {
                match => qr/\A(dump(:\w+(\.\w+)*)?|eval:.+|print_as_string|print_method:\w+(\.\w+)*|count)\z/,
            }],
        }],
        default => ['print_as_string'],
        cmdline_aliases => {
            print => {
                summary => 'Shortcut for --node-action print_as_string',
                is_flag => 1,
                code => sub {
                    my $args = shift;
                    $args->{node_actions} //= [];
                    my $actions = $args->{node_actions};
                    unless (grep {$_ eq 'print_as_string'} @$actions) {
                        push @$actions, 'print_as_string';
                    }
                },
            },
            count => {
                summary => 'Shortcut for --node-action count',
                is_flag => 1,
                code => sub {
                    my $args = shift;
                    $args->{node_actions} //= [];
                    my $actions = $args->{node_actions};
                    unless (grep {$_ eq 'count'} @$actions) {
                        push @$actions, 'count';
                    }
                },
            },
            dump => {
                summary => 'Shortcut for --node-action dump',
                is_flag => 1,
                code => sub {
                    my $args = shift;
                    $args->{node_actions} //= [];
                    my $actions = $args->{node_actions};
                    unless (grep {$_ eq 'dump'} @$actions) {
                        push @$actions, 'dump';
                    }
                },
            },
            eval => {
                summary => '--eval E is shortcut for --action eval:E',
                code => sub {
                    my ($args, $val) = @_;
                    $args->{node_actions} //= [];
                    push @{ $args->{node_actions} }, "eval:$val";
                },
            },
            print_method => {
                summary => '--print-method M is shortcut for --node-action print_method:M',
                code => sub {
                    my ($args, $val) = @_;
                    $args->{node_actions} //= [];
                    push @{ $args->{node_actions} }, "print_method:$val";
                },
            },
        },
        description => <<'_',

Each action can be one of the following:

* `count` will print the number of matching nodes.

* `print_method` will call on or more of the node object's methods and print the
  result. Example:

    print_method:as_string

* `dump` will show a indented text representation of the node and its
  descendants. Each line will print information about a single node: its class,
  followed by the value of one or more attributes. You can specify which
  attributes to use in a dot-separated syntax, e.g.:

    dump:tag.id.class

  which will result in a node printed like this:

    HTML::Element tag=p id=undef class=undef

By default, if no attributes are specified, `id` is used. If the node class does
not support the attribute, or if the value of the attribute is undef, then
`undef` is shown.

* `eval` will execute Perl code for each matching node. The Perl code will be
  called with arguments: `($node)`. For convenience, `$_` is also locally set to
  the matching node. Example in <prog:htmlsel> you can add this action:

    eval:'print $_->tag'

  which will print the tag name for each matching <pm:HTML::Element> node.

_
    },
    node_actions_on_descendants => {
        summary => 'Specify how descendants should be actioned upon',
        schema => ['str*', in=>['', 'descendants_depth_first']],
        default => '',
        description => <<'_',

This option sets how node action is performed (See `node_actions` option).

When set to '' (the default), then only matching nodes are actioned upon.

When set to 'descendants_depth_first', then after each matching node is actioned
upon by an action, the descendants of the matching node are also actioned, in
depth-first order. This option is sometimes necessary e.g. when your node's
`as_string()` method shows a node's string representation that does not include
its descendants.

_
        cmdline_aliases => {R=>{is_flag=>1, summary=>'Shortcut for --node-action-on-descendants=descendants_depth_first', code=>sub { $_[0]{node_actions_on_descendants} = 'descendants_depth_first'}}},
    },
);

$SPEC{parse_csel} = {
    v => 1.1,
    summary => 'Parse CSel expression',
    args => {
        expr => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
    'cmdline.default_format' => 'json-pretty',
};
sub parse_csel {
    require Data::CSel;
    my %args = @_;
    [200, "OK", Data::CSel::parse_csel($args{expr})];
}

sub _elide {
    my ($str, $len) = @_;
    return $str if length($str) <= $len;
    my $show_len = $len - 3;
    $show_len = 0 if $show_len < 0;
    substr($str, 0, $show_len) . ' ..';
}

sub foosel {
    my %args = @_;

    my $select_action = $args{select_action} // 'csel';
    my $expr = $args{expr};
    my $node_actions = $args{node_actions};
    my $node_actions_on_descendants = $args{node_actions_on_descendants} // '';

  PARSE_CSEL: {
        unless ($select_action eq 'root') {
            defined $expr or return [400, "Please specify a CSel expression"];
            # parse first so we can bail early on error without having to read
            # the input
            require Data::CSel;
            Data::CSel::parse_csel($expr)
                  or return [400, "Invalid CSel expression '$expr'"];
        }
    }

    my $tree;
  READ_TREE: {
        $tree = $args{code_read_tree}->(\%args);
    }

    my @matches;
  SELECT_NODES: {
        if ($select_action eq 'root') {
            @matches = ($tree);
        } else {
            require Data::CSel;
            @matches = Data::CSel::csel($args{csel_opts} // {}, $expr, $tree);

            # skip root node itself to avoid duplication
            @matches = grep { refaddr($_) ne refaddr($tree) } @matches
                unless @matches <= 1;
        }
    }

  TRANSFORM_NODE_ACTIONS: {
        $args{code_transform_node_actions}->(\%args)
            if $args{code_transform_node_actions};
    }

    my $res = [200, "OK"];
  PERFORM_NODE_ACTIONS: {
        my $actions = $args{node_actions};

        my @action_targets;
        if ($node_actions_on_descendants) {
            require Code::Includable::Tree::NodeMethods;
            @action_targets = map {
                ($_, Code::Includable::Tree::NodeMethods::descendants_depth_first($_))
            } @matches;
        } else {
            @action_targets = @matches;
        }

        for my $action (@$actions) {
            if ($action =~ /\Adump(?::(.+))?/) {
                my $cols = $ENV{COLUMNS} // do {
                    my $cols;
                    eval {
                        require Term::Size;
                        ($cols) = Term::Size::chars(*STDOUT{IO});
                    };
                    $cols;
                } // 80;

                require Tree::To::TextLines;
                my @attrs = split /\./, $1;
                @attrs = ('id') unless @attrs;
                push @{ $res->[2] }, map {
                    Tree::To::TextLines::render_tree_as_text({
                        show_guideline  => 1,
                        on_show_node    => sub {
                            my ($node, $level, $seniority, $is_last_child, $opts) = @_;
                            my $str = ref($node)." ".
                                join(", ", map {
                                    (@attrs > 1 ? "$_=":"") .
                                        dmp(($node->can($_) ? $node->$_ : undef) // 'undef')
                                    } @attrs);
                            _elide($str, $cols - $level*4);
                        },
                    }, $_)
                  } @action_targets;
            } elsif ($action =~ /\Aeval:(.+)/) {
                my $string_code = $1;
                my $compiled_code =
                    eval "package main; no strict; no warnings; sub { $string_code }";
                if ($@) {
                    die "Can't compile code in eval: $@\n";
                }
                for my $node (@action_targets) {
                    local $_ = $node;
                    $compiled_code->($node);
                }
            } elsif ($action eq 'count') {
                if (@$actions == 1) {
                    $res->[2] = ~~@matches;
                } else {
                    push @{ $res->[2] }, ~~@matches;
                }
            } elsif ($action eq 'print_as_string') {
                push @{ $res->[2] }, map {$_->as_string} @action_targets;
            } elsif ($action =~ /\Aprint_method:(.+)\z/) {
                my @meths = split /\./, $1;
                for my $node (@action_targets) {
                    my $node_res = $node;
                    for my $meth (@meths) {
                        eval { $node_res = $node_res->$meth };
                        if ($@) {
                            $node_res = undef;
                            last;
                        }
                    }
                    push @{ $res->[2] }, $node_res;
                }
            } elsif ($action =~ /\Aprint_func:(.+)\z/) {
                no strict 'refs';
                my @funcs = split /\./, $1;
                for my $node (@action_targets) {
                    my $node_res = $node;
                    for my $func (@funcs) {
                        eval { $node_res = &{$func}($node_res) };
                        if ($@) {
                            $node_res = undef;
                            last;
                        }
                    }
                    push @{ $res->[2] }, $node_res;
                }
            } elsif ($action =~ /\Aprint_func_or_meth:(.+)\z/) {
                no strict 'refs';
                my @entries = split /\./, $1;
                for my $node (@action_targets) {
                    my $node_res = $node;
                    for my $entry (@entries) {
                        my ($type, $name) = $entry =~ /\A(func|meth)::?(.+)\z/ or
                            return [400, "For action print_func_or_meth, ".
                                    "specify func:FUNCNAME or meth:METHNAME"];
                        eval {
                            if ($type eq 'func') {
                                #use DD; say "func: $name(", DD::dump($node_res), ")";
                                $node_res = &{$name}($node_res);
                            } else {
                                #use DD; say "meth: $name on ", DD::dump($node_res);
                                $node_res = $node_res->$name;
                            }
                        };
                        if ($@) {
                            #warn $@;
                            $node_res = undef;
                            last;
                        }
                    }
                    push @{ $res->[2] }, $node_res;
                }
            } else {
                return [400, "Unknown action '$action'"];
            }
        } # for $action
    }
    $res;
}

$SPEC{ddsel} = {
    v => 1.1,
    summary => 'Select Perl data structure elements using CSel (CSS-selector-like) syntax',
    description => <<'_',

Note that this operates against Perl data structure, not Perl source code
elements (see <prog:ppisel> for that). File is Perl source code that defines
data structure, e.g.:

    {
        summary => 'This is a hash',
        # this is an array inside a hash
        array => [
            1, 2, 3,
        ],
    };

_
    args => {
        %foosel_args_common,
    },
};
sub ddsel {
    foosel(
        @_,

        code_read_tree => sub {
            my $args = shift;
            my $data;
            if ($args->{file} eq '-') {
                binmode STDIN, ":encoding(utf8)";
                $data = eval join("", <>);
                die if $@;
            } else {
                require File::Slurper;
                $data = eval File::Slurper::read_text($args->{file});
                die if $@;
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
                    $action = 'print_func_or_meth:meth:value.func:Data::Dmp::dmp';
                } elsif ($action eq 'dump') {
                    $action = 'dump:value';
                }
            }
        },
    );
}

1;

# ABSTRACT: Utilities related to Data::CSel

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CSelUtils - Utilities related to Data::CSel

=head1 VERSION

This document describes version 0.088 of App::CSelUtils (from Perl distribution App-CSelUtils), released on 2021-06-27.

=head1 DESCRIPTION

This distribution contains the following utilities:

=over

=item * L<ddsel>

=item * L<parse-csel>

=back

=head1 FUNCTIONS


=head2 ddsel

Usage:

 ddsel(%args) -> [$status_code, $reason, $payload, \%result_meta]

Select Perl data structure elements using CSel (CSS-selector-like) syntax.

Note that this operates against Perl data structure, not Perl source code
elements (see L<ppisel> for that). File is Perl source code that defines
data structure, e.g.:

 {
     summary => 'This is a hash',
     # this is an array inside a hash
     array => [
         1, 2, 3,
     ],
 };

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



=head2 parse_csel

Usage:

 parse_csel(%args) -> [$status_code, $reason, $payload, \%result_meta]

Parse CSel expression.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<expr>* => I<str>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=for Pod::Coverage ^(foosel)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-CSelUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CSelUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CSelUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<htmlsel>, L<orgsel>, L<jsonsel>, L<yamlsel>, L<podsel>, L<ppisel>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
