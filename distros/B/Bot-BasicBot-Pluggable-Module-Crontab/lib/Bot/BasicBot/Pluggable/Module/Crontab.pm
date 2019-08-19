package Bot::BasicBot::Pluggable::Module::Crontab;

use warnings;
use strict;

our $VERSION = '1.01';
 
#----------------------------------------------------------------------------

#############################################################################
#Library Modules                                                            #
#############################################################################

use base qw(Bot::BasicBot::Pluggable::Module);

use DateTime;
use IO::File;
use Time::Crontab;

#############################################################################
#Variables
#############################################################################

my @crontab;
my $load_time = 0;

#----------------------------------------------------------------------------

#############################################################################
# Public Methods                                                            #
#############################################################################

sub init {
    my $self = shift;

    my $file = $self->store->get( 'crontab', 'file' );
    unless($file) {
        $file = $0;
        $file =~ s/\.pl$/.cron/;
    }

    $self->store->set( 'crontab', 'file', $file );
}
 
sub help {
    return "Posts messages to specific channels based on a crontab.";
}
 
sub tick {
    my $self = shift;

    $self->_load_cron();
    my $wkno = DateTime->now->week_number;

    for my $cron (@crontab) {
        next unless($cron->{tab}->match(time));
        next unless(
                $cron->{weekno} eq '*' 
            || ( $cron->{modulus} && $cron->{result} == ($wkno % $cron->{modulus}) )
            || ( $cron->{weekno} =~ /^\d+$/ && $wkno == $cron->{weekno} )
        );

        $self->say(
            channel => $cron->{channel},
            body    => $cron->{message}
        );
    }

    return 60 - DateTime->now->second; # ensure we are running each minute
}

#############################################################################
# Private Methods                                                           #
#############################################################################

sub _load_cron {
    my $self = shift;

    my $fn = $self->store->get( 'crontab', 'file' ) or return 0;
    return 0 unless(-r $fn); # file must be readable

    my $mod = (stat($fn))[9];
    return 1 if($mod <= $load_time); # don't reload if not modified

    @crontab = ();

    my $fh = IO::File->new($fn,'r') or die "Cannot load file [$fn]: $!\n";
    while(<$fh>) {
        s/\s+$//;
        my $line = $_;
        next unless($line);

        next if($line =~ /^#/); # ignore comment lines
        next if($line =~ /^$/); # ignore blank lines

        my @fields = split(/ /,$line,8);
        my $crontab = join(' ',(@fields)[0..4]);
        my $tab;
        eval { $tab = Time::Crontab->new($crontab) };
        next if($@);

        my ($modulus,$result);
        ($modulus,$result) = split(/\//,$fields[5],2)    if($fields[5] =~ m!^\d+/\d+!);

        push @crontab, {
            tab     => $tab,
            weekno  => $fields[5],
            modulus => $modulus,
            result  => $result,
            channel => $fields[6],
            message => $fields[7]
        };

        print "added $crontab $fields[5] = $fields[6] - $fields[7]\n";
    }

    $fh->close;
    $load_time = $mod;
}
 
 
1;
 
__END__
 
#----------------------------------------------------------------------------

=head1 NAME
 
Bot::BasicBot::Pluggable::Module::Crontab - Provides a crontab-like message service for IRC channels
 
=head1 DESCRIPTION

This module does not respond to user messages, public or private. It is purely
for posting messages to notminated channels as a specifed time.

A crontab like file is used to load instruction sets, which are then acted on
at the designated time.

Examples are:

    +-- minute
    | +-- hour
    | | +-- day of the month
    | | | +-- month (1= January, ...)
    | | | | +-- day of the week (0 = sunday ....)
    | | | | | +-- week of the year (2/0 = even weeks, 2/1 = odd weeks)
    v v v v v v
    * * * * * * #dev Minute Check!
    0 * * * * * #dev Hour Check!
    */10 * * * * * #dev 10 minute Check!
    0 9 * * 1 2/0 #dev Review every even week
    0 9 * * 1 3/1 #dev Review every third Week

As per normal crontabs, the first 5 fields allow for ranges, steps as well as strict values.
The 6th field is the week of the year field. In working with Scrum teams running 2 week sprints,
knowing when it was an odd week or even week, meant we knew whether we had a regular stand-up
or sprint planning meeting.

By default this field can be attributed to every week using the traditional '*' symbol. However,
to determine when to run, a two part value is used, separated by a '/' symbol. The first part
designates the modulus value, and the second part the result it must match. For example, to
trigger fornightly on week 1, 3, 5, etc, this would be '2/1'. To trigger every second week of a
3 week sprint, this would be '3/1'.

The 7th field determines the channel to post to. Note that the bot cannot post to all channels.
However, may be a feature added in a future release.

The final free form field is the message. The complete line will be sent, with any line
continuation markers ignored. Line continuation markers may be a feature in the future.

=head1 SYNOPSIS

    my $bot = Bot::BasicBot::Pluggable->new(
        ... # various settings
    }; 

    $bot->store->set( 'crontab', 'file', '/path/to/mycrontab.file' },
    $bot->load('Crontab');

=head1 METHODS
 
=over 4
 
=item tick()
 
Loads the crontab file, if not previously done so, and checks all entries to see whether the
timing stated matches the current time. If so the message is sent to the appropriate channel,
otherwise the entry is ignored. The process repeats every 60 seconds.

Note that a change to the crontab file, will force a reload of the file on the next invocation.
As such, note that there may be a delay of up to 2 minutes before you see the next updated
entry actioned.

=back
 
=head1 VARS
 
=over 4
 
=item crontab
 
Path to the crontab file.
 
The crontab file is assumed to be either based on the calling script, or a designated crontab
file. If based on the calling script, if your script was mybot.pl, the crontab file would
default to mybot.cron.

If you wish to designate another filename or path, you may do this via the variable storage
when the bot is initiated. For example:

    my $bot = Bot::BasicBot::Pluggable->new(
        ... # various settings
    }; 

    $bot->store->set( 'crontab', 'file', '/path/to/mycrontab.file' },
 
=back
 
=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2015-2019 Barbie for Miss Barbell Productions

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License v2.

=cut
