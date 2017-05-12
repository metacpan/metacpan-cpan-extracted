package Data::Diver;
use strict;

require Exporter;
use vars qw( $VERSION @EXPORT_OK );
BEGIN {
    $VERSION= 1.01_01;
    @EXPORT_OK= qw( Dive DiveRef DiveVal DiveError DiveDie DiveClear );
    *import= \&Exporter::import;
    *isa= \&UNIVERSAL::isa;
}


# To figure out if an item supports being treated as a particular
# type of reference (hash ref, array ref, or scalar ref) we use:
#   eval { my $x= DEREF_EXPR; 1 }
# Note that we are careful to not put 'DEREF_EXPR' into an "lvalue
# context" (to prevent autovivification) and to also avoid trying to
# convert the value into a number or boolean or such.  The "; 1" is
# so that the eval always returns a true value unless something die()s.

# Using  'ARRAY' eq ref($ref)  is just a horrid alternative, as it would
# prevent these routines from being used on blessed data structures.

# Using  UNIVERSAL::isa($ref,'ARRAY')  is a better alternative, but it
# still fails for more advanced cases of overloading or pathological
# cases of blessing into very-poorly-named packages.  We use this for
# testing for CODE references, since  eval { $ref->() }  would actually
# run the code.


my @lastError;


sub _Error
{
    @lastError= @_[2,0,1];
    return;
}


sub DiveError
{
    return @lastError;
}


sub DiveClear
{
    @lastError= ();
}


sub DiveDie
{
    @_= Dive( @_ )   if  1 < @_;
    return  wantarray ? @_ : pop @_
        if  @_  ||  ! @lastError;
    my( $errDesc, $ref, $svKey )= @lastError;
    die "$errDesc using $$svKey on $ref (from Data::Diver).\n";
}


sub Dive
{
    return   if  ! @_;
    my $ref= shift @_;
    return $ref   if  ! $ref;
    while(  @_  ) {
        my $key= shift @_;
        if(  ! defined $key  ) {
            return  _Error( $ref, \$key, "undef() on non-scalar-ref" )
                if  ! eval { my $x= $$ref; 1 };
            $ref= $$ref;
        } elsif(    eval { my $x= $key->[0]; 1 }
                &&  isa( $ref, 'CODE' )
        ) {
            if(  @_  &&  ! defined $_[0]  ) {
                $ref= \ $ref->( @$key );
            } else {
                $ref= [ $ref->( @$key ) ];
            }
        } elsif(    $key =~ /^-?\d+$/
                &&  eval { my $x= $ref->[0]; 1 }
        ) {
            return  _Error( $ref, \$key, "Index out of range" )
                if  $key < -@$ref
                ||  $#$ref < $key;
            $ref= $ref->[$key];
        } elsif(  eval { exists $ref->{$key} }  ) {
            if(  eval { my $x= $$key; 1 }  ) {
                $ref= $ref->{$$key};
            } else {
                $ref= $ref->{$key};
            }
        } elsif(  eval { my $x= $ref->{$key}; 1 }  ) {
            return  _Error( $ref, \$key, "Key not present in hash" );
        } else {
            return  _Error( $ref, \$key, "Not a valid type of reference" );
        }
    }
    return $ref;
}


sub DiveVal :lvalue
{
    ${ DiveRef( @_ ) };
}


sub DiveRef
{
    return   if  ! @_;
    my $sv= \shift @_;
    return $$sv   if  ! $$sv;
    while(  @_  ) {
        my $key= shift @_;
        if(  ! defined $key  ) {
            $sv= \$$$sv;
        } elsif(    eval { my $x= $key->[0]; 1 }
                &&  isa( $$sv, 'CODE' )
        ) {
            if(  @_  &&  ! defined $_[0]  ) {
                $sv= \ $$sv->( @$key );
            } else {
                $sv= \[ $$sv->( @$key ) ];
            }
        } elsif(    eval { my $x= $$key; 1 }
                and     ! defined($$sv)
                    ||  eval { my $x= $$sv->{0}; 1 }
        ) {
            $sv= \$$sv->{$$key};
        } elsif(    $key =~ /^-?\d+$/
                and     ! defined($$sv)
                    ||  eval { my $x= $$sv->[0]; 1 }
        ) {
            $sv= \$$sv->[$key];
        } else {
            $sv= \$$sv->{$key};
        }
    }
    return $sv;
}


