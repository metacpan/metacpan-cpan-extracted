#!/usr/bin/env perl

use strict;
use warnings;
use lib qw(lib ../lib);

use AnyEvent::Filesys::Notify;
use AnyEvent::Impl::Perl;  # Could be use Event or use EV, see AnyEvent

my $notifier = AnyEvent::Filesys::Notify->new(
    dirs     => [qw(lib t)],
    interval => 0.5,
    filter   => sub { shift !~ /\.(swp|tmp)$/ },
    cb       => sub {
        my @events = @_;

        printf "%s %s\n", $_->path, $_->type for @events;
        ## Do something with them...
    },
);

print "Watching " . join( ", ", @{ $notifier->dirs } ) . " for changes.\n";
AnyEvent::Impl::Perl::loop();
