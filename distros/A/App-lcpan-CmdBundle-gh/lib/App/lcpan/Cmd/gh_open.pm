package App::lcpan::Cmd::gh_open;

our $DATE = '2017-01-23'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

require App::lcpan;
require App::lcpan::Cmd::dist_meta;

our %SPEC;

$SPEC{handle_cmd} = {
    v => 1.1,
    summary => 'Open the GitHub project page of a module/dist',
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
            "SELECT file_id FROM dist WHERE name=? AND is_latest", {}, $args{module_or_dist})) {
            $dist = $args{module_or_dist};
            last;
        }
        # try mod
        if (($file_id, $dist) = $dbh->selectrow_array("SELECT m.file_id, d.name FROM module m JOIN dist d ON m.file_id=d.file_id WHERE m.name=?", {}, $args{module_or_dist})) {
            last;
        }
    }
    $file_id or return [404, "No such module/dist '$args{module_or_dist}'"];

    my $res = App::lcpan::Cmd::dist_meta::handle_cmd(%args, dist=>$dist);
    return [412, $res->[1]] unless $res->[0] == 200;
    my $meta = $res->[2];

    unless ($meta->{resources} && $meta->{resources}{repository} && $meta->{resources}{repository}{type} eq 'git') {
        return [412, "No git repository specified in the distmeta's resources"];
    }
    my $url = $meta->{resources}{repository}{web};
    unless ($url =~ m!^https?://github\.com!i) {
        return [412, "Git repository web URL not on github ($url)"];
    }

    require Browser::Open;
    my $err = Browser::Open::open_browser($url);
    return [500, "Can't open browser"] if $err;
    [200];
}

1;
# ABSTRACT: Open the GitHub project page of a module/dist

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::gh_open - Open the GitHub project page of a module/dist

=head1 VERSION

This document describes version 0.003 of App::lcpan::Cmd::gh_open (from Perl distribution App-lcpan-CmdBundle-gh), released on 2017-01-23.

=head1 DESCRIPTION

This module handles the L<lcpan> subcommand C<gh-open>.

=head1 FUNCTIONS


=head2 handle_cmd(%args) -> [status, msg, result, meta]

Open the GitHub project page of a module/dist.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-gh>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-gh>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-gh>

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
