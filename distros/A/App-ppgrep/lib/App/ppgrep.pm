package App::ppgrep;

our $DATE = '2019-07-04'; # DATE
our $VERSION = '0.032'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{ppgrep} = {
    v => 1.1,
    summary => 'Look up parents\' processes based on name and other attributes',
    description => <<'_',

This utility is similar to <prog:pgrep> except that we only look at our
descendants (parent, parent's parent, and so on up to PID 1).

_
    args => {
        pattern => {
            summary => 'Only match processes whose name/cmdline match the pattern',
            schema => 'str*',
            pos => 0,
            tags => ['category:filtering'],
        },
        count => {
            summary => 'Suppress normal output; instead print a count of matching processes',
            schema => 'true*',
            cmdline_aliases => {c=>{}},
            tags => ['category:display'],
        },
        full => {
            summary => 'The pattern is normally only matched against the process name. When -f is set, the full command line is used.',
            schema => 'true*',
            cmdline_aliases => {f=>{}},
            tags => ['category:filtering'],
        },
        pgroup => {
            summary => 'Only match processes in the process group IDs listed',
            schema => ['array*', of=>'uint*', 'x.perl.coerce_rules' => ['str_comma_sep']],
            cmdline_aliases => {g=>{}},
            tags => ['category:filtering'],
        },
        group => {
            summary => 'Only match processes whose real group ID is listed. Either the numerical or symbolical value may be used.',
            schema => ['array*', of=>'str*', 'x.perl.coerce_rules' => ['str_comma_sep']],
            cmdline_aliases => {G=>{}},
            tags => ['category:filtering'],
        },
        list_name => {
            summary => 'List the process name as well as the process ID',
            schema => ['true*'],
            cmdline_aliases => {l=>{}},
            tags => ['category:display'],
        },
        list_full => {
            summary => 'List the full command line as well as the process ID',
            schema => ['true*'],
            cmdline_aliases => {a=>{}},
            tags => ['category:display'],
        },
        session => {
            summary => 'Only match processes whose process session ID is listed',
            schema => ['array*', of=>'uint*', 'x.perl.coerce_rules' => ['str_comma_sep']],
            cmdline_aliases => {s=>{}},
            tags => ['category:filtering'],
        },
        terminal => {
            summary => 'Only match processes whose controlling terminal is listed. The terminal name should be specified without the "/dev/" prefix.',
            schema => ['array*', of=>'str*', 'x.perl.coerce_rules' => ['str_comma_sep']],
            cmdline_aliases => {t=>{}},
            tags => ['category:filtering'],
        },
        euid => {
            summary => 'Only match processes whose effective user ID is listed. Either the numerical or symbolical value may be used.',
            schema => ['array*', of=>'str*', 'x.perl.coerce_rules' => ['str_comma_sep']],
            cmdline_aliases => {u=>{}},
            tags => ['category:filtering'],
        },
        uid => {
            summary => 'Only match processes whose user ID is listed. Either the numerical or symbolical value may be used.',
            schema => ['array*', of=>'str*', 'x.perl.coerce_rules' => ['str_comma_sep']],
            cmdline_aliases => {U=>{}},
            tags => ['category:filtering'],
        },
        inverse => {
            summary => 'Negates the matching',
            schema => ['true*'],
            cmdline_aliases => {v=>{}},
            tags => ['category:filtering'],
        },
        exact => {
            summary => 'Only match processes whose names (or command line if -f is specified) exactly match the pattern',
            schema => ['true*'],
            cmdline_aliases => {x=>{}},
            tags => ['category:filtering'],
        },
        # XXX --ns (root only, currently Proc::ProcessTable doesn't output this)
        # XXX --nslist (root only, currently Proc::ProcessTable doesn't output this)
    },
    links => [
        'prog:pgrep',
    ],
};
sub ppgrep {
    require Proc::Find::Parents;

    my %args = @_;

    my $ppids = Proc::Find::Parents::get_parent_processes(
        $$, {method=>'proctable'});

    # convert to numerical
    if ($args{group} && @{$args{group}}) {
        for (@{ $args{group} }) {
            if (/\D/) {
                my @ent = getgrnam($_);
                $_ = @ent ? $ent[2] : -1;
            }
        }
    }
    if ($args{uid} && @{$args{uid}}) {
        for (@{ $args{uid} }) {
            if (/\D/) {
                my @ent = getpwnam($_);
                $_ = @ent ? $ent[2] : -1;
            }
        }
    }
    if ($args{euid} && @{$args{euid}}) {
        for (@{ $args{euid} }) {
            if (/\D/) {
                my @ent = getpwnam($_);
                $_ = @ent ? $ent[2] : -1;
            }
        }
    }

    my @res;
    for my $p (@$ppids) {
        my $match = 1;
      MATCHING: {

            if (defined $args{pattern}) {
                if ($args{exact}) {
                    if ($args{full}) {
                        do { $match = 0; last MATCHING } unless $p->{cmdline} eq $args{pattern};
                    } else {
                        do { $match = 0; last MATCHING } unless $p->{name}    eq $args{pattern};
                    }
                } else {
                    if ($args{full}) {
                        do { $match = 0; last MATCHING } unless $p->{cmdline} =~ /$args{pattern}/;
                    } else {
                        do { $match = 0; last MATCHING } unless $p->{name}    =~ /$args{pattern}/;
                    }
                }
            }

            if ($args{pgroup} && @{$args{pgroup}}) {
                my $found = 0;
                for (@{ $args{pgroup} }) {
                    if ($_ == $p->{pgrp}) {
                        $found++; last;
                    }
                }
                do { $match = 0; last MATCHING } unless $found;
            }

            if ($args{group} && @{$args{group}}) {
                my $found = 0;
                for (@{ $args{group} }) {
                    if ($_ == $p->{gid}) {
                        $found++; last;
                    }
                }
                do { $match = 0; last MATCHING } unless $found;
            }

            if ($args{uid} && @{$args{uid}}) {
                my $found = 0;
                for (@{ $args{uid} }) {
                    if ($_ == $p->{uid}) {
                        $found++; last;
                    }
                }
                do { $match = 0; last MATCHING } unless $found;
            }

            if ($args{euid} && @{$args{euid}}) {
                my $found = 0;
                for (@{ $args{euid} }) {
                    if ($_ == $p->{euid}) {
                        $found++; last;
                    }
                }
                do { $match = 0; last MATCHING } unless $found;
            }

            if ($args{session} && @{$args{session}}) {
                my $found = 0;
                for (@{ $args{session} }) {
                    if ($_ == $p->{sess}) {
                        $found++; last;
                    }
                }
                do { $match = 0; last MATCHING } unless $found;
            }

            if ($args{terminal} && @{$args{terminal}}) {
                my $found = 0;
                $p->{ttydev} =~ s!^/dev/!!;
                for (@{ $args{terminal} }) {
                    if ($_ eq $p->{ttydev}) {
                        $found++; last;
                    }
                }
                do { $match = 0; last MATCHING } unless $found;
            }

        } # MATCHING

        if ($args{inverse}) {
            push @res, $p unless $match;
        } else {
            push @res, $p if $match;
        }
    }

    my $res = "";
    if ($args{count}) {
        $res .= scalar(@res) . "\n";
    } elsif ($args{list_full}) {
        for (@res) {
            $res .= "$_->{pid} $_->{cmdline}\n";
        }
    } elsif ($args{list_name}) {
        for (@res) {
            $res .= "$_->{pid} $_->{name}\n";
        }
    } else {
        for (@res) {
            $res .= "$_->{pid}\n";
        }
    }

    [200, "OK", $res, {
        'cmdline.skip_format'=>1,
        'cmdline.exit_code' => @res ? 0:1,
    }];
}

1;
# ABSTRACT: Look up parents' processes based on name and other attributes

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ppgrep - Look up parents' processes based on name and other attributes

=head1 VERSION

This document describes version 0.032 of App::ppgrep (from Perl distribution App-ppgrep), released on 2019-07-04.

=head1 SYNOPSIS

See included script L<ppgrep>.

=head1 FUNCTIONS


=head2 ppgrep

Usage:

 ppgrep(%args) -> [status, msg, payload, meta]

Look up parents' processes based on name and other attributes.

This utility is similar to L<pgrep> except that we only look at our
descendants (parent, parent's parent, and so on up to PID 1).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<count> => I<true>

Suppress normal output; instead print a count of matching processes.

=item * B<euid> => I<array[str]>

Only match processes whose effective user ID is listed. Either the numerical or symbolical value may be used.

=item * B<exact> => I<true>

Only match processes whose names (or command line if -f is specified) exactly match the pattern.

=item * B<full> => I<true>

The pattern is normally only matched against the process name. When -f is set, the full command line is used.

=item * B<group> => I<array[str]>

Only match processes whose real group ID is listed. Either the numerical or symbolical value may be used.

=item * B<inverse> => I<true>

Negates the matching.

=item * B<list_full> => I<true>

List the full command line as well as the process ID.

=item * B<list_name> => I<true>

List the process name as well as the process ID.

=item * B<pattern> => I<str>

Only match processes whose name/cmdline match the pattern.

=item * B<pgroup> => I<array[uint]>

Only match processes in the process group IDs listed.

=item * B<session> => I<array[uint]>

Only match processes whose process session ID is listed.

=item * B<terminal> => I<array[str]>

Only match processes whose controlling terminal is listed. The terminal name should be specified without the "/dev/" prefix.

=item * B<uid> => I<array[str]>

Only match processes whose user ID is listed. Either the numerical or symbolical value may be used.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-ppgrep>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ppgrep>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ppgrep>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO


L<pgrep>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
