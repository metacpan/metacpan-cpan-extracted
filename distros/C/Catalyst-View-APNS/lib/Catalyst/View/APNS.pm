package Catalyst::View::APNS;

use strict;
use Net::APNS;
use base qw( Catalyst::View );
use Data::Dumper;
use Carp;
use Catalyst::Exception;
our $VERSION = '0.01';

__PACKAGE__->mk_accessors(qw(apns cv certification private_key passwd));

sub new {
    my ( $class, $c, $arguments ) = @_;
    my $self = $class->next::method($c);

    for my $field ( keys(%$arguments) ) {
        next unless $field;
        next if $field ne 'apns';
        my $subs = $arguments->{$field};
        for my $subfield ( keys(%$subs) ) {
            if ( $self->can($subfield) ) {
                $self->$subfield( $subs->{$subfield} );
            }
            else {
                $c->log->debug( "Invalied parameter " . $subfield );
            }
        }
    }
    unless ( $self->certification ) {
        croak "Invalied certification";
    }
    unless ( $self->private_key ) {
        croak "Invalied private_key";
    }
    return $self;
}

sub process {
    my ( $self, $c ) = @_;
    my $apns   = Net::APNS->new;
    my $notify = $apns->notify(
        {
            cert => $self->certification,
            key  => $self->private_key,
        }
    );
    if ( $self->passwd ) {
        $notify->passwd( $self->passwd );
    }
    $notify->sandbox( $c->stash->{apns}->{sandbox} ) if $c->stash->{apns}->{sandbox};
    unless ( $c->stash->{apns}->{device_token} ) {
        croak "Invalied device token";
    }
    $notify->devicetoken( $c->stash->{apns}->{device_token} );
    $notify->message( $c->stash->{apns}->{message} )
      if $c->stash->{apns}->{badge};
    $notify->badge( $c->stash->{apns}->{badge} ) if $c->stash->{apns}->{badge};
    $notify->write;
}

1;
__END__

=head1 NAME

Catalyst::View::APNS - APNS View Class.

=head1 SYNOPSIS

# lib/MyApp/View/APNS.pm
package MyApp::View::APNS;
use base qw/Catalyst::View::APNS/;
1;

# Configure in lib/MyApp.pm
MyApp->config(
    {
        apns => {
            certification => cert    #require to specify
              private_key => key     #require to specify
        }
    }
);

sub hello : Local {
    my ( $self, $c ) = @_;
    $c->stash->{apns} = {
        device_token => $device_token,
        message      => $message,
        badge        => $badge,
        sandbox      => 0 | 1            #optional
    };
    $c->forward('MyApp::View::APNS');
}

Use the helper to create your View:
 
    myapp_create.pl view APNS APNS

=head1 DESCRIPTION

Catalyst::View::APNS is Catalyst view handler that Apple Push Notification Service.

=head1 AUTHOR

haoyayoi E<lt>st.hao.yayoi@gmail.comE<gt>

=head1 SEE ALSO

L<Net::APNS>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
