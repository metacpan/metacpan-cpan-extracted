#!/bin/false
# PODNAME: BZ::Client::XMLRPC::Handler
# ABSTRACT: Abstract event handler for parsing an XML-RPC response.
use strict;
use warnings 'all';

package BZ::Client::XMLRPC::Handler;
$BZ::Client::XMLRPC::Handler::VERSION = '4.4001';
sub new {
    my $class = shift;
    my $self = { @_ };
    $self->{'level'} = 0;
    bless($self, ref($class) || $class);
    return $self
}

sub init {
    my($self,$parser) = @_;
    $self->parser($parser);
}

sub parser {
    my $self = shift;
    if (@_) {
        $self->{'parser'} = shift;
    } else {
        return $self->{'parser'};
    }
}

sub level {
    my $self = shift;
    if (@_) {
        $self->{'level'} = shift;
    } else {
        return $self->{'level'};
    }
}

sub inc_level {
    my $self = shift;
    my $res = $self->{'level'}++;
    return $res
}

sub dec_level {
    my $self = shift;
    my $res = --$self->{'level'};
    return $res
}

sub error {
    my($self, $msg) = @_;
    $self->parser()->error($msg);
}

sub characters {
    my($self, $text) = @_;
    if ($text !~ /^\s*$/s) {
        $self->error("Unexpected non-whitespace: $text");
    }
}

sub end {
    # my($self,$name) = @_;
    my $self = shift;
    my $l = $self->dec_level();
    if ($l == 0) {
        $self->parser()->remove($self);
    }
    return $l
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BZ::Client::XMLRPC::Handler - Abstract event handler for parsing an XML-RPC response.

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
