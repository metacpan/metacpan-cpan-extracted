package App::lcpan::Cmd::bugs_open;

use 5.010001;
use strict;
use warnings;
use Log::ger;

require App::lcpan;
require App::lcpan::Cmd::dist_meta;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-27'; # DATE
our $DIST = 'App-lcpan-CmdBundle-bugs'; # DIST
our $VERSION = '0.004'; # VERSION

our %SPEC;

$SPEC{handle_cmd} = {
    v => 1.1,
    summary => "Open a module/dist's bugtracker page in browser",
    args => {
        %App::lcpan::common_args,
        %App::lcpan::mod_or_dist_args,
    },
};
sub handle_cmd {
    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my ($dist, $file_id);
    {
        # first find dist
        if (($file_id) = $dbh->selectrow_array(
            "SELECT id FROM file WHERE dist_name=? AND is_latest_dist", {}, $args{module_or_dist})) {
            $dist = $args{module_or_dist};
            last;
        }
        # try mod
        if (($file_id, $dist) = $dbh->selectrow_array("SELECT m.file_id, f.dist_name FROM module m JOIN file f ON m.file_id=f.id WHERE m.name=?", {}, $args{module_or_dist})) {
            last;
        }
    }
    $file_id or return [404, "No such module/dist '$args{module_or_dist}'"];

    my $res = App::lcpan::Cmd::dist_meta::handle_cmd(%args, dist=>$dist);
    return [412, $res->[1]] unless $res->[0] == 200;
    my $meta = $res->[2];

    my $url;
    unless ($meta->{resources} &&
                $meta->{resources}{bugtracker} &&
                ($url = $meta->{resources}{bugtracker}{web})) {
        return [412, "No bugtracker web URL specified in the distmeta's resources"];
    }

    require Browser::Open;
    my $err = Browser::Open::open_browser($url);
    return [500, "Can't open browser"] if $err;
    [200];

}

1;
# ABSTRACT: Open a module/dist's bugtracker page in browser

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::bugs_open - Open a module/dist's bugtracker page in browser

=head1 VERSION

This document describes version 0.004 of App::lcpan::Cmd::bugs_open (from Perl distribution App-lcpan-CmdBundle-bugs), released on 2022-03-27.

=head1 DESCRIPTION

This module handles the L<lcpan> subcommand C<bugs-open>.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [$status_code, $reason, $payload, \%result_meta]

Open a moduleE<sol>dist's bugtracker page in browser.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

Defaults to C<~/cpan>.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<module_or_dist>* => I<str>

Module or dist name.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-bugs>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-bugs>.

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

This software is copyright (c) 2022, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-bugs>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
