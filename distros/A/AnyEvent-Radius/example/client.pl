#!/usr/bin/perl
use strict;
use Data::Dumper;
use Data::HexDump;
use Time::HiRes;

use Data::Radius::Constants qw(:all);
use AnyEvent::Radius::Client;

my $dict = AnyEvent::Radius::Client->load_dictionary('radius/dictionary');

my @result = ();

sub radius_reply_raw {
    my($self, $data, $from) = @_;
    printf "Received\n%s\n", HexDump($data);

    #push @result, $data;
}

my %types = (
    &ACCESS_ACCEPT => 'Access-Accept',
    &ACCESS_REJECT => 'Access-Reject',
    &ACCOUNTING_RESPONSE => 'Accounting-Response',
);

my %queue = ();

sub radius_reply {
    my ($self, $h) = @_;

    #print Dumper($h);

    printf "Received %s (%d) #%d\n",
            $types{ $h->{type} }, $h->{type}, $h->{request_id};

    foreach my $av (@{ $h->{av_list} }) {
        if ($av->{Vendor}) {
            printf "  %s / %s = %s\n", $av->{Vendor} // '', $av->{Name}, $av->{Value};
        }
        else {
            printf "  %s = %s\n", $av->{Name}, $av->{Value};
        }
    }

    my $dq = $queue{ $h->{request_id} };
    if (! $dq) {
        warn "Received reply for request $h->{request_id} not in queue!";
        return;
    }

    $dq->{done} = 1;
}

# sub on_read_raw {
#     my ($client, $data, $from) = @_;
#     print "Raw packet:\n", HexDump($data), "\n";
# }

sub read_timeout_cb {
    print "Read timeout\n";
}
sub write_timeout_cb {
    print "Write timeout\n";
}

my $ip = $ARGV[0] || '127.0.0.1';
my $port = $ARGV[1] || 1812;

my $nas = AnyEvent::Radius::Client->new(
                ip => $ip,
                port => $port,
                read_timeout => 60,
                on_read => \&radius_reply,
                #on_read_raw => \&radius_reply_raw,
                on_read_timeout => \&read_timeout_cb,
                on_write_timeout => \&write_timeout_cb,
                dictionary => $dict,
                secret => 'topsecret',
            );

# random bunch of AV
my @av = (
    { Name => 'NAS-IP-Address', Value => '10.20.30.40' },
    { Name => 'User-Name', Value => '12412641261' },
    #{ Name => 'User-Name', Value => 'a' },
    #{ Name => 'Password', Value => 'a' },
    { Name => 'Calling-Station-Id', Value => '14:da:e9:ef:ae:06' },
    # { Name => 'WiMAX-AAA-Session-Id', Value => 'ashsfhasf-sdfsdfsfd' },
    # { Name => 'Huawei-ISP-ID', Value => 'Super ISP' },
    # { Name => 'Huawei-User-Priority', Value => 'Gold' },
    # { Name => 'WiMAX-Capability', Value => [
    #         { Name => 'WiMAX-Accounting-Capabilities', Value => 5 },
    #         { Name => 'WiMAX-Release', Value => 'v1.1' },
    #     ]},
    { Name => 'subscriber', Value => 'A1' },
    { Name => 'h323-conf-id', Value => 'xxxx-yyyy' },
);

my $id;

$id =$nas->send_auth(\@av);
# identify which requests were sent and replies received
$queue{ $id } = {db_id => $id, done => 0 };
printf "Scheduled auth as #%d\n", $id;

$id = $nas->send_auth([
    { Name => 'NAS-IP-Address', Value => '10.10.10.10' },
    { Name => 'User-Name', Value => 'a' },
    { Name => 'Password', Value => 'a' },
]);
printf "Scheduled auth as #%d\n", $id;
$queue{ $id } = {db_id => $id, done => 0 };

printf "Waiting for results\n";
$nas->wait;

printf "Result: %s to send: %d sent: %d answers: %d\n",
            $nas->queue_cnt, $nas->sent_cnt, $nas->reply_cnt;

# now process %queue and update status in DB etc..


