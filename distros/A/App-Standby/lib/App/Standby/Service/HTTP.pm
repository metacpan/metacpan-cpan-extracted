package App::Standby::Service::HTTP;
$App::Standby::Service::HTTP::VERSION = '0.04';
BEGIN {
  $App::Standby::Service::HTTP::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: Baseclass for any simple HTTP service

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
# use English qw( -no_match_vars );
use Try::Tiny;
use JSON;
use LWP::UserAgent;
use URI::Escape;

# extends ...
extends 'App::Standby::Service';
# has ...
has '_ua' => (
    'is'      => 'rw',
    'isa'     => 'LWP::UserAgent',
    'lazy'    => 1,
    'builder' => '_init_ua',
);

has '_json' => (
    'is'      => 'rw',
    'isa'     => 'JSON',
    'lazy'    => 1,
    'builder' => '_init_json',
);

has 'username' => (
    'is'    => 'rw',
    'isa'   => 'Str',
    'required' => 0,
);

has 'password' => (
    'is'    => 'rw',
    'isa'   => 'Str',
    'required' => 0,
);

has 'endpoints' => (
    'is'    => 'rw',
    'isa'   => 'ArrayRef',
    'lazy'  => 1,
    'builder'   => '_init_endpoints',
);
# with ...
# initializers ...
sub _init_json {
    my $self = shift;

    my $JSON = JSON::->new->utf8();

    return $JSON;
}

sub _init_ua {
    my $self = shift;

    my $UA = LWP::UserAgent::->new();
    $UA->agent('App::Standby::Service::HTTP/0.01');

    return $UA;
}

# your code here ...
sub _build_payload {
    my $self = shift;
    my $user_ref = shift;

    my $content = $self->_json()->encode($user_ref);
    $content = URI::Escape::uri_escape($content);
    #$content =~ s/%3D/=/g;
    $content = 'queue='.$content;
    $content .= '&group_id='.$self->_config_value($self->name().'_group_id');

    return $content;
}

sub _update {
    my $self = shift;
    my $user_ref = shift;

    my $count = 0;

    foreach my $endpoint (@{$self->endpoints()}) {
        $self->logger()->log( message => "Updating endpoint: ".$endpoint, level => 'debug', );
        my $req = HTTP::Request::->new( POST => $endpoint );
        $req->content_type('application/x-www-form-urlencoded');
        my $payload = $self->_build_payload($user_ref);
        $req->content($payload);
        $self->logger()->log( message => "Payload: ".$payload, level => 'debug', );

        if($self->username() && $self->password()) {
            $req->authorization_basic( $self->username(), $self->password() );
        }

        my $content;
        my $response;
        my $prev_alarm = 0;

        my $success = try {
            local $SIG{ALRM} = sub { die "alarm-standby-service\n"; };
            $prev_alarm = alarm 10;
            $response   = $self->_ua()->request($req);
            if ( !$response->is_success ) {
                my $msg = "ERROR Request to $endpoint failed: " . $response->code() . ' - ' . $response->message();
                $self->logger()->log( message => $msg, level => 'error', );
                die( $msg );
            }
            $content = $response->content;
            if ( !$content ) {
                my $msg = "ERROR No content at $endpoint : " . $response->code() . ' - ' . $response->message();
                $self->logger()->log( message => $msg, level => 'error', );
                die( $msg );
            }
            1;    # make sure $success has a true value ...
        }
        catch {
            $self->logger()->log( message => "Request failed: ".$_, level => 'debug', );
        }
        finally {

            # make sure the alarm is off
            alarm $prev_alarm;
        };

        $count++ if $success;
    }

    return $count;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

App::Standby::Service::HTTP - Baseclass for any simple HTTP service

=head1 NAME

App::Standby::Service::HTTP - Baseclass for any simple HTTP service

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
