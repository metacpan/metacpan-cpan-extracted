package Ark::Request;
use Mouse;

extends 'Plack::Request::WithEncoding';

use Path::AttrRouter::Match;

has match => (
    is      => 'rw',
    isa     => 'Path::AttrRouter::Match',
    handles => [qw/action args captures/],
);

{
    no warnings 'once';
    *arguments = \&args;
}

no Mouse;

# for backward compatible
sub wrap {
    my ($class, $req) = @_;

    warn 'Ark::Request#wrap is deprecated. use new() directory instead';
    return $class->new( $req->env );
}

sub uri {
    my $self = shift;

    $self->{uri} ||= $self->SUPER::uri;
    $self->{uri}->clone; # avoid destructive opearation
}

sub base {
    my $self = shift;

    $self->{base} ||= $self->SUPER::base;
    $self->{base}->clone; # avoid destructive operation
}

sub uri_with {
    my ($self, $args) = @_;

    my $uri = $self->uri;

    my %params = $uri->query_form;
    while (my ($k, $v) = each %$args) {
        $params{$k} = $v;
    }
    $uri->query_form(%params);

    return $uri;
}

1;