'Data::Diver';

__END__
# Cheap pod2pm (convert POD to PerlMonk's HTMLish)
my $p= 0;
my $c= 0;
while( <> ) {
    s/\r$//;
    if( /^$/ ) {
        $p= 1;
        next;
    }
    if( $p ) {
        if( /^ / ) {
            $p= 0;
            if( $c ) {
                print $/;
            } else {
                print "<code>\n";
                $c= 1;
            }
        } elsif( /^\S/ and $c || !/^=/ ) {
            $p= 0;
            if( $c ) {
                print "</code>\n";
                $c= 0;
            } else {
                print "<p>\n";
            }
        }
    }
    if( !$c ) {
        s#^=head(\d+)\s+(.*)# my $h= $1+2; "<h$h>$2</h$h>"#e;
        s#^=over.*#<ul>#;
        s#^=item\s+(.*)#<li>$1#;
        s#^=back.*#</ul>#;
        s/\[/&#91;/g;
        s/\]/&#93;/g;
        s#C<([^<>]+)>#<code>$1</code>#g;
        s#C<< (.+?) >>#<code>$1</code>#g;
        s#L</([^<>]+)>#<u>$1</u>#g;
    }
    print;
}
__END__

=head1 NAME

Data::Diver - Simple, ad-hoc access to elements of deeply nested structures

=head1 SUMMARY

Data::Diver provides the Dive() and DiveVal() functions for ad-hoc
access to elements of deeply nested data structures, and the
DiveRef(), DiveError(), DiveClear(), and DiveDie() support functions.

=head1 SYNOPSIS

    use Data::Diver qw( Dive DiveRef DiveError );

    my $root= {
        top => [
            {   first => 1 },
            {   second => {
                    key => [
                        0, 1, 2, {
                            three => {
                                exists => 'yes',
                            },
                        },
                    ],
                },
            },
        ],
    };

    # Sets $value to 'yes'
    # ( $root->{top}[1]{second}{key}[3]{three}{exists} ):
    my $value= Dive( $root, qw( top 1 second key 3 three exists ) );

    # Sets $value to undef() because "missing" doesn't exist:
    $value= Dive( $root, qw( top 1 second key 3 three missing ) );

    # Sets $value to undef() because
    # $root->{top}[1]{second}{key}[4] is off the end of the array:
    $value= Dive( $root, qw( top 1 second key 4 ... ) );

    # Sets $value to undef() because
    # $root->{top}[1]{second}{key}[-5] would be a fatal error:
    $value= Dive( $root, qw( top 1 second key -5 ... ) );

    # Sets $ref to \$root->{top}[9]{new}{sub} (which grows
    # @{ $root->{top} } and autovifies two anonymous hashes):
    my $ref= DiveRef( $root, qw( top 9 new sub ) );

    # die()s because "other" isn't a valid number:
    $ref= DiveRef( $root, qw( top other ... ) );

    # Does: $root->{num}{1}{2}= 3;
    # (Autovivifies hashes despite the numeric keys.)
    DiveVal( $root, \( qw( num 1 2 ) ) ) = 3;
    # Same thing:
    ${ DiveRef( $root, 'num', \1, \2 ) } = 3;

    # Retrieves above value, $value= 3:
    $value= DiveVal( $root, 'num', \1, \2 );
    # Same thing:
    $value= ${ DiveRef( $root,  \( qw( num 1 2 ) ) ) };

    # Tries to do $root->{top}{1} and dies
    # because $root->{top} is an array reference:
    DiveRef( $root, 'top', \1 );

    # To only autovivify at the last step:
    $ref= DiveRef(
        Dive( $root, qw( top 1 second key 3 three ) ),
        'missing' );
    if(  $ref  ) {
        $$ref= 'me too'
    } else {
        my( $nestedRef, $svKey, $errDesc )= DiveError();
        die "Couldn't dereference $nestedRef via $$svKey: $errDesc\n";
    }

=head1 DESCRIPTION

