package App::bwk::mn;

our $DATE = '2019-07-08'; # DATE
our $VERSION = '0.000'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use IPC::System::Options qw(system readpipe);

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Some commands to manage Bulwark masternode',
};

$SPEC{status} = {
    v => 1.1,
    summary => 'bulwark-cli getblockcount + masternode status',
    description => <<'_',

This is mostly just a shortcut for running `bulwark-cli getblockcount` and
`bulwark-cli masternode status`.

_
    args => {
    },
    deps => {
        prog => 'bulwark-cli',
    },
};
sub status {
    my %args = @_;

    system({log=>1}, "bulwark-cli", "getblockcount");
    system({log=>1}, "bulwark-cli", "masternode", "status");
    [200];
}

1;
# ABSTRACT: Some commands to manage Bulwark masternode

__END__

=pod

=encoding UTF-8

=head1 NAME

App::bwk::mn - Some commands to manage Bulwark masternode

=head1 VERSION

This document describes version 0.000 of App::bwk::mn (from Perl distribution App-bwk-mn), released on 2019-07-08.

=head1 SYNOPSIS

Please see included script L<bwk-mn>.

=head1 FUNCTIONS


=head2 status

Usage:

 status() -> [status, msg, payload, meta]

bulwark-cli getblockcount + masternode status.

This is mostly just a shortcut for running C<bulwark-cli getblockcount> and
C<bulwark-cli masternode status>.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-bwk-mn>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-bwk-mn>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-bwk-mn>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<cryp-mn> from L<App::cryp::mn>

Other C<App::cryp::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
