package Data::Reuse;

# runtime settings we need
use 5.008001;
use strict;
use warnings;

# set up version info
our $VERSION= '0.10';

# we need this otherwise nothing works
use Data::Alias qw( alias copy );

# other modules we need
use Carp         qw( croak );
use Digest::MD5  qw( md5 );
use Encode       qw( encode_utf8 );
use Scalar::Util qw( reftype );

=for Explanation:
     Since Data::Alias uses Exporter, we might as well do that also.  Otherwise
     we'd probably hack an import method ourselves

=cut

use base 'Exporter';
our @EXPORT=      qw();
our @EXPORT_OK=   qw( alias fixate forget reuse spread );
our %EXPORT_TAGS= ( all => \@EXPORT_OK );

# ID prefixes
my $U= "\1U\1";
my $S= "\1S\1";
my $A= "\1A\1";
my $H= "\1H\1";

# set up data store with predefined ro undef value
my %reuse;
forget();

# mark constants as read only
Internals::SvREADONLY $_, 1 foreach ( $U, $S, $A, $H );

# recursion level
my $level= 0;

# references being handled
my %handling;

# satisfy -require-
1;

#---------------------------------------------------------------------------
# reuse
#
# Make given values, store them in the constant hash and return them
#
#  IN: 1..N values to be folded into constants
# OUT: 1..N same as input, but read-only and folded

sub reuse (@); # needed because of recursion
sub reuse (@) {

    # being called with return values
    my $not_void= defined wantarray;

    # we're one level deeper
    $level++;

    # there are values specified that haven't been folded yet or are undef
    if ( alias my @special= grep { !defined or !exists $reuse{$_} } @_ ) {

        # values specified that haven't been folded yet
        if ( alias my @new= grep { defined() } @special ) {
            foreach (@new) { # natural aliasing

                # reference being handled, make sure it is known
                if ( exists $handling{$_} ) {
                     alias $reuse{$_} ||= $_;
                }

                # handle references
                elsif ( my $reftype= reftype $_ ) {
                    $handling{$_}= $level;
                    my $id;

                    # aliasing everything in here
                    alias {

                        # all elements of list
                        if ( $reftype eq 'ARRAY' ) {
                            $id= _list_id( $_ );

                            # not seen, recurse
                            if ( !exists $reuse{$id} ) {
                                my @list= @{$_};
                                (@list)= reuse @list;

=for Explanation:
     We need to use copy semantics, because aliasing semantics segfaults.
     Or as Matthijs put it:
=
 Hah, het is een combinatie van:
 1. bug in perl m.b.t. \-prototypes (\[$%@] in dit geval)
 2. de refgen operator van Data::Alias (de impliciete \)
 3. het in void context zijn van dit blok
 4. totaal gebrek aan argument-checking in Internals::SvREADONLY
 het prototype maakt van:
=
   Internals::SvREADONLY my @array, 1
=
 zoiets als:
=
   &Internals::SvREADONLY(\my @array, 1);
=
 Echter hij markeert de \ zonder enige context.  Dit hoort normaal alleen
 de gebeuren voor de laatste expressie in een block, en betekent "evalueer
 dit in de context van deze block".  In dit geval is het omliggende block
 de top-level code, en die is altijd in void context.  Perl evalueert dus
 de \ in void context.
=
 Hier ben je echter in perl zelf geen last van, omdat perl's ingebouwde
 refgen op (\) alleen maar test op list-context, en gaat er van uit dat
 het anders scalar context is.  D::A's refgen onderscheid alle drie de
 contexts, en produceert dus niets omdat het in void context is.
=
 Hierdoor wordt de call dus:
=
   &Internals::SvREADONLY(1);
=
 En zoals ik al zei, Internals::SvREADONLY heeft geen argument validatie
 en probeert dus fijn op adres 0x00000001 te lezen.. SEGV

=cut

                                # mark readonly, see above
                                copy Internals::SvREADONLY @list, 1;

                                # recursive structures may be replaced
                                $id= _list_id( $_ );
                            }
                        }

                        # all values of hash
                        elsif ( $reftype eq 'HASH' ) {
                            $id= _hash_id( $_ );

                            # not seen, recurse, set result if first
                            if ( !$reuse{$id} ) {
                                my %hash= %{$_};
                                ( @hash{ keys %hash } )= reuse values %hash;

                                # mark readonly, see above
                                copy Internals::SvREADONLY %hash, 1;

                                # recursive structures may be replaced
                                $id= _hash_id( $_ );
                            }
                        }

                        # the value of a scalar ref
                        elsif ( $reftype eq 'SCALAR' ) {
                            my $scalar= ${$_};

                            # may be reused
                            if ( defined $scalar ) {
                                $id= md5( $S . $scalar );

                                # not seen, recurse, set result if first
                                if ( !$reuse{$id} ) {
                                    ($scalar)= reuse $scalar;
                                    copy Internals::SvREADONLY $scalar, 1;

                                    # recursive structures may be replaced
                                    $id= md5( $S . $scalar );
                                }
                            }

                            # always reuse the default undef value
                            else {
                                $id= $U;
                            }
                        }

                        # huh?
                        else {
                            croak "Cannot reuse '$reftype' references";
                        }

=for Explanation:
     When called in void context, perl may actually have used a memory location
     for a temporary data structure that may return later with a different
     content.  As we don't want to equate those two different structures, we
     are not going to save this reference if called in void context.  And we
     are also not going to overwrite anything that's there already.

=cut

                        $reuse{$id} ||= $_ if $not_void;

                        # store in data store
                        $reuse{$_}= $reuse{$id} || $_;
                    };   #alias

                    # done handling this ref
                    delete $handling{$_};
                }

                # not a ref, but now already in store
                elsif ( exists $reuse{$_} ) {
                }

                # not a ref, and not in store either
                else {

                    # not readonly already, make a read only copy
                    $_= $_, Internals::SvREADONLY $_, 1
                      if !Internals::SvREADONLY $_;

                    # store in data store
                    alias $reuse{$_}= $_;
                }
            }
        }
    }

    # done on this level
    $level--;

    # return aliases of the specified values if needed
    alias return @reuse{ map { defined() ? $_ : $U } @_ } if $not_void;
}    #reuse

