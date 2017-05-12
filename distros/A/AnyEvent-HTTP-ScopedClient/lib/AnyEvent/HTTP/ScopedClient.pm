package AnyEvent::HTTP::ScopedClient;
{
  $AnyEvent::HTTP::ScopedClient::VERSION = '0.0.5';
}

# ABSTRACT: L<AnyEvent> based L<https://github.com/technoweenie/node-scoped-http-client>

use Moose;
use namespace::autoclean;

use URI;
use Try::Tiny;
use MIME::Base64;
use HTTP::Request;
use Encode qw/encode_utf8/;
use AnyEvent::HTTP;
use URI::QueryParam;
use URI::Escape;

has 'options' => (
    is  => 'ro',
    isa => 'HashRef',
);

sub request {
    my ( $self, $method, $reqBody, $callback ) = @_;
    if ( 'CODE' eq ref($reqBody) ) {
        $callback = $reqBody;
        undef $reqBody;
    }

    my %options = %{ $self->options };
    try {
        my %headers = %{ $options{headers} };

        if ( 'HASH' eq ref($reqBody) ) {
            my @pair;

            # push @pair, "$_=$reqBody->{$_}" for ( keys %$reqBody );
            push @pair, "$_=" . uri_escape_utf8( $reqBody->{$_} )
                for ( keys %$reqBody );
            $reqBody = join( '&', @pair );
        }

        my $sendingData
            = ( $method =~ m/^P/ && $reqBody && length $reqBody > 0 ) ? 1 : 0;
        $headers{'Content-Length'} = length $reqBody if $sendingData;
        $headers{'Content-Type'} = 'application/x-www-form-urlencoded'
            if ( $sendingData && !$headers{'Content-Type'} );

        if ( $options{auth} ) {
            $headers{Authorization}
                = 'Basic ' . encode_base64( $options{auth}, '' );
        }

        if ( $ENV{DEBUG} ) {
            print "$method " . $self->options->{url} . "\n";
            while ( my ( $k, $v ) = each %headers ) {
                print "$k: $v\n";
            }

            print "\n";
            print "$reqBody\n" if $sendingData;
        }

        http_request(
            $method,
            $options{url},
            headers => \%headers,
            body    => $sendingData ? encode_utf8($reqBody) : undef,
            $callback
        );
    }
    catch {
        $callback->($_) if $callback;
    };

    return $self;
}

sub fullPath {
    my ( $self, $p ) = @_;
}

sub scope {
    my ( $self, $url, $options, $callback ) = @_;
}

sub join {
    my ( $self, $suffix ) = @_;
}

sub path {
    my ( $self, $p ) = @_;
}

sub query {
    my ( $self, $key, $value ) = @_;
    if ( 'HASH' eq ref $key ) {
        while ( my ( $k, $v ) = each %$key ) {
            $self->options->{url}->query_param( $k => $v );
        }
    }
    else {
        $self->options->{url}->query_param( $key => $value );
    }
    return $self;
}

sub host {
    my ( $self, $h ) = @_;
}

sub protocol {
    my ( $self, $p ) = @_;
}

sub auth {
    my ( $self, $user, $pass ) = @_;
    if ( !$user ) {
        $self->options->{auth} = undef;
    }
    elsif ( !$pass && $user =~ m/:/ ) {
        $self->options->{auth} = $user;
    }
    else {
        $self->options->{auth} = "$user:$pass";
    }

    return $self;
}

sub header {
    my ( $self, $name, $value ) = @_;
    if ( 'HASH' eq ref $name ) {
        while ( my ( $k, $v ) = each %$name ) {
            $self->options->{headers}{$k} = $v;
        }
    }
    else {
        $self->options->{headers}{$name} = $value;
    }

    return $self;
}

sub headers {
    my ( $self, $h ) = @_;
}

sub buildOptions {
    my ( $self, $url, $params ) = @_;
    $params->{options}{url} = URI->new($url);
    $params->{options}{headers} ||= {};
}

sub BUILDARGS {
    my ( $self, $url, %params ) = @_;
    $self->buildOptions( $url, \%params );
    return \%params;
}

sub get    { shift->request( 'GET',    @_ ) }
sub post   { shift->request( 'POST',   @_ ) }
sub patch  { shift->request( 'PATCH',  @_ ) }
sub put    { shift->request( 'PUT',    @_ ) }
sub delete { shift->request( 'DELETE', @_ ) }
sub head   { shift->request( 'HEAD',   @_ ) }

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

AnyEvent::HTTP::ScopedClient - L<AnyEvent> based L<https://github.com/technoweenie/node-scoped-http-client>

=head1 VERSION

version 0.0.5

=head1 SYNOPSIS

    my $client = AnyEvent::HTTP::ScopedClient->new('http://example.com');
    $client->request('GET', sub {
        my ($body, $hdr) = @_;    # $body is undef if error occured
        return if ( !$body || $hdr->{Status} !~ /^2/ );
        # do something;
    });

    # shorcut for GET
    $client->get(sub {
        my ($body, $hdr) = @_;
        # ...
    });

    # Content-Type: application/x-www-form-urlencoded
    $client->post(
        { foo => 1, bar => 2 },    # note this.
        sub {
            my ($body, $hdr) = @_;
            # ...
        }
    );

    # application/x-www-form-urlencoded post request
    $client->post(
        "foo=1&bar=2"    # and note this.
        sub {
            my ($body, $hdr) = @_;
            # ...
        }
    );

    # Content-Type: application/json
    use JSON::XS;
    $client->header('Content-Type', 'application/json')
        ->post(
            encode_json({ foo => 1 }),
            sub {
                my ($body, $hdr) = @_;
                # ...
            }
        );

    $client->header('Accept', 'application/json')
        ->query({ key => 'value' })
        ->query('key', 'value')
        ->get(
            sub {
                my ($body, $hdr) = @_;
                # ...
            }
        );

    # headers at once
    $client->header({
        Accept        => '*/*',
        Authorization => 'Basic abcd'
    })->get(
        sub {
            my ($body, $hdr) = @_;
            # ...
        }
    );

=head1 DESCRIPTION

L<AnyEvent::HTTP> wrapper

=head1 SEE ALSO

L<https://github.com/technoweenie/node-scoped-http-client>

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Hyungsuk Hong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
