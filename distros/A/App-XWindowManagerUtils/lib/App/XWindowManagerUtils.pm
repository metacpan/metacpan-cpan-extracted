package App::XWindowManagerUtils;

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use Exporter qw(import);
use IPC::System::Options 'system', -log=>1;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-04-06'; # DATE
our $DIST = 'App-XWindowManagerUtils'; # DIST
our $VERSION = '0.003'; # VERSION

our @EXPORT_OK = qw(
                       list_xwm_windows
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to X Window Manager',
};

$SPEC{list_xwm_windows} = {
    v => 1.1,
    summary => "List all Windows",
    description => <<'MARKDOWN',

This utility is currently a wrapper for <prog:wmctrl>.

MARKDOWN
    args => {
        query => {
            schema => ['array*', of=>'str*'],
            pos => 0,
            slurpy => 1,
            description => <<'MARKDOWN',

Queries are matched against window titles, IDs, and KDE activity names & GUIDs
(if KDE activity names & GUIDs are requested).

MARKDOWN
            tags => ['category:filtering'],
        },
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
        with_kde_activity => {
            summary => 'Show KDE activity GUID for each window (old name for with_kde_activity_guid)',
            schema => 'bool*',
        },
        with_kde_activity_guid => {
            summary => 'Show KDE activity GUID for each window',
            schema => 'bool*',
        },
        with_kde_activity_name => {
            summary => 'Show KDE activity name for each window',
            schema => 'bool*',
            cmdline_aliases => {k=>{}},
        },
    },
    deps => {
        prog => 'wmctrl',
    },
};
sub list_xwm_windows {
    my %args = @_;

    my $with_kde_activity =
        $args{with_kde_activity} ||
        $args{with_kde_activity_guid} ||
        $args{with_kde_activity_name};
    my $detail = $args{detail};
    $detail //=1 if $with_kde_activity;

    my @rows;
    system({capture_stdout => \my $stdout}, "wmctrl", "-lpG");
    return [500, "Can't run wmctrl"] if $?;

    my @positive_query;
    my @negative_query;
  BUILD_QUERY: {
        for my $query (@{ $args{query} // [] }) {
            if ($query =~ /\A-(.*)/) {
                my $q = $1;
                push @negative_query, sub { $_[0] =~ /\Q$q\E/i ? 1 : 0 };
            } elsif ($query =~ m!\A/(.*)/\z!) {
                my $re = $1;
                push @positive_query, sub { $_[0] =~ /$re/i ? 1 : 0 };
            } else {
                push @positive_query, sub { $_[0] =~ /\Q$query\E/i ? 1 : 0 };
            }
        }
    } # BUILD_QUERY

    my $res_list_kact;
    if ($with_kde_activity) {
        require Desktop::KDEActivity::Util;
        $res_list_kact = Desktop::KDEActivity::Util::list_kde_activities(detail=>1);
        return [500, "Can't list KDE activities: $res_list_kact->[0] - $res_list_kact->[1]"]
            unless $res_list_kact->[0] == 200;
    }

  LINE:
    for my $line (split /^/m, $stdout) {
        my ($id, $desktop, $pid,
            $x, $y, $width, $height,
            $host, $title) = $line =~ /^(\S+)\s+(\S+)\s+(\d+)\s+
                                       (\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+
                                       (\S+)\s+(.*)/x;
        my $row = {
            id => $id,
            desktop => $desktop,
            pid => $pid,
            x => $x,
            y => $y,
            width => $width,
            height => $height,
            host => $host,
            title => $title,
        };

      GET_KDE_ACTIVITY: {
            last unless $with_kde_activity;
            my $res_get_act = get_xwm_window_kde_activity(id => $row->{id});
            if ($res_get_act->[0] != 200) {
                log_warn "Can't get KDE activity for window id %s: %d - %s", $row->{id}, $res_get_act->[0], $res_get_act->[1];
                last;
            }
            my $guid = $res_get_act->[2];
            my $name;
            if ($args{with_kde_activity_name}) {
                for my $row (@{ $res_list_kact->[2] }) {
                    if ($guid && $row->{guid} eq $guid) {
                        $name = $row->{name};
                        last;
                    }
                }
            }
            $row->{kde_activity_guid} = $guid if $args{with_kde_activity} || $args{with_kde_activity_guid};
            $row->{kde_activity_name} = $name if $args{with_kde_activity_name};
        }

      FILTER: {
          NEGATIVE_QUERY: {
                last unless @negative_query;
                my $match = 1;
                for my $query (@negative_query) {
                    if ($query->($row->{title})) {
                        $match = 0; goto L1;
                    }
                }
              L1:
                unless ($match) {
                    log_trace "Skipping window id=%s title=<%s>: matches negative query in %s", $row->{id}, $row->{title}, $args{query};
                    next LINE;
                }
            }

          POSITIVE_QUERY: {
                last unless @positive_query;
                my $match = 1;
                for my $query (@positive_query) {
                    if (!$query->(
                        join("|", grep {defined} ($row->{title}, $row->{kde_activity_guid}, $row->{kde_activity_name}))
                    )) {
                        $match = 0; goto L1;
                    }
                }

              L1:
                unless ($match) {
                    log_trace "Skipping window id=%s title=<%s>: does not match all positive query in %s", $row->{id}, $row->{title}, $args{query};
                    next LINE;
                }
            } # QUERY
        } # FILTER

        push @rows, $row;
    } # for line

    unless ($args{detail}) {
        @rows = map { $_->{id} } @rows;
    }

    [200, "OK", \@rows];
}

$SPEC{get_xwm_window_kde_activity} = {
    v => 1.1,
    summary => "Get the KDE activity GUID(s) of a specific window",
    description => <<'MARKDOWN',

A window can be displayed in more than one KDE activities, so this utility can
return a comma-separated list of GUIDs.

MARKDOWN
    args => {
        id => {
            summary => 'Window ID, specified in hex form with 0x prefix, e.g. 0x05a0000e',
            schema => ['str*'],
            req => 1,
            pos => 0,
        },
    },
    deps => {
        all => [
            {prog => 'wmctrl'},
            {prog => 'xprop'},
        ],
    },
};
sub get_xwm_window_kde_activity {
    my %args = @_;

    my $id = $args{id} or return [400, "Please specify id"];

    system({capture_stdout => \my $stdout, capture_stderr => \my $stderr},
           "xprop", "-id", $id, "_KDE_NET_WM_ACTIVITIES");
    if ($?) {
        if ($stderr =~ /BadWindow.*invalid Window parameter/) {
            return [404, "No such window ID"];
        } else {
            return [500, "Can't successfully run xprop"];
        }
    } else {
        # sample output: _KDE_NET_WM_ACTIVITIES(STRING) = "40eabb80-2103-48af-8977-23b6e06fbcc3"
        my ($guid) = $stdout =~ /^_KDE_NET_WM_ACTIVITIES.+"([^"]+)"/;

        return [200, "OK", $guid];
    }
}

