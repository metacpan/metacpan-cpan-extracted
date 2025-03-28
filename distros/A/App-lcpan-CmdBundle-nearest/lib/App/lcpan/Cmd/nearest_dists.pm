package App::lcpan::Cmd::nearest_dists;

use 5.010001;
use strict;
use warnings;

require App::lcpan;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-27'; # DATE
our $DIST = 'App-lcpan-CmdBundle-nearest'; # DIST
our $VERSION = '0.003'; # VERSION

our %SPEC;

$SPEC{handle_cmd} = {
    v => 1.1,
    summary => 'List dists with names nearest to a specified name',
    args => {
        %App::lcpan::dist_args,
    },
};

sub handle_cmd {
    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $sth = $dbh->prepare("SELECT dist_name FROM file WHERE dist_name IS NOT NULL");
    $sth->execute;
    my @names;
    while (my ($name) = $sth->fetchrow_array) { push @names, $name }

    require Text::Fuzzy;
    my $tf = Text::Fuzzy->new($args{dist});

    [200, "OK", [$tf->nearestv(\@names)]];
}

1;
# ABSTRACT: List dists with names nearest to a specified name

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::nearest_dists - List dists with names nearest to a specified name

=head1 VERSION

This document describes version 0.003 of App::lcpan::Cmd::nearest_dists (from Perl distribution App-lcpan-CmdBundle-nearest), released on 2022-03-27.

=head1 DESCRIPTION

This module handles the L<lcpan> subcommand C<nearest-dists>.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [$status_code, $reason, $payload, \%result_meta]

List dists with names nearest to a specified name.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dist>* => I<perl::distname>


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

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-nearest>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-nearest>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-nearest>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
