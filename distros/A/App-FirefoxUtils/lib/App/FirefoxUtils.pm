package App::FirefoxUtils;

our $DATE = '2019-11-28'; # DATE
our $DIST = 'App-FirefoxUtils'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;


our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to Firefox',
};

our %argopt_users = (
    users => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'user',
        summary => 'Kill Firefox processes of certain users only',
        schema => ['array*', of=>'unix::local_uid*'],
    },
);

sub _do_firefox {
    require Proc::Find;

    my ($which, %args) = @_;

    my $pids = Proc::Find::find_proc(
        filter => sub {
            my $p = shift;

            if ($args{users} && @{ $args{users} }) {
                return 0 unless grep { $p->{uid} == $_ } @{ $args{users} };
            }
            return 0 unless $p->{fname} =~ /\A(Web Content|WebExtensions|firefox-bin)\z/;
            log_trace "Found PID %d (cmdline=%s, fname=%s, uid=%d)", $p->{pid}, $p->{cmndline}, $p->{fname}, $p->{uid};
            1;
        },
    );

    if ($which eq 'pause') {
        kill STOP => @$pids;
    } elsif ($which eq 'unpause') {
        kill CONT => @$pids;
    } elsif ($which eq 'terminate') {
        kill KILL => @$pids;
    }
    [200, "OK", "", {"func.pids" => $pids}];
}

$SPEC{pause_firefox} = {
    v => 1.1,
    summary => "Pause (kill -STOP) Firefox",
    args => {
        %argopt_users,
    },
};
sub pause_firefox {
    _do_firefox('pause', @_);
}

$SPEC{unpause_firefox} = {
    v => 1.1,
    summary => "Unpause (resume, continue, kill -CONT) Firefox",
    args => {
        %argopt_users,
    },
};
sub unpause_firefox {
    _do_firefox('unpause', @_);
}

$SPEC{terminate_firefox} = {
    v => 1.1,
    summary => "Terminate  (kill -KILL) Firefox",
    args => {
        %argopt_users,
    },
};
sub terminate_firefox {
    _do_firefox('terminate', @_);
}

1;
# ABSTRACT: Utilities related to Firefox

__END__

=pod

=encoding UTF-8

=head1 NAME

App::FirefoxUtils - Utilities related to Firefox

=head1 VERSION

This document describes version 0.003 of App::FirefoxUtils (from Perl distribution App-FirefoxUtils), released on 2019-11-28.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to Firefox:

=over

=item * L<kill-firefox>

=item * L<pause-firefox>

=item * L<terminate-firefox>

=item * L<unpause-firefox>

=back

=head1 FUNCTIONS


=head2 pause_firefox

Usage:

 pause_firefox(%args) -> [status, msg, payload, meta]

Pause (kill -STOP) Firefox.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<users> => I<array[unix::local_uid]>

Kill Firefox processes of certain users only.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 terminate_firefox

Usage:

 terminate_firefox(%args) -> [status, msg, payload, meta]

Terminate  (kill -KILL) Firefox.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<users> => I<array[unix::local_uid]>

Kill Firefox processes of certain users only.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 unpause_firefox

Usage:

 unpause_firefox(%args) -> [status, msg, payload, meta]

Unpause (resume, continue, kill -CONT) Firefox.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<users> => I<array[unix::local_uid]>

Kill Firefox processes of certain users only.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-FirefoxUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-FirefoxUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-FirefoxUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Some other CLI utilities related to Firefox: L<dump-firefox-history> (from
L<App::DumpFirefoxHistory>).

L<App::ChromeUtils>

L<App::OperaUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
