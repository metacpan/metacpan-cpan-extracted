package App::lcpan::Cmd::rt_tickets;

our $DATE = '2017-02-03'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
no warnings 'once';
use Log::Any::IfLOG '$log';

require App::lcpan;
use Perinci::Object;

our %SPEC;

$SPEC{handle_cmd} = {
    v => 1.1,
    summary => 'Return RT tickets for dist/module',
    args => {
        %App::lcpan::common_args,
        %App::lcpan::mods_or_dists_args,
        type => {
            schema => ['str*', in=>[qw/Active Resolved Rejected/]],
            default => 'Active',
        },
        count => {
            summary => 'Instead of listing each ticket, return ticket count for each distribution',
            schema => ['bool*', is=>1],
            cmdline_aliases => {c=>{}},
        },
    },
};
sub handle_cmd {
    require WWW::RT::CPAN;

    my %args = @_;
    my $type = $args{type};

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my @res;
    my $envres = envresmulti();
    my $resmeta = {};

    if ($args{count}) {
        $resmeta->{'table.fields'} = [qw/dist count/];
    } else {
        $resmeta->{'table.fields'} = [qw/dist ticket_id ticket_title ticket_status/];
    }

  ARG:
    for my $module_or_dist (@{ $args{modules_or_dists} }) {
        my ($dist, $file_id, $cpanid, $version);
        {
            # first find dist
            if (($file_id, $cpanid, $version) = $dbh->selectrow_array(
                "SELECT file_id, cpanid, version FROM dist WHERE name=? AND is_latest", {}, $module_or_dist)) {
                $dist = $module_or_dist;
                last;
            }
            # try mod
            if (($file_id, $dist, $cpanid, $version) = $dbh->selectrow_array("SELECT m.file_id, d.name, d.cpanid, d.version FROM module m JOIN dist d ON m.file_id=d.file_id WHERE m.name=?", {}, $module_or_dist)) {
                last;
            }
        }
        $file_id or do { $envres->add_result(404, "No such module/dist '$module_or_dist'"); next ARG };

        my $res;
        if ($type eq 'Resolved') {
            $res = WWW::RT::CPAN::list_dist_resolved_tickets(dist => $dist);
        } elsif ($type eq 'Rejected') {
            $res = WWW::RT::CPAN::list_dist_rejected_tickets(dist => $dist);
        } else {
            $res = WWW::RT::CPAN::list_dist_active_tickets(dist => $dist);
        }

        $res->[0] == 200 or do { $envres->add_result(500, "Can't fetch ticket for dist '$dist'", $res); next ARG };
        my $count = 0;
        for my $t (@{ $res->[2] }) {
            if ($args{count}) {
                $count++;
            } else {
                push @res, {dist=>$dist, ticket_id=>$t->{id}, ticket_title=>$t->{title}, ticket_status=>$t->{status}};
            }
        }
        if ($args{count}) {
            push @res, {dist=>$dist, count=>$count};
        }
        $envres->add_result(200, "OK", {item_id=>$dist});
    }

    my $res = $envres->as_struct;
    if ($res->[0] == 200) {
        $res->[2] = \@res;
        $res->[3] = $resmeta;
    }
    $res;
}

1;
# ABSTRACT: Return RT tickets for dist/module

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::rt_tickets - Return RT tickets for dist/module

=head1 VERSION

This document describes version 0.002 of App::lcpan::Cmd::rt_tickets (from Perl distribution App-lcpan-CmdBundle-rt), released on 2017-02-03.

=head1 DESCRIPTION

This module handles the L<lcpan> subcommand C<rt-tickets>.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, result, meta]

Return RT tickets for dist/module.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<count> => I<bool>

Instead of listing each ticket, return ticket count for each distribution.

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. /path/to/cpan.

Defaults to C<~/cpan>.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

=item * B<modules_or_dists>* => I<array[str]>

Module or dist names.

=item * B<type> => I<str> (default: "Active")

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

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-rt>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-rt>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-rt>

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
