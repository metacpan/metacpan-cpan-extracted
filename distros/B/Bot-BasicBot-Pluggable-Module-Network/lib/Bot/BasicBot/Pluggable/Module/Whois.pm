package Bot::BasicBot::Pluggable::Module::Whois;

use strict;
use Bot::BasicBot::Pluggable::Module; 
use base qw(Bot::BasicBot::Pluggable::Module);

use Net::Whois;

sub said { 
    my ($self, $mess, $pri) = @_;

    my $body = $mess->{body}; 
    my $who  = $mess->{who};

    return unless ($pri == 2);

    return unless $body =~ /^(whois|internic|ripe)(?: for)?\s+(\S+)$/i;

    my $where = $1;
    my $what  = $2;

    my $w = Net::Whois::Domain->new($what) || return "Can't connect to the WHOIS server";

    return "No match for $what" unless $w->ok;

    my $address = join "", map { "$_, " } $w->address;
    my $ns      = join "", map { my $name =  $$_[0]; my $ip = $$_[1] || " "; "$name ($ip), " } @{$w->servers};

    my $response = "";
    $response .= "Domain: ". $w->domain. " ";
    $response .= "Name: ". $w->name. " ";
    $response .= "Tag: ". $w->tag. " ";
    $response .= "Address: $address ";
    $response .= "Country: ". $w->country. " ";
    $response .= "Name Servers: $ns"; 

    return $response;



}

sub help {
    return "Commands: '(whois|internic|ripe) fo <host>'";
}

1;

=head1 NAME

Bot::BasicBot::Pluggable::Module::Whois - look up Internic/RIPE whois records for a host


=head1 SYNOPSIS

Queries RIPE or the Internic for the whois information about the
supplied host, and formats it up nicely.


=head1 IRC USAGE

    Internic|RIPE for <host>

=head1 AUTHOR

Simon Wistow, <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2005, Simon Wistow

Distributed under the same terms as Perl itself.

=head1 SEE ALSO


=cut 

