package Beekeeper::JSONRPC::Notification;

use strict;
use warnings;

our $VERSION = '0.09';


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
    $_[0]->{_mqtt_properties};
}

1;

__END__

=pod

=encoding utf8

=head1 NAME
 
Beekeeper::JSONRPC::Notification - Representation of a JSON-RPC notification
 
=head1 VERSION
 
Version 0.09

=head1 DESCRIPTION

Objects of this class represent a JSON-RPC notification (see L<http://www.jsonrpc.org/specification>).

On worker classes the method handlers setted by L<Beekeeper::Worker::accept_notifications> 
will receive these objects as parameters.

=head1 ACCESSORS

=over

=item method

Returns a string with the name of the method invoked.

=item params

Returns the arbitrary data structure passed as parameters.

=item id

Always returns undef.

=item mqtt_properties

Returns a hashref containing the MQTT properties of the notification.

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