Note that Data::Diver does C<use strict;> and so will not use symbolic
references.  That is, a simple string can never be used as a reference.

=head2 Dive

    $value= Dive( $root, @ListOfKeys )

Dive() pulls out one value from a nested data structure.

Dive() absolutely refuses to autovivify anything.  If you give any 'key'
that would require autovivification [or would cause an error or warning],
then an empty list is returned.

How Dive() works is easiest to "explain" by looking at the examples
listed in the L</SYNOPSIS> section above.

$root should be a reference, usually a reference to hash or to an array.
@ListOfKeys should be a list of values to use as hash keys or array
indices [or a few other things] that will be used to deference deeper
and deeper into the data structure that $root refers to.

More details can be found under L</Simple 'key' values> and
L</Advanced 'key' values> further down.

If you want to distinguish between C<exists> and C<defined> for a hash
element, then you can distinguish between an empty list, C<( )>, being
returned and one C<undef>, C<( undef )>, being returned:

    my @exists= Dive( \%hashOfHashes, 'first', 'second' );
    if(  ! @exists  ) {
        warn "\$hashOfHashes{first}{second} does not exists.\n";
    } elsif(  ! defined $exists[0]  ) {
        warn "\$hashOfHashes{first}{second} exists but is undefined.\n";
    }

=head2 DiveVal

    $val= DiveVal( $root, @ListOfKeys );

    DiveVal( $root, @ListOfKeys )= $val;

DiveVal() is very much like Dive() except that it autovivifies if it
can, dies if it can't, and is an LValue subroutine.  So you can assign
to DiveVal() and the
dereferenced element will be modified.  You can also take a reference
to the call to DiveVal() or do anything else that you can do with a
regular scalar variable.

If $root is undefined, then DiveVal() immediately returns C<( undef )>
[without overwriting C<DiveError()>].  This is for the special case of
using C<DiveVal( Dive( ... ), ... )> because you want to only allow
partial autovivifying.

=head2 DiveRef

    $ref= DiveRef( $root, @ListOfKeys )

=head2 Simple 'key' values

Both Dive() and DiveRef() start by trying to dereference $root using
the first element of @ListOfKeys.  We refer to the resulting value
as C<$ref> and, if there are more elements in @ListOfKeys, then the
next step will be to try to dereference C<$ref> using that next 'key'
[producing a new value for C<$ref>].

To dereference an array reference, you must give a 'key' value that
is defined and matches C<m/^-?\d+$/>.  So, if you have more general
numeric values, you should use C<int()> to convert them to simple
integers.

To dereference a hash reference, you must give a 'key' value that
is C<defined> (or that is a reference to a scalar that will be used
as the key).

Note that all 'keys' that work for arrays also work for hashes.  If
you have a reference that is overloaded such that it can both act
as an array reference and as a hash reference [or, in the case of
DiveVal() and DiveRef(), if you have an undefined C<$ref> which can
be autovivified into either type of reference], then numeric-looking
key values cause an array dereference.  In the above cases, if you
want to do a hash dereference, then you need to pass in a reference
to the key.

Note that undefined keys are reserved for a special meaning
discussed in L</Advanced 'key' values> further down.  That section
discusses how to dereference other types of references [scalar
references and subroutine references] and exactly how the different
reference types and key values interact.

=head2 DiveError

    ( $errDesc, $ref, $svKey )= DiveError();

In the case of Dive() returning an empty list, a subsequent call to
DiveError() will return a description of why Dive() failed, the
specific reference that was trying to be dereferenced [not just the
top-level $root reference that was passed into Dive], and a reference
to the specific 'key'.

=head2 DiveClear

    DiveClear();

DiveClear() erases the record of any previous Dive() failures.

=head2 DiveDie

    DiveDie();

or

    $value= DiveDie( Dive(...) );

or

    $value= DiveDie( $root, @ListOfKeys );

This C<die>s with an error message based on the previously saved
Dive() failure reason.

If there is no previously saved failure reason or if one argument is
passed into DiveDie(), then it simply returns that argument [or an empty list].

If more than one argument is passed into DiveDie(), then those arguments
are passed to Dive() and then DiveDie() behaves as described above.
That is, C<DiveDie($root,@list)> acts the same as
C<DiveDie(Dive($root,@list))>.

