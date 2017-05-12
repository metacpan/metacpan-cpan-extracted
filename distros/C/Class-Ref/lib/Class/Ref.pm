package Class::Ref;

=head1 NAME

Class::Ref - Automatic OO wrapping of container references

=head1 SYNOPSIS

    $o = Class::Ref->new({ foo => { bar => 'Hello World!' } });
    $o->foo->bar;    # returns "Hello World!"
    $o->baz({ blah => 123 });
    $o->baz->blah;    # returns 123

    $o = Class::Ref->new({ foo => [{ bar => 'Hello Again!' }] });
    $o->foo->[0]->bar;    # returns "Hello Again!"

=head1 DESCRIPTION

L<Class::Ref> provides an OO wrapping layer around Hash and Array references.
Part of the magic is that it does this deeply and across array/hash boundaries.

=cut

use strict;
use warnings;

use Scalar::Util ();
use Carp ();

our $VERSION = '0.05';

=head1 OPTIONS

Some of the behavior of the encapsulation can be modified by the following options:

=over 4

=item B<$raw_access> (Default: 0)

    $o = Class::Ref->new({ foo => { bar => 1 } });
    {
        $Class::Ref::raw_access = 1;
        $o->foo;    # returns { bar => 1 }
    }

Should you ever need to work with the raw contents of the data structure,
setting C<$raw_access> with cause every member retrieval to just the referenced
data rather than a wrapped form of it.

The observant reader will note that this does not provide access to the base
data. In order to access that, you must dereference the object:

    $$o;    # returns { foo => { bar => 1 } } unblessed

See L<GUTS|/GUTS> for more information.

=cut

# bypass wrapping and access the raw data structure
our $raw_access = 0;

=item B<$allow_undef> (Default: 0)

    $o = Class::Ref->new({ foo => { bar => 1 } });
    {
        $Class::Ref::allow_undef = 1;
        $o->not_here;    # returns undef
    }
    $o->not_here;        # raises exception

By default, an excpetion will be raised if you try read from a HASH key that is
non-existent.

=back

=cut

# instead of raising an exception when accessing a non-existent value,
# return 'undef' instead
our $allow_undef = 0;

# disable defaults at your peril
our %nowrap = map { ($_ => 1) } (
    'Regexp', 'CODE', 'SCALAR', 'REF', 'LVALUE', 'VSTRING',
    'GLOB',   'IO',   'FORMAT'
);

my $bless = sub {
    my ($class, $ref) = @_;
    return $ref if $raw_access;
    my $type = ref $ref;
    return bless \$ref => "$class\::$type";
};

my $test = sub {
    return unless $_[0] and ref $_[0];
    return if Scalar::Util::blessed $_[0];
    return if $nowrap{ ref $_[0] };
    1;
};

my $assign = sub {
    my $v = shift;
    $$v = shift if @_;
    return $test->($$v) ? \__PACKAGE__->$bless($$v) : $v;
};

=head1 METHODS

There is only the constructor.

=over 4

=item B<new>

    $o = Class::Ref->new({...});
    $o = Class::Ref->new([...]);

Wrap the provided reference in OO getters and setters.

=back

=cut

sub new {
    my ($class, $ref) = @_;
    Carp::croak "not a valid reference for $class" unless $test->($ref);
    return $class->$bless($ref);
}

=head1 PHILOSOPHY

A lot of effort has been made to ensure that the only code that changes your
wrapped data is your code. There is no blessing of any of the data wrapped
by L<Class::Ref>.

With that being said, the goal has been to reduce the syntax need to access
values deep inside a HASH/ARRAY reference.

=head1 HASH Refs

Wrapping a HASH is a fairly straightforward process. All keys of the hash will
be made available as a method call.

There is a bit more here however. If, for example, you accessed the actual hash,
L<Class::Ref> will still encapsulate the return value if that value is a HASH or
an ARRAY:

    $o = Class::Ref->new({ foo => { bar => 1 } });
    $o->{foo}->bar;    # works

But all without modifying, blessing, or otherwise messing with the value. The
data referenced with C<$o> remains the same as when it originally wrapped.

=cut

