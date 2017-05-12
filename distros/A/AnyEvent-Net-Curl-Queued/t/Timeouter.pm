package Timeouter;
use strict;
use utf8;
use warnings qw(all);

use Data::Dumper;
use Moo;
use MooX::Types::MooseLike::Base qw(Num);
use Test::More;
use Time::HiRes qw(time);

extends 'AnyEvent::Net::Curl::Queued::Easy';

has started => (is => 'rw', isa => Num, default => sub { time });
has '+use_stats' => (default => sub { 1 });

around finish => sub {
    my ($class, $self, $result) = @_;
    like(
        q...$result,
        qr{\btimed?out\b}ix,
        sprintf('%s after %0.3fs [%s]', $self->final_url, time - $self->started, scalar localtime),
    );

    diag Dumper $self->stats
        unless 0 + $result;
};

1;
