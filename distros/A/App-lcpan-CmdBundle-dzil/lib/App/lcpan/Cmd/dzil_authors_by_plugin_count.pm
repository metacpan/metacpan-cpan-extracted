package App::lcpan::Cmd::dzil_authors_by_plugin_count;

our $DATE = '2017-01-20'; # DATE
our $VERSION = '0.05'; # VERSION

use 5.010;
use strict;
use warnings;

require App::lcpan;

our %SPEC;

$SPEC{'handle_cmd'} = {
    v => 1.1,
    summary => 'List authors ranked by number of Dist::Zilla plugins',
    args => {
        %App::lcpan::common_args,
    },
};
sub handle_cmd {
    my %args = @_;

    App::lcpan::_set_args_default(\%args);
    my $cpan = $args{cpan};
    my $index_name = $args{index_name};

    my $dbh = App::lcpan::_connect_db('ro', $cpan, $index_name);

    my $sql = "SELECT
  cpanid author,
  COUNT(*) AS mod_count
FROM module m
WHERE m.name LIKE 'Dist::Zilla::Plugin::%'
GROUP BY cpanid
ORDER BY mod_count DESC
";

    my @res;
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while (my $row = $sth->fetchrow_hashref) {
        push @res, $row;
    }
    my $resmeta = {};
    $resmeta->{'table.field'} = [qw/author mod_count/];
    [200, "OK", \@res, $resmeta];
}

1;
# ABSTRACT: List authors ranked by number of Dist::Zilla plugins

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::dzil_authors_by_plugin_count - List authors ranked by number of Dist::Zilla plugins

=head1 VERSION

This document describes version 0.05 of App::lcpan::Cmd::dzil_authors_by_plugin_count (from Perl distribution App-lcpan-CmdBundle-dzil), released on 2017-01-20.

=head1 DESCRIPTION

This module handles the L<lcpan> subcommand C<dzil-authors-by-plugin-count>.

=head1 FUNCTIONS


=head2 handle_cmd(%args) -> [status, msg, result, meta]

List authors ranked by number of Dist::Zilla plugins.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. /path/to/cpan.

Defaults to C<~/cpan>.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-dzil>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-dzil>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-dzil>

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
