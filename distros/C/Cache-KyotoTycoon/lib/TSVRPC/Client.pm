package TSVRPC::Client;
use strict;
use warnings;
use 5.008001;
our $VERSION = '0.16';
use TSVRPC::Parser;
use TSVRPC::Util;
use Furl::HTTP qw/HEADERS_NONE/;

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;

    my $base = $args{base} or Carp::croak("missing argument named 'base' for rpc base url");
    $base .= '/' unless $base =~ m{/$};

    my $timeout = exists( $args{timeout} ) ? $args{timeout} : 1;

    my $agent = $args{agent} || "$class/$VERSION";

    my $furl = Furl::HTTP->new(
        timeout       => $timeout,
        useragent     => $agent,
        header_format => HEADERS_NONE,
    );

    return bless {furl => $furl, base => $base}, $class;
}

sub call {
    my ( $self, $method, $args, $req_encoding ) = @_;
    $req_encoding ||= 'B'; # default encoding is base64. because base64 is very fast.
    my $content      = TSVRPC::Parser::encode_tsvrpc($args, $req_encoding);
    my $furl = $self->{furl};
    my %special_headers = ('content-type' => undef);
    my ( $minor_version, $code, $msg, $headers, $body ) = $furl->request(
        url     => $self->{base} . $method,
        headers => [
            "Content-Type" => "text/tab-separated-values; colenc=$req_encoding",
            "Content-Length" => length($content),
        ],
        method          => 'POST',
        content         => $content,
        special_headers => \%special_headers,
    );
    my $decoded_body;
    if (my $content_type = $special_headers{'content-type'}) {
        my $res_encoding = TSVRPC::Util::parse_content_type( $content_type );
        $decoded_body = defined($res_encoding) ? TSVRPC::Parser::decode_tsvrpc( $body, $res_encoding ) : undef;
    }
    return ($code, $decoded_body, $msg);
}

1;
__END__

=head1 NAME

TSVRPC::Client - TSV-RPC client library

=head1 SYNOPSIS

    use TSVRPC::Client;

    my $t = TSVRPC::Client->new(
        base    => 'http://localhost:1978/rpc/',
        agent   => "myagent",
        timeout => 1
    );
    $t->call('echo', {a => 'b'});

=head1 DESCRIPTION

The client library for TSV-RPC.

=head1 METHODS

=over 4

=item my $t = TSVRPC::Client->new();

Create new instance.

=over 4

=item base

The base TSV-RPC end point URL.

=item timeout

Timeout value for each request.

I<Default>: 1 second

=item agent

User-Agent value.

=back

=item my ($code, $body, $http_message) = $t->call($method[, \%args[, $encoding]]);

Call the $method with \%args.

I<$encoding>: the encoding for TSVRPC call. Following methods are available.

    B: Base64(Default. Because its very fast)
    Q: Quoted-Printable
    U: URI escape

I<Return>: $code: HTTP status code, $body: body hashref, $http_message: HTTP message.

=back

=head1 SEE ALSO

L<http://fallabs.com/mikio/tech/promenade.cgi?id=97>

