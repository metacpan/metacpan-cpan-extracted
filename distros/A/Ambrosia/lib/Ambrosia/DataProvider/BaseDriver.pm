package Ambrosia::DataProvider::BaseDriver;
use strict;
use warnings;

use Ambrosia::core::Nil;
use Ambrosia::error::Exceptions;
require Ambrosia::core::ClassFactory;

use Ambrosia::Meta;

class abstract
{
    public    => [qw/type catalog schema host port/],
    protected => [qw/_handler _cql_query _cache/],
};

our $VERSION = 0.010;

sub _init
{
    my $self = shift;
    $self->SUPER::_init(@_);
    $self->_cql_query = [];
}

sub cache
{
    return $_[0]->_cache;
}

######################## CONNECTION/TRANSACTION ########################
#Open connection. Return handler.
sub open_connection : Abstract {}

#Close connection
sub close_connection : Abstract {}

#Begin transaction
sub begin_transaction : Abstract {}

#Save transaction
sub save_transaction : Abstract {}

#Canceled transaction (rollback)
sub cancel_transaction : Abstract {}

sub handler
{
    $_[0]->_handler ||= $_[0]->open_connection;
}

sub table_info
{
    my $self = shift;
    $self->handler()->table_info($self->catalog, $self->schema, @_);
}

sub foreign_key_info
{
    my $self = shift;
    $self->handler()->foreign_key_info($self->catalog, $self->schema, @_);
}

sub primary_key_info
{
    my $self = shift;
    $self->handler()->primary_key_info($self->catalog, $self->schema, @_);
}

sub column_info
{
    my $self = shift;
    $self->handler()->column_info($self->catalog, $self->schema, @_);
}

######################## CQL ########################
sub reset
{
    my $self = shift;
    $self->_cql_query = [];
    $self->_cache = new Ambrosia::core::Nil();
    return $self;
}

sub next : Abstract {}

sub count : Abstract {}

####### CQL #########
sub WHAT()     { 0 }
sub SELECT()   { 1 }
sub INSERT()   { 2 }
sub UPDATE()   { 3 }
sub DELETE()   { 4 }
sub SOURCE()   { 5 }
sub PREDICATE() { 6 }
sub LIMIT()    { 7 }
sub ORDER_BY() { 8 }
sub NO_QUOTE() { 9 }
sub JOIN()     { 10 }
sub ON()       { 11 }
sub UNIQ()     { 12 }
sub UNION()    { 13 }
#####################
sub get_what      { $_[0]->_cql_query->[&WHAT] }
sub get_select    { $_[0]->_cql_query->[&SELECT] }
sub get_insert    { $_[0]->_cql_query->[&INSERT] }
sub get_update    { $_[0]->_cql_query->[&UPDATE] }
sub get_delete    { $_[0]->_cql_query->[&DELETE] }
sub get_source    { $_[0]->_cql_query->[&SOURCE] }
sub get_predicate { $_[0]->_cql_query->[&PREDICATE] }
sub get_limit     { $_[0]->_cql_query->[&LIMIT] }
sub get_order_by  { $_[0]->_cql_query->[&ORDER_BY] }
sub get_no_quote  { $_[0]->_cql_query->[&NO_QUOTE] }
sub get_join      { $_[0]->_cql_query->[&JOIN] }
sub get_on        { $_[0]->_cql_query->[&ON] }
sub get_uniq      { $_[0]->_cql_query->[&UNIQ] }
sub get_union     { $_[0]->_cql_query->[&UNION] }

sub what
{
    my $self = shift;
    $self->_cql_query->[&WHAT] = [@_];
    return $self;
}

sub select
{
    return $_[0];
}

sub insert
{
    return $_[0];
}

sub update
{
    return $_[0];
}

sub delete
{
    return $_[0];
}

sub source
{
    my $self = shift;
    $self->_cql_query->[&SOURCE] = ref $_[0] ? $_[0] : [@_];
    return $self;
}

sub from
{
    goto &source;
}

sub into
{
    goto &source;
}

sub predicate
{
    my $self = shift;
    push @{$self->_cql_query->[&PREDICATE]}, [@_] if @_;
    return $self;
}

sub where
{
    goto &predicate;
}

sub limit
{
    my $self = shift;

    if ( $_[0] )
    {
        $self->_cql_query->[&LIMIT]->[0] = $_[0];
    }
    else
    {
        delete $self->_cql_query->[&LIMIT];
    }
    return $self;
}

sub skip
{
    my $self = shift;
    if ( @_ )
    {
        $self->_cql_query->[&LIMIT]->[1] = shift;
    }
    elsif ( $self->_cql_query->[&LIMIT] )
    {
        delete $self->_cql_query->[&LIMIT]->[1];
    }
    return $self;
}

sub order_by
{
    my $self = shift;
    push @{$self->_cql_query->[&ORDER_BY]}, @_;
    return $self;
}

sub no_quote
{
    my $self = shift;
    $self->_cql_query->[&NO_QUOTE] = shift;
    return $self;
}

sub join
{
    return $_[0];
}

sub on
{
    my $self = shift;
    push @{$self->_cql_query->[&ON]}, [@_];
}

sub uniq
{
    my $self = shift;
    $self->_cql_query->[&UNIQ] = [@_];
}

sub union
{
    return $_[0];
}

1;


__END__

=head1 NAME

Ambrosia::DataProvider::BaseDriver - a base abstract class for concrete DriverType.

=head1 VERSION

version 0.010

=head1 DESCRIPTION

C<Ambrosia::DataProvider> is a base abstract class for concrete DriverType.

For more information see:

=over

=item L<Ambrosia::DataProvider::DBIDriver>

=item L<Ambrosia::DataProvider::IODriver>

=item L<Ambrosia::DataProvider::ResourceDriver>

=back

=head1 SUBROUTINES/METHODS


=head2 open_connection (Abstract method. Must be overriden in children class.)

Opens a connection. Returns a handler.

=head2 close_connection (Abstract method. Must be overriden in children class.)

Closes a connection.

=head2 begin_transaction (Abstract method. Must be overriden in children class.)

Begins a transaction

=head2 save_transaction (Abstract method. Must be overriden in children class.)

Saves a transaction

=head2 cancel_transaction (Abstract method. Must be overriden in children class.)

Canceled a transaction (rollback)

=head2 handler

Returns a handler of driver.

=head2 CQL (Abstract method. Must be overriden in children class.)

Returns an adapter for L<Ambrosia::QL>

=cut

=head1 DEPENDENCIES

L<Ambrosia::core::ClassFactory>
L<Ambrosia::error::Exceptions>

=head1 THREADS

Not tested.

=head1 BUGS

Please report bugs relevant to C<Ambrosia> to <knm[at]cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 Nickolay Kuritsyn. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nikolay Kuritsyn (knm[at]cpan.org)

=cut
