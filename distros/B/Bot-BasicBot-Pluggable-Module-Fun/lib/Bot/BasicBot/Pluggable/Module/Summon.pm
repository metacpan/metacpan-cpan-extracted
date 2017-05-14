package Bot::BasicBot::Pluggable::Module::Summon;

use strict;
use Bot::BasicBot::Pluggable::Module; 
use base qw(Bot::BasicBot::Pluggable::Module);

my @yows;

sub said { 
    my ($self, $mess, $pri) = @_;

    my $body = $mess->{body}; 
    my $who  = $mess->{who};

    return unless ($pri == 2);

    return unless $body  =~ /^summon\s+(.*?)\s*$/i;
    my $name =  $1;
    
    # TODO jabber stuff
    return uc("$name ") x int(50 / (length($name)+1)) . "COME TO ME";
}

sub help {
    return "Commands: 'summon <name>'";
}

1;

=head1 NAME

Bot::BasicBot::Pluggable::Module::Summon - summon someone on irc

=head1 SYNOPSIS

Summon someone to IRC

=head1 IRC USAGE

    summon <name>

=head1 AUTHOR

Simon Wistow, <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2005, Simon Wistow

Distributed under the same terms as Perl itself.

=head1 SEE ALSO


=cut 

