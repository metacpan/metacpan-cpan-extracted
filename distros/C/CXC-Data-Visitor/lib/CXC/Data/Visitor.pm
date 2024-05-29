package CXC::Data::Visitor;

# ABSTRACT: Invoke a callback on every element at every level of a data structure.

use v5.20;
use strict;
use warnings;


use feature 'current_sub';
use experimental 'signatures', 'lexical_subs', 'postderef';

our $VERSION = '0.04';

use base 'Exporter::Tiny';
use Hash::Util 'lock_hash', 'unlock_hash', 'unlock_value';
use POSIX 'floor';
use Scalar::Util 'refaddr', 'looks_like_number';
use Ref::Util 'is_plain_arrayref', 'is_plain_hashref', 'is_coderef', 'is_plain_refref';
use Feature::Compat::Defer;

use constant {
    CYCLE_DIE      => 'die',
    CYCLE_CONTINUE => 'continue',
    CYCLE_TRUNCATE => 'truncate',
};
use constant CYCLE_QR => qr /\A die|continue|truncate \z/x;
use constant { VISIT_CONTAINER => 0b01, VISIT_LEAF => 0b10, VISIT_ALL => 0b11 };
use constant {
    RESULT_RETURN            => 0,
    RESULT_CONTINUE          => 1,
    RESULT_REVISIT_CONTAINER => 2,
    RESULT_REVISIT_ELEMENT   => 3,
};

use constant { PASS_VISIT_ELEMENT => 1, PASS_REVISIT_ELEMENT => 2 };

our %EXPORT_TAGS = (
    funcs     => [qw( visit )],
    results   => [qw( RESULT_RETURN RESULT_CONTINUE RESULT_REVISIT_CONTAINER RESULT_REVISIT_ELEMENT )],
    cycles    => [qw( CYCLE_DIE CYCLE_CONTINUE CYCLE_TRUNCATE )],
    visits    => [qw( VISIT_CONTAINER VISIT_LEAF VISIT_ALL )],
    passes    => [qw( PASS_VISIT_ELEMENT PASS_REVISIT_ELEMENT )],
    constants => [qw( :results :cycles :visits )],
);

our @EXPORT_OK = map { $EXPORT_TAGS{$_}->@* } keys %EXPORT_TAGS;

my sub croak {
    require Carp;
    goto \&Carp::croak;
}


## no critic (Subroutines::ProhibitManyArgs  Subroutines::ProhibitExcessComplexity)
my sub _visit ( $node, $code, $context, $cycle, $visit, $meta ) {

    my $path          = $meta->{path};
    my $ancestors     = $meta->{ancestors};
    my $revisit_limit = $meta->{revisit_limit};

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

    # after this call to _visit, will have visited all descendents of
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

    my $visit_leaf = !!( $visit & VISIT_LEAF );
    my $visit_node = !!( $visit & VISIT_CONTAINER );

  SCAN: {
        last unless --$revisit_limit;

        my @idx = $is_hashref ? sort keys $node->%* : keys $node->@*;

        for my $idx ( @idx ) {

            push $path->@*, $idx;
            defer { pop $path->@* }

            my $vref = \( $is_hashref ? $node->{$idx} : $node->[$idx] );

            my $is_node = is_plain_refref( $vref );

            my $visit_element   = $is_node ? $visit_node : $visit_leaf;
            my $revisit_element = !!0;

            $meta{pass} = PASS_VISIT_ELEMENT;
            if ( $visit_element
                and ( my $result = $code->( $idx, $vref, $context, \%meta ) ) != RESULT_CONTINUE )
            {
                redo SCAN  if $result == RESULT_REVISIT_CONTAINER;
                return !!0 if $result == RESULT_RETURN;
                if ( $result == RESULT_REVISIT_ELEMENT ) {
                    $revisit_element = !!1;
                }
                elsif ( $result != RESULT_CONTINUE ) {
                    croak( "unknown return value from visit: $result" );
                }
            }

            next unless is_plain_refref( $vref );

            my $ref = $vref->$*;
            if ( is_plain_arrayref( $ref ) || is_plain_hashref( $ref ) ) {
                __SUB__->( $ref, $code, $context, $cycle, $visit, \%meta ) || return !!0;

                if ( $revisit_element ) {
                    $meta{pass} = PASS_REVISIT_ELEMENT;
                    my $result = $code->( $idx, $vref, $context, \%meta );
                    return !!0 if $result == RESULT_RETURN;
                    next       if $result == RESULT_CONTINUE;
                    croak( "unknown return value from visit: $result" );
                }
            }
        }
    }
    croak( "exceeded limit ($meta->{revisit_limit}) on revisiting containers" )
      unless $revisit_limit;

    return !!1;
}
## critic (Subroutines::ProhibitManyArgs  Subroutines::ProhibitExcessComplexity)



































































































































































































































































