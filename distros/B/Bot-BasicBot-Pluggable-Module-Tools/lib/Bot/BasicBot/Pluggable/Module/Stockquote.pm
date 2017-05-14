package Bot::BasicBot::Pluggable::Module::Stockquote;

use strict;
use Bot::BasicBot::Pluggable::Module; 
use base qw(Bot::BasicBot::Pluggable::Module);

use Finance::Quote;

sub said { 
    my ($self, $mess, $pri) = @_;

    my $body = $mess->{body}; 
    my $who  = $mess->{who};

    return unless ($pri == 2);

    return unless $body =~ m!quote\s+([A-Z]{3,4})(\s+|$)!i;
    my $symbol = uc($1);


    my $q = Finance::Quote->new || return "Finance quoting seems to be broken";

    my @sources = $q->sources;

    

    foreach my $source (@sources) {
        my %hash = $q->fetch($source, $symbol);
        next unless defined $hash{$symbol,'price'};
        return sprintf "At %s %s %s traded at %s", $hash{$symbol,'date'}, 
                                                   $hash{$symbol,'time'}, 
                                                   $symbol, 
                                                   $hash{$symbol,'last'};
    }

    return "Couldn't get a value for $symbol";
}

sub help {
    return "Commands: 'yow' or 'be zippy'";
}

1;

=head1 NAME

Bot::BasicBot::Pluggable::Module::Stockquote - Get stock quote


=head1 SYNOPSIS
    
This allows you to get a stock quote for a symbol from various stock services

=head1 IRC USAGE

    quote <LETTER-TICKERNAME>

=head1 AUTHOR

Simon Wistow, <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2005, Simon Wistow

Distributed under the same terms as Perl itself.

=head1 SEE ALSO


=cut 

