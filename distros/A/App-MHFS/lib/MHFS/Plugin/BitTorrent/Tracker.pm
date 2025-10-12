package MHFS::Plugin::BitTorrent::Tracker v0.7.0;
use 5.014;
use strict; use warnings;
use feature 'say';
use Time::HiRes qw( clock_gettime CLOCK_MONOTONIC);
use MHFS::BitTorrent::Bencoding qw(bencode);
use Data::Dumper;
use Feature::Compat::Try;
use MHFS::BitTorrent::Client;
use MHFS::BitTorrent::Metainfo;
use MHFS::Util qw(parse_ipv4 read_file);

sub createTorrent {
    my ($self, $request) = @_;
    my $fileitem = $self->{fs}->lookup($request->{'qs'}{'name'}, $request->{'qs'}{'sid'});
    if(!$fileitem) {
        $request->Send404;
        return;
    }
    my $absurl = $request->getAbsoluteURL;
    if(! $absurl) {
        say 'unable to $request->getAbsoluteURL';
        $request->Send404;
    }
    print Dumper($fileitem);
    my $outputname = $self->{'settings'}{'MHFS_TRACKER_TORRENT_DIR'}.'/'.$fileitem->{'name'}.'.torrent';
    my %maketorrent = ( private => 1,
    dest_metafile => $outputname,
    src => $fileitem->{filepath},
    tracker => $absurl.'/torrent/tracker');
    my $server = $request->{'client'}{'server'};
    my $evp = $server->{'evp'};
    MHFS::BitTorrent::Metainfo::Create($evp, \%maketorrent, sub {

    my $torrentData = do {
        try { read_file($outputname) }
        catch ($e) {
            $request->Send404;
            return;
        }
    };
    my $torrent = MHFS::BitTorrent::Metainfo::Parse(\$torrentData);
    if(! $torrent) {
        $request->Send404; return;
    }
    my $asciihash = $torrent->InfohashAsHex();
    say "asciihash: $asciihash";
    $self->{'torrents'}{pack('H*', $asciihash)} //= {};

    MHFS::BitTorrent::Client::torrent_start($server, \$torrentData, $fileitem->{'containingdir'}, {
        'on_success' => sub {
            $request->{'responseopt'}{'cd_file'} = 'attachment';
            $request->SendLocalFile($outputname, 'applications/x-bittorrent');
        },
        'on_failure' => sub {
            $request->Send404;
        }
    })});
}

sub announce_error {
    my ($message) = @_;
    return ['d', ['bstr', 'failure reason'], ['bstr', $message]];
}

sub peertostring {
    my ($peer) = @_;
    my @pvals = unpack('CCCCCC', $peer);
    return "$pvals[0].$pvals[1].$pvals[2].$pvals[3]:" . (($pvals[4] << 8) | $pvals[5]);
}

sub removeTorrentPeer {
    my ($self, $infohash, $peer, $reason) = @_;
    say __PACKAGE__.": removing torrent peer ".peertostring($peer). " - $reason";
    delete $self->{torrents}{$infohash}{$peer};
}

