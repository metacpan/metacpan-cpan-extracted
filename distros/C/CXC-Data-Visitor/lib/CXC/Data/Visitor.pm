package CXC::Data::Visitor;

# ABSTRACT: Invoke a callback on every element at every level of a data structure.

use v5.20;
use strict;
use warnings;


use feature 'current_sub';
use experimental 'signatures', 'lexical_subs', 'postderef';

#<<< no tidy
our $VERSION = '0.12';
#>>>

use base 'Exporter::Tiny';
use Hash::Util 'lock_hash', 'unlock_hash', 'unlock_value';
use POSIX 'floor';
use Scalar::Util 'refaddr', 'looks_like_number';
use Ref::Util 'is_plain_arrayref', 'is_plain_hashref', 'is_coderef', 'is_plain_ref',
  'is_plain_refref';
use Feature::Compat::Defer;

use constant {
    CYCLE_DIE      => 'die',
    CYCLE_CONTINUE => 'continue',
    CYCLE_TRUNCATE => 'truncate',
};
use constant CYCLE_QR => qr /\A die|continue|truncate \z/x;
use constant {
    VISIT_HASH      => 0b0001,
    VISIT_ARRAY     => 0b0010,
    VISIT_CONTAINER => 0b0011,
    VISIT_LEAF      => 0b0100,
    VISIT_ALL       => 0b0111,
    VISIT_ROOT      => 0b1000,
};
use constant {
    RESULT_NULL              => 0b000000,
    RESULT_RETURN            => 0b000001,
    RESULT_CONTINUE          => 0b000010,
    RESULT_REVISIT_CONTENTS  => 0b000100,
    RESULT_REVISIT_CONTAINER => 0b000100,    # back compat
    RESULT_REVISIT_ELEMENT   => 0b001000,
    RESULT_STOP_DESCENT      => 0b010000,
    RESULT_REVISIT_ROOT      => 0b100000,
};

use constant {
    PASS_VISIT_ELEMENT   => 0b01,
    PASS_REVISIT_ELEMENT => 0b10,
};

our %EXPORT_TAGS = (
    funcs   => [qw( visit )],
    results => [ qw(
          RESULT_NULL
          RESULT_RETURN
          RESULT_CONTINUE
          RESULT_REVISIT_ROOT
          RESULT_REVISIT_CONTENTS
          RESULT_REVISIT_CONTAINER
          RESULT_REVISIT_ELEMENT
          RESULT_STOP_DESCENT
        ),
    ],

    cycles => [ qw(
          CYCLE_DIE
          CYCLE_CONTINUE
          CYCLE_TRUNCATE
        ),
    ],

    visits => [ qw(
          VISIT_ARRAY
          VISIT_HASH
          VISIT_CONTAINER
          VISIT_LEAF
          VISIT_ALL
          VISIT_ROOT
        ),
    ],

    passes => [ qw(
          PASS_VISIT_ELEMENT
          PASS_REVISIT_ELEMENT
        ),
    ],

    constants => [qw( :results :cycles :visits :passes )],
);

our @EXPORT_OK = map { $EXPORT_TAGS{$_}->@* } keys %EXPORT_TAGS;

my sub croak {
    require Carp;
    goto \&Carp::croak;
}


