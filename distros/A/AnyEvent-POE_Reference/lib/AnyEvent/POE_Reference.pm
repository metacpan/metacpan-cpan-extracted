package AnyEvent::POE_Reference;

use 5.008;
use strict;
use warnings;

use AnyEvent (); BEGIN { AnyEvent::common_sense }
use AnyEvent::Handle;

use Carp;

our $VERSION = '0.11';

sub FREEZE ()	{ 0 }
sub THAW ()	{ 1 }

my %SERIALIZERS;
my $ZLIB;

our $SERIALIZED_MAX_SIZE = 1_000_000; # bytes

sub new
{
    my $class = shift;

    @_ > 2 and croak "usage: ${\__PACKAGE__}->new([SERIALIZER[, COMPRESSION]])";

    my($serializer, $compress) = @_;

    $serializer ||= 'Storable';

    $compress = $compress ? '/z' : '';

    my $self = $SERIALIZERS{"$serializer$compress"};

    unless (defined $self)
    {
	$self = bless [], $class;
	eval
	{
	    (my $serializer_path = $serializer) =~ s,::,/,g;
	    require "$serializer_path.pm";

	    my $freeze = $serializer->can('nfreeze')
		|| $serializer->can('freeze')
		|| croak("${\__PACKAGE__} can't find n?freeze method "
			 . "in $serializer module");

	    my $thaw = $serializer->can('thaw')
		|| croak("${\__PACKAGE__} can't find thaw method "
			 . "in $serializer module");

	    if ($compress)
	    {
		eval { require Compress::Zlib; }
		or croak "${\__PACKAGE__} can't load Compress::Zlib";

		$self->[FREEZE] = sub
		{
		    Compress::Zlib::compress($freeze->($_[0]));
		};

		$self->[THAW] = sub
		{
		    $thaw->(Compress::Zlib::uncompress($_[0]));
		};
	    }
	    else
	    {
		$self->[FREEZE] = $freeze;
		$self->[THAW] = $thaw;
	    }

	    1;
	}
	or do
	{
	    croak "${\__PACKAGE__} can't load serializer $serializer\n";
	};

	$SERIALIZERS{"$serializer$compress"} = $self;
    }

    return $self;
}

{
    package # hide from pause
        AnyEvent::Handle;

    # poe_reference => $data, [$serializer[, $compress]]
    register_write_type(
	poe_reference => sub
	{
	    # (SELF, DATA)
	    # (SELF, SERIALIZER, DATA)
	    # (SELF, SERIALIZER, COMPRESS, DATA)
	    my $self = shift;
	    my $data = pop;

	    # (SERIALIZER)
	    # (SERIALIZER, COMPRESS)
	    my($serializer, $compress) = @_;

	    unless (ref $serializer)
	    {
		$serializer = AnyEvent::POE_Reference->new(
		    $serializer, $compress);
	    }

	    $data = $serializer->
		[AnyEvent::POE_Reference::FREEZE]->($data);
	    return length($data) . "\0" . $data;
	});

    # poe_reference => [$serializer[, $compress]], $cb->($hdl, $data)
    register_read_type(
	poe_reference => sub
	{
	    my($self, $cb, $serializer, $compress) = @_;

	    my $rbuf = \$self->{rbuf};

	    return sub
	    {
		if ($$rbuf =~ /^(\d+)(\D)/)
		{
		    if ($1 > $AnyEvent::POE_Reference::SERIALIZED_MAX_SIZE)
		    {
			$self->_error(Errno::E2BIG);
			return 0;
		    }

		    # \0 not found
		    if ($2 ne "\0")
		    {
			$self->_error(Errno::EBADMSG);
			return 0;
		    }

		    return 0 if length($$rbuf) < length($1) + 1 + $1;

		    my $buf = substr($$rbuf, 0, length($1) + 1 + $1, '');

		    unless (ref $serializer)
		    {
			$serializer = AnyEvent::POE_Reference->new(
				$serializer, $compress);
		    }

		    # FreezeThaw returns in list context...
		    if (my($ref) = eval {
			$serializer->[AnyEvent::POE_Reference::THAW]->(
			    substr($buf, length($1) + 1)) })
		    {
			$cb->($_[0], $ref);

			return 1;
		    }
		    else
		    {
			$self->_error(Errno::EBADMSG);
		    }
		}
		# Not a number...
		elsif ($$rbuf =~ /^\D/)
		{
		    $self->_error(Errno::EBADMSG);
		}
		# Too much numbers...
		elsif (length($$rbuf)
		       > length($AnyEvent::POE_Reference::SERIALIZED_MAX_SIZE))
		{
		    $self->_error(Errno::EBADMSG);
		}

		return 0;
	    };
	});
}

1;
__END__
=head1 NAME

AnyEvent::POE_Reference - AnyEvent talking to POE::Filter::Reference

