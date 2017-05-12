# NAME

AnyEvent::WebService::ImKayac - connection wrapper for im.kayac.com

# SYNOPSIS

    use AnyEvent::WebService::ImKayac;

    my $im = AnyEvent::WebService::ImKayac->new(
      type     => 'password',
      user     => '...',
      password => '...'
    );

    $im->send( message => 'Hello! test send!!', cb => sub {
        my ($hdr, $json, $reason) = @_;

        if ( $json ) {
            if ( $json->{result} eq "posted" ) {
            }
            else {
                warn $json->{error};
            }
        }
        else {
            warn $reason;
        }
    });

## METHODS

### new

You must pass `type` and `user` parameter to new method. And type should be
secret, password or none.

- type is secret

    You should pass secret\_key parameter.

- type is password

    You should pass password parameter.

- type is none

    You dond need to pass other parameter.

### $imkayac->send( message => '...', cb => sub {} );

Send with message and cb parameters. cb is called when message have been sent.

# AUTHORS

taiyoh <sun.basix@gmail.com>

soh335 <sugarbabe335@gmail.com>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
