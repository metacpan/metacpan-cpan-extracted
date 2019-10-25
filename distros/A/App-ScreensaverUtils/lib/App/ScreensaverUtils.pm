package App::ScreensaverUtils;

our $DATE = '2019-09-15'; # DATE
our $VERSION = '0.007'; # VERSION

use 5.010001;
use strict;
use warnings;
no warnings 'once'; # use of %arg_screensaver

use Screensaver::Any ();

our %SPEC;

$SPEC{prevent_screensaver_activated_while} = {
    v => 1.1,
    summary => 'Prevent screensaver activated while running a command',
    description => <<'_',

Uses <pm:Proc::Govern> to run a command, with the option `no-screensaver' to
instruct Proc::Govern to regularly simulate user activity, thus preventing the
screensaver from ever activating while running the command. For more options
when running command, e.g. timeout, load control, autorestart, use the module or
its CLI <prog:govproc> directly.

_
    args => {
        command => {
            schema => ['array*', of=>'str*'],
            req => 1,
            pos => 0,
            slurpy => 1,
        },
    },
};
sub prevent_screensaver_activated_while {
    require Proc::Govern;

    my %args = @_;

    my $exit = Proc::Govern::govern_process(
        command => $args{command},
        no_screensaver => 1,
    );

    [200, "Exit code is $exit", "", {"cmdline.exit_code"=>$exit}];
}

$SPEC{prevent_screensaver_activated_until_interrupted} = {
    v => 1.1,
    summary => 'Prevent screensaver activated until interrupted',
    description => <<'_',

Uses <pm:Proc::Govern> to run `sleep infinity`, with the option `no-screensaver'
to instruct Proc::Govern to regularly simulate user activity, thus preventing
the screensaver from ever activating. To stop preventing screensaver from
sleeping, press Ctrl-C.

For more options when running command, e.g. timeout, load control, autorestart,
use the module or its CLI <prog:govproc> directly.

Available in CLI with two shorter aliases: <prog:pause-screensaver> and
<prog:noss>.

_
    args => {
    },
};
sub prevent_screensaver_activated_until_interrupted {
    require Proc::Govern;

    my %args = @_;

    my $exit = Proc::Govern::govern_process(
        command => ['sleep', 'infinity'],
        no_screensaver => 1,
    );

    [200, "Exit code is $exit", "", {"cmdline.exit_code"=>$exit}];
}

$SPEC{get_screensaver_info} = {
    v => 1.1,
    summary => 'Get screensaver information (detected screensaver, is_active, is_enabled, timeout)',
    args => {
        %Screensaver::Any::arg_screensaver,
    },
};
sub get_screensaver_info {
    my %args = @_;

    my %res;

    {
        if ($args{screensaver}) {
            $res{screensaver} = $args{screensaver};
        } else {
            last unless $res{screensaver} = Screensaver::Any::detect_screensaver();
        }

        my $res = Screensaver::Any::screensaver_is_enabled(%args);
        $res{is_enabled} = $res->[0] == 200 ? $res->[2] : undef;

        $res = Screensaver::Any::screensaver_is_active(%args);
        $res{is_active} = $res->[0] == 200 ? $res->[2] : undef;

        $res = Screensaver::Any::get_screensaver_timeout(%args);
        $res{timeout} = $res->[0] == 200 ? $res->[2] : undef;
    }

    [200, "OK", \%res];

}

1;
# ABSTRACT: CLI utilities related to screensaver

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ScreensaverUtils - CLI utilities related to screensaver

=head1 VERSION

This document describes version 0.007 of App::ScreensaverUtils (from Perl distribution App-ScreensaverUtils), released on 2019-09-15.

=head1 DESCRIPTION

This distribution contains the following CLI utilities related to screensaver:

=over

=item * L<activate-screensaver>

=item * L<deactivate-screensaver>

=item * L<detect-screensaver>

=item * L<disable-screensaver>

=item * L<enable-screensaver>

=item * L<get-screensaver-info>

=item * L<get-screensaver-timeout>

=item * L<noss>

=item * L<pause-screensaver>

=item * L<prevent-screensaver-activated>

=item * L<prevent-screensaver-activated-until-interrupted>

=item * L<prevent-screensaver-activated-while>

=item * L<screensaver-is-active>

=item * L<screensaver-is-enabled>

=item * L<set-screensaver-timeout>

=back

=head1 FUNCTIONS


=head2 get_screensaver_info

Usage:

 get_screensaver_info(%args) -> [status, msg, payload, meta]

Get screensaver information (detected screensaver, is_active, is_enabled, timeout).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<screensaver> => I<str>

Explicitly set screensaver program to use.

The default, when left undef, is to detect what screensaver is running,

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 prevent_screensaver_activated_until_interrupted

Usage:

 prevent_screensaver_activated_until_interrupted() -> [status, msg, payload, meta]

Prevent screensaver activated until interrupted.

Uses L<Proc::Govern> to run C<sleep infinity>, with the option `no-screensaver'
to instruct Proc::Govern to regularly simulate user activity, thus preventing
the screensaver from ever activating. To stop preventing screensaver from
sleeping, press Ctrl-C.

For more options when running command, e.g. timeout, load control, autorestart,
use the module or its CLI L<govproc> directly.

Available in CLI with two shorter aliases: L<pause-screensaver> and
L<noss>.

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



=head2 prevent_screensaver_activated_while

Usage:

 prevent_screensaver_activated_while(%args) -> [status, msg, payload, meta]

Prevent screensaver activated while running a command.

Uses L<Proc::Govern> to run a command, with the option `no-screensaver' to
instruct Proc::Govern to regularly simulate user activity, thus preventing the
screensaver from ever activating while running the command. For more options
when running command, e.g. timeout, load control, autorestart, use the module or
its CLI L<govproc> directly.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<command>* => I<array[str]>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-ScreensaverUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ScreensaverUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ScreensaverUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
