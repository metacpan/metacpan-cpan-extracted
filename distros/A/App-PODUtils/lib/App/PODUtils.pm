package App::PODUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-20'; # DATE
our $DIST = 'App-PODUtils'; # DIST
our $VERSION = '0.050'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use File::Slurper::Dash 'read_text';
use Sort::Sub;

our %SPEC;

# old
our $arg_pod_multiple = {
    schema => ['array*' => of=>'perl::podname*', min_len=>1],
    req    => 1,
    pos    => 0,
    greedy => 1,
    element_completion => sub {
        require Complete::Module;
        my %args = @_;
        Complete::Module::complete_module(
            find_pm=>0, find_pmc=>0, find_pod=>1, word=>$args{word});
    },
};

# old
our $arg_pod_single = {
    schema => 'perl::podname*',
    req    => 1,
    pos    => 0,
    completion => sub {
        require Complete::Module;
        my %args = @_;
        Complete::Module::complete_module(
            find_pm=>0, find_pmc=>0, find_pod=>1, word=>$args{word});
    },
};

our %arg0_pod = (
    pod => {
        summary => 'Path to a .POD file, or a POD name (e.g. Foo::Bar) '.
            'which will be searched in @INC',
        description => <<'_',

"-" means standard input.

_
        schema => 'perl::pod_filename*',
        default => '-',
        pos => 0,
    },
);

our %arg0_pods = (
    pods => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'pod',
        summary => 'Paths to .POD files, or POD names (e.g. Foo::Bar) '.
            'which will be searched in @INC',
        schema => ['array*', of=>'perl::pod_filename*'],
        description => <<'_',

"-" means standard input.

_
        pos => 0,
        default => ['-'],
        slurpy => 1,
    },
);

our %argspecopt_naked_pod = (
    naked_pod => {
        schema => 'bool*',
        summary => 'Strip =pod and =cut delimiters',
        cmdline_aliases => {N=>{}},
        description => <<'_',

Normally, when outputing POD text, the `=pod` header and `=cut` footer are
included. This option, if enabled, strips the outputting of such header/footer.

_
    },
);

sub _parse_pod {
    require Pod::Elemental;

    my $file = shift;

    my $doc = Pod::Elemental->read_string(read_text($file));

    require Pod::Elemental::Transformer::Pod5;
    Pod::Elemental::Transformer::Pod5->new->transform_node($doc);

    require Pod::Elemental::Transformer::Nester;
    require Pod::Elemental::Selectors;
    my $nester;
    # TODO: do we have to do nesting in multiple steps like this?
    $nester = Pod::Elemental::Transformer::Nester->new({
        top_selector      => Pod::Elemental::Selectors::s_command('head3'),
        content_selectors => [
            Pod::Elemental::Selectors::s_command([ qw(head4) ]),
            Pod::Elemental::Selectors::s_flat(),
        ],
    });
    $nester->transform_node($doc);

    $nester = Pod::Elemental::Transformer::Nester->new({
        top_selector      => Pod::Elemental::Selectors::s_command('head2'),
        content_selectors => [
            Pod::Elemental::Selectors::s_command([ qw(head3 head4) ]),
            Pod::Elemental::Selectors::s_flat(),
        ],
    });
    $nester->transform_node($doc);

    $nester = Pod::Elemental::Transformer::Nester->new({
        top_selector      => Pod::Elemental::Selectors::s_command('head1'),
        content_selectors => [
            Pod::Elemental::Selectors::s_command([ qw(head2 head3 head4) ]),
            Pod::Elemental::Selectors::s_flat(),
        ],
    });
    $nester->transform_node($doc);

    $doc;
}

$SPEC{dump_pod_structure} = {
    v => 1.1,
    summary => 'Dump POD structure using Pod::Elemental',
    description => <<'_',

This is actually just a shortcut for:

    % podsel FILENAME --root --dump --transform Pod5 --transform Nester

_
    args => {
        %arg0_pod,
    },
    links => [
        {url=>'prog:pomdump', summary=>'Similar script, but using Pod::POM as backend to parse POD document into tree'},
        {url=>'prog:podsel'},
    ],
};
sub dump_pod_structure {
    require App::podsel;

    my %args = @_;

    App::podsel::podsel(
        file => $args{pod},
        select_action => "root",
        node_actions => ['dump'],
        transforms => ['Pod5', 'Nester'],
    );
}

