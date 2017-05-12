package Akamai::Open::Client;
BEGIN {
  $Akamai::Open::Client::AUTHORITY = 'cpan:PROBST';
}
# ABSTRACT: The Akamai Open API Perl client structure for authentication data
$Akamai::Open::Client::VERSION = '0.03';
use strict;
use warnings;

use Moose;
use Akamai::Open::Debug;

has 'debug'         => (is => 'rw', default => sub{ return(Akamai::Open::Debug->instance());});
has 'client_secret' => (is => 'rw', isa => 'Str', trigger => \&Akamai::Open::Debug::debugger);
has 'client_token'  => (is => 'rw', isa => 'Str', trigger => \&Akamai::Open::Debug::debugger);
has 'access_token'  => (is => 'rw', isa => 'Str', trigger => \&Akamai::Open::Debug::debugger);

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Akamai::Open::Client - The Akamai Open API Perl client structure for authentication data

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 use Akamai::Open::Client;
 use Akamai::Open::DiagnosticTools;

 my $client = Akamai::Open::Client->new();
 $client->access_token('foobar');
 $client->client_token('barfoo');
 $client->client_secret('Zm9vYmFyYmFyZm9v');

 my $req = Akamai::Open::DiagnosticTools->new(client => $client);

=head1 ABOUT

I<Akamai::Open::Client> provides the data structure which holds the 
client specific data which is needed for the authentication process 
against the I<Akamai::Open> API.

This data is provided by Akamai and can be found in your 
L<LUNA control center account|https://control.akamai.com/>, 
inside the I<Manage APIs> tool.

=head1 AUTHOR

Martin Probst <internet+cpan@megamaddin.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Martin Probst.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