=head1 SYNOPSIS

  use AnyEvent::POE_Reference;

  ...

  $handle->push_write(poe_reference => [ 1, 2, 3 ]);
  $handle->push_read(poe_reference => sub
		     {
		         my($handle, $ref_data) = @_;
			 ...
		     });
  ...

  # Change the default serializer to YAML
  $handle->push_write(poe_reference => 'YAML', sub { a => 123 });
  $handle->push_read(poe_reference => 'YAML', sub { ... });

  ...

  # Enable compression
  $handle->push_write(poe_reference => 'YAML', 1 => sub { a => 123 });
  $handle->push_read(poe_reference => 'YAML', 1 => sub { ... });

  ...

  # Create a serializer instance to use later
  my $serializer = AnyEvent::POE_Reference->new('YAML', 1);

  $handle->push_write(poe_reference => $serializer, $any_perl_ref);
  $handle->push_read(poe_reference => $serializer,
		       sub { my($hdl, $ref) = @_; ... });


=head1 DESCRIPTION

L<AnyEvent::POE_Reference> allows an L<AnyEvent> program to talk to a
L<POE> one using serialized references as L<POE> formats them.

L<POE> can use any serializer/deserializer by specifying it when
building the L<POE::ReadWrite::Wheel>. It is encapsulated into a
L<POE::Filter::Reference>. It defaults to use L<Storable>.

In L<POE> a L<POE::Wheel::ReadWrite> can receive a L<POE::Filter>
object. In our case it is more precisely a L<POE::Filter::Reference>
instance. Like this:

    my $wheel = POE::Wheel::ReadWrite->new(
	Handle	   => $socket,
	InputEvent => "client_input",
	ErrorEvent => "client_error",
	Filter	   => POE::Filter::Reference->new('YAML', 1),
	);

Here C<'YAML'> and 1 are optional (by default C<'Storable'> and 0 are
used). The first argument is the I<serializer> and the second specify
whether the serialization has to be compressed or not.

In the AnyEvent counterpart, we will have:

    $handle->push_write(poe_reference => 'YAML', 1, $any_perl_ref);
    $handle->push_read(poe_reference => 'YAML', 1,
		       sub { my($hdl, $ref) = @_; ... });

As in L<POE>, here C<'YAML'> and 1 are optional with the same defaults
(C<'Storable'> and 0).

    $handle->push_write(poe_reference => 'YAML', $any_perl_ref);
    $handle->push_read(poe_reference => 'YAML',
		       sub { my($hdl, $ref) = @_; ... });

Will use L<YAML> as serializer but with compression disabled.

    $handle->push_write(poe_reference => $any_perl_ref);
    $handle->push_read(poe_reference => sub { my($hdl, $ref) = @_; ...});

Will use the default serializer L<Storable> with compression disabled.

To activate compression with the default serializer, just pass
C<undef> as the serializer as in:

    $handle->push_write(poe_reference => undef, 1, $any_perl_ref);
    $handle->push_read(poe_reference => undef, 1,
		       sub { my($hdl, $ref) = @_; ... });

To avoid passing the same serializer with its compression flag at each
call, you can create a special serializer object at the beginning of
your code, and use it each time you need to call C<push_write> or
C<push_read>:

    my $serializer = AnyEvent::POE_Reference->new('YAML', 1);
    ...
    $handle->push_write(poe_reference => $serializer, $any_perl_ref);
    $handle->push_read(poe_reference => $serializer,
		       sub { my($hdl, $ref) = @_; ... });

It is useless to create several serializer instances with the B<same>
serializer B<and> compression flag. Indeed, the constructor will
return the same instance because there is no need to have many
identical objects...

Note that, as in the L<POE::Filter::Reference> constructor, the
serializer and the compression flag are optional.

If the serializer can not be found, L<AnyEvent::POE_Reference> croaks.

The maximum size of serialized (and possibly compressed) data is
specified by the variable
C<$AnyEvent::POE_Reference::SERIALIZED_MAX_SIZE>. It defaults to
1_000_000 bytes. In case received data seems to contain more than this
number of bytes, an error C<Errno::E2BIG> is given to the error
handler.

In all other error cases (like wrong serializer for example), an error
C<Errno::EBADMSG> is given to the error handler.


=head1 SERIALIZER FORMAT

The format used is very simple. The length of the serialized data in
human form followed by a C<NUL> byte then by the data. Like:

    12\0xxxxxxxxxxxx

See L<POE::Filter::Reference> for more details.


=head1 DEVELOPMENT

=head2 Repository

    http://github.com/maxatome/p5-AnyEvent-POE_Reference


=head1 SEE ALSO

Test F<t/POE.t> gives an example of an L<AnyEvent> client interracting
with a L<POE> server.

L<AnyEvent>, L<AnyEvent::Handle>, L<POE>, L<POE::Filter::Reference>.

=head1 AUTHOR

Maxime Soule, E<lt>btik-cpan@scoubidou.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 by Ijenko.

http://www.ijenko.com

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
