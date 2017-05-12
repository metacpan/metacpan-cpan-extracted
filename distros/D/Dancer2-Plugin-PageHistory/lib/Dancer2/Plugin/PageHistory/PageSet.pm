package Dancer2::Plugin::PageHistory::PageSet;

=head1 NAME

Dancer2::Plugin::PageHistory::PageSet - collection of pages with accessors

=cut

use Carp qw(croak);
use Scalar::Util qw(blessed);
use Sub::Quote qw(quote_sub);
use Dancer2::Core::Types qw(ArrayRef HashRef InstanceOf Int Maybe Str);
use Moo;
use namespace::clean;

=head1 ATTRIBUTES

=head2 default_type

For all methods that expect an argument C<type> then this C<default_type>
will be the one used when C<type> is not specified. Defaults to C<default>.

=cut

has default_type => (
    is      => 'ro',
    isa     => Str,
    default => 'default',
);

=head2 fallback_page

In the event that L</latest_page> or L</previous_page> have no page to
return then L</fallback_page> is returned instead.

By default this is set to undef.

You can set this page to something else by passing any of the following as
the value of this attribute:

=over

=item * a hash reference to be passed to Dancer2::Plugin::PageHistory::Page->new

=item * a Dancer2::Plugin::PageHistory::Page object

=back

=cut

has fallback_page => (
    is      => 'ro',
    isa     => Maybe [ InstanceOf ['Dancer2::Plugin::PageHistory::Page'] ],
    default => undef,
    coerce  => sub {
        $_[0] ? Dancer2::Plugin::PageHistory::Page->new( %{ $_[0] } ) : undef;
    },
);

=head2 max_items

The maximum number of each history C<type> stored in L</pages>.

=cut

has max_items => (
    is      => 'ro',
    isa     => Int,
    default => 10,
);

=head2 pages

A hash reference of arrays of hash references.

Primary key is the history C<type> such as C<default> or C<product>. For each 
C<type> an array reference of pages is stored with new pages added at 
the start of the array reference.

=cut

has pages => (
    is  => 'rw',
    isa => HashRef [
        ArrayRef [ InstanceOf ['Dancer2::Plugin::PageHistory::Page'] ] ],
    coerce    => \&_coerce_pages,
    predicate => 1,
);

sub _coerce_pages {
    my %pages;
    while ( my ( $type, $list ) = each %{ $_[0] } ) {
        foreach my $page (@$list) {
            if ( !blessed($page) && ref($page) eq 'HASH' ) {
                push @{ $pages{$type} },
                  Dancer2::Plugin::PageHistory::Page->new(%$page);
            }
        }
    }
    return \%pages;
}

=head2 methods

An array reference of extra method names that should be added to the class.
For example if one of these method names is 'product' then the following
shortcut method will be added:

    sub product {
        return shift->pages->{"product"};
    }

=cut

has methods => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
    trigger => 1,
);

sub _trigger_methods {
    my ( $self, $methods ) = @_;
    foreach my $method (@$methods) {
        unless ( $self->can($method) ) {
            quote_sub "Dancer2::Plugin::PageHistory::PageSet::$method",
              q{ return shift->pages->{$type} || []; },
              { '$type' => \$method };
        }
    }
}

=head1 METHODS

=head2 add( %args )

C<$args{type}> defaults to L</default_type>.

In addition to C<type> other arguments should be those passed to C<new> in
L<Dancer2::Plugin::PageHistory::Page>.

=cut

sub add {
    my ( $self, %args ) = @_;

    my $type = delete $args{type} || $self->default_type;

    my $page = Dancer2::Plugin::PageHistory::Page->new(%args);

    if (   !$self->pages->{$type}
        || !$self->pages->{$type}->[0]
        || $self->pages->{$type}->[0]->uri ne $page->uri )
    {

        # not same uri as newest items on this list so add it

        unshift( @{ $self->pages->{$type} }, $page );

        # trim to max_items if necessary
        pop @{ $self->pages->{$type} }
          if @{ $self->pages->{$type} } > $self->max_items;
    }
}

=head2 has_pages

Predicate on L</pages>.

=head2 page_index($index, $type)

Returns the page from L</pages> of type C<$type> at position C<$index>.
If C<$type> is not supplied then L</default_type> will be used.
If page is not found then L</fallback_page> is returned instead.

=cut

sub page_index {
    my ( $self, $index, $type ) = @_;

    croak "index arg must be supplied to page_index" unless defined $index;
    $type = $self->default_type unless $type;

    if ( $self->has_pages && defined $self->pages->{$type}->[$index] ) {
        return $self->pages->{$type}->[$index];
    }
    return $self->fallback_page;
}

=head2 latest_page($type)

A convenience method equivalent to:

    page_index(0, $type)

=cut

sub latest_page {
    return shift->page_index( 0, shift );
}

=head2 previous_page

A convenience method equivalent to:

    page_index(1, $type)

=cut

sub previous_page {
    return shift->page_index( 1, shift );
}

=head2 types

Return all of the page types currently stored in history.

In array context returns an array of type names (keys of L</pages>)
and in scalar context returns the same as an array reference.

=cut

sub types {
    my $self = shift;
    wantarray ? keys %{ $self->pages } : [ keys %{ $self->pages } ];
}

1;
