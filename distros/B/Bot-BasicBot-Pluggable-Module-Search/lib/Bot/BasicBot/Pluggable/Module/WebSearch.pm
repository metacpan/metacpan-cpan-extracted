package Bot::BasicBot::Pluggable::Module::Search;

use strict;
use Bot::BasicBot::Pluggable::Module; 
use base qw(Bot::BasicBot::Pluggable::Module);

use WWW::Search;

sub said { 
    my ($self, $mess, $pri) = @_;

    my $phrase = $mess->{body}; 
    my $who    = $mess->{who};

    return unless ($pri == 2);

    my $engine;

    return unless ($phrase =~ s!search(?: using ([\w\:]+))?(?: for)? !$engine = ucfirst($1) || 'Yahoo';""!ei);

    return "Need something to search with!" if $phrase =~ m!^\s*$!;
 
    my %engines = map { $_ => 1 } WWW::Search::installed_engines;
    return "We don't have the engine installed for $engine, sorry" unless $engines{$engine};

    my $search = WWW::Search->new($engine);
    my $query  = WWW::Search::escape_query($phrase);    
    $search->native_query($query); 

    my $result;
    my $count  = 0;
    while (my $r = $search->next_result()) {
        if ($result) { 
            $result .= " or ".$r->url();
        } else {
            $result = $r->url();
        }
        last if ++$count >= 3;
     }

    return "Sorry, no results" unless $count;
    return $result; 

}

sub help {
    return "Commands: 'search [using <engine>] [for] <phrase>";
}

1;

=head1 NAME

Bot::BasicBot::Pluggable::Module::Search - web search interface

=head1 SYNOPSIS

Does exactly what it says on the tin; looks up things in web search
engines and brings you back the results. 


=head1 IRC USAGE


        [search] <engine> for <entry>

Where E<lt>C<engine>E<gt> is one of

        AltaVista Dejanews Excite Gopher HotBot Infoseek
        Lycos Magellan PLweb SFgate Simple Verity Google


=head1 AUTHOR

Simon Wistow, <simon@thegestalt.org>

based on code by Simon <simon@brecon.co.uk> and Kevin Lenzo <lenzo@cs.cmu.edu>

=head1 COPYRIGHT

Copyright 2005, Simon Wistow

Distributed under the same terms as Perl itself.

=head1 SEE ALSO


=cut 

