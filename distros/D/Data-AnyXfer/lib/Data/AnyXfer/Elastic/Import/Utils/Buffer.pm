package Data::AnyXfer::Elastic::Import::Utils::Buffer;

use v5.16.3;

use Carp;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);


use namespace::autoclean;

=head1 NAME

 Data::AnyXfer::Elastic::Import::Utils::Buffer - Buffer class

=head1 DESCRIPTION

 This module provides methods for buffer action

=head1 SYNOPSIS

    use Data::AnyXfer::Elastic::Import::Utils::Buffer;

    my $buffer = Data::AnyXfer::Elastic::Import::Utils::Buffer->new(
        callback => $sub );

    # push data into buffer
    $buffer->push(@data);

    # called automatically when more than c<max_size> items have
    # been added to the buffer using c<push>
    $buffer->flush();

=head1 ATTRIBUTES

=head2 C<max_size>

 size of the buffer, default is 200

=cut

has max_size => (
    is      => 'rw',
    isa     => Int,
    default => 200,
);

=head2 C<callback>

    # Callback must follow the call signature
    $callback->(@data_entries);

 callback function which will process the data once the buffer
 has been filled

=cut

has callback => (
    is       => 'ro',
    isa      => CodeRef,
    required => 1,
);

has _buffer => (
    is      => 'rw',
    isa     => ArrayRef,
    default => sub { [] },
);

=head2 C<push>

  $buffer->push(@data);

  pushes data to buffer

=cut

sub push {
    my ( $self, @data ) = @_;
    my $size = push @{ $self->_buffer }, @data;

    if ( $size >= $self->max_size ) {
        return $self->flush();
    }
    return 1;
}

=head2 C<flush>

  $buffer->flush();

  passes data to callback and clears buffer

=cut

sub flush {
    my $self = $_[0];

    eval {
        $self->callback->( @{ $self->_buffer } );
        $self->_buffer( [] );
    };
    croak "Error flushing buffer. $@" if $@;

    return 1;

}



1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

