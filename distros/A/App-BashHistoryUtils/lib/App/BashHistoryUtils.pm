package App::BashHistoryUtils;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-08-20'; # DATE
our $DIST = 'App-BashHistoryUtils'; # DIST
our $VERSION = '0.071'; # VERSION

our %SPEC;

our %arg_histfile = (
    histfile => {
        schema => 'str*',
        default => ($ENV{HISTFILE} // "$ENV{HOME}/.bash_history"),
        cmdline_aliases => {f=>{}},
        'x.completion' => ['filename'],
    },
);

our %args_filtering = (
    pattern => {
        summary => 'Match entries using a regex pattern',
        schema => 're*',
        cmdline_aliases => {p=>{}},
        tags => ['category:filtering'],
        pos => 0,
    },
    max_age => {
        summary => 'Match entries older than a certain age',
        schema => 'duration*',
        tags => ['category:filtering'],
    },
    min_age => {
        summary => 'Match entries younger than a certain age',
        schema => 'duration*',
        tags => ['category:filtering'],
    },
    ignore_case => {
        schema => ['bool', is=>1],
        cmdline_aliases => {i=>{}},
    },
    invert_match => {
        schema => ['bool', is=>1],
        #cmdline_aliases => {v=>{}}, # clashes with --version
    },
);

our %args_formatting = (
    strip_timestamp => {
        summary => 'Strip timestamps',
        schema => 'bool',
        tags => ['category:formatting'],
    },
);

sub _do {
    require Bash::History::Read;
    require Capture::Tiny;
    require Cwd;

    my $which = shift;
    my %args = @_;

    my $histfile = $args{histfile};
    return [412, "Can't find '$histfile': $!"] unless -f $histfile;
    my $realhistfile = Cwd::realpath($args{histfile})
        or return [412, "Can't find realpath of '$histfile': $!"];

    if ($which eq 'grep' && !defined($args{pattern})) {
        return [400, "Missing required argument: pattern"];
    }

    my $pat;
    if (defined $args{pattern}) {
        if ($args{ignore_case}) {
            $pat = qr/$args{pattern}/i;
        } else {
            $pat = qr/$args{pattern}/;
        }
    }

    my $now = time;

    my $code;
    if ($which eq 'each') {
        $code = eval "package main; no strict; sub { $args{code} }"; ## no critic: BuiltinFunctions::ProhibitStringyEval
        die if $@;
    } else {
        $code = sub {
            if (defined($args{max_age}) &&
                    $main::TS < $now-$args{max_age}) {
                $main::PRINT = 0;
            }
            if (defined($args{min_age}) &&
                    $main::TS > $now-$args{min_age}) {
                $main::PRINT = 0;
            }
            if ($pat && $_ =~ $pat) {
                $main::PRINT = 0;
            }

            if ($which eq 'grep') {
                $main::PRINT = !$main::PRINT;
            }
            if ($args{invert_match}) {
                $main::PRINT = !$main::PRINT;
            }

            if ($args{strip_timestamp}) {
                undef $main::TS;
            }
        };
    }

    local @ARGV = ($histfile);
    my $stdout = Capture::Tiny::capture_stdout(
        sub {
            Bash::History::Read::each_hist($code);
        }
    );

    if ($which eq 'grep' ||
            $which eq 'each' ||
            $which eq 'delete' && ($args{-dry_run} || !$args{inplace})) {
        return [200,"OK", $stdout, {'cmdline.skip_format'=>1}];
    } elsif ($which eq 'delete') {
        require File::Temp;
        my ($tempfh, $tempfile) = File::Temp::tempfile(template => "${realhistfile}XXXXXX");
        open my($fh), ">", $tempfile
            or return [500, "Can't open temporary file '$tempfile': $!"];

        print $fh $stdout
            or return [500, "Can't write (1) to temporary file '$tempfile': $!"];

        close $fh
            or return [500, "Can't write (2) to temporary file '$tempfile': $!"];

        rename $realhistfile, "$realhistfile~"
            or warn "Can't move '$realhistfile' to '$realhistfile~': $!";
        rename $tempfile, $realhistfile
            or return [500, "Can't replace temporary file '$tempfile' to '$realhistfile': $!"];
    }

    [200,"OK"];
}

$SPEC{grep_bash_history_entries} = {
    v => 1.1,
    summary => 'Show matching entries from bash history file',
    args => {
        %arg_histfile,
        %args_filtering,
        %args_formatting,
    },
};
sub grep_bash_history_entries {
    _do('grep', @_);
}

$SPEC{delete_bash_history_entries} = {
    v => 1.1,
    summary => 'Delete matching entries from bash history file',
    args => {
        %arg_histfile,
        %args_filtering,
        %args_formatting,
        inplace => {
            summary => 'Replace original bash history file',
            schema => ['bool', is=>1],
        },
    },
    features => {
        dry_run => 1,
    },
};
sub delete_bash_history_entries {
    _do('delete', @_);
}

{
    my $spec = {
        v => 1.1,
        summary => 'Run Perl code for each bash history entry',
        args => {
            %arg_histfile,
            %args_filtering,
            %args_formatting,
            code => {
                summary => 'Perl code to run for each entry',
                description => <<'_',

Inside the code, you can set `$PRINT` to 0 to suppress the output of the entry.
You can modify `$_` to modify the entry. `$TS` (timestamp) is also available.

_
                schema => 'str*',
                req => 1,
                pos => 0,
            },
        },
    };
    delete $spec->{args}{pattern};
    $SPEC{each_bash_history_entry} = $spec;
}
sub each_bash_history_entry {
    _do('each', @_);
}

1;
# ABSTRACT: CLI utilities related to bash history file

__END__

=pod

=encoding UTF-8

=head1 NAME

App::BashHistoryUtils - CLI utilities related to bash history file

=head1 VERSION

This document describes version 0.071 of App::BashHistoryUtils (from Perl distribution App-BashHistoryUtils), released on 2025-08-20.

=head1 DESCRIPTION

This distribution includes the following CLI utilities:

=over

=item * L<delete-bash-history-entries>

=item * L<each-bash-history-entry>

=item * L<grep-bash-history-entries>

=item * L<grephist>

=back

=head1 FUNCTIONS


=head2 delete_bash_history_entries

Usage:

 delete_bash_history_entries(%args) -> [$status_code, $reason, $payload, \%result_meta]

Delete matching entries from bash history file.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<histfile> => I<str> (default: "/home/u1/.bash_history")

(No description)

=item * B<ignore_case> => I<bool>

(No description)

=item * B<inplace> => I<bool>

Replace original bash history file.

=item * B<invert_match> => I<bool>

(No description)

=item * B<max_age> => I<duration>

Match entries older than a certain age.

=item * B<min_age> => I<duration>

Match entries younger than a certain age.

=item * B<pattern> => I<re>

Match entries using a regex pattern.

=item * B<strip_timestamp> => I<bool>

Strip timestamps.


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 each_bash_history_entry

Usage:

 each_bash_history_entry(%args) -> [$status_code, $reason, $payload, \%result_meta]

Run Perl code for each bash history entry.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<code>* => I<str>

Perl code to run for each entry.

Inside the code, you can set C<$PRINT> to 0 to suppress the output of the entry.
You can modify C<$_> to modify the entry. C<$TS> (timestamp) is also available.

=item * B<histfile> => I<str> (default: "/home/u1/.bash_history")

(No description)

=item * B<ignore_case> => I<bool>

(No description)

=item * B<invert_match> => I<bool>

(No description)

=item * B<max_age> => I<duration>

Match entries older than a certain age.

=item * B<min_age> => I<duration>

Match entries younger than a certain age.

=item * B<strip_timestamp> => I<bool>

Strip timestamps.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 grep_bash_history_entries

Usage:

 grep_bash_history_entries(%args) -> [$status_code, $reason, $payload, \%result_meta]

Show matching entries from bash history file.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<histfile> => I<str> (default: "/home/u1/.bash_history")

(No description)

=item * B<ignore_case> => I<bool>

(No description)

=item * B<invert_match> => I<bool>

(No description)

=item * B<max_age> => I<duration>

Match entries older than a certain age.

=item * B<min_age> => I<duration>

Match entries younger than a certain age.

=item * B<pattern> => I<re>

Match entries using a regex pattern.

=item * B<strip_timestamp> => I<bool>

Strip timestamps.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-BashHistoryUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-BashHistoryUtils>.

=head1 SEE ALSO

L<Bash::History::Read>

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

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-BashHistoryUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
