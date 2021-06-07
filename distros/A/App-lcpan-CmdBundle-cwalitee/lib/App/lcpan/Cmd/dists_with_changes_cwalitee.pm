package App::lcpan::Cmd::dists_with_changes_cwalitee;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-06'; # DATE
our $DIST = 'App-lcpan-CmdBundle-cwalitee'; # DIST
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

require App::lcpan;
use Cwalitee::Common;
use Hash::Subset qw(hash_subset);

our %SPEC;

my %dists_args = %{$App::lcpan::SPEC{dists}{args}};
my %calc_args = Cwalitee::Common::args_calc('CPAN::Changes::');

$SPEC{handle_cmd} = {
    v => 1.1,
    summary => "Like 'dists' subcommand, but also return CPAN Changes cwalitees in detail (-l) mode",
    args => {
        %dists_args,
        %calc_args,
    },
};
sub handle_cmd {
    require App::lcpan::Cmd::changes;
    require CPAN::Changes::Cwalitee;
    require File::Temp;

    my %args = @_;

    #my $state = App::lcpan::_init(\%args, 'ro');
    #my $dbh = $state->{dbh};

    my $res = App::lcpan::dists(hash_subset(\%args, \%dists_args));
    return $res unless $res->[0] == 200;
    return $res unless $args{detail};

    for my $row (@{$res->[2]}) {
        my $chres = App::lcpan::Cmd::changes::handle_cmd(module_or_dist_or_script => $row->{dist});
        unless ($chres->[0] == 200) {
            log_warn "Can't find Changes for distribution '$row->{dist}': $chres->[0] - $chres->[1]";
            next;
        }

        my ($fh, $filename) = File::Temp::tempfile();
        print $fh $res->[2];
        close $fh;

        my $cwres = CPAN::Changes::Cwalitee::calc_cpan_changes_cwalitee(
            path => $filename,
            hash_subset(\%args, \%calc_args),
        );
        unless ($cwres->[0] == 200) {
            log_warn "Can't calc cwalitee for distribution '$row->{dist}': $cwres->[0] - $cwres->[1]";
            next;
        }
        $row->{cwalitee} = $cwres->[3]{'func.score'};
    }

    $res;
}

1;
# ABSTRACT: Like 'dists' subcommand, but also return CPAN Changes cwalitees in detail (-l) mode

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::dists_with_changes_cwalitee - Like 'dists' subcommand, but also return CPAN Changes cwalitees in detail (-l) mode

=head1 VERSION

This document describes version 0.004 of App::lcpan::Cmd::dists_with_changes_cwalitee (from Perl distribution App-lcpan-CmdBundle-cwalitee), released on 2021-06-06.

=head1 DESCRIPTION

This module handles the L<lcpan> subcommand C<dists-with-changes-cwalitee>.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [$status_code, $reason, $payload, \%result_meta]

Like 'dists' subcommand, but also return CPAN Changes cwalitees in detail (-l) mode.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<added_or_updated_since> => I<date>

Include only records that are addedE<sol>updated since a certain date.

=item * B<added_or_updated_since_last_index_update> => I<true>

Include only records that are addedE<sol>updated since the last index update.

=item * B<added_or_updated_since_last_n_index_updates> => I<posint>

Include only records that are addedE<sol>updated since the last N index updates.

=item * B<added_since> => I<date>

Include only records that are added since a certain date.

=item * B<added_since_last_index_update> => I<true>

Include only records that are added since the last index update.

=item * B<added_since_last_n_index_updates> => I<posint>

Include only records that are added since the last N index updates.

=item * B<author> => I<str>

Filter by author.

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

Defaults to C<~/cpan>.

=item * B<detail> => I<bool>

=item * B<exclude_indicator> => I<array[str]>

Do not use these indicators.

=item * B<exclude_indicator_module> => I<array[perl::modname]>

Do not use indicators from these modules.

=item * B<exclude_indicator_status> => I<array[str]>

Do not use indicators having these statuses.

=item * B<has_buildpl> => I<bool>

=item * B<has_makefilepl> => I<bool>

=item * B<has_metajson> => I<bool>

=item * B<has_metayml> => I<bool>

=item * B<has_multiple_rels> => I<bool>

=item * B<include_indicator> => I<array[str]>

Only use these indicators.

=item * B<include_indicator_module> => I<array[perl::modname]>

Only use indicators from these modules.

=item * B<include_indicator_status> => I<array[str]> (default: ["stable"])

Only use indicators having these statuses.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<latest> => I<bool>

=item * B<min_indicator_severity> => I<uint> (default: 1)

Minimum indicator severity.

=item * B<or> => I<bool>

When there are more than one query, perform OR instead of AND logic.

=item * B<query> => I<array[str]>

Search query.

=item * B<query_type> => I<str> (default: "any")

=item * B<random> => I<true>

Random sort.

=item * B<rel_mtime_newer_than> => I<date>

=item * B<result_limit> => I<uint>

Only return a certain number of records.

=item * B<result_start> => I<posint> (default: 1)

Only return starting from the n'th record.

=item * B<sort> => I<array[str]> (default: ["dist"])

Sort the result.

=item * B<updated_since> => I<date>

Include only records that are updated since certain date.

=item * B<updated_since_last_index_update> => I<true>

Include only records that are updated since the last index update.

=item * B<updated_since_last_n_index_updates> => I<posint>

Include only records that are updated since the last N index updates.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-cwalitee>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-cwalitee>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-cwalitee>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
