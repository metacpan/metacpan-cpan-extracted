package EasyDNS::DDNS::HTTP;

use strict;
use warnings;

use HTTP::Tiny;
use MIME::Base64 qw(encode_base64);

use Retry::Policy;

use EasyDNS::DDNS::Util ();

sub new {
    my ($class, %args) = @_;

    my $timeout = $args{timeout} // 10;

    my $http = $args{http} || HTTP::Tiny->new(
        timeout    => $timeout,
        verify_SSL => 1,
        agent      => $args{agent} // 'sdseasydyn/0.001',
    );

    my $retry = $args{retry} || Retry::Policy->new(
        max_attempts  => $args{max_attempts}  // 5,
        base_delay_ms => $args{base_delay_ms} // 200,
        max_delay_ms  => $args{max_delay_ms}  // 10_000,
        jitter        => $args{jitter}        // 'full',
    );

    my $self = bless {
        timeout => $timeout,
        http    => $http,
        retry   => $retry,
        verbose => $args{verbose} // 0,
    }, $class;

    return $self;
}

sub basicAuthHeader {
    my ($self, $user, $token) = @_;
    my $raw = $user . ":" . $token;
    return "Basic " . encode_base64($raw, "");
}

sub get {
    my ($self, $url, %opt) = @_;
    return $self->request('GET', $url, %opt);
}

sub request {
    my ($self, $method, $url, %opt) = @_;

    my $headers = $opt{headers} || {};
    my $content = $opt{content};
    my $desc    = $opt{desc} || EasyDNS::DDNS::Util::redact_basic_auth_in_url($url);

    my $res = $self->{retry}->run(sub {
        my ($attempt) = @_;

        $self->_v("HTTP $method attempt=$attempt $desc");

        my $r = $self->{http}->request($method, $url, {
            headers => $headers,
            (defined $content ? (content => $content) : ()),
        });

        # Network/timeout failures show up as success==0 in HTTP::Tiny.
        if (!$r->{success}) {
            die "transient: network/timeout\n";
        }

        my $code = $r->{status} // 0;

        # Retry on 429 + 5xx.
        if ($code == 429 || ($code >= 500 && $code <= 599)) {
            die "transient: http_$code\n";
        }

        return $r;
    });

    return $res;
}

sub _v {
    my ($self, $msg) = @_;
    return if !$self->{verbose};
    print STDERR "$msg\n";
}

1;

__END__

=pod

=head1 NAME

EasyDNS::DDNS::HTTP - HTTP layer with Retry::Policy integration

=head1 DESCRIPTION

Thin wrapper around HTTP::Tiny that retries transient failures using
Retry::Policy. Intended to keep retry logic isolated from business logic.

=cut

