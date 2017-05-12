package Autocache::Strategy;

use Any::Moose;

use Autocache::Record;
use Autocache::Logger qw(get_logger);

#
# get REQ
#
sub get { return undef; }

#
# set REQ REC
#
sub set { return $_[2]; }

#
# delete KEY
#
# should we send the request all the way through here too?
#
sub delete { return undef; }

sub clear { return undef; }


#
# create REQ
#
#
# create a cache record by invoking the function to be cached
#
# this generates a basic cache record, strategies built on top of this
# should feel free to add their own data elements to the cache record
#
sub create
{
    my ($self,$req) = @_;
    get_logger()->debug( "create" );
    my $value;

    if( $req->context eq 'S' )
    {
        $value = $req->generator->( @{$req->args} );
    }
    else
    {
        my @value = $req->generator->( @{$req->args} );
        $value = \@value;
    }

    my $rec = Autocache::Record->new(
        name => $req->name,
        key => $req->key,
        value => $value,
    );

    return $rec;
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Autocache::Store - Cached data storage base class.

=head1 DESCRIPTION

This is a base class for objects that provide storage for Autocache record
objects.

All the methods defined in this class are no-ops that conform to the below
documentation.

See also L<Autocache::Record>.

=head1 METHODS

The following methods should be overridden by concrete implementations.

Most sub-classes will over-ride all of them.

If a sub-class does over-ride a particular method it must adhere to the
behaviour described below.

In all cases C<$key> is a string that uniquely identifies the cache record
and C<$record> is an instance of L<Autocache::Record>.

=head2 C<get>

    $record = $store->get( $key );

Find a record identifed by the supplied key and return it, or undef if the
store does not contain a record related to the supplied key.

=head2 C<set>

    $record = $store->set( $key, $record );

Store the record under the supplied key and return the record.

=head2 C<delete>

    $record = $store->delete( $key );

Find a record identifed by the supplied key, delete it from the store and
return it, or undef.

=head2 C<clear>

    $store->clear();

Clear all records from this store.

=head1 LICENSE

This module is Copyright (c) 2010 Nigel Rantor. England. All rights
reserved.

You may distribute under the terms of either the GNU General Public License
or the Artistic License, as specified in the Perl README file.

=head1 SUPPORT / WARRANTY

This module is free software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=head1 AUTHORS

Nigel A Rantor - E<lt>wiggly@wiggly.orgE<gt>

Rajit B Singh - E<lt>rajit.b.singh@gmail.comE<gt>

=cut
