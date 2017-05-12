#!/usr/bin/perl
use strict;
use Data::Dumper;
use Data::HexDump;
use Time::HiRes;

use Data::Radius::Constants qw(:all);
use AnyEvent::Radius::Server ();

my $dict = AnyEvent::Radius::Server->load_dictionary('radius/dictionary');

my @result = ();

sub radius_read_raw {
    my($self, $data, $from) = @_;
    printf "%s: Received\n%s\n", $self->name, HexDump($data);
}

my %types = (
    &ACCESS_REQUEST => 'Access-Request',
    &ACCOUNTING_REQUEST => 'Accouting-Request',
    &DISCONNECT_REQUEST => 'Disconnect-Request',
    &COA_REQUEST => 'CoA-Request',
);

my %queue = ();

sub radius_reply {
    my ($self, $h) = @_;

    printf "Received %s (%d) #%d\n",
            $types{ $h->{type} }, $h->{type}, $h->{request_id};

    my ($user, $pass) = ();
    foreach my $av (@{ $h->{av_list} }) {
        if ($av->{Vendor}) {
            printf "  %s / %s = %s\n", $av->{Vendor} // '', $av->{Name}, $av->{Value};
        }
        else {
            printf "  %s = %s\n", $av->{Name}, $av->{Value};

            if ($av->{Name} eq 'User-Name') {
                $user = $av->{Value};
            }
            if ($av->{Name} eq 'Password') {
                $pass = $av->{Value};
            }
        }
    }

    if ($user eq 'a' && $pass eq 'a') {
        return (ACCESS_ACCEPT, [{Name => 'Reply-Message', Value => 'OK'}]);
    }

    return (ACCESS_REJECT, [{Name => 'Reply-Message', Value => 'NOT FOUND'}]);
}

sub read_timeout_cb {
    print "Read timeout\n";
}
sub write_timeout_cb {
    print "Write timeout\n";
}

my $ip = $ARGV[0] || '127.0.0.1';
my $port = $ARGV[1] || 1812;

my $server = AnyEvent::Radius::Server->new(
                ip => $ip,
                port => $port,
                read_timeout => 60,
                on_read => \&radius_reply,
                dictionary => $dict,
                secret => 'topsecret',
            );
print "Listen on $ip:$port\n";

AnyEvent->condvar->recv;

