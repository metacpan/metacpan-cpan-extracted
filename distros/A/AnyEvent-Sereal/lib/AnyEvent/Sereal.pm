use strict;
use warnings;
package AnyEvent::Sereal;
{
  $AnyEvent::Sereal::VERSION = '0.004';
}

use AnyEvent ();
use AnyEvent::Handle;

our $SERIALIZED_MAX_SIZE = 1_000_000; # bytes

{
    package # hide from pause
        AnyEvent::Handle;

    use Sereal::Encoder 0.09 ();
    use Sereal::Decoder 0.09 ();

    # push_write(sereal => $data, [$options])
    register_write_type(
        sereal => sub
        {
	    my $self = shift;
	    my $data = shift;

	    # When options are passed, we will create a new encoder instance
	    undef $self->{_sereal_encoder} if @_;

	    pack("w/a*",
		 ($self->{_sereal_encoder} ||= Sereal::Encoder::->new(@_))
		 ->encode($data));
        });

    # push_read(sereal => [$sereal_options], $cb->($hdl, $data))
    register_read_type(
        sereal => sub
        {
	    my $self = shift;
	    my $cb = shift;

	    # When options are passed, we will create a new decoder instance
	    undef $self->{_sereal_decoder} if @_;

	    $self->{_sereal_decoder} ||= Sereal::Decoder::->new(@_);

            return sub
            {
                # when we can use 5.10 we can use ".", but for 5.8 we
                # use the re-pack method
                defined(my $len = eval { no warnings 'uninitialized';
                                         unpack "w", $_[0]{rbuf} })
                    or return;

                if ($len > $AnyEvent::Sereal::SERIALIZED_MAX_SIZE)
                {
                    $_[0]->_error(Errno::E2BIG);
                    return;
                }

                my $format = length pack "w", $len;

                if ($format + $len <= length $_[0]{rbuf})
                {
                    my $data = substr($_[0]{rbuf}, $format, $len);
                    substr($_[0]{rbuf}, 0, $format + $len, '');

                    my $dec;
                    eval { $dec = $_[0]{_sereal_decoder}->decode($data); 1 }
                        or return $_[0]->_error(Errno::EBADMSG);

                    $cb->($_[0], $dec);
                }
                else
                {
                    # remove prefix
                    substr($_[0]{rbuf}, 0, $format, '');

                    # read remaining chunk
                    $_[0]->unshift_read(
                        chunk => $len, sub
                        {
                            my $dec;
                            eval { $dec = $_[0]{_sereal_decoder}->decode($_[1]);
				   1 } or return $_[0]->_error(Errno::EBADMSG);

                            $cb->($_[0], $dec);
                        });
                }

                return 1;
            };
        });
}

1;
__END__

=encoding iso-8859-1

=head1 NAME

AnyEvent::Sereal - Sereal stream serializer/deserializer for AnyEvent

=head1 SYNOPSIS

    use AnyEvent::Sereal;
    use AnyEvent::Handle;

    my $hdl = AnyEvent::Handle->new(
        # settings...
    );
    $hdl->push_write(sereal => [ 1, 2, 3 ]);
    $hdl->push_read(sereal => sub {
        my($hdl, $data) = @_;
          # $data is [ 1, 2, 3 ]
    });

    # Can pass L<Sereal::Encoder> options to C<push_write>
    $hdl->push_write(sereal => 'a' x 1_000, { snappy => 1 });

    # And pass L<Sereal::Decoder> options to C<push_read>
    $hdl->push_read(sereal => { refuse_snappy => 1 }, sub { ... });


=head1 DESCRIPTION

L<AnyEvent::Sereal> is Sereal serializer/deserializer for L<AnyEvent>.

The maximum size of serialized (and possibly compressed) data is
specified by the variable
C<$AnyEvent::Sereal::SERIALIZED_MAX_SIZE>. It defaults to 1_000_000
bytes. In case received data seems to contain more than this number of
bytes, an error C<Errno::E2BIG> is given to the error handler.

The serializer options has to be passed for the first C<push_write>
call only, otherwise a new serializer will be instanciated internally
and a performance penalty will occur.

The same applies for the deserializer options and the first
C<push_read> or C<unshift_read> calls.

See Implementation below for details.


=head1 IMPLEMENTATION

To be fast, the serializer stores a L<Sereal::Encoder> instance in the
C<_sereal_encoder> attribute of the L<AnyEvent::Handle> instance.

Each time the serializer receives options via C<push_write>, a new
L<Sereal::Encoder> object is instanciated and the previous one is
destroyed. When C<push_write> is called without an options hash, the
existing L<Sereal::Encoder> instance is re-used. To reset options, by
instanciating a new L<Sereal::Encoder> instance, simply pass them to
{}.

    $hdl->push_write(sereal => [ 1, 2, 3 ]);
    # Here $hdl->{_sereal_encoder} is a Sereal::Encoder instance
    $hdl->push_write(sereal => 42);
    # Here $hdl->{_sereal_encoder} is still the same
    $hdl->push_write(sereal => { a => 1 }, { snappy => 1 });
    # Here $hdl->{_sereal_encoder} contains a *new* Sereal::Encoder instance
    # with snappy option enabled
    $hdl->push_write(sereal => 42);
    # Here $hdl->{_sereal_encoder} is still the same, so with snappy
    # option enabled
    $hdl->push_write(sereal => 42, {});
    # Here $hdl->{_sereal_encoder} contains a *new* Sereal::Encoder instance,
    # without any option
    ...

The same applies for the deserializer:

Still to be fast, a L<Sereal::Decoder> instance is stored in the
C<_sereal_decoder> attribute of the L<AnyEvent::Handle> instance.

Each time the deserializer receives options via C<push_read> or
C<unshift_read>, a new L<Sereal::Decoder> object is instanciated and
the previous one is destroyed. When C<push_read> or C<unshift_read>
are called without options, the existing L<Sereal::Decoder> instance
is re-used. To reset options, by instanciating a new
L<Sereal::Decoder> instance, simply pass them to {}.

    $hdl->push_read(sereal => \&cb1);
    # When cb1 is called, $hdl->{_sereal_decoder} contains a
    # Sereal::Decoder instance
    $hdl->push_read(sereal => \&cb2);
    # When cb2 is called, $hdl->{_sereal_decoder} is still the same
    $hdl->push_read(sereal => { refuse_snappy => 1 }, \&cb3);
    # When cb3 is called, $hdl->{_sereal_decoder} contains a *new*
    # Sereal::Decoder instance with refuse_snappy option enabled
    $hdl->push_read(sereal => \&cb4);
    # When cb4 is called, $hdl->{_sereal_decoder} is still the same,
    # so with refuse_snappy option enabled
    $hdl->push_read(sereal => {}, \&cb5);
    # When cb5 is called, $hdl->{_sereal_decoder} contains a *new*
    # Sereal::Decoder instance, without any option
    ...

Note that the Sereal::{De,En}coder instances are re-instanciated each
time an options hash is passed, even if the options do not change.


=head1 SEE ALSO

L<AnyEvent::Handle> and storable filter.

L<Sereal::Encoder> and L<Sereal::Decoder>.


=head1 AUTHOR

Maxime SoulE<eacute>, E<lt>btik-cpan@scoubidou.comE<gt>


=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ijenko.

http://www.ijenko.com

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
