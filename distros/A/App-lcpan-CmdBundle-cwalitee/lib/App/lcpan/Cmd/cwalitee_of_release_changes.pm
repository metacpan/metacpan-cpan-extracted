package App::lcpan::Cmd::cwalitee_of_release_changes;

our $DATE = '2020-01-19'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

require App::lcpan;
use Cwalitee::Common;
use Hash::Subset qw(hash_subset);

our %SPEC;

my %calc_args = Cwalitee::Common::args_calc('CPAN::Changes::');

$SPEC{handle_cmd} = {
    v => 1.1,
    summary => "Calculate the cwalitee of a release's Changes file",
    description => <<'_',

_
    args => {
        %App::lcpan::common_args,
        #%App::lcpan::dist_or_release_args,
        %App::lcpan::mod_or_dist_or_script_args,
        %calc_args,
   },
};
sub handle_cmd {
    require App::lcpan::Cmd::changes;
    require CPAN::Changes::Cwalitee;
    require File::Temp;

    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $mod_or_dist_or_script = $args{module_or_dist_or_script};
    $mod_or_dist_or_script =~ s!/!::!g; # XXX this should be done by coercer
    # XXX changes doesn't yet accept release name

    my $res = App::lcpan::Cmd::changes::handle_cmd(%args);
    return $res unless $res->[0] == 200;

    my ($fh, $filename) = File::Temp::tempfile();
    print $fh $res->[2];
    close $fh;

    CPAN::Changes::Cwalitee::calc_cpan_changes_cwalitee(
        path => $filename,
        hash_subset(\%args, \%calc_args),
    );
}

1;
# ABSTRACT: Calculate the cwalitee of a release's Changes file

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::cwalitee_of_release_changes - Calculate the cwalitee of a release's Changes file

=head1 VERSION

This document describes version 0.003 of App::lcpan::Cmd::cwalitee_of_release_changes (from Perl distribution App-lcpan-CmdBundle-cwalitee), released on 2020-01-19.

=head1 DESCRIPTION

This module handles the L<lcpan> subcommand C<cwalitee-of-release-changes>.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, payload, meta]

Calculate the cwalitee of a release's Changes file.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. /path/to/cpan.

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

=item * B<module_or_dist_or_script>* => I<str>

Module or dist or script name.

=item * B<use_bootstrap> => I<bool> (default: 1)

Whether to use bootstrap database from App-lcpan-Bootstrap.

If you are indexing your private CPAN-like repository, you want to turn this
off.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

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

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
