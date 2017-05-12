package App::Donburi::Util;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT = qw(conf irc xslate logger store send_chan send_srv);

use Scope::Container;
use Encode ();

sub conf { scope_container('config') }

sub irc { scope_container('irc') }

sub xslate { scope_container('xslate') }

sub logger { scope_container('logger') }

sub store { 
    my $new_store = shift;

    if ( $new_store ) {
        scope_container('store', $new_store);
        return $new_store;
    } else {
        return scope_container('store');
    }
}

sub send_chan {
    my ($channel1, $mode, $channel2, $msg) = @_;
    my $enc = conf()->{irc}->{encoding} || 'utf-8';
    $channel1 = Encode::encode($enc, $channel1);
    $channel2 = Encode::encode($enc, $channel2);
    $msg = Encode::encode($enc, $msg);
    irc()->send_chan($channel1, $mode, $channel2, $msg);

}

sub send_srv {
    my ($mode, $channel) = @_;
    my $enc = conf()->{irc}->{encoding} || 'utf-8';
    $channel = Encode::encode($enc, $channel);
    irc()->send_srv($mode, $channel);

}

1;