sub visit ( $struct, $callback, %opts ) {

    is_coderef( $callback )
      or croak( q{parameter 'callback' must be a coderef} );

    my $context = delete $opts{context} // {};
    is_plain_hashref( $context )
      or croak( q{parameter 'context' must be a plain hash} );

    my %metadata = (
        path          => [],
        seen          => {},
        ancestors     => [],
        container     => undef,
        revisit_limit => delete $opts{revisit_limit} // 10,
    );

    croak( "illegal value for 'revisit_limit' : $metadata{revisit_limit}" )
      unless looks_like_number( $metadata{revisit_limit} )
      && floor( $metadata{revisit_limit} ) == $metadata{revisit_limit};


    my $cycle = delete $opts{cycle} // 'die';
    my $visit = delete $opts{visit} // VISIT_ALL;

    $cycle =~ CYCLE_QR
      or croak( "illegal value for cycle parameter: $cycle" );

    %opts
      and croak( 'illegal parameters: ', join( q{, }, keys %opts ) );

    lock_hash( %metadata );
    unlock_value( %metadata, 'container' );
    my $completed = _visit( $struct, $callback, $context, $cycle, $visit, \%metadata );
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

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory selectable

=head1 NAME

CXC::Data::Visitor - Invoke a callback on every element at every level of a data structure.

=head1 VERSION

version 0.04

=head1 SYNOPSIS

  use CXC::Data::Visitor 'visit', 'RESULT_CONTINUE';

  my $hoh = { fruit => { berry => 'purple' }, };

  visit(
      $hoh,
      sub {
          my ( $key, $vref ) = @_;
          $$vref = 'blue' if $key eq 'berry';
          return RESULT_CONTINUE;
      } );

  say $hoh->{fruit}{berry}    # 'blue'

=head1 DESCRIPTION

B<CXC::Data::Visitor> provides a means of performing a depth first
traversal of a data structure.  There are similar modules on CPAN
(L</SEE ALSO>); this module provides a few extras:

=over

=item *

The traversal may be aborted.

=item *

A container (hash or array) may be immediately revisited if the
callback requests it.

=item *

An element whose value is a container may be revisited after the container is
visited if the callback requests it.

=item *

User selectable behavior upon detection of a traversal cycle.

=item *

The complete path from the structure route to an element (both the
ancestor containers and the keys and indexes required to traverse the
path) is available.

=back

=head1 SUBROUTINES

=head2 visit

   ( $completed, $context, $metadata ) = visit( $struct, $callback, %opts );

Perform a depth-first traversal of B<$struct>, invoking B<$callback>
on containers (hashes and arrays) and terminal elements in B<$struct>.

=over

=item *

Blessed hashes or arrays are treated as terminal elements and are not
further traversed.

=item *

Hashes are traversed in sorted key order.

=item *

Cycles are detected upon traversing a container a second time in a
depth first search.

=item *

Containers that can be reached multiple times without cycling, e.g.

  %hash = ( a => { b => 1 }, );
  $hash{c} = $hash{a};

are visited once per parent, e.g.

  {a}, {a}{b}, {a}{b}[0]
  {c}, {c}{b}, {c}{b}[0]

=item *

B<$callback> is first invoked on a container and then its
elements.  Given

  { a => { b => [ 0 ], c => 2 } }

the callback order is

  {a}, {a}{b}, {a}{b}[0], {a}{c}

=back

L</visit> returns the following:

=over

=item B<$completed>  => I<Boolean>

I<true> if all elements were visited, I<false> if
B<$callback> requested a premature return.

=item B<$context> => I<hash>

a hash made available to B<$callback> to stash data

=item B<$metadata> => I<hash>

collected metadata. See L</$metadata> below.

=back

B<$callback> will be called as:

  $handle_return = $callback->( $kydx, $vref, $context, \%metadata );

and should return one of the following (see L</EXPORTS> to import the constants):

=over

=item RESULT_CONTINUE

The process of visiting elements should continue.

=item RESULT_RETURN

L</visit> should return immediately to the caller.

=item RESULT_REVISIT_CONTAINER

Further processing of the elements in the current container should stop
and the container should be revisited.  This allows L</$callback> to
modify the container and have it reprocessed.

To avoid inadvertent infinite loops, a finite number of revisits
is allowed during a traversal of a container (see L</revisit_limit>).
Containers with multiple parents are traversed once per parent;
The limit is reset for each traversal.

=item RESULT_REVISIT_ELEMENT

If the value of this element is a container, it should be revisited
(by calling L</$callback>) after its value is visited.  This
allows post-processing results when travelling back up the structure.

During the initial visit

  $metadataa->{pass} & PASS_VISIT_ELEMENT

will be true.  During the followup visit

  $metadata->{pass} & PASS_REVISIT_ELEMENT

will be true and L</$callback> may only return values of
B<RESULT_RETURN> and B<RESULT_CONTINUE>; any other values will cause
an exception.

The ordered contents of the L<$metadata{path}> array uniquely
identify an element, so may be used to track elements using external data
structures.  Do not depend upon reference addresses remaining constant.

=back

L</$callback> is passed

=over

=item B<$kydx>

the key or index into B<$container> of the element being visited.

=item B<$vref>

a reference to the value of the element being visited.  Use B<$$vref>
to get the actual value.

=item B<$context>

A hash which can be used by the caller to stash data.

=item B<$metadata>

A hash of state information kept by B<CXC::Data::Visitor>, but which
may be of interest to the callback:

=over

=item B<container>

a reference to the hash or array which contains the element being visited.

=item B<path>

An array which contains the path (keys and indices) used to arrive
at the current element from B<$struct>.

=item B<ancestors>

An array contains the ancestor containers of the current element.

=back

=item B<pass>

A constant indicating the current visit pass through an element.

=back

B<%opts> may contain the following entries:

=over

=item B<context> => I<hashref>

A reference to a hash passed to L</$callback>, for the caller's
use. It defaults to a freshly created hash.

=item B<cycle> => CYCLE_TRUNCATE | CYCLE_DIE | CYCLE_CONTINUE | <$coderef>

How to handle cycles in the data structure.

See L</EXPORTS> to import the constant values.

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

=item I<visit> => VISIT_CONTAINER | VISIT_LEAF | VISIT_ALL

The parts of the structure that will trigger a callback.
See L</EXPORTS> to import the constants.

=over

=item VISIT_CONTAINER

Invoke L</$callback> on containers.  For example, the elements in the
following structure

  $struct = { a => { b => 1, c => [ 2, 3 ] } }

passed to L</$callback> are:

  a => {...}  # $struct->{a}
  c => [...]  # $struct->{c}

=item VISIT_LEAF

Invoke L</$callback> on terminal (leaf) elements.  For example, the
elements in the following structure

  $struct = { a => { b => 1, c => [ 2, 3 ] } }

passed to L</$callback> are:

  b => 1  # $struct->{a}{b}
  0 => 2  # $struct->{a}{c}[0]
  1 => 3  # $struct->{a}{c}[1]

=item VISIT_ALL

Invoke L</$callback> on all elements.  This is the default.

=back

=item revisit_limit

If L</$callback> returns B<RESULT_REVISIT_CONTAINER>, then the parent container
of the element is re-scanned for its elements and revisited.  To avoid an inadvertent
infinite loop, an exception is thrown if the parent container is revisited more
than this number of times.  It defaults to 10;

=back

=head1 EXPORTS

This module uses L<Exporter::Tiny>, which provides enhanced import utilities.

The following symbols may be exported:

  visit
  VISIT_CONTAINER VISIT_LEAF VISIT_ALL
  CYCLE_DIE CYCLE_CONTINUE CYCLE_TRUNCATE
  RESULT_RETURN RESULT_CONTINUE RESULT_REVISIT_CONTAINER RESULT_REVISIT_ELEMENT
  PASS_VISIT_ELEMENT PASS_REVISIT_ELEMENT

The available tags and their respective imported symbols are:

=over

=item B<all>

Import all symbols.

=item B<results>

 RESULT_RETURN RESULT_CONTINUE
 RESULT_REVISIT_CONTAINER RESULT_REVISIT_ELEMENT

=item B<cycles>

 CYCLE_DIE CYCLE_CONTINUE CYCLE_TRUNCATE

=item B<visits>

 VISIT_CONTAINER VISIT_LEAF VISIT_ALL

=item B<passes>

  PASS_VISIT_ELEMENT PASS_REVISIT_ELEMENT

=item B<constants>

Import tags C<results>, C<cycles>, C<visits>.

=back

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-cxc-data-visitor@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-Data-Visitor>

=head2 Source

Source is available at

  https://gitlab.com/djerius/cxc-data-visitor

and may be cloned from

  https://gitlab.com/djerius/cxc-data-visitor.git

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