package Class::Ref::HASH;

use strict;
use warnings;

use overload '%{}' => sub {
    return ${ $_[0] } if $raw_access;
    tie my %h, __PACKAGE__ . '::Tie', ${ $_[0] };
    \%h;
  },
  fallback => 1;

our $AUTOLOAD;

sub AUTOLOAD {
    # enable access to $h->{AUTOLOAD}
    my $name
      = defined $AUTOLOAD
      ? substr($AUTOLOAD, 1 + rindex $AUTOLOAD, ':')
      : 'AUTOLOAD';

    # undef so that we can detect if next call is for $h->{AUTOLOAD}
    # - needed cause $AUTOLOAD stays set to previous value until next call
    undef $AUTOLOAD;

    # NOTE must do this after AUTOLOAD check
    # - weird things happen when a wrapped HASH is an element of a wrapped
    #   ARRAY. tie'd ARRAYs have some lvalue magic on their FETCHed values.
    #   As a result, this call to shift triggers the tie object call to FETCH
    #   to ensure the lvalue is still valid.
    my $self = shift;

    # simulate a fetch for a non-existent key without autovivification
    unless (exists $$self->{$name} or @_) {
        return undef if $allow_undef or $name eq 'DESTROY';
        Carp::croak sprintf 'Can\'t locate object method "%s" via package "%s"',
          $name,
          ref $self;
    }

    # keep this broken up in case I decide to implement lvalues
    my $o = $assign->(\$$self->{$name}, @_);
    $$o;
}

package Class::Ref::HASH::Tie;

use strict;
use warnings;

# borrowed from Tie::StdHash (in Tie::Hash)

#<<< ready... steady... cross-eyed!!
sub TIEHASH  { bless [$_[1]], $_[0] }
sub STORE    { $_[0][0]->{ $_[1] } = $_[2] }
sub FETCH    { ${ $assign->(\$_[0][0]->{ $_[1] }) } }                    # magic
sub FIRSTKEY { my $a = scalar keys %{ $_[0][0] }; each %{ $_[0][0] } }
sub NEXTKEY  { each %{ $_[0][0] } }
sub EXISTS   { exists $_[0][0]->{ $_[1] } }
sub DELETE   { delete $_[0][0]->{ $_[1] } }
sub CLEAR    { %{ $_[0][0] } = () }
sub SCALAR   { scalar %{ $_[0][0] } }
#>>>

=head1 ARRAY Refs

Wrapping ARRAYs is much less straightforward. Using an C<AUTOLOAD> method
doesn't help because perl symbols cannot begin with a number. Makes it a
little difficult to do the following:

    $o->0;    # compile error

So for the purpose of this module, wrapped ARRAYs exactly like an ARRAY
reference:

    $o->[0];    # ahh, much better

The tricky part comes in wanting to make sure that values returned from such a
call would still be wrapped:

    $o->[0]->foo;    # $o = [{ foo => 'bar' }]

See L<GUTS|/GUTS> for more discussion on how this is done.

I am still debating if adding formal accessors moethods would be helpful in
this context.

=cut

package Class::Ref::ARRAY;

use strict;
use warnings;

# tie a proxy array around the real one
use overload '@{}' => sub {
    return ${ $_[0] } if $raw_access;
    tie my @a, __PACKAGE__ . '::Tie', ${ $_[0] };
    \@a;
  },
  fallback => 1;

sub index {
    my $self = shift;
    defined(my $i = shift) or Carp::croak "No index given";
    ${ $assign->(\$$self->[$i], @_) };
}

sub iterator {
    my $self = shift;
    my $raw  = $raw_access;
    my $i    = 0;
    return sub {
        # preserve access mode for the life of the iterator
        local $raw_access = $raw;
        ${ $assign->(\$$self->[$i++]) } ;
    };
}

our $AUTOLOAD;

