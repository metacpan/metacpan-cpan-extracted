package App::lcpan::Cmd::sah_compilers;

our $DATE = '2017-01-20'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
use warnings;

require App::lcpan;

our %SPEC;

$SPEC{handle_cmd} = {
    v => 1.1,
    summary => 'List Data::Sah compilers available on CPAN',
    args => {
        %App::lcpan::common_args,
        %App::lcpan::query_multi_args,
        %App::lcpan::fauthor_args,
        %App::lcpan::fdist_args,
        %App::lcpan::flatest_args,
        %App::lcpan::sort_modules_args,
    },
};
sub handle_cmd {
    my %args = @_;

    my $res = App::lcpan::modules(%args, namespaces=>['Data::Sah::Compiler']);

    # remove Acme::CPANLists itself
    my $filtered = [];
  REC:
    for my $rec (@{$res->[2]}) {
        for ($args{detail} ? $rec->{module} : $rec) {
            s/\AData::Sah::Compiler::// or next REC;
            /\A([^:]::)*[a-z][^:]*\z/ or next REC;
        }
        push @$filtered, $rec;
    }
    $res->[2] = $filtered;
    $res;
}

1;
# ABSTRACT: List Data::Sah compilers available on CPAN

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::sah_compilers - List Data::Sah compilers available on CPAN

=head1 VERSION

This document describes version 0.01 of App::lcpan::Cmd::sah_compilers (from Perl distribution App-lcpan-CmdBundle-sah), released on 2017-01-20.

=head1 DESCRIPTION

This module handles the L<lcpan> subcommand C<sah-compilers>.

=head1 FUNCTIONS


=head2 handle_cmd(%args) -> [status, msg, result, meta]

List Data::Sah compilers available on CPAN.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<author> => I<str>

Filter by author.

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. /path/to/cpan.

Defaults to C<~/cpan>.

=item * B<detail> => I<bool>

=item * B<dist> => I<perl::distname>

Filter by distribution.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

=item * B<latest> => I<bool>

=item * B<or> => I<bool>

When there are more than one query, perform OR instead of AND logic.

=item * B<query> => I<array[str]>

Search query.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-sah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-sah>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-sah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
