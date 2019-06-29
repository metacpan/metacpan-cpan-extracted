package App::lcpan::Cmd::author_deps;

our $DATE = '2019-06-26'; # DATE
our $VERSION = '1.035'; # VERSION

use 5.010;
use strict;
use warnings;

require App::lcpan;

our %SPEC;

$SPEC{'handle_cmd'} = {
    v => 1.1,
    summary => "List dependencies for all of the dists of an author",
    args => {
        %App::lcpan::common_args,
        %App::lcpan::author_args,
        %App::lcpan::deps_args,
        module_authors => {
            summary => 'Only list depended modules published by specified author(s)',
            'x.name.is_plural' => 1,
            schema => ['array*', of=>'str*'],
            element_completion => \&App::lcpan::_complete_cpanid,
        },
        module_authors_arent => {
            summary => 'Do not list depended modules published by specified author(s)',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'module_author_isnt',
            schema => ['array*', of=>'str*'],
            element_completion => \&App::lcpan::_complete_cpanid,
        },
    },
};
sub handle_cmd {
    my %args = @_;

    my $author = $args{author};

    my $res = App::lcpan::modules(%args, author=>$author);
    return $res if $res->[0] != 200;
    my $mods = $res->[2];

    my %deps_args = %args;
    $deps_args{modules} = $mods;
    delete $deps_args{authors};
    delete $deps_args{authors_arent};
    $deps_args{authors} = $args{module_authors};
    $deps_args{authors_arent} = $args{module_authors_arent};
    $deps_args{phase} = $args{phase};
    $deps_args{rel} = $args{rel};
    $res = App::lcpan::deps(%deps_args);
    return $res if $res->[0] != 200;

    $res;
}

1;
# ABSTRACT: List dependencies for all of the dists of an author

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::author_deps - List dependencies for all of the dists of an author

=head1 VERSION

This document describes version 1.035 of App::lcpan::Cmd::author_deps (from Perl distribution App-lcpan), released on 2019-06-26.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, payload, meta]

List dependencies for all of the dists of an author.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<author>* => I<str>

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. /path/to/cpan.

Defaults to C<~/cpan>.

=item * B<flatten> => I<bool>

Instead of showing tree-like information, flatten it.

When recursing, the default is to show the final result in a tree-like table,
i.e. indented according to levels, e.g.:

 % lcpan deps -R MyModule
 | module            | author  | version |
 |-------------------|---------|---------|
 | Foo               | AUTHOR1 | 0.01    |
 |   Bar             | AUTHOR2 | 0.23    |
 |   Baz             | AUTHOR3 | 1.15    |
 | Qux               | AUTHOR2 | 0       |

To be brief, if C<Qux> happens to also depends on C<Bar>, it will not be shown in
the result. Thus we don't know the actual C<Bar> version that is needed by the
dependency tree of C<MyModule>. For example, if C<Qux> happens to depends on C<Bar>
version 0.45 then C<MyModule> indirectly requires C<Bar> 0.45.

To list all the direct and indirect dependencies on a single flat list, with
versions already resolved to the largest version required, use the C<flatten>
option:

 % lcpan deps -R --flatten MyModule
 | module            | author  | version |
 |-------------------|---------|---------|
 | Foo               | AUTHOR1 | 0.01    |
 | Bar               | AUTHOR2 | 0.45    |
 | Baz               | AUTHOR3 | 1.15    |
 | Qux               | AUTHOR2 | 0       |

Note that C<Bar>'s required version is already 0.45 in the above example.

=item * B<include_core> => I<bool> (default: 1)

Include core modules.

=item * B<include_noncore> => I<bool> (default: 1)

Include non-core modules.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<level> => I<int> (default: 1)

Recurse for a number of levels (-1 means unlimited).

=item * B<module_authors> => I<array[str]>

Only list depended modules published by specified author(s).

=item * B<module_authors_arent> => I<array[str]>

Do not list depended modules published by specified author(s).

=item * B<perl_version> => I<str> (default: "v5.26.1")

Set base Perl version for determining core modules.

=item * B<phase> => I<str> (default: "runtime")

=item * B<rel> => I<str> (default: "requires")

=item * B<use_bootstrap> => I<bool> (default: 1)

Whether to use bootstrap database from App-lcpan-Bootstrap.

If you are indexing your private CPAN-like repository, you want to turn this
off.

=item * B<with_xs_or_pp> => I<bool>

Check each dependency as XS/PP.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
