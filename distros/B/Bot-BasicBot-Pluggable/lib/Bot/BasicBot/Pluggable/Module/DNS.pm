package Bot::BasicBot::Pluggable::Module::DNS;
$Bot::BasicBot::Pluggable::Module::DNS::VERSION = '1.20';
use base qw(Bot::BasicBot::Pluggable::Module);
use warnings;
use strict;

use Socket;

sub help {
    return
"DNS lookups for hosts or IPs. Usage: 'dns <ip address>' for the hostname, 'nslookup <hostname>' for the IP address.";
}

sub told {
    my ( $self, $mess ) = @_;
    my $body = $mess->{body};

    my ( $command, $param ) = split( /\s+/, $body, 2 );
    $command = lc($command);

    if ( $command eq "dns" ) {
        my $addr = inet_aton($param);
        my @addr = gethostbyaddr( $addr, AF_INET );
        return "$param is $addr[0].";
    }
    elsif ( $command eq "nslookup" ) {
        my @addr    = gethostbyname($param);
        my $straddr = inet_ntoa( $addr[4] );
        return "$param is $straddr.";
    }
}

1;

__END__

=head1 NAME

Bot::BasicBot::Pluggable::Module::DNS - DNS lookups for hostnames or IP addresses

=head1 VERSION

version 1.20

=head1 IRC USAGE

=over 4

=item dns <ip address>

Returns the hostname of that IP address

=item nslookup <hostname>

Returns the IP address of the hostname.

=back

=head1 AUTHOR

Mario Domgoergen <mdom@cpan.org>

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.
