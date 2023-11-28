package App::Hack::Exe 0.000001;
use 5.012;
use warnings;

use constant {
    DEFAULTS => {
        get_ipv4 => 1,
        get_ipv6 => 1,
        no_delay => 0,
        ports => [qw/ 143 993 587 456 25 587 993 80 /],
        proxies => [qw/ BEL AUS JAP CHI NOR FIN UKR /],
    },
    # Original ASCII art by Jan (janbrennen@github)
    # Source: https://github.com/janbrennen/rice/blob/master/hack.exe.c
    DEMON => <<'EOD',
          .                                                      .
        .n                   .                 .                  n.
  .   .dP                  dP                   9b                 9b.    .
 4    qXb         .       dX                     Xb       .        dXp     t
dX.    9Xb      .dXb    __                         __    dXb.     dXP     .Xb
9XXb._       _.dXXXXb dXXXXbo.                 .odXXXXb dXXXXb._       _.dXXP
 9XXXXXXXXXXXXXXXXXXXVXXXXXXXXOo.           .oOXXXXXXXXVXXXXXXXXXXXXXXXXXXXP
  `9XXXXXXXXXXXXXXXXXXXXX'~   ~`OOO8b   d8OOO'~   ~`XXXXXXXXXXXXXXXXXXXXXP'
    `9XXXXXXXXXXXP' `9XX'   DIE    `98v8P'  HUMAN   `XXP' `9XXXXXXXXXXXP'
        ~~~~~~~       9X.          .db|db.          .XP       ~~~~~~~
                        )b.  .dbo.dP'`v'`9b.odb.  .dX(
                      ,dXXXXXXXXXXXb     dXXXXXXXXXXXb.
                     dXXXXXXXXXXXP'   .   `9XXXXXXXXXXXb
                    dXXXXXXXXXXXXb   d|b   dXXXXXXXXXXXXb
                    9XXb'   `XXXXXb.dX|Xb.dXXXXX'   `dXXP
                     `'      9XXXXXX(   )XXXXXXP      `'
                              XXXX X.`v'.X XXXX
                              XP^X'`b   d'`X^XX
                              X. 9  `   '  P )X
                              `b  `       '  d'
                               `             '
EOD
    # Float; Number of seconds to display "loading" animation for
    DOTS_DURATION => 1,
    # Int; Number of characters to draw each "loading" animation line
    # 77 = Width of demon
    DOTS_WIDTH => 77,
    # ANSI escape codes for cursor manipulation
    MEMORIZE_CURSOR => "\e\x{37}",
    RECALL_CURSOR => "\e\x{38}",
};

use Socket qw/
    AF_INET
    AF_INET6
    NI_NUMERICHOST
    NI_NUMERICSERV
    getaddrinfo
    getnameinfo
/;
use Term::ANSIColor qw/ color colored /;
use Time::HiRes qw/ sleep /;

use fields qw/
    get_ipv4
    get_ipv6
    no_delay
    ports
    proxies
/;

sub new {
    my ($class, %args) = @_;
    my App::Hack::Exe $self = $class;
    unless (ref $self) {
        $self = fields::new($class);
    }
    %{$self} = (%{$self}, %{+DEFAULTS}, %args);
    return $self;
}

sub _colored_demon {
    (my $colored = DEMON) =~ s{DIE|HUMAN}{q{color('yellow') . ${^MATCH} . color('red')}}eegp;
    return colored($colored, 'red');
}

sub _dots {
    my ($self, $text) = @_;
    print $text;
    # 10 = length of '[COMPLETE]'
    my $num_dots = DOTS_WIDTH - 10 - length $text;
    my $pause_for = DOTS_DURATION / $num_dots;
    while ($num_dots --> 0) {
        print '.';
        $self->_sleep($pause_for);
    }
    say '[', colored('COMPLETE', 'bold green'), ']';
    $self->_sleep(0.6);
    return;
}

