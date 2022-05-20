package Addr::MyIP;

use strict;
use warnings;

use Data::Dumper;
use Exporter qw(import);
use HTTP::Tiny;

our $VERSION = '0.05';

our @EXPORT = qw(myip myip6);

use constant {
    IPV4_URL    => 'https://api.ipify.org',
    IPV6_URL    => 'https://api64.ipify.org',
};

my $client = HTTP::Tiny->new;

sub myip {
    return _get(IPV4_URL);
}
sub myip6 {
    my $ip = _get(IPV6_URL);

    return $ip =~ /\./ ? '' : $ip;
}

sub _get {
    my ($url) = @_;
    my $response = $client->get($url);

    my $status = $response->{status};

    if ($status != 200) {
        warn "Failed to connect to $url to get your address: $response->{content}";
        return '';
    }

    return $response->{content};
}

sub __placeholder {}

1;
__END__

=head1 NAME

Addr::MyIP - Get your public facing IPv4 or IPv6 address

=for html
<a href="https://github.com/stevieb9/addr-myip/actions"><img src="https://github.com/stevieb9/addr-myip/workflows/CI/badge.svg"/></a>
<a href='https://coveralls.io/github/stevieb9/addr-myip?branch=main'><img src='https://coveralls.io/repos/stevieb9/addr-myip/badge.svg?branch=main&service=github' alt='Coverage Status' /></a>

=head1 SYNOPSIS

    use Addr::MyIP;

    my $ipv4_addr = myip();
    my $ipv6_addr = myip6();

=head1 DESCRIPTION

For end-users, please review the
L<documentation|https://metacpan.org/pod/distribution/Addr-MyIP/bin/myip.pod> for
the L<myip|https://metacpan.org/pod/distribution/Addr-MyIP/bin/myip.pod>
program that we've installed for you as part of this distribution.

This software uses the B<api[64].ipify.org> website to fetch your public IP
address. We do this in as small and tight a package as we can.

=head1 FUNCTIONS

There are only two functions we provide, both exported into your namespace by
default.

=head2 myip

Returns a string containing your IPv4 address. If one isn't found, we'll return
an empty string.

=head2 myip6

Returns a string containing your IPv6 address if available. If one isn't found,
we'll return an empty string.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2022 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