## no critic (Subroutines::ProhibitManyArgs  Subroutines::ProhibitExcessComplexity)
my sub visit_node ( $node, $code, $context, $cycle, $visit, $meta ) {

    my $path      = $meta->{path};
    my $ancestors = $meta->{ancestors};

    my $sort_key_mode = $meta->{sort_key_mode};
    my $sort_idx_mode = $meta->{sort_idx_mode};
    my $key_sort      = $meta->{key_sort};
    my $idx_sort      = $meta->{idx_sort};

    my $visit_leaf  = !!( $visit & VISIT_LEAF );
    my $visit_hash  = !!( $visit & VISIT_HASH );
    my $visit_array = !!( $visit & VISIT_ARRAY );

    my $refaddr = refaddr( $node );
    if ( exists $meta->{seen}{$refaddr} ) {

        my $lcycle
          = is_coderef( $cycle )
          ? $cycle->( $node, $context, $meta )
          : $cycle;

        $lcycle eq CYCLE_TRUNCATE and return !!1;
        $lcycle eq CYCLE_DIE
          and croak( __PACKAGE__ . '::visit: cycle detected: ', join( '->', $path->@* ) );

        $lcycle eq CYCLE_CONTINUE
          or croak( __PACKAGE__ . "::visit: unkown cycle parameter value: $lcycle" );
    }

    # after this call to visit_node, will have visited all descendents of
    # $node, so don't need this any longer.
    $meta->{seen}{$refaddr} = ();
    defer { delete $meta->{seen}{$refaddr} }

    my %meta = $meta->%*;
    $meta{container} = $node;

    # deal with bare next in $code body
    use warnings FATAL => 'exiting';

    my $is_hashref = is_plain_hashref( $node );

    push $ancestors->@*, $node;
    defer { pop $ancestors->@* };

    my $revisit_limit = $meta->{revisit_limit};
    @meta{ 'visit', 'idx' } = ( 0, -1 );

  SCAN: {
        last unless --$revisit_limit;

        $meta{visit}++;
        $meta{idx} = -1;

        my $rescan_container = !!0;

        my $kydx_arr = do {

            if ( $is_hashref ) {
                    $sort_key_mode == 0 ? $key_sort->( [ keys $node->%* ] )
                  : $sort_key_mode == 1 ? [ sort keys $node->%* ]
                  :                       [ keys $node->%* ];
            }

            # must be an arrayref
            else {
                $sort_idx_mode == 0
                  ? $idx_sort->( 0+ $node->@* )
                  : [ 0 .. ( $node->@* - 1 ) ];
            }
        };

        for my $kydx ( $kydx_arr->@* ) {
            $meta{idx}++;

            push $path->@*, $kydx;
            defer { pop $path->@* }

            my $vref = \( $is_hashref ? $node->{$kydx} : $node->[$kydx] );

            my $visit_element
              = is_plain_hashref( $$vref )  ? $visit_hash
              : is_plain_arrayref( $$vref ) ? $visit_array
              :                               $visit_leaf;

            my $revisit_element = !!0;

            $meta{pass} = PASS_VISIT_ELEMENT;
            if ( $visit_element
                and ( my $result = $code->( $kydx, $vref, $context, \%meta ) ) != RESULT_CONTINUE )
            {
                # immediate rescan if explicitly set to value,
                # otherwise it will happen after the container is
                # completely visited
                redo SCAN                  if $result == RESULT_REVISIT_CONTENTS;
                return RESULT_RETURN       if $result == RESULT_RETURN;
                return RESULT_REVISIT_ROOT if $result == RESULT_REVISIT_ROOT;

                $rescan_container = $result & RESULT_REVISIT_CONTENTS;

                next if $result & RESULT_STOP_DESCENT;    # this works for both leaves and containers

                $revisit_element = $result & RESULT_REVISIT_ELEMENT;

                croak( "unknown return value from visit: $result" )
                  if !$revisit_element && !$result & RESULT_CONTINUE;
            }

            next unless is_plain_refref( $vref );

            my $ref = $vref->$*;
            if ( is_plain_arrayref( $ref ) || is_plain_hashref( $ref ) ) {
                my $result = __SUB__->( $ref, $code, $context, $cycle, $visit, \%meta );
                return RESULT_RETURN       if $result == RESULT_RETURN;
                return RESULT_REVISIT_ROOT if $result == RESULT_REVISIT_ROOT;
                if ( $revisit_element ) {
                    $meta{pass} = PASS_REVISIT_ELEMENT;
                    $result = $code->( $kydx, $vref, $context, \%meta );
                    return RESULT_RETURN       if $result == RESULT_RETURN;
                    return RESULT_REVISIT_ROOT if $result == RESULT_REVISIT_ROOT;
                    croak( "unexpected return value from visit: $result" )
                      if $result & ~( RESULT_CONTINUE | RESULT_REVISIT_CONTENTS );
                    $rescan_container |= $result & RESULT_REVISIT_CONTENTS;
                }
            }
        }
        redo SCAN if $rescan_container;
    }
    croak( "exceeded limit ($meta{revisit_limit}) on revisiting containers" )
      unless $revisit_limit;

    return RESULT_CONTINUE;
}

