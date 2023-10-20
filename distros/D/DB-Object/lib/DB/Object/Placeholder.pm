##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Placeholder.pm
## Version v0.1.0
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2023/07/08
## Modified 2023/07/08
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package DB::Object::Placeholder;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw( $REGISTRY $VERSION );
    use Scalar::Util ();
    use overload (
        '""'   => 'as_string',
        'bool' => sub{1},
    );
    our $REGISTRY = {};
    our $VERSION = 'v0.12.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{type}  = undef;
    $self->{value} = undef;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    my $addr = Scalar::Util::refaddr( $self );
    $REGISTRY->{ $addr } = $self;
    return( $self );
}

sub as_string
{
    my $self = shift( @_ );
    my $addr = Scalar::Util::refaddr( $self );
    return( "__PLACEHOLDER__${addr}__" );
}

sub has
{
    my $self = shift( @_ );
    my $str  = shift( @_ );
    $str = Scalar::Util::reftype( $str ) eq 'SCALAR' ? $str : \$str;
    return( CORE::index( $$str, '__PLACEHOLDER__' ) != -1 );
}

sub replace
{
    my $self = shift( @_ );
    my $str  = shift( @_ );
    $str = Scalar::Util::reftype( $str ) eq 'SCALAR' ? $str : \$str;
    return if( !defined( $$str ) || !length( $$str ) );
    my $types  = $self->new_array( [] );
    my $values = $self->new_array( [] );
    $$str =~ s
    {
        __PLACEHOLDER__(\d+)__
    }
    {
        if( exists( $REGISTRY->{ $1 } ) )
        {
            my $p = $REGISTRY->{ $1 };
            push( @$types, $p->type );
            push( @$values, $p->value );
        }
        "?";
    }gexm;
    return( wantarray() ? ( $types, $$str ) : $types );
}

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

sub value { return( shift->_set_get_scalar( 'value', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

DB::Object::Placeholder - Placeholder Object

=head1 SYNOPSIS

    my $p = $dbh->P( type => 'inet', value => '127.0.0.1' );
    my $q = "SELECT * FROM ip_registry WHERE ip_addr = inet($p) OR inet($p) << ip_addr";
    my $types = $p->replace( \$q );
    # or, since the object here is just an accessor for this method
    # my $types = DB::Object::Placeholder->replace( \$q );
    # Got a Module::Generic::Array in response
    # $types->first -> inet
    # $types->second -> inet

For example:

	my $P = $dbh->placeholder( type => 'inet' );
    $orders_tbl->where( $dbh->OR( $orders_tbl->fo->ip_addr == "inet $P", "inet $P" << $orders_tbl->fo->ip_addr ) );
    my $order_ip_sth = $orders_tbl->select( 'id' ) || fail( "An error has occurred while trying to create a select by ip query for table orders: " . $orders_tbl->error );
    # SELECT id FROM orders WHERE ip_addr = inet ? OR inet ? << ip_addr

=head1 DESCRIPTION

This is a placeholder representation class, because sometime, putting a placeholder in complex or even simple sql expression makes it impossible for this API to detect it.

Using this class, you can place placeholder in your query, specify what data type they represent and allow this api to recognise them and benefit from them even.

=head1 METHODS

=head2 new

Takes a list of below options-value pairs and return a new instance of this class.

=over 5

=item * C<type>

The placeholder SQL data type

=item * C<value>

The placeholder value to bind, if any.

=back

=head2 as_string

Returns the placeholder object as a string, which would look something like C<__PLACEHOLDER_1234567__>

=head2 has

Provided with a query as a string or as a scalar reference and this will check if it contains any placeholder objects. It returns true if it does or false otherwise.

=head2 replace

Provided with a scalar (string) or scalar reference and this will replace any placeholder objects with actual SQL placeholders, i.e. C<?>, and return an array object of those placeholder datatypes, which may be blank. This is ok, it will be passed to the database driver upon binding and let it guess the best type. In list context, it also returns the modified query. This is useful if you only passed a string and not a scalar reference.

    my $types = $p->replace( \$query );
    # or
    my( $types, $query ) = $p->replace( $query );

=head2 type

Sets or gets the SQL data type for this placeholder. It is not the constant, but the data type string itself. For example, for C<PG_JSONB> in PostgreSQL, it would simply be C<jsonb>

=head2 value

Sets or gets the value of the placeholder, if any. This method is actually not used for now. It is reserved here for the future.

=head1 SEE ALSO

L<DB::Object::DB::Element>, L<DB::Object::DB::Elements>

L<DBI>, L<Apache::DBI>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021-2023 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
