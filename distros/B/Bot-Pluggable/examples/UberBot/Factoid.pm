
package UberBot::Factoid;
use strict;

use POE;

sub new {
    my $class = shift;
    return bless { @_ }, $class;
}

sub irc_public {
    my ($self, $bot, $who, $where, $msg) = 
      @_[OBJECT, SENDER, ARG0, ARG1, ARG2];
    
    # warn("who is $who, where is $where, msg is $msg\n");
    $msg =~ s/^($bot->{Nick})[:,]?\s+//;
    
    if ($self->{AddressingMode}) {
        return unless $1;
    }
    
    my ($nick, undef) = split(/!/, $who, 2);
    my $channel = $where->[0];
    
    if ($msg =~ /^(.{2,30}) is (.+)$/) {
        $self->{Factoid}{$1} = $2;
        $bot->privmsg( $channel, "ok, $nick" );
    }
    elsif ($msg =~ /^forget (.{2,30})$/) {
        if (delete($self->{Factoid}{$1})) {
            $bot->privmsg( $channel, "I forgot $1, $nick" );
        }
        else {
            $bot->privmsg( $channel, "I don't know about $1, $nick" );
        }
    }
    elsif ($msg =~ /^(.{2,30})\?\s*$/) {
        if (exists($self->{Factoid}{$1})) {
            $bot->privmsg( $channel, "$1 is " . $self->{Factoid}{$1} );
        }
        else {
            $bot->privmsg( $channel, "No idea, $nick" );
        }
    }
    else {
        return 0;
    }
    
    return 1;
}

1;