my sub visit_root ( $root, $code, $context, $cycle, $visit, $meta ) {

    my %meta          = $meta->%*;
    my $revisit_limit = $meta{revisit_limit};
    $meta{pass} = PASS_VISIT_ELEMENT;
    @meta{ 'visit', 'idx' } = ( 0, 0 );

  FROOT_LOOP:
    {
        $meta{visit}++;
        last unless --$revisit_limit;

        my $result = $code->( undef, \$root, $context, \%meta );

        redo FROOT_LOOP if $result == RESULT_REVISIT_ROOT;

        return !!0 if $result == RESULT_RETURN;
        return !!1 if $result == RESULT_STOP_DESCENT;

        my $revisit_element = $result & RESULT_REVISIT_ELEMENT;

        croak( "unknown return value from visit: $result" )
          if !$revisit_element && !$result & RESULT_CONTINUE;

        my $status = visit_node( $root, $code, $context, $cycle, $visit, \%meta );
        return !!0 if $status == RESULT_RETURN;

        if ( $revisit_element ) {
            $meta{pass} = PASS_REVISIT_ELEMENT;
            $result = $code->( undef, \$root, $context, \%meta );
            return !!0 if $result == RESULT_RETURN;
            return !!1 if $result == RESULT_CONTINUE;
            croak( "unexpected return value while revisiting root: $result" );
        }
    }
    croak( "exceeded limit ($meta{revisit_limit}) while revisiting root" )
      unless $revisit_limit;

    return !!1;
}



## critic (Subroutines::ProhibitManyArgs  Subroutines::ProhibitExcessComplexity)
sub visit ( $root, $callback, %opts ) {

    is_coderef( $callback )
      or croak( q{parameter 'callback' must be a coderef} );

    my $context = delete $opts{context} // {};

    # back compat
    if ( defined( my $sort_keys = delete $opts{sort_keys} ) ) {
        croak( q{specify only one of 'key_sort' or 'sort_keys'} )
          if defined $opts{key_sort};

        $opts{key_sort} = is_coderef( $sort_keys )
          ? sub ( $array ) {
            [ sort { $sort_keys->( $a, $b ) } $array->@* ];
          }
          : $sort_keys;
    }

    croak( "illegal value for 'revisit_limit' : $opts{revisit_limit}" )
      if defined $opts{revisit_limit}
      && !(looks_like_number( $opts{revisit_limit} )
        && floor( $opts{revisit_limit} ) == $opts{revisit_limit} );

    my %metadata = (
        path          => [],
        seen          => {},
        ancestors     => [],
        container     => undef,
        revisit_limit => delete $opts{revisit_limit} // 10,
        key_sort      => delete $opts{key_sort},
        idx_sort      => delete $opts{idx_sort},
    );

    {
        my $key_sort = $metadata{key_sort};
        my $idx_sort = $metadata{idx_sort};

        # $sort_key_mode =
        #  0 if passed coderef
        #  1 if should sort
        #  2 if should not sort
        $metadata{sort_key_mode}
          = defined $key_sort ? ( is_coderef( $key_sort ) ? 0 : $key_sort ? 1 : 2 ) : 1;

        # sorting indices is different than sorting keys,
        # as unlike for keys, indices are intrinsicly sorted

        # $sort_idx_modes =
        #  0 if passed coderef
        #  1 otherwise
        $metadata{sort_idx_mode} = defined( $idx_sort ) && is_coderef( $idx_sort ) ? 0 : 1;
    }

    my $cycle = delete $opts{cycle} // 'die';
    my $visit = delete $opts{visit} // VISIT_ALL;
    $visit |= VISIT_ALL if $visit == VISIT_ROOT;

    $cycle =~ CYCLE_QR
      or croak( "illegal value for cycle parameter: $cycle" );

    %opts
      and croak( 'illegal parameters: ', join( q{, }, keys %opts ) );

    lock_hash( %metadata );
    unlock_value( %metadata, 'container' );

    my $completed;

    if ( $visit & VISIT_ROOT ) {
        $completed = visit_root( $root, $callback, $context, $cycle, $visit, \%metadata );
    }
    else {
        my $revisit_limit = $metadata{revisit_limit};
        while ( --$revisit_limit ) {
            last unless --$revisit_limit;
            $completed = visit_node( $root, $callback, $context, $cycle, $visit, \%metadata );
            last unless $completed == RESULT_REVISIT_ROOT;
        }
        croak( "exceeded limit ($metadata{revisit_limit}) while revisiting root" )
          unless $revisit_limit;
        $completed = $completed != RESULT_RETURN;
    }

    unlock_hash( %metadata );

    delete $metadata{ancestors};    # should be empty, but just in case,
                                    # don't want to keep references
                                    # around.

    return ( $completed, $context, \%metadata );
}

