#!perl

use v5.20.0;
use warnings;

package Cron::Sequencer;

our $VERSION = '0.03';

use Carp qw(croak confess);

require Cron::Sequencer::Parser;

# scalar -> filename
# ref to scalar -> contents
# hashref -> fancy

sub new {
    my ($class, @args) = @_;
    confess('new() called as an instance method')
        if ref $class;

    my @self;
    for my $arg (@args) {
        $arg = Cron::Sequencer::Parser->new($arg)
            unless UNIVERSAL::isa($arg, 'Cron::Sequencer::Parser');
        push @self, $arg->entries();
    }

    return bless \@self, $class;
}

# The intent is to avoid repeatedly calling ->next_time() on every event on
# every loop, which would make next() have O(n) performance, and looping a range
# O(n**2)

sub _next {
    my $self = shift;

    my $when = $self->[0]{next};
    my @found;

    for my $entry (@$self) {
        if ($entry->{next} < $when) {
            # If this one is earlier, discard everything we found so far
            $when = $entry->{next};
            @found = $entry;
        } elsif ($entry->{next} == $when) {
            # If it's a tie, add it to the list of found
            push @found, $entry;
        }
    }

    my @retval;

    for my $entry (@found) {
        my %published = (
            time => $when, %$entry{qw(file lineno when command)},
        );
        # Be careful not to set these if they are not present in the input hash
        # (If the key is present the value is always defined, so it doesn't
        # actually matter if we do an exists test or a defined test. It's sort
        # of annoying that the hash key-value slice syntax always provides a
        # list pair ($key, undef) for missing keys, but the current behaviour is
        # also useful in other cases, and we only have one syntax available)
        for my $key (qw(env unset)) {
            $published{$key} = $entry->{$key}
                if exists $entry->{$key};
        }
        push @retval, \%published;

        # We've "consumed" this firing, so update the cached value
        $entry->{next} = $entry->{whenever}->next_time($when);
    }

    return @retval;
}

sub sequence {
    my ($self, $start, $end) = @_;

    croak('sequence($epoch_seconds, $epoch_seconds)')
        if $start !~ /\A[1-9][0-9]*\z/ || $end !~ /\A[1-9][0-9]*\z/;

    return
        unless @$self;

    # As we have to call ->next_time(), which returns the next time *after* the
    # epoch time we pass it.
    --$start;

    for my $entry (@$self) {
        # Cache the time (in epoch seconds) for the next firing for this entry
        $entry->{next} = $entry->{whenever}->next_time($start);
    }

    my @results;
    while(my @group = $self->_next()) {
        last
            if $group[0]->{time} >= $end;

        push @results, \@group;
    }

    return @results;
}

=head1 NAME

Cron::Sequencer

=head1 SYNOPSIS

    my $crontab = Cron::Sequencer->new("/path/to/crontab");
    print encode_json([$crontab->sequence($start, $end)]);

=head1 DESCRIPTION

This class can take one or more crontabs and show the sequence of commands
that they would run for the time interval requested.

=head1 METHODS

=head2 new

C<new> takes a list of arguments each representing a crontab file, passes each
in turn to C<< Cron::Sequence::Parser->new >>, and then combines the parsed
files into a single set of crontab events.

See L<Cron::Sequencer::Parser/new> for the various formats to specify a crontab
file or its contents.

=head2 sequence I<from> I<to>

Generates the sequence of commands that the crontab(s) would run for the
specific time interval. I<from> and I<to> are in epoch seconds, I<from> is
inclusive, I<end> exclusive.

Hence for this input:

    30 12 * * * lunch!
    30 12 * * 5 POETS!

Calling C<< $crontab->sequence(45000, 131400) >> generates this output:

    [
      [
        {
          command => "lunch!",
          env     => undef,
          file    => "reminder",
          lineno  => 1,
          time    => 45000,
          unset   => undef,
          when    => "30 12 * * *",
        },
      ],
    ]

where the event(s) at C<131400> are not reported, because the end is
exclusive. Whereas C<< $crontab->sequence(45000, 131401) >> shows:

    [
      [
        {
          command => "lunch!",
          env     => undef,
          file    => "reminder",
          lineno  => 1,
          time    => 45000,
          unset   => undef,
          when    => "30 12 * * *",
        },
      ],
      [
        {
          command => "lunch!",
          env     => undef,
          file    => "reminder",
          lineno  => 1,
          time    => 131400,
          unset   => undef,
          when    => "30 12 * * *",
        },
        {
          command => "POETS!",
          env     => undef,
          file    => "reminder",
          lineno  => 2,
          time    => 131400,
          unset   => undef,
          when    => "30 12 * * 5",
        },
      ],
    ]

The output is structured as a list of lists, with events that fire at the
same time grouped as lists. This makes it easier to find cases where different
crontab lines trigger at the same time.

=head1 SEE ALSO

This module uses L<Algorithm::Cron> to implement the cron scheduling, but has
its own crontab file parser. There are many other modules on CPAN:

=over 4

=item L<Config::Crontab>

Parses, edits and outputs crontab files

=item L<Config::Generator::Crontab>

Outputs crontab files

=item L<DateTime::Cron::Simple>

Parse a cron entry and check against current time

=item L<DateTime::Event::Cron>

Generate recurrence sets from crontab lines and files

=item L<Mojar::Cron>

Cron-style datetime patterns and algorithm (for Mojolicious)

=item L<Parse::Crontab>

Parses crontab files

=item L<Pegex::Crontab>

A Pegex crontab Parser

=item L<QBit::Cron>

"Class for working with Cron" (for qbit)

=item L<Set::Crontab>

Expands crontab integer lists

=item L<Schedule::Cron>

cron-like scheduler for Perl subroutines

=item L<Schedule::Cron::Events>

take a line from a crontab and find out when events will occur

=item L<Time::Crontab>

Parser for crontab time specifications

=back

These modules fall into roughly three groups

=over 4

=item *

Abstract C<crontab> file parsing and manipulation

=item *

Parsing individule command time specification strings

=item *

Scheduling events in real time

=back

None of the "schedulers" are easy to adapt to show events (rather than running
them) and to do so for arbitrary time intervals. The parsers effectively provide
an "abstract syntax tree" for the crontab, but by design don't handle
"compiling" this into a sequence of "this command, with these environment
variable definitions in scope". The parser/compiler in this module is 70 lines
of code, including comments, and handles various corner cases and quirks of the
vixie crontab C parser code. Interfacing to one of AST parser modules and
implementing a "compiler" on it would likely be more code than this.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/cron-sequencer

=head1 AUTHOR

Nicholas Clark - C<nick@ccl4.org>

=cut

1;
