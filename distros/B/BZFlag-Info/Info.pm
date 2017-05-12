package BZFlag::Info;

use 5.006001;
use strict;
use warnings;

use LWP::UserAgent;
use Socket;

our $VERSION = '1.9.2';

sub new {
    my $self = { };
    bless $self, "BZFlag::Info";
    return $self;
}

sub serverlist(%) {
    my $self = shift;
    
    my %options;
    while (my @option = splice(@_, 0, 2)) {
	$options{$option[0]} = $option[1];
    }
    
    my $proxy = $options{Proxy};
    my $response;
    my $ua = new LWP::UserAgent;
    $ua->proxy('http', $proxy) if defined($proxy);
    
    $ua->timeout(10);
    
    my $req = HTTP::Request->new('GET', ($options{Server} ? $options{Server} : $self->listserver));
    my $res = $ua->request($req);
    my $totalServers = 0;
    my $totalPlayers = 0;
    for my $line (split("\n",$res->content)) {
	my ($serverport, $version, $flags, $ip, $description) = split(" ",$line,5);
	
	my @fields = ('style','maxShots','shakeWins','shakeTimeout','maxPlayerScore',
	    'maxTeamScore','maxTime','maxPlayers','rogueSize','rogueMax','redSize',
	    'redMax','greenSize','greenMax','blueSize','blueMax','purpleSize',
	    'purpleMax','observerSize','observerMax'
	    );

	my @info = unpack("(A4)7 (A2)13", $flags);

	my $counter = 0;
	my %info;

	foreach (@fields) {
	    $info{$_} = oct('0x'.$info[$counter]);
	    $counter++;
	}
	
	my $playerSize = $info{rogueSize} + $info{redSize} + $info{greenSize}
	    + $info{blueSize} + $info{purpleSize} + $info{observerSize};
	
	unless ($serverport =~ m/.*:\d+/) {
	    $serverport = "$serverport:5154";
	}
	
	$response->{servers}->{$serverport}->{version}     = $version;
	$response->{servers}->{$serverport}->{ip}          = $ip;
	$response->{servers}->{$serverport}->{description} = $description;
	
	$response->{servers}->{$serverport}->{numplayers}   = $playerSize;
	$response->{servers}->{$serverport}->{roguesize}    = $info{rogueSize};
	$response->{servers}->{$serverport}->{redsize}      = $info{redSize};
	$response->{servers}->{$serverport}->{greensize}    = $info{greenSize};
	$response->{servers}->{$serverport}->{bluesize}     = $info{blueSize};
	$response->{servers}->{$serverport}->{purplesize}   = $info{purpleSize};
	$response->{servers}->{$serverport}->{observersize} = $info{observerSize};

	$response->{servers}->{$serverport}->{serverconfig}->{style}          = $self->parsestyle($info{style});
	$response->{servers}->{$serverport}->{serverconfig}->{maxshots}       = $info{maxShots};
	$response->{servers}->{$serverport}->{serverconfig}->{shakewins}      = $info{shakeWins};
	$response->{servers}->{$serverport}->{serverconfig}->{shaketimeout}   = $info{shakeTimeout} / 10;
	$response->{servers}->{$serverport}->{serverconfig}->{maxplayerscore} = $info{maxPlayerScore};
	$response->{servers}->{$serverport}->{serverconfig}->{maxteamscore}   = $info{maxTeamScore};
	$response->{servers}->{$serverport}->{serverconfig}->{maxtime}        = $info{maxTime};
	$response->{servers}->{$serverport}->{serverconfig}->{maxplayers}     = $info{maxPlayers};
	$response->{servers}->{$serverport}->{serverconfig}->{roguemax}       = $info{rogueMax};
	$response->{servers}->{$serverport}->{serverconfig}->{redmax}         = $info{redMax};
	$response->{servers}->{$serverport}->{serverconfig}->{greenmax}       = $info{greenMax};
	$response->{servers}->{$serverport}->{serverconfig}->{bluemax}        = $info{blueMax};
	$response->{servers}->{$serverport}->{serverconfig}->{purplemax}      = $info{purpleMax};
	$response->{servers}->{$serverport}->{serverconfig}->{observermax}    = $info{observerMax};

	$totalServers += 1;
	$totalPlayers += $playerSize;
    }
    $response->{totalservers} = $totalServers;
    $response->{totalplayers} = $totalPlayers;

    return ($response);

}    

