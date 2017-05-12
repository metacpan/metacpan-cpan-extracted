package Crixa::HasMQ;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.13';

use Moose::Role;

use Moose::Util::TypeConstraints qw( duck_type );

# XXX - Test::Net::RabbitMQ doesn't support some of the methods we call
# internally so we won't require them but it sure would be nice to patch
# Test::Net::RabbitMQ to include these:
#
#        ack
#        basic_qos
#        exchange_delete
#        queue_delete
my $mq_api_type = duck_type [
    qw(
        channel_open
        connect
        disconnect
        exchange_declare
        get
        publish
        queue_bind
        queue_declare
        )
];

has _mq => (
    is       => 'ro',
    isa      => $mq_api_type,
    required => 1,
);

1;

# ABSTRACT: For internal use only

__END__

=pod

=head1 NAME

Crixa::HasMQ - For internal use only

=head1 VERSION

version 0.13

=head1 DESCRIPTION

This is used internally by Crixa. There are no user accessible parts here.

=encoding UTF-8

=head1 AUTHORS

=over 4

=item *

Chris Prather <chris@prather.org>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 - 2015 by Chris Prather.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
