package App::lcpan::Cmd::cwalitees_of_modules_abstracts;

our $DATE = '2021-06-06'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

require App::lcpan;
use Cwalitee::Common;
use Hash::Subset qw(hash_subset);

our %SPEC;

my %calc_args = Cwalitee::Common::args_calc('Module::Abstract::');

$SPEC{handle_cmd} = {
    v => 1.1,
    summary => "Calculate the cwalitees of modules' Abstracts",
    description => <<'_',

_
    args => {
        %App::lcpan::common_args,
        %App::lcpan::mods_args,
        %calc_args,
    },
};
sub handle_cmd {
    require Module::Abstract::Cwalitee;

    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my @rows;
    for my $mod (@{ $args{modules} }) {
        my ($file_id, $abstract) = $dbh->selectrow_array(
            "SELECT file_id, abstract FROM module WHERE name=?", {}, $mod);
        $file_id or do {
            log_warn "No such module '$mod'";
        };

        my $cres = Module::Abstract::Cwalitee::calc_module_abstract_cwalitee(
            abstract => $abstract,
            module => $mod,
            hash_subset(\%args, \%calc_args),
        );
        unless ($cres->[0] == 200) {
            log_warn "Can't calc cwalitee for $mod: $cres->[0] - $cres->[1]";
            next;
        }

        push @rows, {
            module => $mod,
            abstract => $abstract,
            result => $cres->[2][-1]{result},
        };
    }

    [200, "OK", \@rows];
}

1;
# ABSTRACT: Calculate the cwalitees of modules' Abstracts

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::cwalitees_of_modules_abstracts - Calculate the cwalitees of modules' Abstracts

=head1 VERSION

This document describes version 0.004 of App::lcpan::Cmd::cwalitees_of_modules_abstracts (from Perl distribution App-lcpan-CmdBundle-cwalitee), released on 2021-06-06.

=head1 DESCRIPTION

This module handles the L<lcpan> subcommand C<cwalitees-of-modules-abstracts>.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [$status_code, $reason, $payload, \%result_meta]

Calculate the cwalitees of modules' Abstracts.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

Defaults to C<~/cpan>.

=item * B<exclude_indicator> => I<array[str]>

Do not use these indicators.

=item * B<exclude_indicator_module> => I<array[perl::modname]>

Do not use indicators from these modules.

=item * B<exclude_indicator_status> => I<array[str]>

Do not use indicators having these statuses.

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

=item * B<min_indicator_severity> => I<uint> (default: 1)

Minimum indicator severity.

=item * B<modules>* => I<array[perl::modname]>

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