sub _sort {
    my ($node, $command, $sorter, $sorter_meta) = @_;

    my @children = @{ $node->children // [] };
    return unless @children;

    # recurse depth-first to sort the children's children
    for my $child (@children) {
        next unless $child->can("children");
        my $grandchildren = $child->children;
        next unless $grandchildren && @$grandchildren;
        _sort($child, $command, $sorter, $sorter_meta);
    }

    my $has_command_sub = sub {
        $_->can("command") &&
            $_->command &&
            $_->command eq $command
    };
    return unless grep { $has_command_sub->($_) } @children;

    my $child_has_command_sub = sub {
        $children[$_]->can("command") &&
            $children[$_]->command &&
            $children[$_]->command eq $command
    };

    require Sort::SubList;
    my @sorted_children =
        map { $children[$_] }
        Sort::SubList::sort_sublist(
            sub {
                if ($sorter_meta->{compares_record}) {
                    my $rec0 = [$children[$_[0]]->content, $_[0]];
                    my $rec1 = [$children[$_[1]]->content, $_[1]];
                    $sorter->($rec0, $rec1);
                } else {
                    $sorter->($children[$_[0]]->content, $children[$_[1]]->content);
                }
            },
            $child_has_command_sub,
            0..$#children);
    $node->children(\@sorted_children);
}

sub _doc_as_pod_string {
    my ($doc, $args) = @_;
    my $res = $doc->as_pod_string;
    if ($args->{naked_pod}) {
        $res =~ s/\A\s*^=pod\s*//ms;
        $res =~ s/^=cut\s*\z//ms;
    }
    $res;
}

$Sort::Sub::argsopt_sortsub{sort_sub}{cmdline_aliases} = {S=>{}};
$Sort::Sub::argsopt_sortsub{sort_args}{cmdline_aliases} = {A=>{}};

$SPEC{sort_pod_headings} = {
    v => 1.1,
    summary => 'Sort POD headings in text',
    description => <<'_',

This utility sorts POD headings in text. By default it sorts =head1 headings.
For example this POD:

    =head1 b

    some text for b

    =head1 a

    text for a

    =head2 a2

    =head2 a1

    =head1 c

    text for c

will be sorted into:

    =head1 a

    text for a

    =head2 a2

    =head2 a1

    =head1 b

    some text for b

    =head1 c

    text for c

Note that the =head2 headings are not sorted. If you want to sort those, you can
rerun the utility and specify the `--command=head2` option.

_
    args => {
        %arg0_pod,
        %argspecopt_naked_pod,
        command => {
            schema => ['str*', {
                match=>qr/\A\w+\z/,
                #in=>[qw/head1 head2 head3 head4/],
            }],
            default => 'head1',
        },
        %Sort::Sub::argsopt_sortsub,
    },
    result_naked => 1,
};
sub sort_pod_headings {
    my %args = @_;

    my $sortsub_routine = $args{sort_sub} // 'asciibetically';
    my $sortsub_args    = $args{sort_args} // {};
    my ($sorter, $sorter_meta) =
        Sort::Sub::get_sorter($sortsub_routine, $sortsub_args, 'with meta');

    my $command = $args{command} // 'head1';

    my $doc = _parse_pod($args{pod});
    _sort($doc, $command, $sorter, $sorter_meta);
    _doc_as_pod_string($doc, \%args);
}

$SPEC{reverse_pod_headings} = {
    v => 1.1,
    summary => 'Reverse POD headings',
    args => {
        %arg0_pod,
        %argspecopt_naked_pod,
        command => {
            schema => ['str*', {
                match=>qr/\A\w+\z/,
                #in=>[qw/head1 head2 head3 head4/],
            }],
            default => 'head1',
        },
    },
    result_naked => 1,
};
sub reverse_pod_headings {
    my %args = @_;
    sort_pod_headings(%args, sort_sub=>'record_by_reverse_order');
}

$SPEC{extract_links_in_pod} = {
    v => 1.1,
    summary => 'Extract links in POD',
    args => {
        %arg0_pod,
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
    result_naked => 1,
};
sub extract_links_in_pod {
    my %args = @_;

    my $pod_parser = App::PODUtils::PodParser::XLinks->new;
    $pod_parser->{_links} = [];
    eval {
        $pod_parser->parse_string_document(read_text $args{pod});
    };
    return [500, "Can't parse POD: $@"] if $@;

    unless ($args{detail}) {
        $pod_parser->{_links} = [map { $_->{raw} } @{ $pod_parser->{_links} }];
    }

    [200, "OK", $pod_parser->{_links}];
}

package # hide from PAUSE
    App::PODUtils::PodParser::XLinks;
use Log::ger;

use parent qw(Pod::Simple::Methody);

sub start_L {
    my $self = shift;
    push @{ $self->{_links} }, $_[0];
}

1;
# ABSTRACT: Command-line utilities related to POD

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PODUtils - Command-line utilities related to POD

=head1 VERSION

This document describes version 0.050 of App::PODUtils (from Perl distribution App-PODUtils), released on 2021-07-20.

=head1 SYNOPSIS

This distribution provides the following command-line utilities related to Perl
POD:

=over

=item * L<dump-pod-structure>

=item * L<elide-pod>

=item * L<extract-links-in-pod>

=item * L<poddump>

=item * L<podless>

=item * L<podstrip>

=item * L<podxlinks>

=item * L<reverse-pod-headings>

=item * L<sort-pod-headings>

=back

=head1 FUNCTIONS


=head2 dump_pod_structure

Usage:

 dump_pod_structure(%args) -> [$status_code, $reason, $payload, \%result_meta]

Dump POD structure using Pod::Elemental.

This is actually just a shortcut for:

 % podsel FILENAME --root --dump --transform Pod5 --transform Nester

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<pod> => I<perl::pod_filename> (default: "-")

Path to a .POD file, or a POD name (e.g. Foo::Bar) which will be searched in @INC.

"-" means standard input.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 extract_links_in_pod

Usage:

 extract_links_in_pod(%args) -> any

Extract links in POD.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

=item * B<pod> => I<perl::pod_filename> (default: "-")

Path to a .POD file, or a POD name (e.g. Foo::Bar) which will be searched in @INC.

"-" means standard input.


=back

Return value:  (any)



=head2 reverse_pod_headings

Usage:

 reverse_pod_headings(%args) -> any

Reverse POD headings.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<command> => I<str> (default: "head1")

=item * B<naked_pod> => I<bool>

Strip =pod and =cut delimiters.

Normally, when outputing POD text, the C<=pod> header and C<=cut> footer are
included. This option, if enabled, strips the outputting of such header/footer.

=item * B<pod> => I<perl::pod_filename> (default: "-")

Path to a .POD file, or a POD name (e.g. Foo::Bar) which will be searched in @INC.

"-" means standard input.


=back

Return value:  (any)



=head2 sort_pod_headings

Usage:

 sort_pod_headings(%args) -> any

Sort POD headings in text.

This utility sorts POD headings in text. By default it sorts =head1 headings.
For example this POD:

 =head1 b
 
 some text for b
 
 =head1 a
 
 text for a
 
 =head2 a2
 
 =head2 a1
 
 =head1 c
 
 text for c

will be sorted into:

 =head1 a
 
 text for a
 
 =head2 a2
 
 =head2 a1
 
 =head1 b
 
 some text for b
 
 =head1 c
 
 text for c

Note that the =head2 headings are not sorted. If you want to sort those, you can
rerun the utility and specify the C<--command=head2> option.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<command> => I<str> (default: "head1")

=item * B<naked_pod> => I<bool>

Strip =pod and =cut delimiters.

Normally, when outputing POD text, the C<=pod> header and C<=cut> footer are
included. This option, if enabled, strips the outputting of such header/footer.

=item * B<pod> => I<perl::pod_filename> (default: "-")

Path to a .POD file, or a POD name (e.g. Foo::Bar) which will be searched in @INC.

"-" means standard input.

=item * B<sort_args> => I<array[str]>

Arguments to pass to the Sort::Sub::* routine.

=item * B<sort_sub> => I<sortsub::spec>

Name of a Sort::Sub::* module (without the prefix).


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-PODUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-PODUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-PODUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<pod2html>

L<podtohtml> from L<App::podtohtml>

L<App::PMUtils>

L<App::PlUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