1;

#
# This file is part of CXC-Data-Visitor
#
# This software is Copyright (c) 2024 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory selectable idx

=head1 NAME

CXC::Data::Visitor - Invoke a callback on every element at every level of a data structure.

=head1 VERSION

version 0.12

=head1 SYNOPSIS

 use CXC::Data::Visitor 'visit', 'RESULT_CONTINUE';
 
 my %root = (
     fruit => {
         berry  => 'purple',
         apples => [ 'fuji', 'macoun' ],
     } );
 
 visit(
     \%root,
     sub ( $kydx, $vref, @ ) {
         $vref->$* = 'blue' if $kydx eq 'berry';
         return RESULT_CONTINUE;
     } );
 
 say $root{fruit}{berry}

results in

 blue

=head1 DESCRIPTION

B<CXC::Data::Visitor::visit> performs a depth-first traversal of a data
structure, invoking a provided callback subroutine on elements in the
structure.

=head2 Features

=over

=item *

The type of element passed to the callback (containers, terminal
elements) can be selected.

=item *

The order of traversal at a given depth (i.e. within a container's
elements) may be customized.

=item *

The callback can modify the traversal process.

=item *

The complete path from the structure to an element (both the ancestor
containers and the keys and indexes required to traverse the path) is
available to the callback.

=item *

Cycles are detected upon traversing a container a second time in a
depth first search, and the resultant action may be specified.

=item *

Objects are treated as terminal elements and are not traversed.

=item *

Containers that can be reached multiple times without cycling are visited once per parent.

=back

=head2 Overview

C<visit> recursively traverses the container, C<$root>, calling the
passed subroutine, C<$callback> on each element, C<$element>, which
is allowed by the L</visit> option.

The traversal is depth-first, e.g. if C<$element> is a
container, C<$callback> is called on it and then its contents before
processing C<$element>'s siblings.

Each container's contents are traversed in sorted order.  For hashes,
this is alphabetical, for arrays, numerical. (This may be
changed with the L</key_sort> and L</idx_sort> options).

For example, the default traversal order for the structure in the L</SYNOPSIS> is

 +-------------------------+-----------------------+-----+
 | path                    | value                 | idx |
 +-------------------------+-----------------------+-----+
 | $root{fruit}            | \$root{fruit}         | 0   |
 | $root{fruit}{apples}    | \$root{fruit}{apples} | 0   |
 | $root{fruit}{apples}[0] | fuji                  | 0   |
 | $root{fruit}{apples}[1] | macoun                | 1   |
 | $root{fruit}{berry}     | purple                | 1   |
 +-------------------------+-----------------------+-----+

Containers that can be reached multiple times without cycling, e.g.

  %hash = ( a => { b => 1 }, );
  $hash{c} = $hash{a};

are visited once per parent, e.g.

  {a}, {a}{b}
  {c}, {c}{b}

C<$callback>'s return value indicates how C<visit> should proceed (see
L</Traversal Directives>).  The simplest directive is to continue
traversal; additional directives abort the traversal,
abort descent into a container, revisit the current container
immediately, revisit a container after its contents are visited,
and other obscure combinations.

=head1 USAGE

C<visit> has the following signature:

  ( $completed, $context, $metadata ) = visit( $root, $callback, %options )

The two mandatory arguments are C<$root>, a reference to either a
hash or an array, and C<$callback>, a reference to a subroutine which
will be invoked on visited elements. By default C<$callback> is invoked on
C<$root>'s elements, not on C<$root> itself; use the L</VISIT_ROOT>
flag change this.

=over

=item B<$completed>  => I<Boolean>

I<true> if all elements were visited, I<false> if
B<$callback> requested a premature return.

=item B<$context>

The variable of the same name passed to B<$callback>; see the L</context> option.

=item B<$metadata> => I<hash>

