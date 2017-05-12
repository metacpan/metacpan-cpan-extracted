package Ambrosia::RPC::Service::SOAP::Lite;
use strict;

use SOAP::Lite;
use SOAP::Lite +trace => 'all';

use Ambrosia::Meta;
class
{
    private => [qw/__soap __proxy __outputxml __readable __default_ns __ns __soapversion __timeout __on_error/]
};

our $VERSION = 0.010;

sub _init
{
    my $self = shift;
    $self->SUPER::_init( @_ );
    $self->__outputxml = undef if $self->__outputxml ne 'true';
    $self->__soapversion = '1.2' unless $self->__soapversion;
    $self->__soap = undef;
    $self->__on_error = sub {
        my $soap = shift;
        my $som = shift;

        my $error_msg = join "\n", (
                ref $som
                ? ('SOAP FAULT: ', 'code: ' . $som->faultcode, 'desc: ' . $som->faultstring)
                : ('SOAP TRANSPORT ERROR', $soap->transport->status)
            );

        die $error_msg;
    };
}

sub open_connection
{
    my $self = shift;
    unless ( $self->__soap )
    {
        $self->__soap = SOAP::Lite
            ->outputxml($self->__outputxml)
            ->default_ns($self->__default_ns)
            ->readable($self->__readable)
            ->soapversion($self->__soapversion)
            ->on_fault($self->__on_error)
            ->proxy($self->__proxy);
        $self->__soap->ns($self->__ns) if $self->__ns;
    }
    return $self;
}

sub close_connection
{
    $_[0]->__soap = undef;
}
################################################################################

sub on_success
{
}

sub on_error
{
    my $self = shift;
    my $proc = shift;
    if ( $proc && ref $proc eq 'CODE' )
    {
        $self->__on_error = $proc;
    }
    return $self;
}

sub call
{
    my $self = shift;
    my $action = shift;
    my %params = @_;
    return $self->__soap->call(
            $action,
            (map { SOAP::Data->name($_)->value( $params{$_} ) } keys %params)
        )->result;
}

1;

__END__

=head1 NAME

Ambrosia::RPC::Service::SOAP::Lite - implement remote procedure call through SOAP::Lite.

=head1 VERSION

version 0.010

=head1 DESCRIPTION

C<Ambrosia::RPC::Service::SOAP::Lite> implement remote procedure call through SOAP::Lite.

=head1 CONSTRUCTOR

=head1 THREADS

Not tested.

=head1 BUGS

Please report bugs relevant to C<Ambrosia> to <knm[at]cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 Nickolay Kuritsyn. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nikolay Kuritsyn (knm[at]cpan.org)

=cut
