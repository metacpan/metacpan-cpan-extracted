package Bot::BasicBot::Pluggable::Module::Traceroute;

use strict;
use Bot::BasicBot::Pluggable::Module; 
use base qw(Bot::BasicBot::Pluggable::Module);

use Net::Traceroute;

sub said { 
    my ($self, $mess, $pri) = @_;

    my $body = $mess->{body}; 
    my $who  = $mess->{who};

    return unless ($pri == 2);
    return unless $body =~ m!\s*traceroute\s+([\w\.]+)!;
    
    my $host = $1; 
    
    
    my $t;
    eval  { $t = Net::Traceroute->new( host => $host ) };

    return "Hrmm, couldn't traceroute to $host - $@" if $@;
    return "Hrmm, couldn't traceroute to $host cos I can't find it" if !$t->found;
    
    return $t->hop_query_host($t->hops,0);
}

sub help {
    return "Commands: 'traceroute <host>";
}

1;

=head1 NAME

Bot::BasicBot::Pluggable::Module::Traceroute - do a traceroute for a host

=head1 IRC USAGE

      traceroute <host>

=head1 AUTHOR

Simon Wistow, <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2005, Simon Wistow

Distributed under the same terms as Perl itself.

=head1 SEE ALSO


=cut 

