package Data::AnyXfer::From::Iterator;

use v5.16.3;

use Moo::Role;
use MooX::Types::MooseLike::Base qw(:all);


use Carp;


=head1 NAME

Data::AnyXfer::From::Iterator - transfer from generic sources using the iterator interface

=head1 SYNOPSIS

    use Moo;
use MooX::Types::MooseLike::Base qw(:all);


    extends 'Data::AnyXfer';
    with 'Data::AnyXfer::From::Iterator';

    ...

    # Some kind of iterator
    has '+source_iterator' => ( default => $iterator; } );

    # or, another kind...
    has '+source_iterator' => ( default => $default_rs; } );


=head1 DESCRIPTION

The role configures L<Data::AnyXfer> to use an iterator object as a data source.

=head1 ATTRIBUTES

=head2 source_iterator

Any object implementing the common perl idiom for iteration.

The object must have a C<next> method, which returns one 'thing' (object, document, data structure)
at a time, and C<undef> once exhausted.

=cut

has source_iterator => (
    is       => 'ro',
    isa      => AnyOf[HasMethods['next'],CodeRef],
    required => 1,
    lazy     => 1,
    default  => sub {
        return $_[0]->can('get_iterator')
            ? $_[0]->get_iterator
            : undef;
    },
);

has _source_iterator => (
    is      => 'ro',
    isa     => CodeRef,
    lazy    => 1,
    default => sub {

        my $itr = $_[0]->source_iterator;

        # support both anonymous subs and objects as iterators
        # (wrap objects in a subref)
        return ref $itr ne 'CODE'
            ? sub { $itr->next }
            : $itr;
    },
);


around 'fetch_next' => sub {
    my ( $orig, $self ) = @_;

    $self->$orig or return;
    return scalar $self->_source_iterator->();
};


around 'transform' => sub {
    my ( $orig, $self, $res ) = @_;
    $self->$orig;
    return $res;
};




1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

