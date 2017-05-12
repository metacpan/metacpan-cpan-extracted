package Alter;
use 5.008000;
use strict; use warnings;

our $VERSION = '0.07';

our %EXPORT_TAGS = (
    all => [ qw(
        alter ego
        STORABLE_freeze STORABLE_attach STORABLE_thaw
        Dumper
    ) ],
);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

# for re-exportation
*STORABLE_freeze = \ &Alter::Storable::STORABLE_freeze;
*STORABLE_thaw = \ &Alter::Storable::STORABLE_thaw;
*STORABLE_attach = \ &Alter::Storable::STORABLE_attach;
*Dumper= \ &Alter::Dumper::Dumper;

eval {
    die "Pure Perl requested" if $ENV{ PERL_ALTER_NO_XS}; # fake load failure
    no warnings 'redefine';
    require XSLoader;
    XSLoader::load('Alter', $VERSION);
    *is_xs = sub { 1 };
};
if ( $@ ) {
    # Fallback to pure perl implementation
    no warnings 'redefine';
    require Alter::AlterXS_in_perl if $@;
    *is_xs = sub { 0 };
}

### Import/Export

# Types supported for autovivification
use Scalar::Util qw( reftype);
my %ref_tab = (
    NOAUTO => 'NOAUTO',
    map +( reftype( $_) => $_) => (
        \ do { my $o }, # scalar
        [],             # array
        {},             # hash
    ),
);

sub import {
    require Exporter;
    my $class = shift;
    my $client = caller;
    my $storable = my $dumper = my $destroy = 1;
    for ( 1 .. @_ ) {
        my $arg = shift;
        $storable = 0, next if $arg eq '-storable';
        $dumper = 0, next if $arg eq '-dumper';
        $destroy = 0, next if $arg eq '-destroy';
        $storable = 0 if $arg =~ /^STORABLE_/;
        $dumper = 0 if $arg eq 'Dumper';
        my $type = ref( $arg) ? $arg : $ref_tab{ $arg};
        if ( $type && ref( $type) && $ref_tab{ reftype $type} ) {
            _set_class_type( $client, $type);
            next;
        } elsif ( $type and $type eq 'NOAUTO' ) {
            _set_class_type( $client, undef); # delete entry
            next;
        }
        push @_, $arg; # hand down to Exporter::import()
    }
    _add_base( $client, 'Alter::Storable')   if $storable;
    _add_base( $client, 'Alter::Dumper')     if $dumper;
    _add_base( $client, 'Alter::Destructor') if !is_xs() && $destroy;
    unshift @_, $class;
    goto Exporter->can( 'import') || die "Exporter can't import???";
}

sub _add_base {
    my ( $client, $base) = @_;
    return if $client->isa( $base);
    no strict 'refs';
    push @{ join '::' => $client, 'ISA' }, $base;
}

### Serialization support: ->image and ->reify

# Key to use for object body in image (different from any class name)
use constant BODY => '(body)';

# create a hash image of an object that contains the body and
# corona data
sub image {
    my $obj = shift;
    +{
        BODY() => $obj,
        %{ corona( $obj) }, # shallow copy
    };
}

# recreate the original object from an image.  When called as a
# class method, take the object from the "(body)" entry in image
# (the class is ignored).  Called as an object method, re-model
# the given object (whose data is lost) to match the image.  In
# this case, the types of the given object and the "(body)" entry
# must match, or else...  Also, the ref type must be supported
# ("CODE" isn't).
sub reify {
    my $obj = shift;
    my $im = shift;
    if ( ref $obj ) {
        my $orig = delete $im->{ BODY()};
        _transfer_content( $orig, $obj);
    } else {
        $obj = delete $im->{ BODY()};
    }
    %{ corona( $obj)} = %$im;
    $obj;
}

my %trans_tab = (
    SCALAR => sub { ${ $_[ 1] } = ${ $_[ 0] } },
    ARRAY  => sub { @{ $_[ 1] } = @{ $_[ 0] } },
    HASH   => sub { %{ $_[ 1] } = %{ $_[ 0] } },
    GLOB   => sub { *{ $_[ 1] } = *{ $_[ 0] } },
);

use Carp;
sub _transfer_content {
    my ( $from, $to) = @_;
    my $type = reftype $from;
    croak "Incompatible types in STORABLE_thaw" unless
        $type eq reftype $to;
    croak "Unsupported type '$type' in STORABLE_thaw" unless
        my $trans = $trans_tab{ $type};
    $trans->( $_[ 0], $_[ 1]); # may change $_[ 1] ($to)
    $_[ 1];
}

