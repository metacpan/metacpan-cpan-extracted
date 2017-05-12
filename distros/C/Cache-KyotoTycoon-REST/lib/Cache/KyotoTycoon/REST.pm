package Cache::KyotoTycoon::REST;
use strict;
use warnings;
use 5.00800;
our $VERSION = '0.03';
use URI::Escape ();

use WWW::Curl::Easy;

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;

    my $agent = $args{agent} || "$class/$VERSION";
    my $timeout = $args{timeout} || 5;
    my $db = $args{db};

    my $curl = WWW::Curl::Easy->new();
    $curl->setopt(CURLOPT_TIMEOUT, $timeout);
    $curl->setopt(CURLOPT_USERAGENT, $agent);
    $curl->setopt(CURLOPT_HEADER, 0);

    my $host = $args{host} || '127.0.0.1';
    my $port = $args{port} || 1978;
    my $base = "http://${host}:${port}/";
    $base .= URI::Escape::uri_escape($db) . '/' if defined($db);
    bless {
        curl         => $curl,
        base         => $base,
    }, $class;
}

sub base { $_[0]->{base} }

sub get {
    my ($self, $key) = @_;
    my $curl = $self->{curl};
    $curl->setopt( CURLOPT_URL, $self->{base} . URI::Escape::uri_escape($key) );
    $curl->setopt( CURLOPT_CUSTOMREQUEST, "GET" );
    $curl->setopt( CURLOPT_HTTPHEADER, [
            "Connection: Keep-Alive",
            "Keep-Alive: 300",
            "Content-Length: 0",
            "\r\n"
        ]
    );
    $curl->setopt( CURLOPT_NOBODY, 0 );
    $curl->setopt( CURLOPT_POSTFIELDS, '' );
    my $response_content = '';
    open(my $fh, ">", \$response_content) or die "cannot open buffer";
    $curl->setopt(CURLOPT_WRITEDATA, $fh);
    my $retcode = $curl->perform();
    if ($retcode == 0) {
        my $code = $curl->getinfo(CURLINFO_HTTP_CODE);
        if ($code eq 200) {
            return $response_content;
        } elsif ($code eq 404) {
            return; # not found
        } else {
            die "unknown status code: $code";
        }
    } else {
        die $curl->strerror($retcode);
    }
}

sub head {
    my ($self, $key) = @_;
    my $curl = $self->{curl};
    $curl->setopt( CURLOPT_URL, $self->{base} . URI::Escape::uri_escape($key) );
    $curl->setopt( CURLOPT_HTTPHEADER,
        [
            "Content-Length: 0",
            "Connection: Keep-Alive",
            "Keep-Alive: 300",
            "\r\n"
        ]
    );
    $curl->setopt( CURLOPT_NOBODY, 1 );
    $curl->setopt( CURLOPT_CUSTOMREQUEST, "HEAD" );
    $curl->setopt( CURLOPT_POSTFIELDS,    '' );
    $curl->setopt( CURLOPT_HEADER,        0 );
    $curl->setopt( CURLOPT_WRITEDATA, undef );
    my $xt;
    $curl->setopt( CURLOPT_HEADERFUNCTION,
        sub {
            $xt          = $1 if $_[0] =~ m{^X-Kt-Xt\s*:\s*(.+)\015\012$};
            return length( $_[0] );
        }
    );
    my $retcode = $curl->perform;
    if ($retcode == 0) {
        my $code = $curl->getinfo(CURLINFO_HTTP_CODE);
        if ($code eq 200) {
            return $xt || '';
        } elsif ($code eq 404) {
            return; # not found
        }
    } else {
        die $curl->strerror($retcode);
    }
}