#---------------------------------------------------------------------------
# fixate
#
# Fixate the values of the given hash / array ref
#
#  IN: 1 hash / array ref
#      2..N values for fixation

sub fixate (\[@%]@) {

    # fetch structure
    alias my $struct= shift;
    croak "Must specify a hash or array as first parameter to fixate"
      unless my $reftype= reftype $struct;

    # just fixate existing structure
    reuse($struct), return if !@_;

    # alias semantices from here on
    alias {

        # it's a hash
        if ( $reftype eq 'HASH' ) {
            my %hash= %{$struct};
            croak "Can only fixate specific values on an empty hash"
              if keys %hash;

            # fill the hash and make sure only its values are reused
            (%hash)= @_;
            reuse \%hash; # also makes hash ro
        }

        # it's is an array
        elsif ( $reftype eq 'ARRAY' ) {
            my @array= @{$struct};
            croak "Can only fixate specific values on an empty array"
              if @array;

            # fill the array and make sure its values are reused
            (@array)= reuse @_;
            copy Internals::SvREADONLY @array, 1; # must copy, see above
        }

        # huh?
        else {
            croak "Don't know how to fixate '$reftype' references";
        }
    };

    return;
} #fixate

#---------------------------------------------------------------------------
# spread
#
# Spread a shared constant value in a data structure
#
#  IN: 1 data structure (hash / array ref)
#      2 value to be set (default: undef )
#      3..N keys / indexes to set