### Data::Dumper support (for viewing only)
{
    package Alter::Dumper;

    # return a viewable string containing the object information
    sub Dumper {
        my $obj = shift;
        require Data::Dumper;
        local $Data::Dumper::Purity = 1;
        Data::Dumper::Dumper( $obj->Alter::image);
    }
}

### Storable support
{
    package Alter::Storable;

    my $running; # indicate if the call is (indirectly) from ourselves
    sub STORABLE_freeze {
        my ( $obj, $cloning) = @_;
        return if $cloning;
        return unless $running = !$running; # return if $running was true
        # $running now true, preventing recursion
        Storable::freeze( $obj->Alter::image);
    }

    # recognized (and preferred) by Storable 2.15+, (Perl v5.8.8)
    # ignored by earlier versions
    sub STORABLE_attach {
        my ( $class, $cloning, $ser) = @_;
        ++ our $attaching; # used by t/*.t, not needed for anything else
        $class->Alter::reify( Storable::thaw( $ser));
    }

    # recognized by all versions of Storable
    # incidentally, the code is equivalent to STORABLE_attach
    sub STORABLE_thaw {
        my ( $obj, $cloning, $ser) = @_;
        ++ our $thawing; # used by t/*.t, not needed for anything else
        $obj->Alter::reify( Storable::thaw( $ser));
    }
}

1;
__END__

=head1 NAME

Alter - Alter Ego Objects

=head2 Synopsis

  package MyClass;
  use Alter ego => {}; # Alter ego of type hash

  # Put data in it
  my $obj = \ do { my $o };
  ego( $obj)->{a} = 1;
  ego( $obj)->{b} = 2;

  # Retrieve it again
  print ego( $obj)->{ b}, "\n"; # prints 2

  package OtherClass;
  defined( ego $obj) or die; # dies, OtherClass hasn't set an alter ego

  # Direct access to the corona of alter egos
  my $crown = Alter::corona $obj;

=head2 Functions

=head3 Basic Functions

The functions described here accept a first argument named $obj.
Despite the name, C<$obj> can be any reference, it doesn't I<have>
to be blessed (though it usually will be).  It is a fatal error
if it is not a reference or if the reference points to a read-only value.

=over

=item C<ego($obj)>

Retrieves the class-specific I<alter ego> assigned to C<$obj> by
C<alter()> or by L<autovivification|/Autovivification> if that is
enabled.  If neither is the case, an undefined value is returned.
The class is the package into which the call to C<ego()> is compiled.

=item C<alter($obj, $val)>

Assigns C<$val> to the reference C<$obj> as an I<alter ego> for the caller's
class.  The class is the package into which the call to C<alter> is compiled.
Returns C<$obj> (I<not> the value assigned).

=item C<Alter::corona( $obj)>

Direct access to the I<corona> of I<alter ego>'s of C<$obj>.  The
corona is a hash keyed by class name in which the alter ego's of
an object are stored.  Unlike C<alter()> and C<ego()>, this function is
not caller-sensitive. Returns a reference to the corona hash, which
is created if necessary.  This function is not exported, if needed
it must be called fully qualified.

=item C<Alter::is_xs>

Returns a true value if the XS implementation of C<Alter> is active,
false if the pure Perl fallback is in place.

=back

=head3 Autovivification

You can set one of the types C<SCALAR>, C<ARRAY>, C<HASH> or C<GLOB> for
autovivification of the alter ego.  This is done by specifying the
type in a C<use> statement, as in

    package MyClass;
    use Alter 'ARRAY';

