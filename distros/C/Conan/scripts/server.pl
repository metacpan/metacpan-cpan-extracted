#!/usr/bin/perl

use POE qw(Component::Server::TCP);


POE::Component::Server::TCP->new(
  Port => 12345,
  ClientConnected => sub {
    print "got a connection from $_[HEAP]{remote_ip}\n";
    $_[HEAP]{client}->put("Smile from the server!");
  },
  ClientInput => sub {
    my $client_input = $_[ARG0];
    $client_input =~ tr[a-zA-Z][n-za-mN-ZA-M];
    $_[HEAP]{client}->put($client_input);
  },
);

POE::Kernel->run;
exit;
