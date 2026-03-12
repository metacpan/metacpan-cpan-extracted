package DNS::Robot;

use strict;
use warnings;

use HTTP::Tiny;
use JSON::PP qw(encode_json decode_json);
use Carp qw(croak);

our $VERSION = '0.01';

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        base_url   => $args{base_url}   || 'https://dnsrobot.net/api',
        user_agent => $args{user_agent} || "DNS-Robot-Perl/$VERSION",
        timeout    => $args{timeout}    || 30,
    }, $class;
    $self->{http} = HTTP::Tiny->new(
        agent   => $self->{user_agent},
        timeout => $self->{timeout},
    );
    return $self;
}

# ── Internal helpers ──

sub _post {
    my ($self, $endpoint, $payload) = @_;
    my $url  = "$self->{base_url}/$endpoint";
    my $body = encode_json($payload);
    my $res  = $self->{http}->request('POST', $url, {
        headers => { 'Content-Type' => 'application/json' },
        content => $body,
    });
    croak "DNS::Robot: HTTP $res->{status} from $endpoint"
        unless $res->{success};
    return decode_json($res->{content});
}

sub _get {
    my ($self, $endpoint, $params) = @_;
    my $query = join '&', map { "$_=" . _uri_encode($params->{$_}) } sort keys %$params;
    my $url   = "$self->{base_url}/$endpoint?$query";
    my $res   = $self->{http}->request('GET', $url);
    croak "DNS::Robot: HTTP $res->{status} from $endpoint"
        unless $res->{success};
    return decode_json($res->{content});
}

sub _uri_encode {
    my ($str) = @_;
    $str =~ s/([^A-Za-z0-9\-._~])/sprintf("%%%02X", ord($1))/ge;
    return $str;
}

# ── Public methods ──

sub dns_lookup {
    my ($self, %args) = @_;
    croak "dns_lookup: 'domain' is required" unless $args{domain};
    return $self->_post('dns-query', {
        domain     => $args{domain},
        recordType => $args{record_type} || 'A',
        dnsServer  => $args{dns_server}  || '8.8.8.8',
    });
}

sub whois_lookup {
    my ($self, %args) = @_;
    croak "whois_lookup: 'domain' is required" unless $args{domain};
    return $self->_post('whois', { domain => $args{domain} });
}

sub ssl_check {
    my ($self, %args) = @_;
    croak "ssl_check: 'domain' is required" unless $args{domain};
    return $self->_post('ssl-certificate', { domain => $args{domain} });
}

sub spf_check {
    my ($self, %args) = @_;
    croak "spf_check: 'domain' is required" unless $args{domain};
    return $self->_post('spf-checker', { domain => $args{domain} });
}

sub dkim_check {
    my ($self, %args) = @_;
    croak "dkim_check: 'domain' is required" unless $args{domain};
    my $payload = { domain => $args{domain} };
    $payload->{selector} = $args{selector} if $args{selector};
    return $self->_post('dkim-checker', $payload);
}

sub dmarc_check {
    my ($self, %args) = @_;
    croak "dmarc_check: 'domain' is required" unless $args{domain};
    return $self->_post('dmarc-checker', { domain => $args{domain} });
}

sub mx_lookup {
    my ($self, %args) = @_;
    croak "mx_lookup: 'domain' is required" unless $args{domain};
    return $self->_post('mx-lookup', { domain => $args{domain} });
}

sub ns_lookup {
    my ($self, %args) = @_;
    croak "ns_lookup: 'domain' is required" unless $args{domain};
    return $self->_post('ns-lookup', { domain => $args{domain} });
}

sub ip_lookup {
    my ($self, %args) = @_;
    croak "ip_lookup: 'ip' is required" unless $args{ip};
    return $self->_post('ip-info', { ip => $args{ip} });
}