1;
# ABSTRACT: Utilities related to X Window Manager

__END__

=pod

=encoding UTF-8

=head1 NAME

App::XWindowManagerUtils - Utilities related to X Window Manager

=head1 VERSION

This document describes version 0.003 of App::XWindowManagerUtils (from Perl distribution App-XWindowManagerUtils), released on 2026-04-06.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to "X Window Manager":

=over

=item * L<get-xwm-window-kde-activity>

=item * L<list-xwm-windows>

=back

Under the hood, it's currently a wrapper to tools like C<wmctrl>, etc.

C<wmctrl> works on EWMH-compliant X11 window managers. This means mainstream
desktop environments like KWin, Xfwm, Mutter (GNOME). It works partially or
doesn't work with minimalist window managers like dwm, suckless. It partially
works with Wayland where there is an X compatibility layer, e.g. GNOME Wayland,
KDE Plasma Wayland.

=head1 FUNCTIONS


=head2 get_xwm_window_kde_activity

Usage:

 get_xwm_window_kde_activity(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get the KDE activity GUID(s) of a specific window.

A window can be displayed in more than one KDE activities, so this utility can
return a comma-separated list of GUIDs.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<id>* => I<str>

Window ID, specified in hex form with 0x prefix, e.g. 0x05a0000e.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 list_xwm_windows

Usage:

 list_xwm_windows(%args) -> [$status_code, $reason, $payload, \%result_meta]

List all Windows.

This utility is currently a wrapper for L<wmctrl>.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

(No description)

=item * B<query> => I<array[str]>

Queries are matched against window titles, IDs, and KDE activity names & GUIDs
(if KDE activity names & GUIDs are requested).

=item * B<with_kde_activity> => I<bool>

Show KDE activity GUID for each window (old name for with_kde_activity_guid).

=item * B<with_kde_activity_guid> => I<bool>

Show KDE activity GUID for each window.

=item * B<with_kde_activity_name> => I<bool>

Show KDE activity name for each window.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-XWindowManagerUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-XWindowManagerUtils>.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-XWindowManagerUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