sub queryserver(%) {
    my $self = shift;

    my %options;
    while (my @option = splice(@_, 0, 2)) {
	$options{$option[0]} = $option[1];
    }

    my $hostandport = $options{Server};
    my $timeout = $options{Timeout};

    my @teamName = ("X", "R", "G", "B", "P", "O", "H");
#    my @teamName     = ("X", "R", "G", "B", "P");
    my ($message, $server);
    my $response;
    my ($servername, $port) = split(/:/, $hostandport);
    $port = 5154 unless $port;
    
    # socket define
    my $sockaddr = 'S n a4 x8';
    
    # port to port number
    my ($name,$aliases,$proto) = getprotobyname('tcp');
    ($name,$aliases,$port)  = getservbyname($port,'tcp') unless $port =~ /^\d+$/;
    
    # get server address
    my ($type,$len,$serveraddr);
    ($name,$aliases,$type,$len,$serveraddr) = gethostbyname($servername);
    $server = pack($sockaddr, AF_INET, $port, $serveraddr);
    
    # connect
    unless (socket(S, AF_INET, SOCK_STREAM, $proto)) {
	$self->{error} = 'errSocketError';
	return undef;
    }

    unless (connect(S, $server)) {
	$self->{error} = "errCouldNotConnect: $servername:$port";
	return undef;
    }
    
    # don't buffer
    select(S); $| = 1; select(STDOUT);
    
    # get hello
    my $buffer;
    unless (read(S, $buffer, 9) == 9) {
	$self->{error} = 'errReadError';
	return undef;
    }

    # parse reply
    my ($magic, $version, $id) = unpack("a4 a4 C1", $buffer);
    
    # quit if version isn't valid
    if ($magic ne "BZFS") {
	$self->{error} = 'errNotABzflagServer';
	return undef;
    }

    # try incompatible for 1.7, etc.
    if ($version != '1910') {
	$self->{error} = 'errIncompatibleVersion';
	return undef;
    }
    
    # send game request
    print S pack("n2", 0, 0x7167);
    
    # get reply
    unless (read(S, $buffer, 40) == 40) {
	$self->{error} = 'errServerReadError';
	return undef;
    }

    my ($infolen,$infocode,$style,$maxPlayers,$maxShots,
	$rogueSize,$redSize,$greenSize,$blueSize,$purpleSize,
	$rogueMax,$redMax,$greenMax,$blueMax,$purpleMax,
	$shakeWins,$shakeTimeout,
	$maxPlayerScore,$maxTeamScore,$maxTime) = unpack("n20", $buffer);

    unless ($infocode == 0x7167) {
	$self->{error} = 'errBadServerData';
	return undef;
    }

    $response->{serverconfig}->{style} = $self->parsestyle($style);

    $response->{serverconfig}->{maxplayers} = $maxPlayers;
    $response->{serverconfig}->{maxshots} = $maxShots;
    $response->{serverconfig}->{roguemax} = $rogueMax;
    $response->{serverconfig}->{redmax} = $redMax;
    $response->{serverconfig}->{greenmax} = $greenMax;
    $response->{serverconfig}->{bluemax} = $blueMax;
    $response->{serverconfig}->{purplemax} = $purpleMax;
    $response->{serverconfig}->{shakewins} = $shakeWins;
    $response->{serverconfig}->{shaketimeout} = $shakeTimeout;
    $response->{serverconfig}->{maxplayerscore} = $maxPlayerScore;
    $response->{serverconfig}->{maxteamscore} = $maxTeamScore;
    $response->{serverconfig}->{maxtime} = $maxTime;

    # send players request
    print S pack("n2", 0, 0x7170);
    
    # get number of teams and players we'll be receiving
    unless (read(S, $buffer, 8) == 8) {
	$self->{error} = 'errCountReadError';
	return undef;
    }

    my ($countlen,$countcode,$numTeams,$numPlayers) = unpack("n4", $buffer);
    unless ($countcode == 0x7170) {
	$self->{error} = 'errBadCountData';
	return undef;
    }

    $response->{numplayers} = $numPlayers;

    unless (read(S, $buffer, 5) == 5) {
	$self->{error} = 'errCountReadError';
	return undef;
    }

    my ($countlen2, $countcode2, $numTeams2) = unpack("n2 C", $buffer);
    unless ($countcode2 == 0x7475) {
	$self->{error} = 'errBadCountData';
        return undef;
    }

    $response->{numteams} = $numTeams2;

    # get the teams
    for (1..$numTeams2) {
	unless (read(S, $buffer, 8) == 8) {
	    $self->{error} = 'errTeamReadError';
	    return undef;
	}

	my ($team, $size, $wins, $losses) = unpack("n4", $buffer);

	my $score = $wins - $losses;

	$response->{teams}->{$teamName[$team]}->{size}   = $size;
	$response->{teams}->{$teamName[$team]}->{score}  = $score;
	$response->{teams}->{$teamName[$team]}->{wins}   = $wins;
	$response->{teams}->{$teamName[$team]}->{losses} = $losses;
	
    }
    
    # get the players
    for (1..$numPlayers) {
	next unless (read(S, $buffer, 175) == 175);
	my ($len, $code, $pID, $type, $team, $wins, $losses, $tks, $callsign, $email) = 
	    unpack("n2 C n5 A32 A128", $buffer);

	unless ($code == 0x6170) {
	    $self->{error} = 'errBadPlayerData';
	    return undef;
	}

	my $score = $wins - $losses;

	$response->{players}->{$callsign}->{team}   = $teamName[$team];
	$response->{players}->{$callsign}->{email}  = $email;
	$response->{players}->{$callsign}->{score}  = $score;
	$response->{players}->{$callsign}->{wins}   = $wins;
	$response->{players}->{$callsign}->{losses} = $losses;
	$response->{players}->{$callsign}->{tks}    = $tks;
	$response->{players}->{$callsign}->{pID}    = $pID;

    }
    if ($numPlayers <= 1) {
	$self->{error} = 'errNoPlayers';
	return undef;
    }
    
    # close socket
    close(S);
    
    return $response;

}

