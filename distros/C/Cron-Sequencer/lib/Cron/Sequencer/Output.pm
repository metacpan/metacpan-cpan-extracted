#!perl

use v5.20.0;
use warnings;

# The parts of this that we use have been stable and unchanged since v5.20.0:
use feature qw(postderef);
no warnings 'experimental::postderef';

package Cron::Sequencer::Output;

our $VERSION = '0.03';

use Carp qw(confess croak);

# TODO - take formatter options. Mininally, timezone to use
sub new {
    my ($class, %opts) = @_;
    confess('new() called as an instance method')
        if ref $class;

    my %state = %opts{qw(count group hide-env json)};

    return bless \%state;
}

sub render {
    my ($self, @groups) = @_;

    return $self->{json}
        ? $self->render_json(@groups) : $self->render_text(@groups);
}

sub render_text {
    my ($self, @groups) = @_;

    # We assume that you normally want things grouped, so we aren't particularly
    # optimising the "flat" --no-group path:
    @groups = map { [$_] } map { @$_ } @groups
        unless $self->{group};

    my @output;

    for my $group (@groups) {
        # Should this be an error?
        unless (@$group) {
            push @output, "";
            next;
        }

        # 1+ entries that all fire at the same time
        my @cluster;

        for my $entry (@$group) {
            # The first blank line we add here is replaced below with the time.
            push @cluster, "";
            if ($self->{count} > 1) {
                push @cluster, "$entry->{file}:$entry->{lineno}: $entry->{when}";
            } else {
                push @cluster, "line $entry->{lineno}: $entry->{when}";
            }

            unless ($self->{hide_env}) {
                local *_;
                push @cluster, map "unset $_", $entry->{unset}->@*
                    if $entry->{unset};
                my $env = $entry->{env};
                push @cluster, map "$_=$env->{$_}", sort keys %$env
                    if $env;
            }

            push @cluster, $entry->{command};
        }

        # This replaces the blank line at the start of the "cluster".
        my $when = DateTime->from_epoch(epoch => $group->[0]{time});
        $cluster[0] = $when->stringify();

        push @output, @cluster, "", "";
    }

    # Drop the (second) empty string added just above in the last iteration of
    # the loop. If we don't do this, the second would cause an extra blank line
    # at the end. The first empty string causes the last (real) line to get a
    # newline (a newline that we want to have).
    pop @output;

    return join "\n", @output;
}

sub render_json {
    my ($self, @groups) = @_;
    require JSON::MaybeXS;

    my %opts = $self->{json}->%*;

    # CLI parser forbids 'seq' and 'split' simultaneously.
    my $seq = delete $opts{seq};
    my $start = $seq ? "\x1E" : "";
    my $split = delete $opts{split} || $seq;

    my $json = JSON::MaybeXS->new(%opts);

    my $munged;
    if ($self->{'hide-env'}) {
        # We shouldn't mutate our input, so we need to make a copy. As we need
        # to loop over the data anyway for --no-groups, combine the two loops
        if ($self->{group}) {
            for my $group (@groups) {
                # We need to create new anon arrays to hold our cleaned entries:
                my @cleaned;
                for my $entry (@$group) {
                    my %copy = %$entry;
                    # Clean
                    delete @copy{qw(unset env)};
                    # and flatten
                    push @cleaned, \%copy;
                }
                push @$munged, \@cleaned;
            }
        } else {
            for my $entry (map { @$_ } @groups) {
                my %copy = %$entry;
                # Clean
                delete @copy{qw(unset env)};
                # and flatten
                push @$munged, \%copy;
            }
        }
    } elsif ($self->{group}) {
        # Nothing to do!
        $munged = \@groups;
    } else {
        @$munged = map { @$_ } @groups;
    }

    return $json->encode($munged) . "\n"
        unless $split;

    return join '', map { $start . $json->encode($_) . "\n" } @$munged;
}

# TODO - improve this documentation, as a side effect of adding other output
# formats

=head1 NAME

Cron::Sequencer::Output

=head1 SYNOPSIS

    my $formatter = Cron::Sequencer::Output->new('hide-env' => 1);
    print $formatter->render($crontab->sequence($start, $end));

=head1 DESCRIPTION

This class implements output formatting for L<Cron::Sequencer>

Currently it can only output a pretty-printed text format, and the only option
is whether to show or hide environment variable declartions.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/cron-sequencer

=head1 AUTHOR

Nicholas Clark - C<nick@ccl4.org>

=cut

54;