sub spread (\[@%]@) {

    # find out where to spread
    alias my $struct= shift;
    croak "Must specify a hash or array as first parameter to spread"
      unless my $reftype= reftype $struct;

    # huh? no value?
    croak "Must specify a value as second parameter to spread"
      if !@_;

    # fetch proper constant alias
    alias my $value= reuse shift;

    # nothing to be done
    return if !@_;

    # alias semantics from here on
    alias {

        # it's a hash, but can we do it?
        if ( $reftype eq 'HASH' ) {
            my %hash= %{$struct};
            croak "Cannot spread values in a restricted hash"
              if Internals::SvREADONLY %hash;

            # spread the values in the hash
            $hash{$_}= $value foreach @_;
        }

        # it's an array, but can we do it?
        elsif ( $reftype eq 'ARRAY' ) {
            my @array= @{$struct};
            croak "Cannot spread values in a restricted array"
              if Internals::SvREADONLY @array;

            # spread the values in the list
            $array[$_]= $value foreach @_;
        }

        # huh?
        else {
            croak "Don't know how to spread values in '$reftype' references";
        }
    };

    return;
}    #spread

#---------------------------------------------------------------------------
# forget
#
# Forget about the values that have been reused so far, or since the last
# time "forget" was called.

sub forget {

    # copy a fresh undef value (shouldn't alias the system undef!)
    %reuse= ( $U => undef );

    # make sure this undef can't be changed
    Internals::SvREADONLY $reuse{$U}, 1;

    return;
} #forget

#---------------------------------------------------------------------------
#
# Internal methods
#
#---------------------------------------------------------------------------
# _hash_id
#
# Return the ID for a hash ref
#
#  IN: 1 hash ref
# OUT: 1 id

sub _hash_id {
    alias my %hash= %{ $_[0] };

    return md5( encode_utf8( $H . join $;, map {
      $_ => ( defined $hash{$_} ? $hash{$_} : $U )
    } sort keys %hash ) );
}    #_hash_id

#---------------------------------------------------------------------------
# _list_id
#
# Return the ID for a list ref
#
#  IN: 1 list ref
# OUT: 1 id

sub _list_id {
    alias my @list= @{ $_[0] };

    return md5( $A . join $;, map { defined() ? $_ : $U } @list );
}    #_list_id

#---------------------------------------------------------------------------
#
# Debug methods
#
#---------------------------------------------------------------------------
# _constants
#
# Return hash ref of hash containing the constant values
#
# OUT: 1 hash ref

sub _constants { return \%reuse } #_constants

#---------------------------------------------------------------------------

__END__

=head1 NAME

Data::Reuse - share constant values with Data::Alias

=head1 VERSION

This documentation describes version 0.10.

=head1 SYNOPSIS

 use Data::Reuse qw(fixate);
 fixate my @array => ( 0, 1, 2, 3 );  # initialize and fixate
 my @filled_array=  ( 0, 1, 2, 3 );
 fixate @filled_array;                # fixate existing values
 print \$array[0] == \$filled_array[0]
   ? "Share memory\n" : "Don't share memory\n";

 fixate my %hash => ( zero => 0, one => 1, two => 2, three => 3 ); 
 my %filled_hash=  ( zero => 0, one => 1, two => 2, three => 3 );
 fixate %filled_hash;
 print \$hash{zero} == \$filled_hash{zero}
   ? "Share memory\n" : "Don't share memory\n";

 use Data::Reuse qw(reuse);
 reuse my $listref= [ 0, 1, 2, 3 ];
 reuse my $hashref= { zero => 0, one => 1, two => 2, three => 3 };
 print \$listref->[0] == \$hashref->{zero}
   ? "Share memory\n" : "Don't share memory\n";

 use Data::Alias qw(alias);
 use Data::Reuse qw(reuse);
 alias my @foo= reuse ( 0, 1, 2, 3 );
 print \$foo[0] == \$hashref->{zero}
   ? "Share memory\n" : "Don't share memory\n";

 use Data::Reuse qw(spread);
 spread my %spread_hash => undef, qw(foo bar baz);
 print \$spread_hash{foo} == \$spread_hash{bar}
   ? "Share memory\n" : "Don't share memory\n";
 spread my @spread_array => 1, 0 .. 3;
 print \$spread_array[0] == \$spread_array[1]
   ? "Share memory\n" : "Don't share memory\n";

 use Data::Reuse qw(forget);
 forget();  # free memory used for tracking constant values

