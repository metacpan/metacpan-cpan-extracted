package Data::ConveyorBelt;
use strict;
use 5.008_001;

use base qw( Class::Accessor::Fast );

our $VERSION = '0.02';

__PACKAGE__->mk_accessors(qw( getter filters ));

use Carp qw( croak );
use List::Util qw( min );

sub new {
    my $class = shift;
    my $machine = $class->SUPER::new(@_);
    $machine->filters( [ ] )
        unless defined $machine->filters;
    return $machine;
}

sub add_filter {
    push @{ shift->filters }, $_[0];
}

sub fetch {
    my $machine = shift;
    my(%param) = @_;

    my $limit = $param{limit} or croak "limit is required";
    my $offset = $param{offset} || 0;
    my $chunk_size = $param{chunk_size} || $limit;

    my $getter = $machine->getter or croak "No getter defined";
    my $filters = $machine->filters || [];

    my @data;
    my $need = $limit + $offset;
    my $off = 0;
    while ( @data < $need ) {
        my $data = $getter->( $chunk_size, $off );
        last unless $data && @$data;
        
        ## If we asked for $chunk_size results and got back fewer, we know
        ## that there aren't any more.
        my $got_enough = @$data >= $chunk_size ? 1 : 0;

        for my $filter ( @$filters ) {
            $data = $filter->( $data );
        }
        push @data, @$data;
        
        last unless $got_enough;
        
        $off += $chunk_size;
    }

    return [ @data[ $offset .. min($#data, $need - 1) ] ];
}

1;
__END__

=head1 NAME

Data::ConveyorBelt

=head1 SYNOPSIS

    my @data = ( 1 .. 15 );

    my $machine = Data::ConveyorBelt->new;
    $machine->getter( sub {
        my( $limit, $offset ) = @_;
        $offset ||= 0;
        return [ @data[ $offset .. $offset + $limit ] ];
    } );

    $machine->add_filter( sub {
        my( $data ) = @_;
        return [ grep { $_ % 2 == 1 } @$data ];
    } );
    
    my $data = $machine->fetch( limit => 5 );

=head1 DESCRIPTION

=head1 USAGE

=head2 Data::ConveyorBelt->new

Returns a new I<Data::ConveyorBelt> instance.

=head2 $machine->getter( [ \&getter ] )

Gets/sets the getter subroutine I<\&getter> that represents the list of
items in your data source. Required before calling I<fetch>.

A getter subroutine will be passed two arguments: the number of items to
return, and the offset into the list (0-based). It must return a reference
to the matching list of items.

=head2 $machine->add_filter( \&filter )

Adds a filter subroutine I<\&filter> to your chain of filters.

A filter will be passed a reference to a list of items as returned either
from your getter or from a previous filter in the chain. A filter must
return a reference to a list of items.

A filter can alter the size of the list of items, either removing or
expanding items in the list. It can also transform the items in the list.

=head2 $machine->fetch( %param )

Fetches a list of items from your data source, passes them through your
filters, and returns a reference to a list of items.

You must install a I<getter> before calling I<fetch>, but you don't have
to install any filters. Running I<fetch> without any filters does what
you'd expect: it returns the values directly from your data source,
unmodified and unfiltered.

I<%param> can contain:

=over 4

=item * limit

The number of items to return. Required.

=item * offset

The offset into the full list of items (0-based). Optional; defaults to C<0>.

=item * chunk_size

The number of items to request at a time from your getter function.

For example, if your getter has high latency (reading from a network
resource, for example), and if you suspect that your filters will be
fairly aggressive--and will end up removing a good percentage of the
items returned from the getter--you may want to fetch larger chunks of
data at a time.

Optional; defaults to the same value as I<limit>.

=back

=head1 LICENSE

I<Data::ConveyorBelt> is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR & COPYRIGHT

Except where otherwise noted, I<Data::ConveyorBelt> is Copyright 2007
Six Apart, cpan@sixapart.com.

=cut
