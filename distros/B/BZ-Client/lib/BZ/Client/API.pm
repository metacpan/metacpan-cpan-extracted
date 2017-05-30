#!/bin/false
# PODNAME: BZ::Client::API
# ABSTRACT: Abstract base class for the clients of the Bugzilla API.

use strict;
use warnings 'all';

package BZ::Client::API;
$BZ::Client::API::VERSION = '4.4002';

sub api_call {
    my(undef, $client, $methodName, $params, $options) = @_;
    return $client->api_call($methodName, $params, $options)
}

sub error {
    my(undef, $client, $message, $http_code, $xmlrpc_code) = @_;
    return $client->error($message, $http_code, $xmlrpc_code)
}

sub new {
    my $class = shift;
    my $self = { @_ };
    bless($self, ref($class) || $class);
    return $self
}

# Move stuff here so we dont do it over and over

sub _create {
    my(undef, $client, $methodName, $params, $key) = @_;
    $key ||= 'id';
    my $sub = ( caller(1) )[3];
    $client->log('debug', $sub . ': Running');
    my $result = __PACKAGE__->api_call($client, $methodName, $params);
    my $id = $result->{$key};
     __PACKAGE__->error($client, "Invalid reply by server, expected $methodName $key.")
        unless $id;
    $client->log('debug', "$sub: Returned $id");
    return $id
}

sub _returns_array {
    my(undef, $client, $methodName, $params, $key) = @_;
    my $sub = ( caller(1) )[3];
    $client->log('debug',$sub . ': Running');
    my $result = __PACKAGE__->api_call($client, $methodName, $params);
    my $foo = $result->{$key};
    __PACKAGE__->error($client, "Invalid reply by server, expected array of $methodName details")
        unless ($foo and 'ARRAY' eq ref $foo);
    $client->log('debug', "$sub: Recieved results");
    return wantarray ? @$foo : $foo
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BZ::Client::API - Abstract base class for the clients of the Bugzilla API.

=head1 VERSION

version 4.4002

=head1 SYNOPSIS

This is an abstract base class for classes like L<BZ::Client::Product>, which
are subclassing this one, in order to inherit common functionality.

None of these methods are useful to end users.

=head1 METHODS

=head2 api_call

Wraps C<BZ::Client::api_call>

=head2 error

Wraps C<BZ::Client::error>

=head2 new

Generic C<new()> function. Saving doing it over and over.

=head2 _create

Calls something on the Bugzilla Server, and returns and ID.

=head2 _returns_array

Calls something on the Bugzilla Server, and returns an array / arrayref.

=head1 SEE ALSO

L<BZ::Client>

=head1 AUTHORS

=over 4

=item *

Dean Hamstead <dean@bytefoundry.com.au>

=item *

Jochen Wiedmann <jochen.wiedmann@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Dean Hamstad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