=head2 Advanced 'key' values

For both Dive() and DiveRef(), each $key in @ListOfKeys can have the
following values:

=over

=item C<undef>

This means that you expect C<$ref> to be a reference to a scalar and
you want to dereference it.

For Dive(), if C<$ref> is undefined or is something that can't act
as a reference to a scalar, then the empty list is returned and
DiveError() can tell you where the problem was.

For DiveRef(), if C<$ref> is C<undef>, then it will be autovivified into
a reference to a scalar [that will start out undefined but may quickly
become autovivified due to the next element of @ListOfKeys].  If C<$ref>
is something that can't act as a scalar reference, then Perl will C<die>
to tell you why.

Otherwise the scalar ref is deferenced (C<$$ref>) and we continue on to
the next element of @ListOfKeys.

=item a reference to a scalar

This means that you expect C<$ref> to be a reference to a hash and
you want to dereference it using C<$$key> as the key.

This is most useful for when you want to use hash keys that match
C<m/^-?\d+$/>.  Note that C<\( listOfScalars )> will give you a list
of references to those scalars so you can often just add C<\(> and C<)>
around your list of keys if you only want to do hash dereferencing:

    DiveVal( $ref, \( 1, -5, qw< 00 01 >, list(), 1-9, 0xFF ) )= 9;

But, if your argument list of key values is build out of at least one
array and any other item, then it won't work since:

    \( @a, $b, 9 ) is ( \@a, \$b, \9 )

so you'll need to either wrap each array in additional parens or use C<map>:

    \( (@a), $b, (@c), 9 )

    map \$_, @a, $b, @c, 9

=item C<$key =~ m/^-?\d+$/>

This means that you might expect C<$ref> to be a reference to an array.

For Dive(), if C<$ref> can act as a reference to an array and
$key is in range ( -@$ref <= $key and $key <= $#$ref ), then
C<< $ref= $ref->[$key]; >> is run [and this can't fail nor autovivify
since we've already checked how big that array was].

If $ref can't be used as an array reference, then $ref might be used
as a hash reference instead, as described further down.

If $ref is undefined or $key is out of range ($key < -@$ref or
$#$ref < $key), then Dive() returns an empty list.

For DiveRef(), if C<$ref> is undefined, then it is autovivified into
a reference to anonymous array.  If C<$ref> can act as a reference
to an array, then C<< $ref= $ref->[$key] >> is attempted.  If $key is
larger than $#$ref, then @$ref will grow.  If $key is less than
-@$ref, then Perl will C<die>.

If C<$ref> cannot act as a reference to an array, then $ref might be
used as a reference to a hash as described further down.

=item a reference to an array

If $key can be used as a reference to an array, then it means that
you might expect C<$ref> to be a reference to a subroutine.

If C<UNIVERSAL::isa( $ref, 'CODE' )> is true, then C<< $ref->( @$key ) >>
is attempted.

If $key isn't the last value in @ListOfKeys and the next value is
undefined, then &$ref is called in a scalar context and $ref is set
to refer to the scalar value returned.

Otherwise, &$ref is called in a list context and $ref is set to refer
to an anonymous array containing the value(s) returned.

=item any (defined) string

This means that you might expect C<$ref> to be a reference to a hash.

For Dive(), if C<$ref> can act as a reference to a hash and
C<<exists $ref->{$key} >> is true, then C<< $ref= $ref->{$key}; >> is run
[and this can't fail nor autovivify].

Otherwise, Dive() returns an empty list and DiveError() can tell you
where the problem was.

For DiveRef(), C<< $ref= $ref->{$key} >> is simply attempted.  This may
autovivify a hash entry or even a new hash.  It may also C<die>, for
example, if $ref can't be used as a hash reference.

=back

Note that the order of the above items is significant.  It represents
the order in which cases are tested.  So an undefined $key will only
be for derefencing a scalar reference and a numeric key will prefer
to treat a reference as an array reference.

=head1 AUTHOR

Tye McQueen, http://www.perlmonks.org/?node=tye

=head1 SEE ALSO

Once More With Feeling -- Joss++

=cut