=head1 DESCRIPTION

By default, Perl doesn't share literal ( 0, 'foo' , "bar" ) values.  That's
because once a literal value is stored in variable (a container), the contents
of that container can be changed.  Even if such a container is marked
"read-only" (e.g. with a module such as L<Scalar::ReadOnly>), it will not
cause the values to be shared.  So each occurrence of the same literal value
has its own memory location, even if it is internally marked as read-only.

In an ideal world, perl would keep a single copy of each literal value
(container) and have all occurrences in memory point to the same container.
Once an attempt is made to change the container would perl make a copy of the
container and put the new value in there.  This principle is usually referred
to as Copy-On-Write (COW).  Unfortunately, perl doesn't have this.

Comes in the L<Data::Alias> module which allows you to share containers
between different variables (amongst other things).  But it still does not
allow you to have literal values share the same memory locations.

Comes in this module, the L<Data::Reuse> module, which allows you to easily
have literal and read-only values share the same memory address.  Which can
save you a lot of memory when you are working with large data structures with
similar values.  Which is especially nice in a mod_perl environment, where
memory usage of persistent processes is one of the major issues..

Of course, no memory savings will occur for literal values that only occur
once.  So it is important that you use the functionality of this module
wisely, only on values that you expect to be duplicated at least two times.

=head1 SUBROUTINES

=head2 fixate

 fixate my @array => ( 0, 1, 2, 3 );

 my @filled_array= ( 0, 1, 2, 3 );
 fixate @filled_array;

 fixate my %hash => ( zero => 0, one => 1, two => 2, three => 3 );

 my %filled_hash= ( zero => 0, one => 1, two => 2, three => 3 );
 fixate %filled_hash;

The C<fixate> function allows you to initialize an array or hash with the given
values, or to reuse all values in either an existing hash or an existing array,
and making that hash or list read-only.  It is a frontend to C<reuse> and is
mainly made for convenience only.

=head2 reuse

 my $listref= reuse [ 1, 2, 3 ];
 my $hashref= reuse { one => 1, two => 2, three => 3 };

 my @list= ( 1, 2, 3 );
 my %hash= ( one => 1, two > 2, three => 3 );
 reuse \@list, \%hash;

The C<reuse> function is the workhorse of this module.  It will investigate
the given data structures and reuse any literal values as much as possible
and mark the structure as read only and return aliases to the given data
structures.

=head2 spread

 spread @array => 1, ( 0, 1, 2, 3 );

 spread %hash => undef, qw(foo bar baz);

The C<spread> function allows you to quickly spread a single value to a number
of elements in a list (specified by indexes), or to spread a single value to
the values of a hash, specified by a number of keys.  It is a frontend to
C<reuse> and is mainly made because you cannot use undef in C<alias> semantics
as a value in a hash.  In other words:

 alias @hash{ qw(foo bar baz) }= ();

doesn't work, instead use:

 spread %hash => undef, qw(foo bar baz);

=head1 EXAMPLE

=head2 inventory information in a hotel

Inventory information often consists of many similar values.  In this
particular example of a hotel and whether its rooms have inventory for the
given period, the dates are always in the same range, the rate ID's are always
the same values from a set, the prices for a particular room / rate combination
will most likely be very similar, and the number of rooms available as well.

