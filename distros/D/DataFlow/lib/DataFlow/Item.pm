package DataFlow::Item;

use strict;
use warnings;

# ABSTRACT: A wrapper around the regular data processed by DataFlow

our $VERSION = '1.121830';    # VERSION

use Moose;
use Moose::Autobox;
use MooseX::Attribute::Chained;

use namespace::autoclean;

has 'metadata' => (
    'is'      => 'ro',
    'isa'     => 'HashRef[Any]',
    'handles' => { metakeys => sub { shift->metadata->keys }, },
    'lazy'    => 1,
    'default' => sub { {} },
);

has 'channels' => (
    'is'      => 'rw',
    'isa'     => 'HashRef[Any]',
    'handles' => { channel_list => sub { shift->channels->keys }, },
    'lazy'    => 1,
    'default' => sub { {} },
    'traits'  => ['Chained'],
);

sub get_metadata {
    my ( $self, $key ) = @_;
    return $self->metadata->{$key};
}

sub set_metadata {
    my ( $self, $key, $data ) = @_;
    $self->metadata->{$key} = $data;
    return $self;
}

sub get_data {
    my ( $self, $channel ) = @_;
    return $self->channels->{$channel};
}

sub set_data {
    my ( $self, $channel, $data ) = @_;
    $self->channels->{$channel} = $data;
    return $self;
}

sub itemize {    ## no critic
    return __PACKAGE__->new()->set_data( $_[1], $_[2] );
}

sub clone {
    my $self = shift;
    my @c    = %{ $self->channels };
    return __PACKAGE__->new( metadata => $self->metadata )->channels( {@c} );
}

sub narrow {
    my ( $self, $channel ) = @_;
    return __PACKAGE__->new( metadata => $self->metadata, )
      ->set_data( $channel, $self->get_data($channel) );
}

__PACKAGE__->meta->make_immutable;

1;



=pod

=encoding utf-8

=head1 NAME

DataFlow::Item - A wrapper around the regular data processed by DataFlow

=head1 VERSION

version 1.121830

=head1 SYNOPSIS

    use DataFlow::Item;
	my $item = DataFlow::Item->itemize( 'channel_name', 42 );
	say $item->get_data( 'channel_name' );

	$item->set_metadata( 'somekey', q{some meta value} );
	say item->get_metadata( 'somekey' );

=head1 DESCRIPTION

Wraps data and metadata for processing through DataFlow.

=head1 ATTRIBUTES

=head2 metadata

A hash reference containing metada for the DataFlow.

=head2 channels

A hash reference containing data for each 'channel'.

=head1 METHODS

=head2 metakeys

A convenience method that returns the list of the keys to the metadata hash
reference.

=head2 channel_list

A convenience method that returns the list of the keys to the channels hash
reference.

=head2 get_metadata

Returns a metadata value, identified by its key.

=head2 set_metadata

Sets a metadata value, identified by its key.

=head2 get_data

Returns a channel value, identified by the channel name.

=head2 set_data

Sets a channel value, identified by the channel name.

=head2 itemize

This is a B<class> method that creates a new C<DataFlow::Item> with a certain
data stored in a specific channel. As a class method, it must be called like
this:

	my $item = DataFlow::Item->itemize( 'channel1', { my => data } );

=head2 clone

Makes a copy of the C<DataFlow::Item> object. Note that the whole metadata
contents (hash reference, really) is passed by reference to the new instance,
while the contents of the channels are copied one by one into the new object.

=head2 narrow

Makes a copy of the C<DataFlow::Item> object narrowed to one single channel.
In other words, it is like clone, but the C<channels> will contain B<only>
the channel specified as a parameter.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<DataFlow|DataFlow>

=back

=head1 AUTHOR

Alexei Znamensky <russoz@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Alexei Znamensky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut


__END__


