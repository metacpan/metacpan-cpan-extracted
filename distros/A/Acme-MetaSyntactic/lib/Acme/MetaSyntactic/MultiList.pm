package Acme::MetaSyntactic::MultiList;
use strict;
use Acme::MetaSyntactic ();    # do not export metaname and friends
use Acme::MetaSyntactic::RemoteList;
use List::Util qw( shuffle );
use Carp;

our @ISA = qw( Acme::MetaSyntactic::RemoteList );
our $VERSION = '1.000';

sub init {
    my ($self, $data) = @_;
    my $class = caller(0);

    $data ||= Acme::MetaSyntactic->load_data($class);
    no strict 'refs';

    # note: variables mentioned twice to avoid a warning

    my $sep = ${"$class\::Separator"} = ${"$class\::Separator"} ||= '/';
    my $tail = qr/$sep?[^$sep]*$/;

    # compute all categories
    my @categories = ( [ $data->{names}, '' ] );
    while ( my ( $h, $k ) = @{ shift @categories or []} ) {
        if ( ref $h eq 'HASH' ) {
            push @categories,
                map { [ $h->{$_}, ( $k ? "$k$sep$_" : $_ ) ] } keys %$h;
        }
        else {    # leaf
            my @items = split /\s+/, $h;
            while ($k) {
                push @{ ${"$class\::MultiList"}{$k} }, @items;
                $k =~ s!$tail!!;
            }
        }
    }

    ${"$class\::Default"} = ${"$class\::Default"} = $data->{default} || ':all';
    ${"$class\::Theme"} = ${"$class\::Theme"} = ( split /::/, $class )[-1];

    *{"$class\::import"} = sub {
        my $callpkg = caller(0);
        my $theme   = ${"$class\::Theme"};
        my $meta    = $class->new;
        *{"$callpkg\::meta$theme"} = sub { $meta->name(@_) };
    };

    ${"$class\::meta"} = ${"$class\::meta"} = $class->new();
}

sub name {
    my ( $self, $count ) = @_;
    my $class = ref $self;

    if ( !$class ) {    # called as a class method!
        $class = $self;
        no strict 'refs';
        $self = ${"$class\::meta"};
    }

    if ( defined $count && $count == 0 ) {
        no strict 'refs';
        return wantarray
            ? shuffle @{ $self->{base} }
            : scalar @{ $self->{base} };
    }

    $count ||= 1;
    my $list = $self->{cache};
    if ( @{ $self->{base} } ) {
        push @$list, shuffle @{ $self->{base} } while @$list < $count;
    }
    splice( @$list, 0, $count );
}

sub new {
    my $class = shift;

    no strict 'refs';
    my $self = bless { @_, cache => [] }, $class;

    # compute some defaults
    $self->{category} ||= ${"$class\::Default"};

    # fall back to last resort (FIXME should we carp()?)
    $self->{category} = ${"$class\::Default"}
        if $self->{category} ne ':all'
        && !exists ${"$class\::MultiList"}{ $self->{category} };

    $self->_compute_base();
    return $self;
}

sub _compute_base {
    my ($self) = @_;
    my $class = ref $self;

    # compute the base list for this category
    no strict 'refs';
    my %seen;
    $self->{base} = [
        grep { !$seen{$_}++ }
            map { @{ ${"$class\::MultiList"}{$_} } }
            $self->{category} eq ':all'
        ? ( keys %{"$class\::MultiList"} )
        : ( $self->{category} )
    ];
    return;
}

sub category { $_[0]->{category} }

sub categories {
    my $class = shift;
    $class = ref $class if ref $class;

    no strict 'refs';
    return keys %{"$class\::MultiList"};
}

sub has_category {
    my ($class, $category) = @_;
    $class = ref $class if ref $class;

    no strict 'refs';
    return exists ${"$class\::MultiList"}{$category};
}

sub theme {
    my $class = ref $_[0] || $_[0];
    no strict 'refs';
    return ${"$class\::Theme"};
}

1;

__END__

=head1 NAME

Acme::MetaSyntactic::MultiList - Base class for themes with multiple lists

=head1 SYNOPSIS

    package Acme::MetaSyntactic::digits;
    use Acme::MetaSyntactic::MultiList;
    our @ISA = ( Acme::MetaSyntactic::MultiList );
    __PACKAGE__->init();
    1;

    =head1 NAME
    
    Acme::MetaSyntactic::digits - The numbers theme
    
    =head1 DESCRIPTION
    
    You can count on this module. Almost.

    =cut
    
    __DATA__
    # default
    :all
    # names primes even
    two
    # names primes odd
    three five seven
    # names composites even
    four six eight
    # names composites odd
    nine
    # names other
    zero one

=head1 DESCRIPTION

C<Acme::MetaSyntactic::MultiList> is the base class for all themes
that are meant to return a random excerpt from a predefined list
I<divided in categories>.

The category is selected at construction time from:

=over 4

=item 1.

the given C<category> parameter,

=item 2.

the default category for the selected theme.

=back

Categories and sub-categories are separated by a C</> character.

=head1 METHODS

Acme::MetaSyntactic::MultiList offers several methods, so that the subclasses
are easy to write (see full example in L<SYNOPSIS>):

=over 4

=item new( category => $category )

The constructor of a single instance. An instance will not repeat items
until the list is exhausted.

    $meta = Acme::MetaSyntactic::digits->new( category => 'primes' );
    $meta = Acme::MetaSyntactic::digits->new( category => 'primes/odd' );

The special category C<:all> will use all the items in all categories.

    $meta = Acme::MetaSyntactic::digits->new( category => ':all' );

If no C<category> parameter is given, C<Acme::MetaSyntactic::MultiList>
will use the class default. If the class doesn't define a default,
then C<:all> is used.

=item init()

init() must be called when the subclass is loaded, so as to read the
__DATA__ section and fully initialise it.

=item name( $count )

Return $count names (default: C<1>).

Using C<0> will return the whole list in list context, and the size of the
list in scalar context (according to the C<category> parameter passed to the
constructor).

=item category()

Return the selected category for this instance.

=item categories()

Return the categories supported by the theme (except C<:all>).

=item has_category( $category )

Return a boolean value indicating if the theme contains the given category.

=item theme()

Return the theme name.

=back

=head1 AUTHOR

Philippe 'BooK' Bruhat, C<< <book@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Philippe 'BooK' Bruhat, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