Once read from the database, they are most likely to remain constant for the
remainder of the lifetime of the process.  It therefore makes sense to fold
the constants into the same memory locations.

 use Data::Reuse qw(reuse);

 my $sth= $dbh->prepare( <<"SQL" );
 SELECT room_id, date, rate_id, price, rooms
   FROM inventory
  WHERE date BETWEEN '$first_date' AND '$last_date'
    AND hotel_id= $hotel_id
  ORDER BY date
 SQL
 my $sth->execute;

 my ( $room_id, $date, $rate_id, $price, $rooms );
 $sth->bind_columns( \( $room_id, $date, $rate_id, $price, $rooms ) );

 my %result;
 push @{ $result{$room_id} }, reuse [ $date, $rate_id, $price, $rooms ]
   while $sth->fetch;

Suppose a hotel has, in a period of 365 days, 10 different room types (ID's)
with an average of 2 different rate types, having a total of 10 different
prices and 10 different number of available rooms.

Without using this module, this would take up 365 x 10 x 2 x 2 = 14400 scalar
values x 24 bytes = 350400 bytes.  With using this module, this would use
365 + 10 + 2 + 10 + 10 = 387 scalar values x 24 bytes = 9288 bytes.  Quite a
significant difference!  Now multiply this by thousands of hotels, and you see
that the space savings can become B<very> significant.

=head1 THEORY OF OPERATION

Each scalar value reused is internally matched against a hash with all
reused values.  This also goes for references, which are reused recursively.
For scalar values, the value itself is used as a key.  For references, an
md5 hash is used as the key.

All values are then aliased to the values in the hash (using L<Data::Alias>'s
C<alias> feature) and returns as aliases when needed.

The C<fixate> and C<spread> functions are basically frontends for the C<reuse>
subroutine.

The C<forget> function simply resets the internal hash used for storing
constant values, freeing all memory associated with it that isn't referenced
anywhere else (a.k.a. usually the memory used by the keys).

=head1 CAVEATS

=head2 reuse lists and hashes

Unfortunately, it is not possible to directly share lists and hashes.  This
is because perl will make copies again after the reusing action:

 reuse my @list= ( 1, 2, 3 );

is functionally equivalent with:

 reuse ( 1, 2, 3 );
 my @list= ( 1, 2, 3 );

so, this will cause the values B<1>, B<2> and B<3> to be in the internal reused
values hash, but the assignment of C<@list> will use new copies, thus
annihilating any memory savings.

Alternately:

 my @list= reuse( 1, 2, 3);

will not produce any space savings because the values are copied again by
perl after having been reused.  If you still want to use this type of idiom,
you can with the help of the "alias" function of the L<Data::Alias> module,
which you can also import from the L<Data::Reuse> module for your convenience:

 use Data::Reuse qw(alias reuse);
 alias my @list= reuse( 1, 2, 3);

will then generate the desired result.

=head1 FREQUENTLY ASKED QUESTIONS

None so far.

=head1 TODO

=head2 merging key and value

Currently, each reused value is kept at least twice in memory: once as a key,
and once as a value.  Deep down in the inside of perl, it is possible to create
a hash entry of which the key is in fact an external SV.  In an ideal world,
this feature should be used so that each reused value really, really only
occurs once in memory.  Suggestions / Patches to achieve this feature are
B<very> welcome!

If this proves to be impossible to do, then probably we need to use md5 strings
for all values to reduce memory requirements (at the expense of more CPU usage).

=head1 ACKNOWLEDGEMENTS

The Amsterdam Perl Mongers for feedback on various aspects of this module.  And
of course Matthijs van Duin for making it all possible with the very nice
L<Data::Alias> module.

=head1 REQUIRED MODULES

 Data::Alias (1.16)

=head1 AUTHOR

Elizabeth Mattijsen <liz@dijkmat.nl>

Copyright (C) 2006, 2007, 2009, 2012 Elizabeth Mattijsen.  All rights reserved.
This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

=cut
