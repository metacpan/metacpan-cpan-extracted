#!/usr/bin/env perl

use Async::Microservice::HelloWorld;
my $mise = Async::Microservice::HelloWorld->new();
return sub { $mise->plack_handler(@_) };

__END__

=head1 NAME

async-microservice-helloworld.psgi - PSGI file for Async::Microservice::Hello

=head1 DESCRIPTION

Synopys example of L<Async::Microservice>.

=cut
