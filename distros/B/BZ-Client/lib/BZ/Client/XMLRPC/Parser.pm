#!/bin/false
# PODNAME: BZ::Client::XMLRPC::Parser
# ABSTRACT: A parser for an XML-RPC response.
# vim: softtabstop=4 tabstop=4 shiftwidth=4 ft=perl expandtab smarttab

use strict;
use warnings 'all';

package BZ::Client::XMLRPC::Parser;
$BZ::Client::XMLRPC::Parser::VERSION = '4.4003';
use BZ::Client::XMLRPC::Response;
use BZ::Client::Exception;
use XML::Parser ();

sub new {
    my $class = shift;
    return bless({ @_ }, ref($class) || $class);
}

sub parse {
    my($self, $content) = @_;
    $self->{'stack'} = [];
    my $handler = BZ::Client::XMLRPC::Response->new();
    $self->register($self, $handler, sub {
        my($self, $handler) = @_;
        $self->{'exception'} = $handler->exception();
        $self->{'result'} = $handler->result();
    });
    my $start = sub {
        my(undef, $name) = @_;
        my $current = $self->{'current'};
        $self->error('Illegal state, no more handlers available on stack.') unless $current;
        $current->start($name);
    };
    my $end = sub {
        my(undef, $name) = @_;
        my $current = $self->{'current'};
        $self->error('Illegal state, no more handlers available on stack.') unless $current;
        $current->end($name);
    };
    my $chars = sub {
        my(undef, $text) = @_;
        my $current = $self->{'current'};
        $self->error('Illegal state, no more handlers available on stack.')
            unless $current;
        $current->characters($text);
    };
    my $parser = XML::Parser->new(
                            Handlers => {
                                Start => $start,
                                End   => $end,
                                Char  => $chars
                            });
    $parser->parse($content);
    die $self->{'exception'}
        if $self->{'exception'};
    return $self->{'result'}
}

sub register {
    my($self, $parent, $handler, $code) = @_;
    my $current = [$parent, $handler, $code];
    if ($parent->can('dec_level')) {
        $parent->dec_level();
    }
    $self->{'current'} = $handler;
    push @{$self->{'stack'}}, $current;
    $handler->init($self)
}

sub remove {
    my($self, $handler) = @_;
    my $stack = $self->{'stack'};
    my $top = pop @$stack;
    $self->{'current'} = @$stack ? $stack->[@$stack-1]->[1] : undef;
    $self->error('Illegal state, no more handlers available on stack.') unless $top;
    my($parent, $h, $code) = @$top;
    $self->error('Illegal state, the current handler is not the topmost.') unless $h eq $handler;
    &$code($parent, $h)
}

sub error {
    my($self, $message) = @_;
    BZ::Client::Exception->throw('message' => $message)
}

sub result {
    my $self = shift;
    my $res = $self->{'result'};
    return $res
}

sub exception {
    my $self = shift;
    return $self->{'exception'}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BZ::Client::XMLRPC::Parser - A parser for an XML-RPC response.

=head1 VERSION

version 4.4003

=head1 AUTHORS

=over 4

=item *

Dean Hamstead <dean@bytefoundry.com.au>

=item *

Jochen Wiedmann <jochen.wiedmann@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Dean Hamstad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
