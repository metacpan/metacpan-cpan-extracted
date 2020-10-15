#!/usr/bin/env perl

use strict;
use warnings;

use Plack::Builder;

use Async::Microservice::Time;

my $mise = Async::Microservice::Time->new();
my $app = sub { $mise->plack_handler(@_) };

builder {
    enable "Plack::Middleware::ContentLength";
    $app;
};

__END__

=head1 NAME

async-microservice-time.psgi - PSGI file for Async::Microservice::Time

=head1 DESCRIPTION

Example psgi for L<Async::Microservice::Time>.

=cut
