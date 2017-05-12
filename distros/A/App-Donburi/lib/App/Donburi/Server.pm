package App::Donburi::Server;
use strict;
use warnings;

use Twiggy::Server;
use AnyEvent;
use AnyEvent::IRC::Client;
use YAML::Syck;
use Text::Xslate;
use Scope::Container;
use File::ShareDir;
use Encode ();

use App::Donburi::Web::Dispatcher;
use App::Donburi::Logger;

sub run {
    my $conf = shift;

    local $YAML::Syck::ImplicitUnicode = 1;
    my $container = start_scope_container();

    my $config = YAML::Syck::LoadFile($conf);
    scope_container('config', $config);

    my $store;
    if ( -e $config->{store} ) {
        $store = YAML::Syck::LoadFile($config->{store});
    } else {
        $store = [];
    }
    scope_container('store', $store);

    my $tmpl_dir = $config->{tmpl_path} ||
                       File::ShareDir::dist_dir('App-Donburi');

    my $tx = Text::Xslate->new(
        path      => [$tmpl_dir],
        cache_dir => '/tmp/.donburi',
        cache     => 1,
    );
    scope_container('xslate', $tx);

    my $logger = App::Donburi::Logger->new();
    scope_container('logger', $logger);

    my $cv = AnyEvent->condvar;
    my $irc = AnyEvent::IRC::Client->new;
    $irc->reg_cb(
        connect => sub {
            my ($irc, $err) = @_;
            if (defined $err) {
                $logger->warn("connect error: $err\n");
                $cv->send;
            }
        },
        registered => sub {
            $logger->info("Registered");
        },
        disconnect => sub {
            $logger->info("Disconnected");
        },
        error => sub {
            my ($irc, $code, $message, $ircmsg) = @_;
            use Data::Dumper; warn Dumper($ircmsg);
            $logger->crit("$code $message");
        }
    );

    $irc->connect(
        $config->{irc}->{server},
        $config->{irc}->{port},
        { nick => $config->{irc}->{nick} }
    );
    for my $channel (@$store) {
        $irc->send_srv("JOIN", Encode::encode($config->{irc}->{encoding} || 'utf-8',$channel));
    }

    scope_container('irc', $irc);

    my $twg = Twiggy::Server->new(
        host => $config->{http}->{server},
        port => $config->{http}->{port},
    );
    my $dispatcher = App::Donburi::Web::Dispatcher->new;
    $twg->register_service(sub {
        my $env = shift;

        return $dispatcher->dispatch($env);
    });

    $SIG{INT} = sub {
        my $yaml = YAML::Syck::Dump(scope_container('store'));
        utf8::encode($yaml);
        open my $fh, '>' , $config->{store};
        print $fh $yaml;
        close $fh;
        exit;
    };

    $logger->info("Web interface is here: http://%s:%s/", $config->{http}->{server}, $config->{http}->{port});

    $cv->recv;
    $irc->disconnect;
}

1;