collected metadata. See L</Metadata>.

=back

=head2 Options

C<visit> may be passed the following options:

=over

=item context I<optional>

Arbitrary data to be passed to L</$callback> via the C<$context>
argument. Use it for whatever you'd like.  If not specified, a hash
will be created.

=item cycle => I<constant|coderef>

How cycles within C<$root> should be handled.  See L</Cycles>.

=item visit => I<constant>

Specify elements (by type) which will be passed to C<$callback>.  See
L</Element Filters>

=item key_sort => I<boolean> | C<$coderef>

The order of keys when traversing hashes.  If I<true> (the default),
the order is that returned by Perl's C<sort> routine.  If I<false>,
it is the order returned that Perl's C<keys> routine.

If a coderef, it is used to sort the keys.  It is called as

  \@sorted_keys = $coderef->( \@unsorted_keys );

=item idx_sort => C<$coderef>

By default array elements are traversed in order of their
ascending index.  Use L</idx_sort> to specify a subroutine
which returns them in an alternative order. It is called as

  \@indices = $coderef->( $n );

where C<$n> is the number of elements in the array.

=item sort_keys => I<coderef>

I<DEPRECATED>

An optional coderef which implements a caller specific sort order.  It
is passed two keys as arguments.  It should return C<-1>, C<0>, or
C<1> indicating that the sort order of the first argument is less
than, equal to, or greater than that of the second argument.

=item revisit_limit

A container may be scanned multiple times during a visit to it.
This sets the maximum number of times the container is re-scanned
during a visit before C<visit> throws an exception to avoid infinite
loops.  This limit also applies to L</RESULT_REVISIT_ROOT>.

The defaults is C<10>. Set it to C<0> to indicate no limit.

=back

=head2 Callback

C<visit> invokes C<$callback> on selected elements of C<$root> (see
L</Element Filters>). C<$callback> is invoked as

  $directive = $callback->( $kydx, $vref, $context, \%metadata );

The arguments passed to C<$callback> are:

=over

=item B<$kydx>

The location (key or index) of the element in its parent
container. This will be undefined when C<$callback> is invoked on
C<$root> (see L</VISIT_ROOT>).

=item B<$vref>

A reference to the element.  Use B<< $vref->$* >> to extract or modify
the element's value.  Do not cache this value; the full path to the
element is provided via the L</$metadata> argument.

=item B<$context>

A reference to data reserved for use by C<$callback>. See the
L</context> option.

=item B<$metadata>

A hash of state information used to keep track of progress. While
primarily of use by C<visit>, some may be of interest to C<$callback>.
See L</Metadata>

=back

=head2 Traversal Directives

L</$callback> must return a constant (see L</EXPORTS>)
indicating what C<visit> should do next.  Not all constants
are allowed in all contexts in which C<$callback> is invoked;
see L</Calling Contexts and Allowed Traversal Directives>.

=head3 Single Directives

=over

=item RESULT_CONTINUE

Visit the next element in the parent container.

 +-------------------------+-----------------------+-----+
 | path                    | value                 | idx |
 +-------------------------+-----------------------+-----+
 | $root{fruit}            | \$root{fruit}         | 0   |
 | $root{fruit}{apples}    | \$root{fruit}{apples} | 0   |
 | $root{fruit}{apples}[0] | fuji                  | 0   |
 | $root{fruit}{apples}[1] | macoun                | 1   |
 | $root{fruit}{berry}     | purple                | 1   |
 +-------------------------+-----------------------+-----+

=item RESULT_RETURN

Return immediately to the caller of C<visit>.

=item RESULT_STOP_DESCENT

If the current element is a hash or array, do not visit its contents,
and visit the next element in the parent container.

If the element is not a container, the next element in the container
will be visited (just as with L</RESULT_CONTINUE>).

For example, If C<RESULT_STOP_DESCENT> is returned when
C<$root{fruit}{apples}> is traversed, the traversal would look like
this:

 +----------------------+-----------------------+-----+
 | path                 | value                 | idx |
 +----------------------+-----------------------+-----+
 | $root{fruit}         | \$root{fruit}         | 0   |
 | $root{fruit}{apples} | \$root{fruit}{apples} | 0   |
 | $root{fruit}{berry}  | purple                | 1   |
 +----------------------+-----------------------+-----+

