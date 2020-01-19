package App::lcpan::Cmd::weaver_section;

our $DATE = '2020-01-19'; # DATE
our $DIST = 'App-lcpan-CmdBundle-weaver'; # DIST
our $VERSION = '0.031'; # VERSION

use 5.010;
use strict;
use warnings;

use Hash::Subset 'hash_subset_without';
require App::lcpan;

our %SPEC;

our %weaver_section_args = (
    weaver_section => {
        schema => 'perl::modname*',
        req => 1,
        pos => 0,
        completion => sub {
            my %args = @_;

            my $word = $args{word} // '';
            my $res = App::lcpan::_complete_mod(
                %args,
                word => "Pod::Weaver::Section::$word",
            );
            for (@$res) { s!^Pod(::|/)Weaver(::|/)Section(::|/)!! }
            $res;
        },
    },
);

$SPEC{handle_cmd} = {
    v => 1.1,
    summary => 'Show a single Pod::Weaver section',
    args => {
        %App::lcpan::common_args,
        %weaver_section_args,
    },
};
sub handle_cmd {
    my %args = @_;

    my $res = App::lcpan::modules(
        hash_subset_without(\%args, ['weaver_section']),
        query => ["Pod::Weaver::Section::$args{weaver_section}"],
        query_type => 'exact-name',
        detail => 1,
    );
    return $res unless $res->[0] == 200;
    for my $entry (@{ $res->[2] }) {
        $entry->{name} = $entry->{module};
        $entry->{name} =~ s/^Pod::Weaver::Section:://;
    }
    unshift @{ $res->[3]{'table.fields'} }, 'name';
    $res;
}

1;
# ABSTRACT: Show a single Pod::Weaver section

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::weaver_section - Show a single Pod::Weaver section

=head1 VERSION

This document describes version 0.031 of App::lcpan::Cmd::weaver_section (from Perl distribution App-lcpan-CmdBundle-weaver), released on 2020-01-19.

=head1 DESCRIPTION

This module handles the L<lcpan> subcommand C<weaver-section>.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, payload, meta]

Show a single Pod::Weaver section.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. /path/to/cpan.

Defaults to C<~/cpan>.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<use_bootstrap> => I<bool> (default: 1)

Whether to use bootstrap database from App-lcpan-Bootstrap.

If you are indexing your private CPAN-like repository, you want to turn this
off.

=item * B<weaver_section>* => I<perl::modname>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-weaver>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-weaver>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-weaver>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
