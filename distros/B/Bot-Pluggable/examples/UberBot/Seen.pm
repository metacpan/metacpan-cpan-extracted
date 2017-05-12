
package UberBot::Seen;
use strict;
use POE;
use Time::Piece;
use Time::Seconds;

sub new {
    my $class = shift;
    warn("New seen bot\n");
    return bless { seen => {} }, $class;
}

sub irc_public {
    my ($self, $bot, $who, $where, $msg) =
      @_[OBJECT, SENDER, ARG0, ARG1, ARG2];
    
    warn("Seen: irc_public\n");
    my ($nick, undef) = split(/!/, $who, 2);
    my $channel = $where->[0];
    
    $self->update_seen($nick, $channel, $msg);
    
    if ($msg =~ /seen\s+(\w+)\?\s*$/) {
        $bot->privmsg($channel, $self->seen_response($1, $nick));
        return 1;
    }
    
    return 0;
}

sub irc_msg {
    my ($self, $bot, $who, $msg) =
      @_[OBJECT, SENDER, ARG0, ARG2];
    
    my ($nick, undef) = split(/!/, $who, 2);
    
    $self->update_seen($nick, "/msg", $msg . " (in private)");
    
    if ($msg =~ /seen\s+(\w+)\?\s*$/) {
        $bot->privmsg($nick, $self->seen_response($1, $nick));
        return 1;
    }
    
    return 0;
}

sub seen_response {
    my ($self, $user, $nick) = @_;
    
    if (exists($self->{seen}{$user})) {
        my $seen = $self->{seen}{$user};
        my $secs = Time::Seconds->new(time - $seen->{'time'});
        return "$nick: $user was last seen on $seen->{channel} " .
            $secs->hours . " hours, ".
            $secs->minutes . " minutes and " .
            $secs->seconds . " seconds ago, saying: " .
            $seen->{msg} . " [" .
            gmtime($seen->{'time'})->strftime . "]";
    }
    else {
        return "I haven't seen $user, $nick";
    }
}

sub update_seen {
    my ($self, $nick, $channel, $msg) = @_;
    $self->{seen}{$nick} = {
        'time' => time(),
        'msg' => $msg,
        'channel' => $channel,
        };
}

1;