package App::PAIA::Agent;
use strict;
use v5.10;

our $VERSION = '0.30';

use HTTP::Tiny 0.024;
use URI;
use App::PAIA::JSON;

sub new {
    my ($class, %options) = @_;
    bless {
        insecure => !!$options{insecure},
        logger   => $options{logger},
        dumper   => $options{dumper},
        agent    => HTTP::Tiny->new( verify_SSL => (!$options{insecure}) ),
    }, $class;
}

sub request {
    my $self    = shift;
    my $method  = shift;
    my $url     = URI->new(shift) // '';
    my $param   = shift // {};
    my $headers = { 
        Accept       => 'application/json',
        'User-Agent' => "App::PAIA/".($APP::PAIA::VERSION//'?'),
        @_ 
    };
    my $content;

    $self->{logger}->("$method $url");

    my $scheme = $url->scheme // '';
    if ($self->{insecure}) {
        return $self->error( msg => "Not an URL: $url" )
            unless $scheme =~ /^https?$/;
    } elsif( $scheme ne 'https' ) {
        return $self->error( 
            msg => "PAIA requires HTTPS unless insecure (got $url)"
        );
    }

    if ($method eq 'POST') {
        $headers->{'Content-Type'} = 'application/json';
        $content = encode_json($param);
    } elsif (%$param) {
        $url->query_form(%$param);
    }

    $self->dump_request( $method, $url, $headers, $content );
    my $response = $self->{agent}->request( $method, $url, {
        headers => $headers,
        content => $content    
    } );

    $self->dump_response( $response );
   
    return $response if $response->{status} eq '599';

    my $json = eval { decode_json($response->{content}) };
    return $self->error( url => "$url", msg => "$@" ) if "$@";

    return ($response, $json);
}

sub error {
    my ($self, %opts) = @_;
    return {        
        url     => $opts{url} // '',
        success => q{},
        status  => $opts{status} // '599',
        reason  => 'Internal Exception',
        content => $opts{msg},
        headers => {
            'content-type'   => 'text/plain',
            'content-length' => length $opts{msg},
        }
    };
}

sub dump {
    my ($self, $msg) = @_;
    #  say ":$msg";
    $self->{dumper}->($msg);
}

sub dump_request {
    my ($self, $method, $url, $headers, $content) = @_;

    $self->dump("$method " . $url->path_query ." HTTP/1.1");
    $self->dump("Host: " . $url->host);
    $self->dump_message( $headers, $content );
}

sub dump_response {
    my ($self, $res) = @_;

    $self->dump("\n" . $res->{protocol} . " " . $res->{status});
    $self->dump_message( $res->{headers}, $res->{content} );
}

sub dump_message {
    my ($self, $headers, $content) = @_;

    while (my ($header, $value) = each %{$headers}) {
        $value = join ", ", @$value if ref $value;
        $self->dump(ucfirst($header) . ": $value");
    }
    $self->dump("\n$content") if defined $content;
}

1;
__END__

=head1 NAME

App::PAIA::Agent - HTTP client wrapper

=head1 DESCRIPTION

This class implements a HTTP client by wrapping L<HTTP::Tiny>. The client
expects to send JSON on HTTP POST and to receive JSON as response content.

=head1 OPTIONS

=over

=item insecure

disables C<verfiy_SSL>.

=item logger

method that HTTP method and URL are send to before each request.

=item dumper

method that HTTP requests and responses are sent to.

=back

=cut