If the C<ego()> function is later called from C<MyClass> before an alter
ego has been specified using C<alter()>, a new I<array reference> will
be created and returned.  Autovivification happens only once
per class and object.  (You would have to delete the class entry from
the object's corona to make it happen again.)

The type specification can also be a referece of the appropriate
type, so C<[]> can be used for C<"ARRAY"> and C<{}> for C<"HASH">
(globrefs and scalar refs can also be used, but are less attractive).

Type specification can be combined with function imports.  Thus

    package MyClass;
    use Alter ego => {};

imports the C<ego()> function and specifies a hash tape for
autovivification.  With autovivification you will usually
not need to import the C<alter> function at all.

Specifying C<"NOAUTO"> in place of a type specification switches
autovivification off for the current class.  This is also the
default.

=head3 Serialization Support

Serialization is supported for human inspection in C<Data::Dumper>
style and for disk storage and cloning in C<Storable> style.

For C<Data::Dumper> support C<Alter> provides the class C<Alter::Dumper>
for use as a base class, which contains the single method C<Dumper>.
C<Dumper> returns a string that represents a hash in C<Data::Dumper>
format.  The hash shows all I<alter ego>s that have been created for
the object, keyed by class.  An additional key "(body)" (which can't
be a class name) holds the actual body of the object.  Formatting-
and other options of C<Data::Dumper> will change the appearance of
the dump string, with the exception of C<$Data::Dumper::Purity>,
which will always be 1.  C<Dumper> can also be imported from
C<Alter> directly.

Note that C<eval()>-ing a dump string will I<not> restore the
object, but rather create a hash as described.  Re-creation of
an object is only available through C<Storable>.

For C<Storable> support the class C<Alter::Storable> is provided
with the methods C<STORABLE_freeze>, C<STORABLE_thaw> and
C<STORABLE_attach>.  The three functions are also exported by C<Alter>
Their interaction with C<Storable> is described there.

Inheriting these methods allows C<Storable>'s own functions C<freeze()>
and C<thaw()> to save and restore an object's I<alter ego>s along with
the actual object body.  Other C<Storable> functions, like C<store>,
C<nstore>, C<retrieve>, etc. also become Alter-aware. There is one
exception.  C<Storable::dclone> cannot be used on C<Alter>-based
objects.  To clone an C<Alter>-based object,
C<Storable::thaw(Storable::freeze($obj)> must be called explicitly.

Per default, both C<Alter::Dumper> and C<Alter::Storable> are made
base classes of the current class (if necessary) by C<use Alter>.
If the function C<Dumper> is imported, or if C<-dumper> is specified,
C<Alter::Dumper> is not made a base class.  If any of the functions
C<STORABLE_freeze>, C<STORABLE_thaw> or C<STORABLE_attach> is imported,
or if C<-storable> is specified, C<Alter::Storable> is not made a base class.

=head3 Fallback Perl Implementation

C<Alter> is properly an XS module and a suitable C compiler is
required to build it.  If compilation isn't possible, the XS part 
is replaced with a I<pure Perl> implementation C<Alter::AlterXS_in_perl>.
That happens automatically at load time when loading the XS part
fails.  The boolean function C<Alter::is_xs> tells (in the obvious
way) which implementation is active.  If, for some reason, you want
to run the Perl fallback when the XS version is available, set
the environment variable C<PERL_ALTER_NO_XS> to a true value before
C<Alter> is loaded.

This fallback is not a full replacement for the XS implementation.
Besides being markedly slower, it lacks key features in that it is
I<not> automatically garbage-collected and I<not> thread-safe.
Instead, C<Alter::AlterXS_in_perl> provides a C<CLONE> method
for thread safety and a universal destructor C<Alter::Destructor::DESTROY>
for garbage collection.  A class that uses the pure Perl implementation
of C<Alter> will obtain this destructor through inheritance (unless
C<-destroy> is specified with the C<use> statement).  So at the surface
thread-safety and garbage-collection are retained.  However, if
you want to add your own destructor to a class, you must make sure
that both (all) destructors are called as needed.  Perl only calls the
first one it meets on the C<@ISA> tree and that's it.

Otherwise the fallback implementation works like the original.  If
compilation has problems, it should allow you to run test cases to
help decide if it's worth trying.  To make sure that production code
doesn't inadvertently run with the Perl implementation

  Alter::is_xs or die "XS implementation of Alter required";

can be used.

=head2 Exports

None by default, C<alter()> and C<ego()> upon request.
Further available are C<STORABLE_freeze>, C<STORABLE_thaw> and
C<STORABLE_attach> as well as C<Dumper>.  C<:all> imports all these
functions.

=head2 Environment

The environment variable C<PERL_ALTER_NO_XS> is inspected once at
load time to decide whether to load the XS version of C<Alter> or
the pure Perl fallback.  At run time it has no effect.

=head2 Description

The C<Alter> module is meant to facilitate the creation of classes
that support I<black-box inheritance>, which is to say that an
C<Alter> based class can be a parent class for I<any other> class,
whether itself C<Alter> based or not.  Inside-out classes also have
that property.  C<Alter> is thus an alternative to the I<inside-out>
technique of class construction.  In some respects, C<Alter> objects
are easier to handle.

Alter objects support the same data model as traditional Perl
objects.  To each class, an Alter object presents an arbitrary
reference, the object's I<alter ego>. The type of reference and
how it is used are the entirely the class's business.  In particular,
the common practice of using a hash whose keys represent object
fields still applies, only each class sees its individual hash.

C<Alter> based objects are garbage-collected and thread-safe without
additional measures.

C<Alter> also supports C<Data::Dumper> and C<Storable> in
a generic way, so that C<Alter> based objects can be easily be viewed
and made persistent (within the limitations of the respective modules).

C<Alter> works by giving every object a class-specific I<alter ego>,
which can be any scalar, for its (the classe's) specific needs for
data storage.  The alter ego is set by the C<alter()> function (or
by autovivification), usually once per class and object at initialization
time.  It is retrieved by the C<ego()> function in terms of which 
a class will define its accessors.

That works by magically (in the technical sense of C<PERL_MAGIC_ext>)
assigning a hash keyed by classname, the I<corona>, to every object
that takes part in the game.  The corona holds the individual alter
ego's for each class.  It is created when needed and stays with
an object for its lifetime.  It is subject to garbage collection
when the object goes out of scope.  Normally the corona is invisible
to the user, but the C<Alter::corona()> function (not exported)
allows direct access if needed.

=head2 Example

The example first shows how a class C<Name> is built from two
classes C<First> and C<Last> which implement the first and last
names separately.  C<First> treats its objects as hashes whereas
C<Last> uses them as arrays.  Nevertheless, the code in C<Name> that
joins the two classes via subclassing is straightforward.

The second part of the example shows that C<Alter> classes actually
support black-box inheritance.  Here, we use an object of class
C<IO::File> as the "carrier" object.  This must be a globref to work.
This object can be initialized to the class C<Name>, which in part
sees it as a hash, in another part as an array.  Methods of both
classes now work on the object.

    #!/usr/local/bin/perl
    use strict; use warnings; $| = 1;

    # Show that class Name works
    my $prof = Name->new( qw( Albert Einstein));
    print $prof->fname, "\n";
    print $prof->lname, "\n";
    print $prof->name, "\n";


    # Share an object with a foreign class
    {
        package Named::Handle;
        use base 'IO::File';
        push our @ISA, qw( Name);

        sub new {
            my $class = shift;
            my ( $file, $first, $last) = @_;
            $class->IO::File::new( $file)->init( $first, $last);
        }

        sub init {
            my $nh = shift;
            $nh->Name::init( @_);
        }
    }

    my $nh = Named::Handle->new( '/dev/null', 'Bit', 'Bucket');
    print "okay, at eof\n" if $nh->eof; # IO::File methods work
    print $nh->name, "\n";      # ...as do Name methods

    exit;

    #######################################################################

    {
        package First;
        use Alter qw( alter ego);

        sub new {
            my $class = shift;
            bless( \ my $o, $class)->init( @_);
        }

        sub init {
            my $f = shift;
            alter $f, { name => shift };
            $f;
        }

        sub fname {
            my $h = ego shift;
            @_ ? $h->{ name} = shift : $h->{ name};
        }
    }

    {
        package Last;
        use Alter qw( alter ego);

        sub new {
            my $class = shift;
            bless( \ my $o, $class)->init( @_);
        }

        sub init {
            my $l = shift;
            alter $l, [ shift];
            $l;
        }

        sub lname {
            my $l = ego( shift);
            @_ ? $l->[ 0] = shift : $l->[ 0];
        }
    }

    {
        package Name;
        use base 'First';
        use base 'Last';

        sub init {
            my $n = shift;
            $n->First::init( shift);
            $n->Last::init( shift);
        }

        sub name {
            my $n = shift;
            join ' ' => $n->fname, $n->lname;
        }
    }

    __END__

=head2 Thanks

Thanks to Abigail who invented the inside-out technique, showhing I<what>
the problem is with Perl inheritance and I<how> it could be overcome
with just a little stroke of genius.

Thanks also to Jerry Hedden for making me aware of the possibilities
of C<ext> magic on which this implementation of C<Alter> is built.

=head1 Author

Anno Siegel, E<lt>anno4000@zrz.tu-berlin.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Anno Siegel

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut
