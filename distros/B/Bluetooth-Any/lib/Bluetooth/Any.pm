package Bluetooth::Any;

our $DATE = '2018-10-22'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter::Rinci qw(import);
use File::Which qw(which);
use IPC::System::Options 'system', 'readpipe', -log=>1;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Common interface to bluetooth functions',
    description => <<'_',

This module provides common functions related to bluetooth.

_
};

$SPEC{'turn_on_bluetooth'} = {
    v => 1.1,
    summary => 'Turn on Bluetooth',
    description => <<'_',

Will try:
- rfkill

_
};
sub turn_on_bluetooth {
    my %args = @_;

  RFKILL:
    {
        unless (which("rfkill")) {
            log_trace "Cannot find rfkill, skipping using rfkill";
            last;
        }
        log_trace "Using rfkill to turn bluetooth on";
        system "rfkill", "unblock", "bluetooth";
        unless ($?) {
            return [200, "OK", undef, {'func.method'=>'rfkill'}];
        }
    }
    [500, "Failed, no methods succeeded"];
}

$SPEC{'turn_off_bluetooth'} = {
    v => 1.1,
    summary => 'Turn off Bluetooth',
    description => <<'_',

Will try:
- rfkill

_
};
sub turn_off_bluetooth {
    my %args = @_;

  RFKILL:
    {
        unless (which("rfkill")) {
            log_trace "Cannot find rfkill, skipping using rfkill";
            last;
        }
        log_trace "Using rfkill to turn bluetooth off";
        system "rfkill", "block", "bluetooth";
        unless ($?) {
            return [200, "OK", undef, {'func.method'=>'rfkill'}];
        }
    }
    [500, "Failed, no methods succeeded"];
}

$SPEC{'bluetooth_is_on'} = {
    v => 1.1,
    summary => 'Return true when bluetooth is on, or 0 otherwise',
    description => <<'_',

Will try:
- rfkill

_
};
sub bluetooth_is_on {
    my %args = @_;

  RFKILL:
    {
        unless (which("rfkill")) {
            log_trace "Cannot find rfkill, skipping using rfkill";
            last;
        }
        log_trace "Using rfkill to check bluetooth status";
        my $out;
        system {capture_stdout=>\$out}, "rfkill", "block", "bluetooth";
        last if $?;
        my $in_bt;
        for (split /^/m, $out) {
            if (/^\d/) {
                if (/bluetooth/i) {
                    $in_bt = 1;
                } else {
                    $in_bt = 0;
                }
                next;
            } else {
                if (/blocked:\s*yes/i) {
                    return [200, "OK", 0, {'func.method'=>'rfkill', 'cmdline.result'=>'Bluetooth is OFF', 'cmdline.exit_code'=>1}];
                }
            }
        }
        return [200, "OK", 1, {'func.method'=>'rfkill', 'cmdline.result'=>'Bluetooth is on', 'cmdline.exit_code'=>0}];
    }
    [500, "Failed, no methods succeeded"];
}

1;
# ABSTRACT: Common interface to bluetooth functions

__END__

=pod

=encoding UTF-8

=head1 NAME

Bluetooth::Any - Common interface to bluetooth functions

=head1 VERSION

This document describes version 0.001 of Bluetooth::Any (from Perl distribution Bluetooth-Any), released on 2018-10-22.

=head1 DESCRIPTION


This module provides common functions related to bluetooth.

=head1 FUNCTIONS


=head2 bluetooth_is_on

Usage:

 bluetooth_is_on() -> [status, msg, payload, meta]

Return true when bluetooth is on, or 0 otherwise.

Will try:
- rfkill

This function is not exported by default, but exportable.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 turn_off_bluetooth

Usage:

 turn_off_bluetooth() -> [status, msg, payload, meta]

Turn off Bluetooth.

Will try:
- rfkill

This function is not exported by default, but exportable.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 turn_on_bluetooth

Usage:

 turn_on_bluetooth() -> [status, msg, payload, meta]

Turn on Bluetooth.

Will try:
- rfkill

This function is not exported by default, but exportable.

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

Please visit the project's homepage at L<https://metacpan.org/release/Bluetooth-Any>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bluetooth-Any>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bluetooth-Any>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