=item RESULT_REVISIT_CONTENTS

Do not visit the next element in the parent container. restart with
the first element in the container.  The order of elements is
determined when the container is visited, so starts within a visit
will have the same order.

For example, if C<RESULT_REVISIT_CONTENTS> is returned the
first time C<$root{fruit}{apples}[0]> is traversed, the
traversal would look like this:

 +-------------------------+-----------------------+-----+-------+
 | path                    | value                 | idx | visit |
 +-------------------------+-----------------------+-----+-------+
 | $root{fruit}            | \$root{fruit}         | 0   | 1     |
 | $root{fruit}{apples}    | \$root{fruit}{apples} | 0   | 1     |
 | $root{fruit}{apples}[0] | fuji                  | 0   | 1     |
 | $root{fruit}{apples}[0] | fuji                  | 0   | 2     |
 | $root{fruit}{apples}[1] | macoun                | 1   | 2     |
 | $root{fruit}{berry}     | purple                | 1   | 1     |
 +-------------------------+-----------------------+-----+-------+

To avoid inadvertent infinite loops, the number of revisits
during a traversal of a container is limited (see L</revisit_limit>).
Containers with multiple parents are traversed once per parent; The
limit is reset for each traversal.

=item RESULT_REVISIT_ROOT

Stop processing and re-start at C<$root>.
To avoid inadvertent infinite loops, the number of revisits
is limited (see L</revisit_limit>).

=item RESULT_REVISIT_ELEMENT

If the current element is not a container, the next element in the
container will be visited (just as with L</RESULT_CONTINUE>).

If the current element is a container, its contents will be visited,
and L</$callback> will be invoked on it again afterwards.

During the call to C<$callback> on the container prior to visiting
its contents,

  $metadata->{pass} & PASS_VISIT_ELEMENT

will be true.  During the followup visit

  $metadata->{pass} & PASS_REVISIT_ELEMENT

will be true.

For example, If C<RESULT_REVISIT_ELEMENT> is returned when
C<$root{fruit}{apples}> is traversed, the traversal would look like
this:

 +-------------------------+-----------------------+-----+----------------------+
 | path                    | value                 | idx | pass                 |
 +-------------------------+-----------------------+-----+----------------------+
 | $root{fruit}            | \$root{fruit}         | 0   | PASS_VISIT_ELEMENT   |
 | $root{fruit}{apples}    | \$root{fruit}{apples} | 0   | PASS_VISIT_ELEMENT   |
 | $root{fruit}{apples}[0] | fuji                  | 0   | PASS_VISIT_ELEMENT   |
 | $root{fruit}{apples}[1] | macoun                | 1   | PASS_VISIT_ELEMENT   |
 | $root{fruit}{apples}    | \$root{fruit}{apples} | 0   | PASS_REVISIT_ELEMENT |
 | $root{fruit}{berry}     | purple                | 1   | PASS_VISIT_ELEMENT   |
 +-------------------------+-----------------------+-----+----------------------+

=back

=head3 Mixed Directives

Some directives can be mixed with L</RESULT_REVISIT_CONTENTS> and
L</RESULT_REVISIT_ELEMENT> by performing a binary OR with them.

=over

=item RESULT_STOP_DESCENT | RESULT_REVISIT_CONTENTS

If the current element is not a container, the next element in the
container will be visited (just as with L</RESULT_CONTINUE>).

If the current element is a hash or array, do not visit its contents,
and continue with the next element in the parent container.  For
non-container elements, continue with the next element in the parent
container.

After all of the container's contents have been visited, start
again with the first element in the container.

For example, if C<RESULT_STOP_DESCENT | RESULT_REVISIT_CONTENTS> is
returned when C<$root{fruit}{apples}> is traversed when
C<$metadata->{visit} ==1>, the traversal would look like

 +----------------------+-----------------------+-----+-------+
 | path                 | value                 | idx | visit |
 +----------------------+-----------------------+-----+-------+
 | $root{fruit}         | \$root{fruit}         | 0   | 1     |
 | $root{fruit}{apples} | \$root{fruit}{apples} | 0   | 1     |
 | $root{fruit}{berry}  | purple                | 1   | 1     |
 | $root{fruit}{apples} | \$root{fruit}{apples} | 0   | 2     |
 | $root{fruit}{berry}  | purple                | 1   | 2     |
 +----------------------+-----------------------+-----+-------+

