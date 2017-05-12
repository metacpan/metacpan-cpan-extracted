package App::lcpan::Cmd::nearest_dists;

our $DATE = '2017-01-20'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

require App::lcpan;

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

    my $sth = $dbh->prepare("SELECT name FROM dist");
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

This document describes version 0.002 of App::lcpan::Cmd::nearest_dists (from Perl distribution App-lcpan-CmdBundle-nearest), released on 2017-01-20.

=head1 DESCRIPTION

This module handles the L<lcpan> subcommand C<nearest-dists>.

=head1 FUNCTIONS


=head2 handle_cmd(%args) -> [status, msg, result, meta]

List dists with names nearest to a specified name.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dist>* => I<perl::distname>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-nearest>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-nearest>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-nearest>

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
