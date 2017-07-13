package App::lcpan::Cmd::cpanratings_get_reviews;

our $DATE = '2017-07-11'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

require App::lcpan;

our %SPEC;

$SPEC{handle_cmd} = {
    v => 1.1,
    summary => 'Get CPAN Ratings reviews for a dist/module',
    args => {
        %App::lcpan::common_args,
        %App::lcpan::mod_or_dist_args,
    },
};
sub handle_cmd {
    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my ($dist, $file_id, $cpanid, $version);
    {
        # first find dist
        if (($file_id, $cpanid, $version) = $dbh->selectrow_array(
            "SELECT file_id, cpanid, version FROM dist WHERE name=? AND is_latest", {}, $args{module_or_dist})) {
            $dist = $args{module_or_dist};
            last;
        }
        # try mod
        if (($file_id, $dist, $cpanid, $version) = $dbh->selectrow_array("SELECT m.file_id, d.name, d.cpanid, d.version FROM module m JOIN dist d ON m.file_id=d.file_id WHERE m.name=?", {}, $args{module_or_dist})) {
            last;
        }
    }
    $file_id or return [404, "No such module/dist '$args{module_or_dist}'"];

    require WWW::CPANRatings;
    my @reviews = WWW::CPANRatings->new->get_reviews($dist);
    for (@reviews) {
        delete $_->{dist_link};
        delete $_->{user_link};
        delete $_->{header};
    }
    [200, "OK", \@reviews, {'table.fields'=>[]}];
}

1;
# ABSTRACT: Get CPAN Ratings reviews for a dist/module

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::cpanratings_get_reviews - Get CPAN Ratings reviews for a dist/module

=head1 VERSION

This document describes version 0.003 of App::lcpan::Cmd::cpanratings_get_reviews (from Perl distribution App-lcpan-CmdBundle-cpanratings), released on 2017-07-11.

=head1 DESCRIPTION

This module handles the L<lcpan> subcommand C<cpanratings-get-reviews>.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, result, meta]

Get CPAN Ratings reviews for a dist/module.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. /path/to/cpan.

Defaults to C<~/cpan>.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

=item * B<module_or_dist>* => I<str>

Module or dist name.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-cpanratings>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-cpanratings>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-cpanratings>

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
