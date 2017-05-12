#!/bin/false
# PODNAME: BZ::Client::XMLRPC::Array
# ABSTRACT: Event handler for parsing a single XML-RPC array.

use strict;
use warnings 'all';

package BZ::Client::XMLRPC::Array;
$BZ::Client::XMLRPC::Array::VERSION = '4.4001';
use parent qw(BZ::Client::XMLRPC::Handler);

sub init {
    my($self,$parser) = @_;
    $self->SUPER::init($parser);
    $self->{'result'} = []
}

sub start {
    my($self,$name) = @_;
    my $l = $self->inc_level();
    if ($l == 0) {
        if ('array' ne $name) {
            $self->error("Expected array element, got $name");
        }
    } elsif ($l == 1) {
        if ('data' ne $name) {
            $self->error("Expected array/data element, got $name");
        }
    } elsif ($l == 2) {
        if ('value' eq $name) {
            my $handler = BZ::Client::XMLRPC::Value->new();
            $self->parser()->register($self, $handler, sub {
                my $array = $self->{'result'};
                push(@$array, $handler->result());
                $array;
            });
            $handler->start($name);
        } else {
            $self->error("Expected array/data/value, got $name");
        }
    } else {
        $self->error("Unexpected level $l with element $name");
    }
    return $l
}

sub result {
    my $self = shift;
    return $self->{'result'}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BZ::Client::XMLRPC::Array - Event handler for parsing a single XML-RPC array.

=head1 VERSION

version 4.4001

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
