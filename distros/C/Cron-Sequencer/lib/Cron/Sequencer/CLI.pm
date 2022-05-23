#!perl

use v5.20.0;
use warnings;

# The parts of this that we use have been stable and unchanged since v5.20.0:
use feature qw(postderef);
no warnings 'experimental::postderef';

package Cron::Sequencer::CLI;

use parent qw(Exporter);
require DateTime;
use Getopt::Long qw(GetOptionsFromArray);

our $VERSION = '0.04';
our @EXPORT_OK = qw(calculate_start_end parse_argv);

my %known_json = map { $_, 1 } qw(seq split pretty canonical);

sub parse_argv {
    my ($pod2usage, @argv) = @_;

    my @groups;
    my $current = [];
    my $json;

    # Split the command line into sections:
    for my $item (@argv) {
        if ($item eq '--') {
            push @groups, $current;
            $current = [];
        } elsif ($item =~ /\A--json(?:=(.*)|)\z/s && !@groups) {
            # GetOpt::Long doesn't appear to have a way to specify to specify an
            # option that can take an argument, but it so, the argument must be
            # given in the '=' form.
            # We'd like to support `--json` and `--json=pretty` but have
            # `--json pretty` mean the same as `./pretty --json`

            if (length $1) {
                for my $opt (split ',', $1) {
                    $pod2usage->(exitval => 255,
                                 message => "Unknown --json option '$opt'")
                        unless $known_json{$opt};
                    $json->{$opt} = 1;
                }
                $pod2usage->(exitval => 255,
                             message => "Can't use --json=seq with --json=split")
                    if $json->{seq} && $json->{split};
            } else {
                # Flag that we saw --json
                $json //= {};
            }
        } else {
            push @$current, $item;
        }
    }
    push @groups, $current;

    my %global_options = (
        group => 1,
    );

    Getopt::Long::Configure('pass_through', 'auto_version', 'auto_help');
    unless(GetOptionsFromArray($groups[0], \%global_options,
                               'show=s',
                               'from=s',
                               'to=s',
                               'hide-env',
                               'group!',
                           )) {
        $pod2usage->(exitval => 255, verbose => 1);
    }

    my ($start, $end) = calculate_start_end(\%global_options);

    my @input;

    Getopt::Long::Configure('no_pass_through', 'no_auto_version');
    for my $group (@groups) {
        my %options;
        unless(GetOptionsFromArray($group, \%options,
                                   'env=s@',
                                   'ignore=s@'
                               )) {
            $pod2usage->(exitval => 255, verbose => 1);
        }
        $pod2usage->(exitval => 255,
                     message => "--env and --hide-env options can't be used together")
            if $global_options{'hide-env'} && $options{env};

        push @input, map {{ source => $_, %options{qw(env ignore)} }} @$group;
    }

    $pod2usage->(exitval => 255)
        unless @input;

    my $output = [%global_options{qw(hide-env group)}, count => scalar @input];

    push @$output, json => $json
        if $json;

    return ($start, $end, $output, @input);
}

sub calculate_start_end {
    my $options = shift;

    my ($start, $end);

    if (defined $options->{from} || defined $options->{to}) {
        die "$0: Can't use --show with --from or --to\n"
            if defined $options->{show};

        # Default is midnight gone
        my $from = $options->{from} // '+0';
        if ($from =~ /\A[1-9][0-9]*\z/) {
            # Absolute epoch seconds
            $start = $from;
        } elsif ($from =~ /\A[-+](?:0|[1-9][0-9]*)\z/) {
            # Seconds relative to midnight gone
            $start = DateTime->today()->epoch() + $from;
        } else {
            die "$0: Can't parse '$from' for --from\n";
        }

        # Default is to show 1 hour
        my $to = $options->{to} // '+3600';
        if ($to =~ /\A[1-9][0-9]+\z/) {
            # Absolute epoch seconds
            $end = $to;
        } elsif ($to =~ /\A\+[1-9][0-9]*\z/) {
            # Seconds relative to from
            # As $end >= $start, '+0' doesn't make sense
            $end = $start + $to;
        } else {
            die "$0: Can't parse '$to' for --to\n";
        }

        die "$0: End $end must be after start $start (--from=$from --to=$to)\n"
            if $end <= $start;
    } else {
        my $show = $options->{show} // 'today';
        if ($show =~ /\A\s*(last|this|next)\s+(minute|hour|day|week)\s*\z/) {
            my $which = $1;
            my $what = $2;
            my $start_of_period = DateTime->now()->truncate(to => $what);
            if ($which eq 'last') {
                $end = $start_of_period->epoch();
                $start_of_period->subtract($what . 's' => 1);
                $start = $start_of_period->epoch();
            } else {
                $start_of_period->add($what . 's' => 1)
                    if $which eq 'next';
                $start = $start_of_period->epoch();
                $start_of_period->add($what . 's' => 1);
                $end = $start_of_period->epoch();
            }
        } elsif ($show =~ /\A\s*(last|next)\s+([1-9][0-9]*)\s+(minute|hour|day|week)s\s*\z/) {
            my $which = $1;
            my $count = $2;
            my $what = $3;

            # I was going to name this $now, but then realised that if I add or
            # subtract on it, it won't be very "now" any more...
            my $aargh_mutable = DateTime->now();

            if ($which eq 'last') {
                $end = $aargh_mutable->epoch();
                $aargh_mutable->subtract($what . 's' => $count);
                $start = $aargh_mutable->epoch();
            } else {
                $start= $aargh_mutable->epoch();
                $aargh_mutable->add($what . 's' => $count);
                $end = $aargh_mutable->epoch();
            }
        } elsif ($show =~ /\A\s*yesterday\s*\z/) {
            my $midnight = DateTime->today();
            $end = $midnight->epoch();
            $midnight->subtract(days => 1);
            $start = $midnight->epoch();
        } elsif ($show =~ /\A\s*(today|tomorrow)\s*\z/) {
            my $midnight = DateTime->today();
            $midnight->add(days => 1)
                if $1 eq 'tomorrow';
            $start = $midnight->epoch();
            $midnight->add(days => 1);
            $end = $midnight->epoch();
        } elsif ($show =~ /\A(?:last|this|next)\z/) {
            die "$0: Unknown time period '$show' for --show (did you forget to escape the space after it?)\n";
        } else {
            die "$0: Unknown time period '$show' for --show\n";
        }
    }

    return ($start, $end);
}

=head1 NAME

Cron::Sequencer::CLI

=head1 SYNOPSIS

This module exists to make it easy to test the command line option parsing
of L<bin/cron-sequencer>. It's for "internal use only", and subject to change
(or deletion) without warning.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/cron-sequencer

=head1 AUTHOR

Nicholas Clark - C<nick@ccl4.org>

=cut

1;
