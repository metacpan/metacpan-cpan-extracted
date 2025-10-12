package MHFS::HTTP::Server v0.7.0;
use 5.014;
use strict; use warnings;
use feature 'say';
use IO::Socket::INET;
use Socket qw(IPPROTO_TCP TCP_KEEPALIVE TCP_NODELAY);
use IO::Poll qw(POLLIN POLLOUT POLLHUP);
use Scalar::Util qw(weaken);
use Feature::Compat::Try;
use File::Path qw(make_path);
use Data::Dumper;
use Carp ();
use Config;
use MHFS::EventLoop::Poll;
use MHFS::FS;
use MHFS::HTTP::Server::Client;
use MHFS::Settings;
use MHFS::Util qw(parse_ipv4 read_text_file);

sub new {
    my ($class, $launchsettings, $plugins, $routes) = @_;

    local $SIG{PIPE} = sub {
        print STDERR "SIGPIPE @_\n";
    };
    local $SIG{ __DIE__ } = \&Carp::confess if ($launchsettings->{debug});

    binmode(STDOUT, ":utf8");
    binmode(STDERR, ":utf8");

    # load settings
    say __PACKAGE__.": loading settings";
    my $settings = MHFS::Settings::load($launchsettings);
    if((exists $settings->{'flush'}) && ($settings->{'flush'})) {
        say __PACKAGE__.": setting autoflush on STDOUT and STDERR";
        STDOUT->autoflush(1);
        STDERR->autoflush(1);
    }

    # make the temp dirs
    make_path($settings->{'VIDEO_TMPDIR'}, $settings->{'MUSIC_TMPDIR'}, $settings->{'RUNTIME_DIR'}, $settings->{'GENERIC_TMPDIR'});
    make_path($settings->{'SECRET_TMPDIR'}, {chmod => 0600});
    make_path($settings->{'DATADIR'}, $settings->{'MHFS_TRACKER_TORRENT_DIR'});

    my $sock = IO::Socket::INET->new(Listen => 10000, LocalAddr => $settings->{'HOST'}, LocalPort => $settings->{'PORT'}, Proto => 'tcp', Reuse => 1, Blocking => 0);
    if(! $sock) {
        say "server: Cannot create self socket";
        return undef;
    }

    if(! $sock->setsockopt( SOL_SOCKET, SO_KEEPALIVE, 1)) {
        say "server: cannot setsockopt";
        return undef;
    }
    my $TCP_KEEPIDLE  = 4;
    my $TCP_KEEPINTVL   = 5;
    my $TCP_KEEPCNT   = 6;
    my $TCP_USER_TIMEOUT = 18;
    #$SERVER->setsockopt(IPPROTO_TCP, $TCP_KEEPIDLE, 1) or die;
    #$SERVER->setsockopt(IPPROTO_TCP, $TCP_KEEPINTVL, 1) or die;
    #$SERVER->setsockopt(IPPROTO_TCP, $TCP_KEEPCNT, 10) or die;
    #$SERVER->setsockopt(IPPROTO_TCP, $TCP_USER_TIMEOUT, 10000) or die; #doesn't work?
    #$SERVER->setsockopt(SOL_SOCKET, SO_LINGER, pack("II",1,0)) or die; #to stop last ack

    # leaving Nagle's algorithm enabled for now as sometimes headers are sent without data
    #$sock->setsockopt(IPPROTO_TCP, TCP_NODELAY, 1) or die("Failed to set TCP_NODELAY");

    # linux specific settings. Check in BEGIN?
    if(index($Config{osname}, 'linux') != -1) {
        use Socket qw(TCP_QUICKACK);
        $sock->setsockopt(IPPROTO_TCP, TCP_QUICKACK, 1) or die("Failed to set TCP_QUICKACK");
    }
    my $evp = MHFS::EventLoop::Poll->new;
    my %self = ( 'settings' => $settings, 'routes' => $routes, 'route_default' => sub { $_[0]->SendDirectory($settings->{'DOCUMENTROOT'}); }, 'plugins' => $plugins, 'sock' => $sock, 'evp' => $evp, 'uploaders' => [], 'sesh' =>
    { 'newindex' => 0, 'sessions' => {}}, 'resources' => {}, 'loaded_plugins' => {});
    bless \%self, $class;

    $evp->set($sock, \%self, POLLIN);

    my $fs = MHFS::FS->new($settings->{'SOURCES'});
    if(! $fs) {
        say "failed to open MHFS::FS";
        return undef;
    }
    $self{'fs'} = $fs;

    # load the plugins
    foreach my $pluginname (@{$plugins}) {
        eval "use $pluginname; 1;" or do {
            say __PACKAGE__.": module $pluginname not found!";
            next;
        };
        next if(defined $settings->{$pluginname}{'enabled'} && (!$settings->{$pluginname}{'enabled'}));
        my $plugin = $pluginname->new($settings, \%self);
        next if(! $plugin);

        foreach my $timer (@{$plugin->{'timers'}}) {
            say __PACKAGE__.': adding '.ref($plugin).' timer';
            $self{'evp'}->add_timer(@{$timer});
        }
        if(my $func = $plugin->{'uploader'}) {
            say __PACKAGE__.': adding '. ref($plugin) .' uploader';
            push (@{$self{'uploaders'}}, $func);
        }
        foreach my $route (@{$plugin->{'routes'}}) {
            say __PACKAGE__.': adding ' . ref($plugin) . ' route ' . $route->[0];
            push @{$self{'routes'}}, $route;
        }
        $plugin->{'server'} = \%self;
        $self{'loaded_plugins'}{$pluginname} = $plugin;
    }

    $evp->run();

    return \%self;
}

sub GetTextResource {
    my ($self, $filename) = @_;
    $self->{'resources'}{$filename} //= read_text_file($filename);
    return \$self->{'resources'}{$filename};
}

sub onReadReady {
    my ($server) = @_;
    # accept the connection
    my $csock = $server->{'sock'}->accept();
    if(! $csock) {
        say "server: cannot accept client";
        return 1;
    }

    # gather connection details and verify client host is acceptable
    my $peerhost = $csock->peerhost();
    if(! $peerhost) {
        say "server: no peerhost";
        return 1;
    }
    my $peerip = do {
        try { parse_ipv4($peerhost) }
        catch ($e) {
            say "server: error parsing ip $peerhost";
            return 1;
        }
    };
    my $ah;
    foreach my $allowedHost (@{$server->{'settings'}{'ARIPHOSTS_PARSED'}}) {
        if(($peerip & $allowedHost->{'subnetmask'}) == $allowedHost->{'ip'}) {
            $ah = $allowedHost;
            last;
        }
    }
    if(!$ah) {
        say "server: $peerhost not allowed";
        return 1;
    }
    my $peerport = $csock->peerport();
    if(! $peerport) {
        say "server: no peerport";
        return 1;
    }

    # finally create the client
    say "-------------------------------------------------";
    say "NEW CONN " . $peerhost . ':' . $peerport;
    my $cref = MHFS::HTTP::Server::Client->new($csock, $server, $ah, $peerip);
    return 1;
}

1;