sub parsestyle ($) {
    my $self = shift;
    my $style = shift;

    my $response;

    if ($style & 0x0001) { 
	$response->{ctf} = 1;
    } else {
	$response->{ctf} = 0;
    }
    
    if ($style & 0x0002) { 
	$response->{superflags} = 1;
    } else {
	$response->{superflags} = 0;
    }
    
    if ($style & 0x0004) { 
	$response->{rogues} = 1;
    } else {
	$response->{rogues} = 0;
    }
    
    if ($style & 0x0008) { 
	$response->{jumping} = 1;
    } else {
	$response->{jumping} = 0;
    }
    
    if ($style & 0x0010) { 
	$response->{inertia} = 1;
    } else {
	$response->{inertia} = 0;
    }
    
    if ($style & 0x0020) { 
	$response->{ricochet} = 1;
    } else {
	$response->{ricochet} = 0;
    }
    
    if ($style & 0x0040) { 
	$response->{shakable} = 1;
    } else {
	$response->{shakable} = 0;
    }
    
    if ($style & 0x0080) { 
	$response->{antidoteflags} = 1;
    } else {
	$response->{antidoteflags} = 0;
    }
    
    if ($style & 0x0100) { 
	$response->{timesync} = 1;
    } else {
	$response->{timesync} = 0;
    }
    
    if ($style & 0x0200) { 
	$response->{rabbitchase} = 1;
    } else {
	$response->{rabbitchase} = 0;
    }

    return $response;
}

sub geterror {
    my $self = shift;
    return $self->{error};
}

sub listserver {
    my $self = shift;
    return "http://list.bzflag.bz/db/";
}

1;

__END__

=head1 NAME

BZFlag::Info - Extracts infomation about BZFlag servers and players

=head1 SYNOPSIS

    use BZFlag::Info;
    
    my $bzinfo = new BZFlag::Info;
    
    my $serverlist = $bzinfo->serverlist;
    my $serverlist = $bzinfo->serverlist(Proxy => 'host:port', Server => 'http://listserver/');
    
    my $serverinfo = $bzinfo->queryserver(Server => 'host:port');
    

=head1 DESCRIPTION

C<BZFlag::Info> is a class for extracting information about BZFlag clients
and servers. Currently, 6 methods are implemented, C<new>,
C<serverlist>, C<queryserver>, C<parsestyle>, C<listserver>, and C<geterror>.

=head1 METHODS

=over 4

=item my $bzinfo = new BZFlag::Info;

C<new> constructs a new C<BZFlag::Info> object. It takes no arguments.

=item my $serverlist = $bzinfo->serverlist;

