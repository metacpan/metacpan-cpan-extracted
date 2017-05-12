package AnyEvent::TLS::SNI;
# ABSTRACT: Adds Server Name Indication (SNI) support to AnyEvent::TLS client.
$AnyEvent::TLS::SNI::VERSION = '0.02';

use strict;
use warnings;
no warnings 'redefine';
no strict 'refs';
use AnyEvent::Socket;
use AnyEvent::TLS;
use Net::SSLeay;
use Carp qw( croak );

{  
    my $old_ref = \&{ 'AnyEvent::TLS::new' };
    *{ 'AnyEvent::TLS::new' } = sub {
        my ( $class, %param ) = @_;

        my $self = $old_ref->( $class, %param );

        $self->{host_name} = $param{host_name}
            if exists $param{host_name};

        $self;
    };
}

{
    my $old_ref = \&{ 'AnyEvent::TLS::_get_session' };
    *{ 'AnyEvent::TLS::_get_session' } = sub($$;$$) {
        my ($self, $mode, $ref, $cn) = @_;

        my $session = $old_ref->( @_ );

        if ( $mode eq 'connect' ) {
            if ( $self->{host_name} ) {
                croak 'Client side SNI not supported for this openssl'
                    if Net::SSLeay::OPENSSL_VERSION_NUMBER() < 0x01000000;
                Net::SSLeay::set_tlsext_host_name( $session, $self->{host_name} );
            }
        }

        $session;
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::TLS::SNI - Adds Server Name Indication (SNI) support to AnyEvent::TLS client.

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    use AnyEvent::HTTP;
    use AnyEvent::TLS::SNI;

    my $cv = AnyEvent->condvar;
    $cv->begin;
    AnyEvent::HTTP::http_get(
        'https://sni.velox.ch/',
        tls_ctx => {
            verify => 1,
            verify_peername => 'https',
            host_name => 'sni.velox.ch'
        },
        sub {
            printf "Body length = %d\n", length( shift );
            $cv->end;
        }
    );
    $cv->recv;

=head1 NAME

AnyEvent::TLS::SNI - Adds Server Name Indication (SNI) support to AnyEvent::TLS client.
This module IS DEPRECATED, AnyEvent 7.12 has SNI support. 

=head1 VERSION

version 0.02

=head1 AUTHOR

Alexander Nalobin <alexander@nalobin.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Alexander Nalobin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Alexander Nalobin <alexander@nalobin.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Alexander Nalobin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
