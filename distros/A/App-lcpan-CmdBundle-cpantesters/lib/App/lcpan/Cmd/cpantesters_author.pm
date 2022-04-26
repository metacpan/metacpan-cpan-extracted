package App::lcpan::Cmd::cpantesters_author;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Perinci::Object;

require App::lcpan;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-27'; # DATE
our $DIST = 'App-lcpan-CmdBundle-cpantesters'; # DIST
our $VERSION = '0.003'; # VERSION

our %SPEC;

$SPEC{handle_cmd} = {
    v => 1.1,
    summary => 'Open author page on CPAN Testers matrix',
    description => <<'_',

Given author with CPAN ID `CPANID`, this will open
`http://matrix.cpantesters.org/?author=CPANID`. `CPANID` will first be checked for
existence in local index database.

_
    args => {
        %App::lcpan::common_args,
        %App::lcpan::authors_args,
    },
};
sub handle_cmd {
    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $envres = envresmulti();
    for my $author (@{ $args{authors} }) {
        my ($cpanid) = $dbh->selectrow_array(
            "SELECT cpanid FROM author WHERE cpanid=?", {}, uc $author);
        defined $cpanid or do {
            $envres->add_result(404, "No such author '$author'");
            next;
        };

        require Browser::Open;
        my $url = "http://matrix.cpantesters.org/?author=$cpanid";
        my $err = Browser::Open::open_browser($url);
        if ($err) {
            $envres->add_result(500, "Can't open browser for URL $url");
        } else {
            $envres->add_result(200, "OK");
        }
    }
    $envres->as_struct;
}

1;
# ABSTRACT: Open author page on CPAN Testers matrix

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::cpantesters_author - Open author page on CPAN Testers matrix

=head1 VERSION

This document describes version 0.003 of App::lcpan::Cmd::cpantesters_author (from Perl distribution App-lcpan-CmdBundle-cpantesters), released on 2022-03-27.

=head1 DESCRIPTION

This module handles the L<lcpan> subcommand C<cpantesters-author>.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [$status_code, $reason, $payload, \%result_meta]

Open author page on CPAN Testers matrix.

Given author with CPAN ID C<CPANID>, this will open
CL<http://matrix.cpantesters.org/?author=CPANID>. C<CPANID> will first be checked for
existence in local index database.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<authors>* => I<array[str]>

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

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


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-cpantesters>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-cpantesters>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-cpantesters>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
