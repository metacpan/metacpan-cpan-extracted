package Connector::Tee;

use strict;
use warnings;
use English;
use Moose;
use Data::Dumper;

extends 'Connector::Proxy';

# Location must not be used
has '+LOCATION' => ( required => 0, 'isa' => 'Undef' );

has branches => (
    is  => 'rw',
    isa => 'ArrayRef',
);

has accept => (
    is  => 'rw',
    isa => 'Str',
    default => '',
);

sub get {

    my $self = shift;
    my $location = shift;
    my @args = @_;

    my $accept = $self->accept();
    $self->log()->trace('initialize tee');

    foreach my $child ( @{$self->branches()} ) {

        $self->log()->debug('query child ' . $child );

        my @prefix = $self->conn()->_build_path([ 'nodes', $child, @{$location}] );

        my $result = $self->conn()->get( \@prefix , \@args );

        $self->log()->trace('raw result ' . ($result // 'undef'));

        if (!defined $result) {
        } elsif (!$accept) {
            return $result;
        } elsif ($result =~ qr/$accept/) {
            $self->log()->debug('result accepted (scalar)');
            return $result;
        } else {
            $self->log()->debug('result mismatches pattern (scalar)');
            $self->log()->trace($accept . ' - ' . $result);
        }
    }

    return $self->_node_not_exists( $location );

}

sub get_hash {

    my $self = shift;
    my $location = shift;
    my @args = @_;

    my $accept = $self->accept();
    $self->log()->trace('initialize tee');

    foreach my $child ( @{$self->branches()} ) {

        $self->log()->debug('query child ' . $child );

        my @prefix = $self->conn()->_build_path([ 'nodes', $child, @{$location}] );

        my $result = $self->conn()->get_hash( \@prefix , \@args );

        $self->log()->trace('raw result ' . ($result // Dumper $result));

        if (!defined $result) {

        } elsif (!$accept) {
            return $result;
        } elsif (keys %{$result}) {
            $self->log()->debug('result accepted (hash)');
            return $result;
        }
    }

    return $self->_node_not_exists( $location );
}

sub get_list {


    my $self = shift;
    my $location = shift;
    my @args = @_;

    $self->log()->trace('initialize tee');

    foreach my $child ( @{$self->branches()} ) {

        $self->log()->debug('query child ' . $child );

        my @prefix = $self->conn()->_build_path([ 'nodes', $child, @{$location}] );

        my @result = $self->conn()->get_list( \@prefix , \@args );

        $self->log()->trace('raw result ' . (Dumper \@result));

        if (@result) {
            $self->log()->debug('result accepted (list)');
            return @result;
        }
    }

    return $self->_node_not_exists( $location );

}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 Name

Connector::Tee

=head1 Description

This connector can be used to search for a value over multiple branches
in a way that is transparent to the caller.

=head1 Configurarion Example

  class: Connector::Tee
  accept: "\\A[a-zA-Z]+\\z"
  branches:
   - static
   - conn1
   - conn2

  nodes:
    static:
       test1: NO
       test2: YES
       test3: 0
    conn1@: connector:connectors.conn1
    conn2@: connector:connectors.conn2

If the connector with the above configuration is called with I<get('test1')>,
the request is dispatched to nodes.static.test1 which evaluates to I<NO>
and is returned as the overall result.

If you call I<get('test3')>, the result is NOT I<0> as this does not match
the regex given as accept pattern! The request is therefore resend to
nodes.conn1.test3 which is revolved to another connector call. In case
the result of this connector does also not match the pattern (or is empty),
the same request is send to nodes.conn2.test3.

For the scalar I<get> call, the value given to accept is evaluated as a
case-sensitive regex pattern using qr// internally. If you set accept to
the empty string, any defined value is accepted.

For I<get_hash>, an empty value for accept will let the empty hash pass,
if accept is set to any true value, only non-empty hashes are accepted.

For I<get_list>, accept is ignored and only non-empty lists are accepted.

