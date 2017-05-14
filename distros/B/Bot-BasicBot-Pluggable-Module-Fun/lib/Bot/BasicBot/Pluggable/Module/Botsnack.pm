package Bot::BasicBot::Pluggable::Module::Botsnack;

use strict;
use Bot::BasicBot::Pluggable::Module; 
use base qw(Bot::BasicBot::Pluggable::Module);

# ways to say hello
my @hello = ('hello', 
              'hi',
              'hey',
              'niihau',
              'bonjour',
              'hola',
              'salut',
              'que tal',
              'privet',
              "what's up");

# things to say when people thank me
my @welcomes = ('no problem', 'my pleasure', 'sure thing',
                 'no worries', 'de nada', 'de rien', 'bitte', 'pas de quoi');

sub said { 
    my ($self, $mess, $pri) = @_;

    my $body = $mess->{body}; 
    my $who  = $mess->{who};

    my $nick      = $self->{nick} || "";
    my $addressed = $mess->{address};

    return unless ($pri == 2);

    # Gotta be gender-neutral here... we're sensitive to the bot's needs. :-)
    if ($body =~ /(good(\s+fuckin[\'g]?)?\s+(bo(t|y)|g([ui]|r+)rl))|(bot(\s|\-)?snack)/i) {
        if (rand()  < .5)  {
            return "thanks $who :)";
         } else {
            return ":)";
         }
    }

    if ($addressed && $body =~ /you (rock|rocks|rewl|rule|are so+ co+l)/i) {
        if (rand()  < .5)  {
            return "thanks $who :)";
         } else {
            return ":)";
         }
    }

    if ($addressed && $body =~ /thank(s| you)/i) {
        if (rand()  < .5)  {
            return $welcomes[int(rand(@welcomes))]." who";
        } else {
            return "$who: ".$welcomes[int(rand(@welcomes))];
        }
    }     


    if ($body =~ /(\bayb\b)|(all your base)|(all your \w+ belong)|(someone set us up the bomb)|(^\s*hello gentlemen\s*$)/i) {
        return "$who - All Your Base references are verboten.  You may be kicked...this is not personal..come back soon";
    }

    if ($body =~ /^\s*(h(ello|i( there)?|owdy|ey|ola)|salut|bonjour|niihau|que\s*tal)( $nick)?\s*$/i) {
        # 65% chance of replying to a random greeting when not addressed
        return if (!$addressed and rand() > 0.35);

        my($r) = $hello[int(rand(@hello))];
        return "$r, $who";
    }

    

}

sub help {
    return "Commands: 'botsnack'";
}

1;

__END__


=head1 NAME

Bot::BasicBot::Pluggable::Module::Botsnack - a bot is for life, not just for Winter-een-mas

=head1 IRC USAGE

    botsnack

=head1 AUTHOR

Simon Wistow, <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2005, Simon Wistow

Distributed under the same terms as Perl itself.

=head1 SEE ALSO

=cut 