sub http_headers {
    my ($self, %args) = @_;
    croak "http_headers: 'url' is required" unless $args{url};
    my $url = $args{url};
    $url = "https://$url" unless $url =~ m{^https?://};
    return $self->_post('http-headers', { url => $url });
}

sub port_check {
    my ($self, %args) = @_;
    croak "port_check: 'host' is required" unless $args{host};
    croak "port_check: 'port' is required" unless $args{port};
    return $self->_get('port-check', {
        host => $args{host},
        port => $args{port},
    });
}

1;

__END__

=head1 NAME

DNS::Robot - Perl client for the DNS Robot API (dnsrobot.net)

=head1 SYNOPSIS

    use DNS::Robot;

    my $dr = DNS::Robot->new();

    # DNS lookup
    my $dns = $dr->dns_lookup(domain => 'example.com', record_type => 'A');
    print "IP: $_\n" for @{ $dns->{resolvedIPs} };

    # WHOIS lookup
    my $whois = $dr->whois_lookup(domain => 'example.com');
    print "Registrar: $whois->{registrar}{name}\n";

    # SSL certificate check
    my $ssl = $dr->ssl_check(domain => 'github.com');
    print "Valid: $ssl->{leafCertificate}{isValid}\n";
    print "Expires in: $ssl->{leafCertificate}{daysToExpire} days\n";

    # SPF record check
    my $spf = $dr->spf_check(domain => 'gmail.com');
    print "Grade: $spf->{grade} ($spf->{score}/100)\n";

    # DKIM record check
    my $dkim = $dr->dkim_check(domain => 'gmail.com', selector => 'google');
    print "Found: $dkim->{found}\n";

    # DMARC record check
    my $dmarc = $dr->dmarc_check(domain => 'gmail.com');
    print "Policy: $dmarc->{policy}\n";

    # MX records
    my $mx = $dr->mx_lookup(domain => 'gmail.com');
    for my $rec (@{ $mx->{mxRecords} }) {
        print "$rec->{priority} $rec->{exchange}\n";
    }

    # NS records
    my $ns = $dr->ns_lookup(domain => 'google.com');
    print "$_->{nameserver}\n" for @{ $ns->{nameservers} };

    # IP geolocation
    my $ip = $dr->ip_lookup(ip => '8.8.8.8');
    print "Location: $ip->{city}, $ip->{country}\n";

    # HTTP headers
    my $headers = $dr->http_headers(url => 'https://example.com');
    print "Status: $headers->{statusCode}\n";

    # Port check
    my $port = $dr->port_check(host => 'example.com', port => 443);
    print "Port 443 is $port->{status}\n";

=head1 DESCRIPTION

DNS::Robot is a Perl client for the free DNS and network tools API at
L<https://dnsrobot.net>. It provides access to 11 tools for DNS lookups,
WHOIS queries, SSL certificate checks, email authentication (SPF, DKIM,
DMARC), and more.

No API key is required. The module uses only core Perl modules (HTTP::Tiny,
JSON::PP, Carp) and has zero external dependencies.

=head1 CONSTRUCTOR

=head2 new

    my $dr = DNS::Robot->new(%options);

Creates a new DNS::Robot client. Options:

=over 4

=item * C<base_url> — API base URL (default: C<https://dnsrobot.net/api>)

=item * C<user_agent> — User-Agent header (default: C<DNS-Robot-Perl/$VERSION>)

=item * C<timeout> — HTTP timeout in seconds (default: 30)

=back

=head1 METHODS

All methods return a hashref of the decoded JSON response. On HTTP errors,
they C<die> with a descriptive message.

=head2 dns_lookup

    my $result = $dr->dns_lookup(
        domain      => 'example.com',   # required
        record_type => 'A',             # optional, default: A
        dns_server  => '8.8.8.8',       # optional, default: 8.8.8.8
    );

Performs a DNS lookup. Supports A, AAAA, MX, TXT, CNAME, NS, SOA, and other
record types.

See also: L<https://dnsrobot.net/dns-lookup>

=head2 whois_lookup

    my $result = $dr->whois_lookup(domain => 'example.com');

Retrieves WHOIS registration data including registrar, dates, nameservers,
and domain status.

See also: L<https://dnsrobot.net/whois-lookup>

=head2 ssl_check

    my $result = $dr->ssl_check(domain => 'github.com');

Checks the SSL/TLS certificate for a domain, returning issuer, validity
dates, certificate chain, and subject alternative names.

See also: L<https://dnsrobot.net/ssl-checker>

=head2 spf_check

    my $result = $dr->spf_check(domain => 'gmail.com');

Validates the SPF (Sender Policy Framework) record, returning the raw
record, parsed mechanisms, grade, and any warnings.

See also: L<https://dnsrobot.net/spf-checker>

=head2 dkim_check

    my $result = $dr->dkim_check(
        domain   => 'gmail.com',    # required
        selector => 'google',       # optional
    );

Checks DKIM (DomainKeys Identified Mail) records. If no selector is given,
common selectors are tried automatically.

See also: L<https://dnsrobot.net/dkim-checker>

=head2 dmarc_check

    my $result = $dr->dmarc_check(domain => 'gmail.com');

Validates the DMARC record, returning the policy, subdomain policy, grade,
and any warnings.

See also: L<https://dnsrobot.net/dmarc-checker>

=head2 mx_lookup

    my $result = $dr->mx_lookup(domain => 'gmail.com');

Retrieves MX records with priority, exchange hostnames, resolved IP
addresses, and provider detection.

See also: L<https://dnsrobot.net/mx-lookup>

=head2 ns_lookup

    my $result = $dr->ns_lookup(domain => 'google.com');

Retrieves nameserver records with response times and resolved IP addresses.

See also: L<https://dnsrobot.net/ns-lookup>

=head2 ip_lookup

    my $result = $dr->ip_lookup(ip => '8.8.8.8');

Looks up geolocation data for an IP address, including city, country, ISP,
organization, and AS number.

See also: L<https://dnsrobot.net/ip-lookup>

=head2 http_headers

    my $result = $dr->http_headers(url => 'https://example.com');

Fetches and analyzes HTTP response headers, including security grade and
individual header details.

See also: L<https://dnsrobot.net/http-headers>

=head2 port_check

    my $result = $dr->port_check(
        host => 'example.com',   # required
        port => 443,             # required (single port)
    );

Checks whether a single TCP port is open or closed on the given host.

See also: L<https://dnsrobot.net/port-checker>

=head1 ERROR HANDLING

All methods C<die> on failure. Wrap calls in C<eval> or use L<Try::Tiny>:

    use Try::Tiny;

    try {
        my $result = $dr->dns_lookup(domain => 'example.com');
        # process $result
    } catch {
        warn "DNS lookup failed: $_";
    };

=head1 SEE ALSO

L<https://dnsrobot.net> — DNS Robot: 53 free online DNS and network tools

L<https://github.com/dnsrobot/dns-robot-cli> — Source repository

=head1 AUTHOR

DNS Robot E<lt>cpan@dnsrobot.netE<gt>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.

=cut
