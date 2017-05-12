package Data::TxnBuffer;
use strict;
use warnings;
use parent 'Data::TxnBuffer::Base';

our $VERSION = '0.05';

our $BACKEND;
unless ($ENV{PERL_ONLY}) {
    eval {
        require XSLoader;
        XSLoader::load(__PACKAGE__, $VERSION);
        $BACKEND = 'XS';
    };
}

unless (__PACKAGE__->can('new')) {
    eval q{
        use parent 'Data::TxnBuffer::PP';
        $BACKEND = 'PP';
    };
}

1;

__END__

=head1 NAME

Data::TxnBuffer - binary read/write buffer supporting transaction read

=head1 SYNOPSIS

    use Data::TxnBuffer;
    
    # create buffer
    my $buf = Data::TxnBuffer->new;
    # or create buffer from some data
    my $buf = Data::TxnBuffer->new($data);
    
    # read some data
    use Try::Tiny;
    try {
        my $u32   = $buf->read_u32; # read unsigned int
        my $bytes = $buf->read(10); # read 10 bytes
    
        $buf->spin; # all data received. clear these data from buffer.
    } catch {
        $buf->reset; # reset read cursor. try again later
    };
    
    # or more easy way. this way automatically call spin or reset method like above.
    try {
        $buf->txn_read(sub {
            my $u32   = $buf->read_u32; # read unsigned int
            my $bytes = $buf->read(10); # read 10 bytes
        });
    } catch {
        # try again later
    };
    
    
    # write some data to filehandle or buffer
    $buf->write_u32(100);
    $buf->write("Hello World");
    
    # got written data
    my $data = $buf->data;
    
    # clear all data from buffer
    $buf->clear;

=head1 DESCRIPTION

Data::TxnBuffer provides some binary buffering functions, such as basic read/write function for buffer, more convenience r/w methods (read_u32/write_u32, etc), and transaction read method.

=head1 XS implementation

This module use XS implementation by default, but fallback to ::PP implementation in pure perl environment or C<PERL_ONLY> environment variable is set.

XS implementation is several times faster than PP implementation.

=head1 CLASS METHOD

=head2 my $buf = Data::TxnBuffer->new($data);

Create a Data::TxnBuffer object.
If you passed some C<$data>, create buffer from the data.

=head1 ACCESSORS

=head2 $buf->cursor

Return buffer read cursor point. This value increase by C<read> methods automatically and reset to 0 by C<reset> method.

=head2 $buf->data

Return buffer's whole data.

=head2 $buf->length

Return buffer's data length. (bytes)

=head1 BASIC METHODS

=head2 $buf->read($bytes)

Read C<$bytes> data from buffer and return the data.
If there's not enough data in buffer, throw exception.

=head2 $buf->write($data)

Write C<$data> into buffer.

=head2 $buf->spin

    $buf->write('foo');
    $buf->write('bar');
    
    my $foo = $buf->read(3); # foo
    $buf->spin; # clear only foo
    
    $buf->data; # == 'bar'

Clear *only* read data from buffer. 
When read cursor == 0, this method does nothing.

And also, this method returns cleared data. For example C<< $buf->spin >> in above example returns 'foo';

=head2 $buf->reset

Reset read cursor to 0.

=head2 $buf->clear

Clear all data from buffer.

=head1 TRANSACTION READ

By combination of C<read>, C<spin>, and C<reset> methods, you can read some data like transaction:

    use Try::Tiny;
    
    try {
        my $foo = $buf->read(3);
        my $bar = $buf->read(3);
        $buf->spin; # clear read data 'foobar'
    } catch {
        $buf->reset;
    };

C<read> method throw exception if there's not enough data in buffer, catch this exception and reset read cursor, then you can read first data again after some seconds.


=head2 $buf->txn_read($code)

Shortcut method for above transaction read example. 

    use Try::Tiny;
    
    try {
        $buf->txn_read(sub {
            my $foo = $buf->read(3);
            my $bar = $buf->read(3);
        });
        # spin automatically called
    } catch {
        # reset automatically called
        # try later
    };

This method automatically call C<spin> method and returns C<spin>'ed data if all data successfully read, or throw exception not enough data in buffer and call C<reset> method automatically.
This method is very useful for typical transaction read functions.

=head1 READ/WRITE HELPER METHODS

This module provides not only basic C<read($bytes)> method but also useful methods to read integer values easily.

=head2 $buf->read_u32

=head2 $buf->read_u24

=head2 $buf->read_u16

=head2 $buf->read_u8

Read unsigned integers. C<uXX> is bit length. (ex: u32 is 32bit unsigned int)


=head2 $buf->read_i32

=head2 $buf->read_i24

=head2 $buf->read_i16

=head2 $buf->read_i8

Read singed integers.


=head2 $buf->write_u32

=head2 $buf->write_u24

=head2 $buf->write_u16

=head2 $buf->write_u8

Write unsigned integers


=head2 $buf->write_i32

=head2 $buf->write_i24

=head2 $buf->write_i16

=head2 $buf->write_i8

Write signed integers

(In XS implementation, this is just an alias to write_uXX)


=head2 $buf->read_n32

=head2 $buf->read_n24

=head2 $buf->read_n16

=head2 $buf->write_n32

=head2 $buf->write_n24

=head2 $buf->write_n16

Read/Write unsigned integers in network byte order.


=head2 $buf->read_float

=head2 $buf->read_double

=head2 $buf->write_float

=head2 $buf->write_double

Read/Write floating points (float = 32bit single precision float, double = 64bit double precision float)

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011 by KAYAC Inc.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
