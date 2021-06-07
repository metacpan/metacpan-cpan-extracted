package Beekeeper::JSONRPC::Notification;

use strict;
use warnings;

our $VERSION = '0.04';


sub new {
    my $class = shift;

    bless {
        jsonrpc => '2.0',
        method  => undef,
        params  => undef,
        @_
    }, $class;
}

sub method { $_[0]->{method} }
sub params { $_[0]->{params} }
sub id     { undef           }

sub mqtt_properties {
    $_[0]->{_mqtt_prop};
}

1;

__END__

=pod

=encoding utf8

=head1 NAME
 
Beekeeper::JSONRPC::Notification - Representation of a JSON-RPC notification.
 
=head1 VERSION
 
Version 0.04

=head1 DESCRIPTION

Objects of this class represents a JSON-RPC notification (see L<http://www.jsonrpc.org/specification>).

=head1 ACCESSORS

=over 4

=item method

A string with the name of the method to be invoked.

=item params

An arbitrary data structure to be passed as parameters to the defined method.

=item id

It is always undef.

=back

=head1 AUTHOR

José Micó, C<jose.mico@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021 José Micó.

This is free software; you can redistribute it and/or modify it under the same 
terms as the Perl 5 programming language itself.

This software is distributed in the hope that it will be useful, but it is 
provided “as is” and without any express or implied warranties. For details, 
see the full text of the license in the file LICENSE.

=cut