sub put {
    my ( $self, $key, $val, $expires_time ) = @_;
    my @headers = (
        "Content-Length: " . length($val),
        "Connection: Keep-Alive",
        "Keep-Alive: 300",
        "\r\n"
    );
    if ($expires_time) {
        my $expires =
          $expires_time > 0 ? time() + $expires_time : -$expires_time;
        unshift @headers, "X-Kt-Xt: $expires";
    }
    my $curl = $self->{curl};
    $curl->setopt( CURLOPT_URL, $self->{base} . URI::Escape::uri_escape($key) );
    $curl->setopt( CURLOPT_NOBODY, 0 );
    $curl->setopt( CURLOPT_HTTPHEADER,    \@headers );
    $curl->setopt( CURLOPT_CUSTOMREQUEST, "PUT" );
    $curl->setopt( CURLOPT_POSTFIELDS, $val );
    $curl->setopt( CURLOPT_WRITEDATA,  undef );
    $curl->setopt( CURLOPT_HEADERFUNCTION, undef );

    my $retcode = $curl->perform();
    if ( $retcode == 0 ) {
        my $code = $curl->getinfo(CURLINFO_HTTP_CODE);
        if ( $code eq 201 ) {
            return 1;
        }
        else {
            return undef;
        }
    }
    else {
        die $curl->strerror($retcode);
    }
}

sub delete {
    my ($self, $key) = @_;
    my $curl = $self->{curl};
    $curl->setopt( CURLOPT_URL, $self->{base} . URI::Escape::uri_escape($key) );
    $curl->setopt( CURLOPT_HTTPHEADER,
        [
            "Content-Length: 0",
            "Connection: Keep-Alive",
            "Keep-Alive: 300",
            "\r\n"
        ]
    );
    $curl->setopt( CURLOPT_CUSTOMREQUEST, "DELETE" );
    $curl->setopt( CURLOPT_NOBODY, 1 );
    $curl->setopt( CURLOPT_POSTFIELDS,    '' );
    $curl->setopt( CURLOPT_HEADER,        0 );
    $curl->setopt( CURLOPT_WRITEDATA, undef );
    $curl->setopt( CURLOPT_HEADERFUNCTION, undef );
    my $retcode = $curl->perform();
    if ($retcode == 0) {
        my $code = $curl->getinfo(CURLINFO_HTTP_CODE);
        if ($code eq 204) {
             return 1;
        } elsif ($code eq '404') {
            return 0;
        } else {
            return undef;
        }
    } else {
        die $curl->strerror($retcode);
    }
}

1;
__END__

=encoding utf8

=head1 NAME

Cache::KyotoTycoon::REST - Client library for KyotoTycoon RESTful API

=head1 SYNOPSIS

    use Cache::KyotoTycoon::REST;

    my $kt = Cache::KyotoTycoon::REST->new(host => $host, port => $port);
    $kt->put("foo", "bar", 100); # store key "foo" and value "bar".
    $kt->get("foo"); # => "bar"
    $kt->delete("foo"); # remove key

=head1 DESCRIPTION

Cache::KyotoTycoon::REST is client library for KyotoTycoon RESTful API.

=head1 CONSTRUCTOR

=over 4

=item port

=item host

=item timeout

=item db

Database name or number.

=back

=head1 METHODS

=over 4

=item my $val = $kt->get($key);

Retrieve the value for a I<$key>.  I<$key> should be a scalar.

I<Return:> value associated with the I<$key> and I<$expires> time in RFC1123 date format of GMT, empty string on no expiration time, or undef on $key is not found.

=item my $expires = $kt->head($key);

Check the I<$key> is exists or not.

I<Return:> I<$expires>: RFC 1123 date format of GMT, empty string on no expiration time, or undef if $key not found.

=item $kt->put($key, $val[, $expires]);

Store the I<$val> on the server under the I<$key>. I<$key> should be a scalar.
I<$value> should be defined and may be of any Perl data type.

I<$expires>: expiration time. If $expires>0, expiration time in seconds from now. If $expires<0, the epoch time. It is never remove if missing $expires.

I<Return:> 1 if server returns OK(201), or I<undef> in case of some error.

=item $kt->delete($key);

Remove cache data for $key.

I<Return:> 1 if server returns OK(200).  0 if server returns not found(404), or I<undef> in case of some error.

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

=head1 SEE ALSO

L<Cache::KyotoTycoon>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