sub announce {
    my ($self, $request) = @_;

    # hide the tracker if the required parameters aren't there
    foreach my $key ('port', 'left', 'info_hash') {
        if(! exists $request->{'qs'}{$key}) {
            say __PACKAGE__.": missing $key";
            $request->Send404;
            return;
        }
    }

    my $dictref;
    while(1) {
        my $port = $request->{'qs'}{'port'};
        if($port ne unpack('S', pack('S', $port))) {
            $dictref = announce_error("bad port");
            last;
        }
        my $left = $request->{'qs'}{'left'};
        if($left ne unpack('Q', pack('Q', $left))) {
            $dictref = announce_error("bad left");
            last;
        }
        if(exists $request->{'qs'}{'compact'} && ($request->{'qs'}{'compact'} eq '0')) {
            $dictref = announce_error("Only compact responses supported!");
            last;
        }

        my $rih = $request->{'qs'}{'info_hash'};
        if(!exists $self->{torrents}{$rih}) {
            $dictref = announce_error("The torrent does not exist!");
            last;
        }

        my $ip = $request->{'ip'};
        my $ipport = pack('Nn', $ip, $port);
        say __PACKAGE__.": announce from ".peertostring($ipport);


        my $event = $request->{'qs'}{'event'};
        #if( (! exists $self->{torrents}{$rih}{$ipport}) &&
        #((! defined $event) || ($event ne 'started'))) {
        #    $dictref = announce_error("first announce must include started event");
        #    last;
        #}

        if($left == 0) {
            $self->{torrents}{$rih}{$ipport}{'completed'} = 1;
        }

        $self->{torrents}{$rih}{$ipport}{'last_announce'} = clock_gettime(CLOCK_MONOTONIC);

        if(defined $event) {
            say __PACKAGE__.": announce event $event";
            if($event eq 'started') {
                #$self->{torrents}{$rih}{$ipport} = {'exists' => 1};
            }
            elsif($event eq 'stopped') {
                $self->removeTorrentPeer($rih, $ipport, " received stopped message");
            }
            elsif($event eq 'completed') {
                #$self->{torrents}{$rih}{$ipport}{'completed'} = 1;
            }
        }

        my $numwant = $request->{'qs'}{'numwant'};
        if((! defined $numwant) || ($numwant ne unpack('C', pack('C', $numwant))) || ($numwant > 55)) {
            $numwant = 50;
        }

        my @dict = ('d');
        push @dict, ['bstr', 'interval'], ['int', $self->{'announce_interval'}];
        my $complete = 0;
        my $incomplete = 0;
        my $pstr = '';
        my $i = 0;
        foreach my $peer (keys %{$self->{torrents}{$rih}}) {
            if($self->{torrents}{$rih}{$peer}{'completed'}) {
                $complete++;
            }
            else {
                $incomplete++;
            }
            if($i++ < $numwant) {
                if($peer ne $ipport) {
                    my @values = unpack('CCCCCC', $peer);
                    my $netmap = $request->{'client'}{'server'}{'settings'}{'NETMAP'};
                    my $pubip = $self->{pubip};
                    if($netmap && (($values[0] == $netmap->[1]) && (unpack('C', $ipport) != $netmap->[1])) && $pubip) {
                        say "HACK converting local peer to public ip";
                        $peer = pack('Nn', $pubip, (($values[4] << 8) | $values[5]));
                    }
                    say __PACKAGE__.": sending peer ".peertostring($peer);
                    $pstr .= $peer;
                }
            }
        }
        #push @dict, ['bstr', 'complete'], ['int', $complete];
        #push @dict, ['bstr', 'incomplete'], ['int', $incomplete];
        push @dict, ['bstr', 'peers'], ['bstr', $pstr];

        $dictref = \@dict;
        last;
    }

    # bencode and send
    my $bdata = bencode($dictref);
    if($bdata) {
        $request->SendBytes('text/plain', $bdata);
    }
    else {
        say "Critical: Failed to bencode!";
        $request->Send404;
    }
}

sub new {
    my ($class, $settings, $server) = @_;
    my $ai = ($settings->{'BitTorrent::Tracker'} && $settings->{'BitTorrent::Tracker'}{'announce_interval'}) ? $settings->{'BitTorrent::Tracker'}{'announce_interval'} : undef;
    $ai //= 1800;

    my $self =  {'settings' => $settings, 'torrents' => \%{$settings->{'TORRENTS'}}, 'announce_interval' => $ai, 'fs' => $server->{'fs'}};
    bless $self, $class;
    say __PACKAGE__.": announce interval: ".$self->{'announce_interval'};

    if (exists $settings->{'PUBLICIP'}) {
        try { $self->{pubip} = parse_ipv4($settings->{'PUBLICIP'}); }
        catch ($e) {}
    }

    # load the existing torrents
    my $odres = opendir(my $tdh, $settings->{'MHFS_TRACKER_TORRENT_DIR'});
    if(! $odres){
        say __PACKAGE__.":failed to open torrent dir";
        return undef;
    }
    while(my $file = readdir($tdh)) {
        next if(substr($file, 0, 1) eq '.');
        my $fullpath = $settings->{'MHFS_TRACKER_TORRENT_DIR'}."/$file";
        my $torrentcontents = do {
            try { read_file($fullpath) }
            catch ($e) {
                say __PACKAGE__.": error reading $fullpath";
                return;
            }
        };
        my $torrent = MHFS::BitTorrent::Metainfo::Parse(\$torrentcontents);
        if(! $torrent) {
            say __PACKAGE__.": error parsing $fullpath";
            return undef;
        }
        $self->{'torrents'}{$torrent->{'infohash'}} = {};
        say __PACKAGE__.": added torrent ".$torrent->InfohashAsHex() . ' '.$file;
    }

    $self->{'routes'} = [
    ['/torrent/tracker', sub {
        my ($request) = @_;
        $self->announce($request);
    }],
    ['/torrent/create', sub {
        my ($request) = @_;
        $self->createTorrent($request);
    }],
    ];

    $self->{'timers'} = [
        # once an hour evict peers that left the swarm ungracefully
        [0, 3600, sub {
            my ($timer, $current_time, $evp) = @_;
            say __PACKAGE__.": evict peers timer";
            foreach my $infohash (keys %{$self->{'torrents'}}) {
                foreach my $peer (keys %{$self->{'torrents'}{$infohash}}) {
                    my $peerdata = $self->{'torrents'}{$infohash}{$peer};
                    if(($current_time - $peerdata->{'last_announce'}) > ($self->{'announce_interval'}+60)) {
                        $self->removeTorrentPeer($infohash, $peer, " timeout");
                    }
                }
            }
            return 1;
        }],
    ];

    return $self;
}

1;