sub _get_ip {
    my ($self, $hostname) = @_;
    $self->_dots('Enumerating Target');
    say ' [+] Host: ', $hostname;
    my %ips = _lookup_ips($hostname);
    my %to_get = (
        'IPv4' => $self->{get_ipv4},
        'IPv6' => $self->{get_ipv6},
    );
    foreach my $ip_type (sort keys %ips) {
        my $addrs = $ips{$ip_type};
        foreach my $addr (@{$addrs}) {
            if ($to_get{$ip_type} --> 0) {
                say " [+] $ip_type: $addr";
            }
        }
    }
    return;
}

sub _lookup_ips {
    my $hostname = shift;
    my %ips;
    my %family_map = (
        (AF_INET) => 'IPv4',
        (AF_INET6) => 'IPv6',
    );

    ## no critic ( ErrorHandling::RequireCheckingReturnValueOfEval )
    # We don't care if this succeeds, just want to keep the script from dying
    # in the event of a network error.
    eval {
        my ($err, @res) = getaddrinfo($hostname, 'echo');
        foreach my $res (@res) {
            my $family_key = $family_map{$res->{family}};
            # Translate packed binary address to human-readable IP address
            # (err, addr, port) = getnameinfo
            my (undef, $ip) = getnameinfo($res->{addr}, NI_NUMERICHOST | NI_NUMERICSERV);
            if (defined $ip) {
                push @{$ips{$family_key}}, $ip;
            }
        }
    };
    return %ips;
}

sub _chainproxies {
    my $self = shift;
    my @proxies = @{$self->{proxies}};
    $self->_dots('Chaining proxies');
    # Interpolation glue
    local $" = '>';
    my $bracket_width = length "@proxies"; # (sic)
    my $proxy_ct = scalar @proxies;
    my @chained;
    print " [+] 0/$proxy_ct proxies chained {", MEMORIZE_CURSOR, (' ' x $bracket_width), '}';
    $self->_sleep(0.2);
    while (@proxies) {
        push @chained, shift @proxies;
        print "\r [+] ", (scalar @chained), RECALL_CURSOR, "@chained";
        $self->_sleep(0.2);
    }
    say '';
    return;
}

sub _launchproxy {
    my $self = shift;
    $self->_dots('Opening SOCKS5 ports on infected hosts');
    say ' [+] SSL entry point on 127.0.0.1:1337';
    return;
}

sub _portknock {
    my $self = shift;
    my @ports = @{$self->{ports}};
    $self->_dots('Launching port knocking sequence');
    # Interpolation glue
    local $" = ',';
    my $bracket_width = length "@ports"; # (sic)
    my @knocked;
    print ' [+] Knock on TCP<', MEMORIZE_CURSOR, (' ' x $bracket_width), '>', RECALL_CURSOR;
    $self->_sleep(0.2);
    while (@ports) {
        push @knocked, shift @ports;
        print $knocked[-1];
        if (@ports) {
            print $";
        }
        $self->_sleep(0.2);
    }
    say '';
    return;
}

sub _prompt {
    my $self = shift;
    my $hostname = shift;
    $self->_sleep(0.5);
    my $prompt = "root\@$hostname:~# ";
    print $prompt;
    # Wait for the user to press Ctrl-d
    while (-t STDIN && <STDIN>) {
        print $prompt;
    }
    return;
}

sub _sleep {
    my ($self, @args) = @_;
    if ($self->{no_delay}) {
        @args = (0);
    }
    return sleep @args;
}

sub _w00tw00t {
    my $self = shift;
    $self->_dots('Sending PCAP datagrams for fragmentation overlap');
    say ' [+] Stack override ***** w00t w00t g0t r00t!';
    say '';
    print '[';
    my $chars = 65;
    while ($chars --> 0) {
        print '=';
        $self->_sleep(0.01);
    }
    say ']';
    return;
}

sub run {
    my ($self, $hostname) = @_;
    unless ($hostname) {
        say STDERR 'No targets specified.';
    }
    local $| = 1;
    print _colored_demon();

    $self->_get_ip($hostname);
    $self->_launchproxy;
    $self->_chainproxies;
    $self->_portknock;
    $self->_w00tw00t;
    $self->_prompt($hostname);

    say 'Done';
    return;
}

1;
