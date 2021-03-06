package App::lcpan::Cmd::changes_entry;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-04'; # DATE
our $DIST = 'App-lcpan-CmdBundle-changes'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

require App::lcpan;
require App::lcpan::Cmd::changes;

our %SPEC;

$SPEC{handle_cmd} = {
    v => 1.1,
    summary => "Show a single entry from a distribution/module's Changes file",
    args => {
        %App::lcpan::common_args,
        %App::lcpan::mod_or_dist_or_script_args,
        version => {
            summary => 'Specify which version',
            schema => 'str*',
            pos => 1,
            description => <<'_',

If unspecified, will show the latest entry.

_
        },
    },
};
sub handle_cmd {
    my %args = @_;

    my $version = delete $args{version};
    my $res = App::lcpan::Cmd::changes::handle_cmd(%args);
    return $res unless $res->[0] == 200;

    require CPAN::Changes;
    my $changes = CPAN::Changes->load_string($res->[2]);

    my %releases;
    for my $release (reverse $changes->releases) {
        $version //= $release->version;
        $releases{ $release->version } = $release;
    }

    if ($releases{$version}) {
        [200, "OK", $releases{$version}->serialize];
    } else {
        [404, "No entry for version $version in the Changes for $args{module_or_dist_or_script}"];
    }
}

1;
# ABSTRACT: Show a single entry from a distribution/module's Changes file

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::changes_entry - Show a single entry from a distribution/module's Changes file

=head1 VERSION

This document describes version 0.001 of App::lcpan::Cmd::changes_entry (from Perl distribution App-lcpan-CmdBundle-changes), released on 2020-10-04.

=head1 DESCRIPTION

This module handles the L<lcpan> subcommand C<changes-entry>.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, payload, meta]

Show a single entry from a distributionE<sol>module's Changes file.

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

=item * B<module_or_dist_or_script>* => I<str>

Module or dist or script name.

=item * B<use_bootstrap> => I<bool> (default: 1)

Whether to use bootstrap database from App-lcpan-Bootstrap.

If you are indexing your private CPAN-like repository, you want to turn this
off.

=item * B<version> => I<str>

Specify which version.

If unspecified, will show the latest entry.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-changes>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-changes>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-changes>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
