package App::Donburi::Web::Request;
use strict;
use warnings;

use parent qw/Plack::Request/;

use Encode ();
use Hash::MultiValue;

sub is_post_request { $_[0]->method eq 'POST' }
sub http_host { $_[0]->env->{HTTP_HOST} }

# from Amon2::Request
sub body_parameters {
    my ($self) = @_;
    $self->{'donburi.body_parameters'} ||= $self->_decode_parameters($self->SUPER::body_parameters());
}

sub query_parameters {
    my ($self) = @_;
    $self->{'donburi.query_parameters'} ||= $self->_decode_parameters($self->SUPER::query_parameters());
}

sub _decode_parameters {
    my ($self, $stuff) = @_;

    my $encoding = 'utf-8';
    my @flatten = $stuff->flatten();
    my @decoded;
    while ( my ($k, $v) = splice @flatten, 0, 2 ) {
        push @decoded, Encode::decode($encoding, $k), Encode::decode($encoding, $v);
    }
    return Hash::MultiValue->new(@decoded);
}
sub parameters {
    my $self = shift;

    $self->env->{'donburi.request.merged'} ||= do {
        my $query = $self->query_parameters;
        my $body  = $self->body_parameters;
        Hash::MultiValue->new( $query->flatten, $body->flatten );
    };
}

1;