=item RESULT_CONTINUE | RESULT_REVISIT_CONTENTS

Visit the remaining elements in the parent container, then start again
with the first element in the container.

For example, if C<RESULT_CONTINUE | RESULT_REVISIT_CONTENTS> is
returned when C<$callback> is first passed
C<$root{fruit}{apples}[0]>, the traversal would look like

 +-------------------------+-----------------------+-----+-------+
 | path                    | value                 | idx | visit |
 +-------------------------+-----------------------+-----+-------+
 | $root{fruit}            | \$root{fruit}         | 0   | 1     |
 | $root{fruit}{apples}    | \$root{fruit}{apples} | 0   | 1     |
 | $root{fruit}{apples}[0] | fuji                  | 0   | 1     |
 | $root{fruit}{apples}[1] | macoun                | 1   | 1     |
 | $root{fruit}{apples}[0] | fuji                  | 0   | 2     |
 | $root{fruit}{apples}[1] | macoun                | 1   | 2     |
 | $root{fruit}{berry}     | purple                | 1   | 1     |
 +-------------------------+-----------------------+-----+-------+

=back

=head2 Calling Contexts and Allowed Traversal Directives

C<$callback>'s allowed return value depends upon the context it is
called in.  C<$callback> may be called on an element multiple times
during different stages of traversal.

=head3 When invoked on an element during a scan of its parent container

=over

=item *

The C<pass> metadata attribute is set to C<PASS_VISIT_ELEMENT>

=item *

C<$callback> must return one of

  RESULT_REVISIT_CONTENTS
  RESULT_RETURN
  RESULT_CONTINUE

  RESULT_CONTINUE | RESULT_REVISIT_CONTENTS
  RESULT_STOP_DESCENT | RESULT_REVISIT_CONTENTS
  RESULT_CONTINUE | RESULT_REVISIT_ELEMENT

=back

=head3 When invoked on a container immediately after its contents have been visited

See L</RESULT_REVISIT_ELEMENT>.

=over

=item *

The C<pass> metadata attribute is set to C<PASS_REVISIT_ELEMENT>

=item *

C<$callback> must return one of

  RESULT_RETURN
  RESULT_CONTINUE
  RESULT_REVISIT_CONTENTS
  RESULT_CONTINUE | RESULT_REVISIT_CONTENTS

=back

=head3 When invoked on C<$root> before its contents have been visited

See L</VISIT_ROOT>.

=over

=item *

The C<pass> metadata attribute is set to C<PASS_VISIT_ELEMENT>

=item *

C<$callback> must return one of

  RESULT_CONTINUE
  RESULT_CONTINUE | RESULT_REVISIT_ELEMENT
  RESULT_RETURN
  RESULT_REVISIT_ROOT
  RESULT_STOP_DESCENT

=back

=head3 When invoked on the C<$root> immediately after its elements have been visited

See L</VISIT_ROOT> and L</RETURN_REVISIT_ELEMENT>.

=over

=item *

The C<pass> metadata attribute is set to C<PASS_REVISIT_ELEMENT>

=item *

C<$callback> must return one of

  RESULT_RETURN
  RESULT_CONTINUE

=back

=head2 Metadata

C<$callback> is passed a hash of state information (C<$metadata>) kept
by B<CXC::Data::Visitor::visit>, some of which may be of interest to
the callback:

C<$metadata> has the following entries:

=over

=item B<container>

A reference to the hash or array which contains the element being visited.

=item B<path>

An array which contains the path (keys and indices) used to arrive
at the current element from B<$root>.

=item B<ancestors>

An array containing references to the ancestor containers of the
current element.

=item B<pass>

A constant indicating the current visit pass of an element.
See L</RESULT_REVISIT_ELEMENT>.

=item B<visit>

A unary-based counter indicating the number of times the element's
container has been scanned and its contents processed in a single
visit.  This will be greater than C<1> if the
L</RESULT_REVISIT_CONTENTS> directive has been applied. It is I<not>
the number of times that the element has been visited, as scans may be
interrupted and restarted.

=item B<idx>