sub AUTOLOAD {
    # enable access to $o->caller::AUTOLOAD
    my $name
      = defined $AUTOLOAD
      ? substr($AUTOLOAD, 1 + rindex $AUTOLOAD, ':')
      : 'AUTOLOAD';

    # undef so that we can detect if next call is for $o->caller::AUTOLOAD
    # - needed cause $AUTOLOAD stays set to previous value until next call
    undef $AUTOLOAD;

    return if $name eq 'DESTROY';

    # NOTE must do this after AUTOLOAD check
    # - weird things happen when a wrapped ARRAY is an element of a wrapped
    #   ARRAY. tie'd ARRAYs have some lvalue magic on their FETCHed values.
    #   As a result, this call to shift triggers the tie object call to FETCH
    #   to ensure the lvalue is still valid.
    my $self = shift;

    # honor @ISA if the caller is using it
    my $pkg = caller;
    my $idx = $pkg->can($name) ? $pkg->$name : undef;

    {
        no warnings 'numeric';
        defined $idx and $idx eq int($idx)
          or Carp::croak "'$name' is not a numeric constant in '$pkg'";
    }

    # simulate a fetch for a non-existent index without autovivification
    return undef unless exists $$self->[$idx] or @_;

    # keep this broken up in case I decide to implement lvalues
    my $o = $assign->(\$$self->[$idx], @_);
    $$o;
}

package Class::Ref::ARRAY::Tie;

use strict;
use warnings;

# borrowed from Tie::StdArray (in Tie::Array)

#<<< ready... steady... cross-eyed!!
sub TIEARRAY  { bless [$_[1]] => $_[0] }
sub FETCHSIZE { scalar @{ $_[0][0] } }
sub STORESIZE { $#{ $_[0][0] } = $_[1] - 1 }
sub STORE     { $_[0][0]->[$_[1]] = $_[2] }
sub FETCH     { ${ $assign->(\$_[0][0][$_[1]]) } }      # magic
sub CLEAR     { @{ $_[0][0] } = () }
sub POP       { pop @{ $_[0][0] } }
sub PUSH      { my $o = shift->[0]; push @$o, @_ }
sub SHIFT     { shift @{ $_[0][0] } }
sub UNSHIFT   { my $o = shift->[0]; unshift @$o, @_ }
sub EXISTS    { exists $_[0][0]->[$_[1]] }
sub DELETE    { delete $_[0][0]->[$_[1]] }
sub EXTEND    { $_[0]->STORESIZE($_[1]) }
sub SPLICE    { splice @{ shift->[0] }, shift, shift, @_ }
#>>>

=head1 GUTS

All objects created and returned by L<Class::Ref> are blessed REF types. This
is what protects the original reference from being blessed into an unwanted
package. The C<ref> type of the given value is what determines what package the
REF is blessed into. HASHes go into C<Class::Ref::HASH> and ARRAYs go into
C<Class::Ref::ARRAY>.

The use of the L<overload> pragma to overload the dereference operators allows
the REF object to still be accesed as HASH refs and ARRAY refs. When these REFs
are coerced into their approriate type, they are wrapped in a tie mechanism to
retain control over the return of member values.

The only way to fully bypass all of this is to manually dereference the REF
object:

    $o = Class::Ref->new({ foo => 1 });
    $$o->{foo};

=head1 CAVEATS

When dealing with a wrapped HASH, there is no way to access keys named C<isa>
and C<can>. They are core methods perl uses to interact with OO values.

Accessing HASH members with invalid perl symbols is possible with a little work:

    my $method = '0) key';
    $o->$method;    # access $o->{'0) key'};

=head1 SEE ALSO

I've always wanted to have this kind of functionality for hashes that really
needed a more formal interface. However, I found myself wanting more from the
existing modules out there in the wild. So I borrowed some the great ideas out
there and brewed my own implementation to have the level of flexibility that I
desire. And if it helps others, that's awesome too.

=over 4

=item * L<Class::Hash>

Probably the defacto module for creating accessors to a hash. However, it only
provides a single layer of encapsulation.

=item * L<Class::ConfigHash>

Provides a deeper implementaion but takes (avoids) steps to make the hash
read-only.

=item * L<Hash::AsObject>

Also provides a deep implemetation. Goes further to provide access to methods
like C<AUTOLOAD> and C<DESTROY>.

=back

=head1 AUTHOR

William Cox <mydimension@gmail.com>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut

1;
