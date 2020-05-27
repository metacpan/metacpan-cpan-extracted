package App::lcpan::Cmd::x_mentions_for_mod;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-26'; # DATE
our $DIST = 'App-lcpan'; # DIST
our $VERSION = '1.058'; # VERSION

use 5.010;
use strict;
use warnings;

require App::lcpan;

our %SPEC;

$SPEC{'handle_cmd'} = {
    v => 1.1,
    summary => 'List distributions which has an x_mentions relationship '.
        'dependency for specified module',
    args => {
        %App::lcpan::common_args,
        %App::lcpan::mod_args,
        %App::lcpan::detail_args,
    },
};
sub handle_cmd {
    my %args = @_;

    $args{modules} = [delete $args{module}];
    App::lcpan::rdeps(
        %args,
        rel => 'x_mentions',
        phase => 'x_mentions',
    );
}

1;
# ABSTRACT: List distributions which has an x_mentions relationship dependency for specified module

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::x_mentions_for_mod - List distributions which has an x_mentions relationship dependency for specified module

=head1 VERSION

This document describes version 1.058 of App::lcpan::Cmd::x_mentions_for_mod (from Perl distribution App-lcpan), released on 2020-05-26.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, payload, meta]

List distributions which has an x_mentions relationship dependency for specified module.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

Defaults to C<~/cpan>.

=item * B<detail> => I<bool>

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<module>* => I<perl::modname>

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

=head1 SEE ALSO

L<acme-cpanmodules-for>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