A zero-based index indicating the order of the element in its container.
Ordering depends upon how container elements are sorted; see
L</key_sort> and L</idx_sort>.

=back

=head2 Element Filters

The parts of the structure that will trigger a callback.  Note that
by default the passed top level structure, C<$root> is I<not>
passed to the callback.  See L</VISIT_ROOT>.

See L</EXPORTS> to import the constants.

=over

=item VISIT_CONTAINER

Invoke L</$callback> on containers (either hashes or arrays).  For
example, the elements in the following structure

  $root = { a => { b => 1, c => [ 2, 3 ] } }

passed to L</$callback> are:

  a => {...}  # $root->{a}
  c => [...]  # $root->{c}

=item VISIT_ARRAY

=item VISIT_HASH

Only visit containers of the given type.

=item VISIT_LEAF

Invoke L</$callback> on terminal (leaf) elements.  For example, the
elements in the following structure

  $root = { a => { b => 1, c => [ 2, 3 ] } }

passed to L</$callback> are:

  b => 1  # $root->{a}{b}
  0 => 2  # $root->{a}{c}[0]
  1 => 3  # $root->{a}{c}[1]

=item VISIT_ALL

Invoke L</$callback> on all elements except for C<$root>.  This is the default.

=item VISIT_ROOT

Pass C<$root> to C<$callback>. To filter on one of the other values, pass
a binary OR of L</VISIT_ROOT> and the other filter, e.g.

  VISIT_ROOT | VISIT_LEAF

Specifying L</VISIT_ROOT> on its own is equivalent to

  VISIT_ROOT | VISIT_ALL

=back

=head2 Cycles

=over

=item CYCLE_DIE

Throw an exception (the default).

=item CYCLE_CONTINUE

Pretend we haven't seen it before. Will cause stack exhaustion if
B<$callback> does handle this.

=item CYCLE_TRUNCATE

Truncate before entering the cycle a second time.

=item I<$coderef>

Examine the situation and request a particular resolution.
B<$coderef> is called as

  $coderef->( $container, $context, $metadata );

where B<$container> is the hash or array which has already been
traversed. See below for L</$context> and L</$metadata>.

B<$coderef> should return one of B<CYCLE_DIE>, B<CYCLE_CONTINUE>, or B<CYCLE_TRUNCATE>,
indicating what should be done.

=back

=head1 EXPORTS

This module uses L<Exporter::Tiny>, which provides enhanced import
utilities.

=head2 Subroutines

The following subroutine may be imported:

 visit

=head3 Constants

Constants may be imported individually or as groups via tags.  The
available tags and their respective imported symbols are:

=over

=item B<all>

Import all symbols.

=item B<results>

 RESULT_CONTINUE
 RESULT_RETURN
 RESULT_REVISIT_CONTAINER  # deprecated alias for RESULT_REVISIT_CONTENTS
 RESULT_REVISIT_CONTENTS
 RESULT_REVISIT_ELEMENT
 RESULT_REVISIT_ROOT
 RESULT_STOP_DESCENT

=item B<cycles>

 CYCLE_CONTINUE
 CYCLE_DIE
 CYCLE_TRUNCATE

=item B<visits>

 VISIT_ALL
 VISIT_CONTAINER
 VISIT_LEAF
 VISIT_ROOT

=item B<passes>

 PASS_REVISIT_ELEMENT
 PASS_VISIT_ELEMENT

=item B<constants>

Import tags C<cycles>, C<passes>, C<results>, C<visits>.

=back

=head1 DEPRECATED CONSTRUCTS

=over

=item *

B<RESULT_REVISIT_CONTAINER> is a deprecated alias for L</RESULT_REVISIT_CONTENTS>.

=back

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-cxc-data-visitor@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-Data-Visitor>

=head2 Source

Source is available at

  https://codeberg.org/CXC-Optics/p5-CXC-Data-Visitor

and may be cloned from

  https://codeberg.org/CXC-Optics/p5-CXC-Data-Visitor.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Data::Rmap|Data::Rmap>

=item *

L<Data::Traverse|Data::Traverse>

=item *

L<Data::Visitor::Lite|Data::Visitor::Lite>

=item *

L<Data::Visitor::Tiny|Data::Visitor::Tiny>

=item *

L<Data::Walk|Data::Walk>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
