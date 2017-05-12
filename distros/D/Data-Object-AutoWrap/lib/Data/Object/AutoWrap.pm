package Data::Object::AutoWrap;

use warnings;
use strict;
use Carp qw( confess croak );

# use Data::Object::AutoWrap::Hash;

$Carp::CarpLevel = 1;

=head1 NAME

Data::Object::AutoWrap - Autogenerate accessors for R/O object data

=head1 VERSION

This document describes Data::Object::AutoWrap version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    package MyData;

    # Our data is in $self->{data}
    use Data::Object::AutoWrap qw( data );

    sub new {
        my ( $class, $data ) = @_;
        bless { data => $data }, $class;
    }

    # ... and then later, elsewhere ...

    my $d = MyData->new( { foo => 1, bar => [ 1, 2, 3 ] } );
    print $d->foo;         # prints "1"
    print $d->bar( 2 );    # prints "3"

=head1 DESCRIPTION

This is an experimental module designed to simplify the implementation
of read-only objects with value semantics.

Objects created using C<Data::Objects::AutoWrap> are bound to a Perl
data structure. The automatically provide read only accessor methods for
the elements of that structure.

=head2 Declaring an autowrapped class

As in the example above an autowrapped class is created by adding the line

    use Data::Object::AutoWrap qw( fieldname );

We assume (for now) that the class is hash based and that this hash
contains a key called C<fieldname>. The corresponding value is the data
structure that will be exposed as the module's interface. The 'root'
level of this data structure must itself be a hash - we need the key
names so we can generate corresponding methods. Below the root of the
data structure any type may be used.

If the C<fieldname> is omitted the entire contents of the object's hash
will be exposed.

=head2 Accessors

For each key in the value hash a corresponding read-only accessor is
made available. In order for these accessors to be callable the key
names must also be valid Perl method names - it's OK to have a key
called '*(&!*(&£' but it's rather tricky to call the
corresponding accessor.

The generated accessors are AUTOLOADed. As a result the bound data
structure may be a different shape for each instance of the containing
class: the accessors are virtual - they don't actually exist in the
module's symbol table.

In the following examples we'll assume that we have a
C<Data::Object::AutoWrap> based class called C<MyData> that gets the
data structure to bind to as the argument to its constructor. The code
fragment in the synopsis is a suitable implementation of such a class.

=head3 Scalar Accessors

Any scalars in the hash get an accessor that takes no arguments and
returns the corresponding value:

    my $sc = MyData->new({ flimp_count => 1 });
    my $fc = $sc->flimp_count; # gets 1

An error is raised if arguments are passed to the accessor.

=head3 Hash Accessors

Any nested hashes in the data structure get accessors that return
recursively wrapped hashes. That means that this will work:

    my $hc = MyData->new(
        {
            person => {
                name => 'Andy',
                job  => 'Perl baiter',
            },
        }
    );

    print $hc->person->job;    # prints "Perl baiter"

=head3 Array accessors

The accessor for array values accepts an optional subscript:

    my $ac = MyData->new( { list => [ 12, 27, 36, 43, ] } );
    my $third = $ac->list( 3 );    # gets 36

Called in a list context with no arguments the accessor for an array
returns that array:

    my @list = $ac->list;   # gets the whole list

=head3 Accessors for other types

Anything that's not an array or a hash gets the scalar accessor - so
things like globs will also be accessible.

=head3 Accessor parameters

Array and hash accessors can accept more than one parameter. For example
if you have an array of arrays you can subscript into it like this:

    my $gc = MyData->new(
        {
            grid => [
                [ 0,  1,  2,  3  ],
                [ 4,  5,  6,  7  ],
                [ 8,  9,  10, 11 ],
                [ 12, 13, 14, 15 ],
            ],
        }
    );

    my $dot = $gc->grid( 3, 4 );    # gets 11

