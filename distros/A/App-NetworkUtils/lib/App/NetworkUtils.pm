package App::NetworkUtils;

our $DATE = '2019-06-15'; # DATE
our $VERSION = '0.004'; # VERSION

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
    summary => 'Command-line utilities related to networking',
};

$SPEC{'turn_on_networking'} = {
    v => 1.1,
    summary => 'Turn on networking',
    description => <<'_',

Will try:
- nmcli

_
};
sub turn_on_networking {
    my %args = @_;

  NMCLI:
    {
        unless (which("nmcli")) {
            log_trace "Cannot find nmcli, skipping using nmcli";
            last;
        }
        log_trace "Using nmcli to turn networking on";
        system "nmcli", "networking", "on";
        unless ($?) {
            return [200, "OK", undef, {'func.method'=>'nmcli'}];
        }
    }
    [500, "Failed, no methods succeeded"];
}

$SPEC{'turn_off_networking'} = {
    v => 1.1,
    summary => 'Turn off networking',
    description => <<'_',

Will try:
- nmcli

_
};
sub turn_off_networking {
    my %args = @_;

  NMCLI:
    {
        unless (which("nmcli")) {
            log_trace "Cannot find nmcli, skipping using nmcli";
            last;
        }
        log_trace "Using nmcli to turn networking off";
        system "nmcli", "networking", "off";
        unless ($?) {
            return [200, "OK", undef, {'func.method'=>'nmcli'}];
        }
    }
    [500, "Failed, no methods succeeded"];
}

$SPEC{'turn_on_wireless'} = {
    v => 1.1,
    summary => 'Turn on wireless networking',
    description => <<'_',

Will try:
- nmcli

_
};
sub turn_on_wireless {
    my %args = @_;

  NMCLI:
    {
        unless (which("nmcli")) {
            log_trace "Cannot find nmcli, skipping using nmcli";
            last;
        }
        log_trace "Using nmcli to turn wireless networking on";
        system "nmcli", "radio", "wifi", "on";
        unless ($?) {
            return [200, "OK", undef, {'func.method'=>'nmcli'}];
        }
    }
    [500, "Failed, no methods succeeded"];
}

$SPEC{'turn_off_wireless'} = {
    v => 1.1,
    summary => 'Turn off wireless networking',
    description => <<'_',

Will try:
- nmcli

_
};
sub turn_off_wireless {
    my %args = @_;

  NMCLI:
    {
        unless (which("nmcli")) {
            log_trace "Cannot find nmcli, skipping using nmcli";
            last;
        }
        log_trace "Using nmcli to turn wireless networking off";
        system "nmcli", "radio", "wifi", "off";
        unless ($?) {
            return [200, "OK", undef, {'func.method'=>'nmcli'}];
        }
    }
    [500, "Failed, no methods succeeded"];
}

$SPEC{'networking_is_on'} = {
    v => 1.1,
    summary => 'Return true when networking is on, or 0 otherwise',
    description => <<'_',

Will try:
- nmcli

_
};
sub networking_is_on {
    my %args = @_;

  NMCLI:
    {
        unless (which("nmcli")) {
            log_trace "Cannot find nmcli, skipping using nmcli";
            last;
        }
        log_trace "Using nmcli to check networking status";
        my $out;
        system {capture_stdout=>\$out}, "nmcli", "networking", "connectivity";
        last if $?;
        $out =~ s/\R//;

        if ($out =~ /none/) {
            return [200, "OK", 0, {'func.method'=>'nmcli', 'cmdline.result'=>"Networking is off ($out)", 'cmdline.exit_code'=>0}];
        } else {
            return [200, "OK", 1, {'func.method'=>'nmcli', 'cmdline.result'=>"Networking is on ($out)", 'cmdline.exit_code'=>0}];
        }
    }
    [500, "Failed, no methods succeeded"];
}

1;
# ABSTRACT: Command-line utilities related to networking

__END__

=pod

=encoding UTF-8

=head1 NAME

App::NetworkUtils - Command-line utilities related to networking

=head1 VERSION

This document describes version 0.004 of App::NetworkUtils (from Perl distribution App-NetworkUtils), released on 2019-06-15.

=head1 DESCRIPTION

This distribution includes the following command-line utilities related to
networking:

=over

=item * L<networking-is-on>

=item * L<turn-networking-off>

=item * L<turn-networking-on>

=item * L<turn-off-networking>

=item * L<turn-off-wireless>

=item * L<turn-on-networking>

=item * L<turn-on-wireless>

=item * L<turn-wireless-off>

=item * L<turn-wireless-on>

=back

=head1 FUNCTIONS


=head2 networking_is_on

Usage:

 networking_is_on() -> [status, msg, payload, meta]

Return true when networking is on, or 0 otherwise.

Will try:
- nmcli

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



=head2 turn_off_networking

Usage:

 turn_off_networking() -> [status, msg, payload, meta]

Turn off networking.

Will try:
- nmcli

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



=head2 turn_off_wireless

Usage:

 turn_off_wireless() -> [status, msg, payload, meta]

Turn off wireless networking.

Will try:
- nmcli

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



=head2 turn_on_networking

Usage:

 turn_on_networking() -> [status, msg, payload, meta]

Turn on networking.

Will try:
- nmcli

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



=head2 turn_on_wireless

Usage:

 turn_on_wireless() -> [status, msg, payload, meta]

Turn on wireless networking.

Will try:
- nmcli

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

Please visit the project's homepage at L<https://metacpan.org/release/App-NetworkUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-NetworUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-NetworkUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::BluetoothUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
