package Recursioner;
use strict;
use utf8;
use warnings qw(all);

use Moo;
use MooX::Types::MooseLike::Base qw(CodeRef Str);
use Net::Curl::Easy qw(/^CURLOPT_/);

extends 'AnyEvent::Net::Curl::Queued::Easy';

has cb      => (is => 'ro', isa => CodeRef, required => 1);

after finish => sub {
    my ($self, $result) = @_;

    my @path = $self->final_url->path_segments;
    my $str = pop @path;
    my $num = pop @path;
    --$num;

    for (0 .. $num) {
        $str++;
        my $uri = $self->final_url->clone;
        $uri->path('/repeat/' . $_ . '/' . $str);

        # TODO prepend() fails sporadically?!
        $self->queue->append(
            sub {
                __PACKAGE__->new(
                    initial_url => $uri,
                    cb          => $self->cb,
                )
            }
        );
    }

    $self->cb->(@_);
};

1;
