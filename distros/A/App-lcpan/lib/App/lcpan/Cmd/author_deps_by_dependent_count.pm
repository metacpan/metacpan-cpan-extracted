package App::lcpan::Cmd::author_deps_by_dependent_count;

our $DATE = '2019-06-19'; # DATE
our $VERSION = '1.034'; # VERSION

use 5.010;
use strict;
use warnings;

require App::lcpan;
require App::lcpan::Cmd::deps_by_dependent_count;

our %SPEC;

my $deps_bdc_args = $App::lcpan::Cmd::deps_by_dependent_count::SPEC{handle_cmd}{args};

$SPEC{'handle_cmd'} = {
    v => 1.1,
    summary => 'List all dependencies of dists of an author, sorted by number of dependent dists',
    args => {
        (map {$_ => $deps_bdc_args->{$_}}
             grep {$_ ne 'modules'} keys %$deps_bdc_args),
        %App::lcpan::author_args,
        module_authors => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'module_author',
            schema => ['array*', of=>'str*', min_len=>1],
            tags => ['category:filtering'],
            element_completion => \&App::lcpan::_complete_cpanid,
        },
        module_authors_arent => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'module_author_isnt',
            schema => ['array*', of=>'str*', min_len=>1],
            tags => ['category:filtering'],
            element_completion => \&App::lcpan::_complete_cpanid,
        },
    },
    tags => [],
};
sub handle_cmd {
    my %args = @_;

    my $res = App::lcpan::modules(%args);
    return $res if $res->[0] != 200;

    my %deps_bdc_args = %args;

    delete $deps_bdc_args{author};
    $deps_bdc_args{modules} = $res->[2];

    delete $deps_bdc_args{module_authors};
    $deps_bdc_args{authors} = $args{module_authors};

    delete $deps_bdc_args{module_authors_arent};
    $deps_bdc_args{authors_arent} = $args{module_authors_arent};

    App::lcpan::Cmd::deps_by_dependent_count::handle_cmd(%deps_bdc_args);
}

1;
# ABSTRACT: List all dependencies of dists of an author, sorted by number of dependent dists

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::author_deps_by_dependent_count - List all dependencies of dists of an author, sorted by number of dependent dists

=head1 VERSION

This document describes version 1.034 of App::lcpan::Cmd::author_deps_by_dependent_count (from Perl distribution App-lcpan), released on 2019-06-19.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, payload, meta]

List all dependencies of dists of an author, sorted by number of dependent dists.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<author>* => I<str>

=item * B<authors> => I<array[str]>

=item * B<authors_arent> => I<array[str]>

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. /path/to/cpan.

Defaults to C<~/cpan>.

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

=item * B<module_authors> => I<array[str]>

=item * B<module_authors_arent> => I<array[str]>

=item * B<perl_version> => I<str> (default: "v5.28.2")

Set base Perl version for determining core modules.

=item * B<phase> => I<str> (default: "runtime")

=item * B<rel> => I<str> (default: "requires")

=item * B<use_bootstrap> => I<bool> (default: 1)

Whether to use bootstrap database from App-lcpan-Bootstrap.

If you are indexing your private CPAN-like repository, you want to turn this
off.

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