C<serverlist> retrieves the current list of public servers. Then
returns a data structure that would be displayed by C<Data::Dumper>
like this:

    $VAR1 = {
          'totalservers' => 1,
          'totalplayers' => 6
          'servers' => {
                         'bzflag.secretplace.us:5255' => {
                                                           'serverconfig' => {
                                                                               'purplemax' => 5,
                                                                               'redmax' => 5,
                                                                               'bluemax' => 5,
                                                                               'greenmax' => 5,
                                                                               'roguemax' => 10,
                                                                               'shakewins' => 1,
                                                                               'observermax' => 5,
                                                                               'style' => {
                                                                                            'ctf' => 0,
                                                                                            'jumping' => 1,
                                                                                            'shakable' => 1,
                                                                                            'antidoteflags' => 1,
                                                                                            'inertia' => 0,
                                                                                            'ricochet' => 1,
                                                                                            'timesync' => 0,
                                                                                            'rabbitchase' => 0,
                                                                                            'superflags' => 1,
                                                                                            'rogues' => 0
                                                                                          },
                                                                               'maxshots' => 10,
                                                                               'maxteamscore' => 0,
                                                                               'shaketimeout' => '5',
                                                                               'maxtime' => 0,
                                                                               'maxplayerscore' => 0
                                                                             },
                                                           'ip' => '69.28.129.162',
                                                           'version' => 'BZFS1910',
                                                           'redsize' => 0,
                                                           'description' => 'Now playing Spirals 3.0 by BZDoug.',
                                                           'bluesize' => 1,
                                                           'numplayers' => 6,
                                                           'roguesize' => 4,
                                                           'observersize' => 0,
                                                           'purplesize' => 0,
                                                           'greensize' => 1
                                                         },
	  };


It can also take 2 options. The Proxy option specifies a proxy server
to handle the HTTP request. The Server option specifies an alternate
BZFlag list server to retrieve the server list from.

=item my $serverinfo = $bzinfo->queryserver(Server => 'host:port');

C<queryserver> extracts information about players and teams from the
BZFlag server specified with the Server option. It returns a data
structure that would be displayed by C<Data::Dumper> like this:

    ## brlcad.org:14244

    $VAR1 = {
          'numplayers' => 2,
          'serverconfig' => {
                              'purplemax' => 200,
                              'redmax' => 200,
                              'bluemax' => 200,
                              'shakewins' => 0,
                              'greenmax' => 200,
                              'roguemax' => 200,
                              'style' => {
                                           'ctf' => 1,
                                           'jumping' => 1,
                                           'shakable' => 0,
                                           'antidoteflags' => 1,
                                           'inertia' => 0,
                                           'ricochet' => 1,
                                           'timesync' => 0,
                                           'rabbitchase' => 0,
                                           'superflags' => 1,
                                           'rogues' => 0
                                         },
                              'maxshots' => 2,
                              'maxteamscore' => 10,
                              'maxplayers' => 8,
                              'maxtime' => 0,
                              'shaketimeout' => 0,
                              'maxplayerscore' => 100
                            },
          'numteams' => 5,
          'teams' => {
                       'X' => {
                                'losses' => 0,
                                'wins' => 0,
                                'score' => 0,
                                'size' => 1
                              },
                       'P' => {
                                'losses' => 0,
                                'wins' => 0,
                                'score' => 0,
                                'size' => 0
                              },
                       'R' => {
                                'losses' => 0,
                                'wins' => 0,
                                'score' => 0,
                                'size' => 0
                              },
                       'G' => {
                                'losses' => 0,
                                'wins' => 0,
                                'score' => 0,
                                'size' => 0
                              },
                       'B' => {
                                'losses' => 0,
                                'wins' => 0,
                                'score' => 0,
                                'size' => 1
                              }
                     },
          'players' => {
                         'romfis' => {
                                       'losses' => 34,
                                       'wins' => 95,
                                       'email' => 'Roman Fischer@fischer-medion',
                                       'pID' => 1,
                                       'score' => 61,
                                       'team' => 'X',
                                       'tks' => 0
                                     },
                         'slowfox' => {
                                        'losses' => 80,
                                        'wins' => 29,
                                        'email' => 'tester@linux.local',
                                        'pID' => 0,
                                        'score' => -51,
                                        'team' => 'B',
                                        'tks' => 0
                                      }
                       }
        };

X, R, G, B, P, O, and H stand for Rogue, Red, Green, Blue, Purple,
Observer, and Rabbit, respectively.

If there was an error retrieving information on a BZFlag server,
C<queryserver> will return undef, C<geterror> will return the error.

=item my $styleinfo = $bzinfo->parsestyle($style);

C<parsestyle> extracts information about game style from one of the
style field returned from either the list server or the game server.
BZFlag server specified with the Server option. It returns a data
structure that would be displayed by C<Data::Dumper> like this:

    $VAR1 = {
           'ctf' => 1,
	   'jumping' => 1,
	   'shakable' => 0,
	   'antidoteflags' => 1,
	   'inertia' => 0,
	   'ricochet' => 1,
	   'timesync' => 0,
	   'rabbitchase' => 0,
	   'superflags' => 1,
	   'rogues' => 0
	 },

=back

=head1 BUGS

I have no idea, tell me if there are any.

=head1 AUTHOR

Tucker McLean, tuckerm@noodleroni.com

=head1 COPYRIGHT

Copyright (c) 2003 Tucker McLean, Tim Riker.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