In general any parameters specify a path through the data structure:

    my $hc = MyData->new(
        {
            deep => {
                smash      => 'pumpkins',
                eviscerate => [ 'a', 'b', 'c' ],
                lament => { fine => 'camels' }
            }
        }
    );

    print $hc->deep( 'smash' );                 # 'pumpkins'
    print $hc->deep( 'eviscerate', 1 );         # 'b'
    print $hc->deep( 'lament',     'fine' );    # 'camels'
    print $hc->deep->lament->fine;              # also 'camels'
    print $hc->deep( 'lament' )->fine;          # 'camels' again
    print $hc->deep->lament( 'fine' );          # more 'camels'

=head1 CAVEATS

This is experimental code. Don't be using it in, for example, a life
support system, ATM or space shuttle.

=head2 AUTOLOAD

C<Data::Object::AutoWrap> injects an C<AUTOLOAD> handler into the
package from which it is used. It doesn't care about any existing
C<AUTOLOAD> or any that might be provided by a superclass. Given that
it's designed for the implementation of simple, value like objects this
shouldn't be a problem - but you've been warned.

=head2 Performance

It's slow. Slow as mollasses in an igloo. Last time I checked the
autogenerated accessors are something like fifteen times slower than the
simplest hand wrought accessor.

This can probably be improved.

=cut

sub _make_value_handler {
  my ( $class, $value ) = @_;
  if ( 'HASH' eq ref $value ) {
    # Delay loading so we're compiled before wrapper
    # attempts to use us.
    eval 'require Data::Object::AutoWrap::Hash';
    die $@ if $@;
    return sub {
      my $self = shift;
      if ( @_ ) {
        my $key = shift;
        return $class->_make_value_handler( $value->{$key} )
         ->( $self, @_ );
      }
      else {
        return Data::Object::AutoWrap::Hash->new( $value );
      }
    };
  }
  elsif ( 'ARRAY' eq ref $value ) {
    return sub {
      my $self = shift;
      # Special case for ARRAY refs because we can't turn an array
      # ref into an object with an accessor; array items are
      # always accessed by subscripting into the parent object.
      return map {
        'ARRAY' eq ref $_
         ? $_
         : $class->_make_value_handler( $_ )->( $self )
       } @$value
       if wantarray && @_ == 0;
      croak "Array accessor needs an index in scalar context"
       unless @_;
      my $idx = shift;
      return $class->_make_value_handler( $value->[$idx] )
       ->( $self, @_ );
    };
  }
  else {
    return sub {
      my $self = shift;
      croak "Scalar accessor takes no argument"
       if @_;
      return $value;
    };
  }
}

sub import {
  my $class = shift;
  my $pkg   = caller;

  my $get_data;
  if ( @_ ) {
    my $field = shift;
    # TODO: Allow a closure here so objects can be promises
    $get_data = sub { shift->{$field} };
  }
  else {
    $get_data = sub { shift };
  }

  no strict 'refs';
  *{"${pkg}::can"} = sub {
    my ( $self, $method ) = @_;
    my $data = $get_data->( $self );
    return
     exists $data->{$method}
     ? $class->_make_value_handler( $data->{$method} )
     : $pkg->SUPER::can( $method );
  };

  our $AUTOLOAD;
  *{"${pkg}::AUTOLOAD"} = sub {
    my $self = shift;
    ( my $field = $AUTOLOAD ) =~ s/.*://;
    return if $field eq 'DESTROY';
    if ( my $code = $self->can( $field ) ) {
      return $self->$code( @_ );
    }

    confess "Undefined subroutine &$AUTOLOAD called";
  };
}

1;

__END__

=head1 CONFIGURATION AND ENVIRONMENT
  
Data::Object::AutoWrap requires no configuration files or environment
variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

Yes, probably.

Please report any bugs or feature requests to
C<bug-data-object-autowrap@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy.armstrong@messagesystems.com> >>

=head1 LICENCE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

Copyright (c) 2008, Message Systems, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or
without modification, are permitted provided that the following
conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in
      the documentation and/or other materials provided with the
      distribution.
    * Neither the name Message Systems, Inc. nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
# vim:ts=4:sw=4:et:ft=perl:
