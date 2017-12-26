package Data::Edit::Struct;

# ABSTRACT: Edit a Perl structure addressed with a Data::DPath path

use strict;
use warnings;

use Exporter 'import';

our $VERSION = '0.06';

use Ref::Util qw[
  is_plain_arrayref is_arrayref
  is_plain_hashref  is_hashref
  is_scalarref is_ref is_coderef
];

use Types::Standard -types;
use Data::Edit::Struct::Types -types;

use custom::failures 'Data::Edit::Struct::failure' => [ qw{
      input::dest
      input::src
      input::param
      internal
      } ];

use List::Util qw[ pairmap ];
use Scalar::Util qw[ refaddr ];
use Params::ValidationCompiler qw[ validation_for ];
use Safe::Isa;

use Data::DPath qw[ dpath dpathr dpathi ];

## no critic(ProhibitSubroutinePrototypes)

# uncomment to run coverage tests, as Safe compartment makes
# Devel::Cover whimper
#
# $Data::DPath::USE_SAFE = 0;

our @EXPORT_OK = qw[ edit ];

#---------------------------------------------------------------------

# Params::ValidationCompiler is used to validate the arguments passed
# to the edit subroutine.  These hashes are used to codify validation
# specifications which are used multiple times.

my %dest = (
    dest  => { type => Context },
    dpath => { type => Str, default => '/' },
);

my %dtype = ( dtype => { type => UseDataAs, default => 'auto' }, );

my %source = (
    src   => { type => Any,       optional => 1 },
    spath => { type => Str,       optional => 1 },
    stype => { type => UseDataAs, default  => 'auto' },
    sxfrm => {
	      # ( Enum [] ) | CoderRef rather than Enum[] | CodeRef for
	      # Perl < 5.14
        type => ( Enum [ 'iterate', 'array', 'hash', 'error' ] ) | CodeRef,
        default => 'error'
    },
    sxfrm_args => {
        type    => HashRef,
        default => sub { {} },
    },
    clone => {
        type    => Bool | CodeRef,
        default => 0
    },
);

my %length = ( length => { type => Int, default => 1 } );
my %offset = (
    offset => {
        type    => Int,
        default => 0,
    } );

# %Validation is a dispatch table for validation specifications for
# the available edit actions. It is used below to create separate
# validation routines for them.
my %Validation = (
    pop    => { %dest, %length },
    shift  => { %dest, %length },
    splice => { %dest, %length, %offset, %source, %dtype },
    insert => {
        %dest, %length, %offset, %source, %dtype,
        insert => {
            type => Enum [ 'before', 'after' ],
            default => 'before',
        },
        anchor =>
          { type => Enum [ 'first', 'last', 'index' ], default => 'first' },
        pad => { type => Any, default => undef },
    },
    delete  => { %dest, %length },
    replace => {
        %dest, %source,
        replace => {
            type => Enum [ 'value', 'key', 'auto' ],
            default => 'auto',
        },

    },
);

# %Validator contains the validation routines, keyed off of the edit actions.
my %Validator = map {
    $_ => validation_for(
        params           => $Validation{$_},
        name             => $_,
        name_is_optional => 1,
      )
  }
  keys %Validation;

#---------------------------------------------------------------------

# the primary entry point.
sub edit {

    my ( $action, $params ) = @_;

    Data::Edit::Struct::failure::input::param->throw( "no action specified\n" )
      unless defined $action;

    defined( my $validator = $Validator{$action} )
      or Data::Edit::Struct::failure::input::param->throw(
        "unknown acton: $action\n" );

    my %arg = $validator->( %$params );

    my $src = _sxfrm( @arg{qw[ src spath sxfrm sxfrm_args ]} );

    my $points
      = _dup_context( $arg{dest} )->_search( dpathr( $arg{dpath} ) )
      ->current_points;

    if ( $action eq 'pop' ) {
        _pop( $points, $arg{length} );
    }

    elsif ( $action eq 'shift' ) {
        _shift( $points, $arg{length} );
    }

    elsif ( $action eq 'splice' ) {

        $src = [ \[] ] if ! defined $src;

        _splice( $arg{dtype}, $points, $arg{offset}, $arg{length},
            _deref( $_, $arg{stype}, $arg{clone} ) )
          foreach @$src;
    }

    elsif ( $action eq 'insert' ) {
        Data::Edit::Struct::failure::input::src->throw(
            "source was not specified" )
          if !defined $src;

        _insert( $arg{dtype}, $points, $arg{insert}, $arg{anchor},
            $arg{pad}, $arg{offset}, _deref( $_, $arg{stype}, $arg{clone} ) )
          foreach @$src;
    }

    elsif ( $action eq 'delete' ) {
        _delete( $points, $arg{length} );
    }

    elsif ( $action eq 'replace' ) {

        Data::Edit::Struct::failure::input::src->throw(
            "source was not specified" )
          if !defined $src;

        Data::Edit::Struct::failure::input::src->throw(
            "source path may not have multiple resolutions" )
          if @$src > 1;

        _replace( $points, $arg{replace}, $src->[0] );
    }

    else {
        Data::Edit::Struct::failure::internal->throw(
            "unexpected action: $action" );
    }
}

#---------------------------------------------------------------------

# Searching a Data::DPath::Context object changes it, rather than
# returning a new context as documented. Thus, we need to create
# a new object for each search.
#
# See https://rt.cpan.org/Public/Bug/Display.html?id=120594

sub _dup_context {

    my ( $context ) = @_;

    Data::DPath::Context->new( give_references => 1 )
      ->current_points( $context->current_points );
}

#---------------------------------------------------------------------

# extract source data from the source structure given a Data::Dpath
# path or context and apply any user specified transforms to it.
sub _sxfrm {

    my ( $src, $spath, $sxfrm, $args ) = @_;

    return unless defined $src;

    my $ctx;

    if ( $src->$_isa( 'Data::DPath::Context' ) ) {
        $ctx = _dup_context( $src );
    }
    else {
        if ( !defined $spath ) {

            if (   is_plain_arrayref( $src )
                || is_plain_hashref( $src ) )
            {
                $spath = '/';
            }

            else {
                $src   = [$src];
                $spath = '/*[0]';
            }
        }

        $ctx = dpathi( $src );
        $ctx->give_references( 1 );
    }

    $spath = dpath( $spath );

    if ( is_coderef( $sxfrm ) ) {
        return $sxfrm->( $ctx, $spath, $args );
    }

    elsif ( $sxfrm eq 'array' ) {
        $ctx->give_references( 0 );
        return [ \$ctx->matchr( $spath ) ];
    }

    elsif ( $sxfrm eq 'hash' ) {

        my %src;

        if ( exists $args->{key} ) {

            my $src = $ctx->matchr( $spath );
            Data::Edit::Struct::failure::input::src->throw(
                "source path may not have multiple resolutions\n" )
              if @$src > 1;
            $src{ $args->{key} } = ${ $src->[0] };
        }

        else {

            $ctx->give_references( 0 );
            for my $point ( @{ $ctx->_search( $spath )->current_points } ) {

                my $attrs = $point->attrs;
                defined( my $key = defined $attrs->{key} ? $attrs->{key} : $attrs->{idx} )
                  or Data::Edit::Struct::failure::input::src->throw(
                    "source path returned multiple values; unable to convert into hash as element has no `key' or `idx' attribute\n"
                  );
                $src{$key} = ${ $point->ref };
            }
        }

        return [ \\%src ];
    }

    elsif ( $sxfrm eq 'iterate' ) {

        return $ctx->matchr( $spath );

    }

    else {

        my $src = $ctx->matchr( $spath );
        Data::Edit::Struct::failure::input::src->throw(
            "source path may not have multiple resolutions\n" )
          if @$src > 1;

        return $src;
    }
}

#---------------------------------------------------------------------

# The default cloning algorithm
sub _clone {

    my ( $ref ) = @_;

    require Storable;
    return Storable::dclone( $ref );
}

#---------------------------------------------------------------------

# given a reference to the extracted source data, massage
# it into the final form (e.g., container, element, cloned )
# to be applied to the destination.

sub _deref {

    my ( $ref, $stype, $clone ) = @_;

    $stype = is_plain_arrayref( $$ref )
      || is_plain_hashref( $$ref ) ? 'container' : 'element'
      if $stype eq 'auto';

    my $struct;
    if ( $stype eq 'element' ) {
        $struct = [$$ref];
    }

    elsif ( $stype eq 'container' ) {

        $struct
          = is_arrayref( $$ref ) ? $$ref
          : is_hashref( $$ref )  ? [%$$ref]
          : Data::Edit::Struct::failure::input::src->throw(
            "\$value is not an array or hash reference" );
    }

    else {
        Data::Edit::Struct::failure::internal->throw(
            "internal error: unknown mode to use source in: $_" );
    }

    $clone = \&_clone unless is_coderef( $clone ) || !$clone;

    return
        is_coderef( $clone ) ? $clone->( $struct )
      : $clone               ? _clone( $struct )
      :                        $struct;
}

#---------------------------------------------------------------------

sub _pop {

    my ( $points, $length ) = @_;

    for my $point ( @$points ) {

        my $dest = ${ $point->ref };
        Data::Edit::Struct::failure::input::dest->throw(
            "destination is not an array" )
          unless is_arrayref( $dest );

        $length = @$dest if $length > @$dest;
        splice( @$dest, -$length, $length );

    }
}

#---------------------------------------------------------------------

sub _shift {

    my ( $points, $length ) = @_;

    for my $point ( @$points ) {
        my $dest = ${ $point->ref };
        Data::Edit::Struct::failure::input::dest->throw(
            "destination is not an array" )
          unless is_arrayref( $dest );
        splice( @$dest, 0, $length );
    }
}

#---------------------------------------------------------------------

sub _splice {

    my ( $dtype, $points, $offset, $length, $replace ) = @_;

    for my $point ( @$points ) {

        my $ref;

        my $attrs = $point->can( 'attrs' );

        my $idx = ( ( defined( $attrs ) && $point->$attrs ) ? $point->$attrs : {} )->{idx};

        my $use = $dtype;

        if ( $use eq 'auto' ) {

            $ref = $point->ref;

            $use
              = is_plain_arrayref( $$ref ) ? 'container'
              : defined $idx               ? 'element'
              : Data::Edit::Struct::failure::input::dest->throw(
                "point is neither an array element nor an array ref" );
        }

        if ( $use eq 'container' ) {
            $ref = $point->ref if ! defined $ref;
            Data::Edit::Struct::failure::input::dest->throw(
                "point is not an array reference" )
              unless is_arrayref( $$ref );

            splice( @{ $$ref }, $offset, $length, @$replace );
        }

        elsif ( $use eq 'element' ) {

            my $rparent = $point->parent;
            my $parent
              = defined( $rparent )
              ? $rparent->ref
              : undef;

            Data::Edit::Struct::failure::input::dest->throw(
                "point is not an array element" )
              unless defined $$parent && is_arrayref( $$parent );

            splice( @$$parent, $idx + $offset, $length, @$replace );
        }

        else {
            Data::Edit::Struct::failure::internal->throw(
                "_splice: unknown use: $use" );
        }
    }
}

#---------------------------------------------------------------------

sub _insert {

    my ( $dtype, $points, $insert, $anchor, $pad, $offset, $src ) = @_;

    for my $point ( @$points ) {

        my $ref;
        my $idx;
        my $attrs;

        my $use = $dtype;
        if ( $dtype eq 'auto' ) {

            $ref = $point->ref;

            $use
              = is_plain_arrayref( $$ref )
              || is_plain_hashref( $$ref ) ? 'container'
              : defined( $attrs = $point->can( 'attrs' ) )
              && defined( $idx = $point->attrs->{idx} ) ? 'element'
              : Data::Edit::Struct::failure::input::dest->throw(
                "point is neither an array element nor an array ref" );
        }

        if ( $use eq 'container' ) {

            $ref = $point->ref if ! defined $ref;

            if ( is_hashref( $$ref ) ) {

                Data::Edit::Struct::failure::input::src->throw(
                    "insertion into a hash requires an even number of elements\n"
                ) if @$src % 2;

                pairmap { ; $$ref->{$a} = $b } @$src;
            }

            elsif ( is_arrayref( $$ref ) ) {
                _insert_via_splice( $insert, $anchor, $pad, $ref, 0,
                    $offset, $src );
            }

            else {
                Data::Edit::Struct::failure::input::dest->throw(
                    "can't insert into a reference of type @{[ ref $$ref]}" );
            }
        }

        elsif ( $use eq 'element' ) {
            my $rparent = $point->parent;
            my $parent
              = defined( $rparent )
              ? $rparent->ref
              : undef;

            Data::Edit::Struct::failure::input::dest->throw(
                "point is not an array element" )
              unless defined $parent && is_arrayref( $$parent );

            $idx = ( defined $attrs ? $attrs : $point->attrs )->{idx} if ! defined $idx;

            _insert_via_splice( $insert, 'index', $pad, $parent, $idx,
                $offset, $src );
        }

        else {
            Data::Edit::Struct::failure::internal->throw(
                "_insert: unknown use: $use" );
        }
    }
}

#---------------------------------------------------------------------

sub _insert_via_splice {

    my ( $insert, $anchor, $pad, $rdest, $idx, $offset, $src ) = @_;

    my $fididx;

    if ( $anchor eq 'first' ) {
        $fididx = 0;
    }
    elsif ( $anchor eq 'last' ) {
        $fididx = $#{ $$rdest };
    }
    elsif ( $anchor eq 'index' ) {
        $fididx = $idx;
    }

    else {
        Data::Edit::Struct::failure::internal->throw(
            "unknown insert anchor: $anchor" );
    }

    # turn relative index into positive index
    $idx = $offset + $fididx;

    # make sure there's enough room.
    my $maxidx = $#{ $$rdest };

    if ( $insert eq 'before' ) {

        if ( $idx < 0 ) {
            unshift @{ $$rdest }, ( $pad ) x ( -$idx );
            $idx = 0;
        }

        elsif ( $idx > $maxidx + 1 ) {
            push @{ $$rdest }, ( $pad ) x ( $idx - $maxidx - 1 );
        }
    }

    elsif ( $insert eq 'after' ) {

        if ( $idx < 0 ) {
            unshift @{ $$rdest }, ( $pad ) x ( -$idx - 1 ) if $idx < -1;
            $idx = 0;
        }

        elsif ( $idx > $maxidx ) {
            push @{ $$rdest }, ( $pad ) x ( $idx - $maxidx );
            ++$idx;
        }

        else {
            ++$idx;
        }

    }
    else {
        Data::Edit::Struct::failure::internal->throw(
            "_insert_via_splice: unknown insert point: $insert" );
    }

    splice( @$$rdest, $idx, 0, @$src );
}

#---------------------------------------------------------------------

sub _delete {

    my ( $points, $length ) = @_;

    for my $point ( @$points ) {

        my $rparent = $point->parent;
        my $parent
          = defined( $rparent )
          ? $rparent->ref
          : undef;

        Data::Edit::Struct::failure::input::dest->throw(
            "point is not an element in a container" )
          unless defined $parent;

        my $attr = $point->attrs;

        if ( defined( my $key = $attr->{key} ) ) {
            delete $$parent->{$key};
        }
        elsif ( exists $attr->{idx} ) {

            splice( @$$parent, $attr->{idx}, $length );

        }
        else {
            Data::Edit::Struct::failure::internal->throw(
                "point has neither idx nor key attribute" );
        }

    }

}

#---------------------------------------------------------------------

sub _replace {

    my ( $points, $replace, $src ) = @_;

    for my $point ( @$points ) {

        $replace = 'value'
          if $replace eq 'auto';

        if ( $replace eq 'value' ) {
            ${ $point->ref } = ${ $src };
        }

        elsif ( $replace eq 'key' ) {

            my $rparent = $point->parent;
            my $parent
              = defined( $rparent )
              ? $rparent->ref
              : undef;

            Data::Edit::Struct::failure::input::dest->throw(
                "key replacement requires a hash element\n" )
              unless is_hashref( $$parent );

            my $old_key = $point->attrs->{key};

            my $new_key = is_ref( $$src ) ? refaddr( $$src ) : $$src;

            $$parent->{$new_key} = delete $$parent->{$old_key};
        }
        else {
            Data::Edit::Struct::failure::internal->throw(
                "_replace: unknown replace type: $replace" );
        }
    }
}


1;

#
# This file is part of Data-Edit-Struct
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

=pod

=head1 NAME

Data::Edit::Struct - Edit a Perl structure addressed with a Data::DPath path

=head1 VERSION

version 0.06

=head1 SYNOPSIS

 use Data::Edit::Struct qw[ edit ];
 
 
 my $src  = { foo => 9, bar => 2 };
 my $dest = { foo => 1, bar => [22] };
 
 edit(
     replace => {
         src   => $src,
         spath => '/foo',
         dest  => $dest,
         dpath => '/foo'
     } );
 
 edit(
     insert => {
         src   => $src,
         spath => '/bar',
         dest  => $dest,
         dpath => '/bar'
     } );
 
 # $dest = { foo => 9, bar => [ 2, 22 ] }

=head1 DESCRIPTION

B<Data::Edit::Struct> provides a high-level interface for editing data
within complex data structures.  Edit and source points are specified
via L<Data::DPath> paths.

The I<destination> structure is the structure to be edited.  If data
are to be inserted into the structure, they are extracted from the
I<source> structure.  See L</Data Copying> for the copying policy.

The following actions may be performed on the destination structure:

=over

=item * C<shift> - remove one or more elements from the front of an array

=item * C<pop> - remove one or more elements from the end of an array

=item * C<splice> - invoke C<splice> on an array

=item * C<insert> - insert elements into an array or a hash

=item * C<delete> - delete array or hash elements

=item * C<replace> - replace array or hash elements (and in the latter case keys)

=back

=head2 Elements I<vs.> Containers

B<Data::Edit::Struct> operates on elements in the destination
structure by following a L<Data::DPath> path.  For example, if

 $src  = { dogs => 'rule' };
 $dest = { bar => [ 2, { cats => 'rule' }, 4 ] };

then a data path of

 /bar/*[0]

identifies the first element in the C<bar> array.  That element may be
treated either as a I<container> or as an I<element> (this is
specified by the L</dtype> option).

In the above example, C<< $dest->{bar}[0] >> resolves to a scalar, so
by default it is treated as an element.  However C<< $dest->{bar[1]}
>> resolves to a hashref.  When operating on it, should it be treated
as an opaque object, or as container?  For example,

 edit(
     insert => {
         src   => $src,
         dest  => $dest,
         dpath => '/bar/*[1]',
     } );

Should C<$src> be inserted I<into> element 2, as in

 $dest = { bar => [2, { cats => "rule", dogs => "rule" }, 4] };

or should it be inserted I<before> element 2 in C<bar>, as in?

 $dest = { bar => [2, "dogs", "rule", { cats => "rule" }, 4] };

The first behavior treats it as a I<container>, the second as an
I<element>.  By default destination paths which resolve to hash or
array references are treated as B<containers>, so the above code
generates the first behavior.  To explicitly indicate how a path
should be treated, use the C<< dtype >> option.  For example,

 edit(
     insert => {
         src   => $src,
         dest  => $dest,
         dpath => '/bar/*[1]',
         dtype => 'element',
     } );

results in

 $dest = { bar => [2, "dogs", "rule", { cats => "rule" }, 4] };

Source structures may have the same ambiguity. In the above example,
note that the I<contents> of the hash in the source path are inserted,
not the reference itself.  This is because non-blessed references in
sources are by default considered to be containers, and their contents
are copied.  To treat a source reference as an opaque element, use the
L</stype> option to specify it as such:

 edit(
     insert => {
         src   => $src,
         stype => 'element',
         dest  => $dest,
         dpath => '/bar/*[1]',
         dtype => 'element',
     } );

which results in

 $dest = { bar => [2, { dogs => "rule" }, { cats => "rule" }, 4] };

Note that C<dpath> was set to I<element>, otherwise C<edit> would have
attempted to insert the source hashref (not its contents) into the
destination hash, which would have failed, as insertion into a hash
requires a multiple of two elements (i.e., C<< $key, $value >>).

=head2 Source Transformations

Data extracted from the source structure may undergo transformations
prior to being inserted into the destination structure.  There are
several predefined transformations and the caller may specify a
callback to perform their own.

Most of the transformations have to do with multiple values being
returned by the source path.  For example,

 $src  = { foo => [1], bar => [5], baz => [5] };
 $spath = '/*/*[value == 5]';

would result in multiple extracted values:

 (5, 5)


By default multiple values are not allowed, but a source
transformation (specified by the C<sxfrm> option ) may be used to
change that behavior.  The provided transforms are:

=over

=item C<array>

The values are assembled into an array.  The C<stype>
parameter is used to determine whether that array is treated as a
container or an element.

=item C<hash>

The items are assembled into a hash.  The C<stype> parameter is used
to determine whether that hash is treated as a container or an
element.  Keys are derived from the data:

=over

=item * Keys for hash values will be their hash keys

=item * Keys for array values will be their array indices

=back

If there is a I<single> value, a hash key may be specified via the
C<key> option to the C<sxfrm_args> option.

=item C<iterate>

The edit action is applied independently to each source value in turn.

=item I<coderef>

If C<sxfrm> is a code reference, it will be called to generate the
source values.  See L</Source Callbacks> for more information.

=back

=head2 Source Callbacks

If the C<sxfrm> option is a code reference, it is called to generate
the source values.  It must return an array which contains I<references>
to the values (even if they are already references).  For example,
to return a hash:

  my %src = ( foo => 1 );
  return [ \\%hash ];

It is called with the arguments

=over

=item C<$ctx>

A L</Data::DPath::Context> object representing the source structure.

=item C<$spath>

The source path.  Unless otherwise specified, this defaults to C</>,
I<except> when the source is not a plain array or plain
hash, in which case the source is embedded in an array, and C<spath> is set to C</*[0]>.

This is because L</Data::DPath> requires a container to be at the root
of the source structure, and anything other than a plain array or hash
is most likely a blessed object or a scalar, both of which should be
treated as elements.

=item C<$args>

The value of the C<sxfrm_args> option.

=back

=head2 Data Copying

By defult, copying of data from the source structure is done
I<shallowly>, e.g. references to arrays or hashes are not copied
recursively.  This may cause problems if further modifications are
made to the destination structure which may, through references,
alter the source structure.

For example, given the following input structures:

 $src  = { dogs => { say => 'bark' } };
 $dest = { cats => { say => 'meow' } };

and this edit operation:

 edit(
     insert => {
 	       src  => $src,
 	       dest => $dest,
     } );

We get a destination structure that looks like this:

 $dest = { cats => { say => "meow" }, dogs => { say => "bark" } };

But if later we change C<$dest>,

 # dogs are more excited now
 $dest->{dogs}{say} = 'howl';

the source structure is also changed:

 $src = { dogs => { say => "howl" } };

To avoid this possible problem, C<Data::Edit::Struct> can be passed
the L<< C<clone>|/clone >> option, which will instruct it how to
copy data.

=head1 SUBROUTINES

=head2 edit ( $action, $params )

Edit a data structure.  The available actions are discussed below.

Destination structure parameters are:

=over

=item C<dest>

A reference to a structure or a L<< Data::DPath::Context >> object.

=item C<dpath>

A string representing the data path. This may result in multiple
extracted values from the structure; the action will be applied to
each in turn.

=item C<dtype>

May be C<auto>, C<element> or C<container>, to treat the extracted
values either as elements or containers.  If C<auto>, non-blessed
arrays and hashes are treated as containers.

=back

Some actions require a source structure; parameters related
to that are:

=over

=item C<src>

A reference to a structure or a L<Data::DPath::Context> object.

=item C<spath>

A string representing the source path. This may result in multiple
extracted values from the structure; the C<sxfrm> option provides
the context for how to interpret these values.

=item C<stype>

May be C<auto>, C<element> or C<container>, to treat the extracted
values either as elements or containers.  If C<auto>, non-blessed
arrays and hashes are treated as containers.

=item C<sxfrm>

A transformation to be applied to the data extracted from the
source. The available values are

=over

=item C<array>

=item C<hash>

=item C<iterate>

=item I<coderef>

=back

See L</Source Transformations> for more information.

=item C<clone>

This may be a boolean or a code reference.  If a boolean, and true,
L<Storable/dclone> is used to clone the source structure.  If set to a
code reference, it is called with a I<reference> to the structure to
be cloned.  It should return a I<reference> to the cloned structure.

=back

Actions may have additional parameters

=head3 C<pop>

Remove one or more elements from the end of an array.  The destination
structure must be an array. Additional parameters are:

=over

=item C<length>

The number of elements to remove.  Defaults to C<1>.

=back

=head3 C<shift>

Remove one or more elements from the front of an array.  The
destination structure must be an array. Additional parameters are:

=over

=item C<length>

The number of elements to remove.  Defaults to C<1>.

=back

=head3 C<splice>

Perform a L<splice|perlfunc/splice> operation on an array, e.g.

  splice( @$dest, $offset, $length, @$src );

The C<$offset> and C<$length> parameters are provided by the C<offset>
and C<length> options.

The destination structure may be an array or an array element.  In the
latter case, the actual offset passed to splice is the sum of the
index of the array element and the value provided by the C<offset>
option.

A source structure is optional, and may be an array or a hash.

=head3 C<insert>

Insert a source structure into the destination structure.  The result
depends upon whether the point at which to insert is to be treated as
a container or an element.

=over

=item container

=over

=item Hash

If the container is a hash, the source must be a container (either
array or hash), and must contain an even number of elements.  Each
sequential pair of values is treated as a key, value pair.

=item Array

If the container is an array, the source may be either a container or
an element. The following options are available:

=over

=item C<offset>

The offset into the array of the insertion point.  Defaults to C<0>.
See L</anchor>.

=item C<anchor>

Indicates which end of the array the C<offset> parameter is relative to.
May be C<first> or C<last>.  It defaults to C<first>.

=item C<pad>

If the array must be enlarged to accomodate the specified insertion point, fill the new
values with this value.  Defaults to C<undef>.

=item C<insert>

Indicates which side of the insertion point data will be inserted. May
be either C<before> or C<after>.  It defaults to C<before>.

=back

=back

=item element

The insertion point must be an array value. The source may be either a
container or an element. The following options are avaliable:

=over

=item C<offset>

Move the insertion point by this value.

=item C<pad>

If the array must be enlarged to accomodate the specified insertion point, fill the new
values with this value.  Defaults to C<undef>.

=item C<insert>

Indicates which side of the insertion point data will be inserted. May
be either C<before> or C<after>.  It defaults to C<before>.

=back

=back

=head2 C<delete>

Remove an array or hash value.

=head2 C<replace>

Replace an array or hash element, or a hash key. The source data is
always treated as an element. It takes the following options:

=over

=item C<replace>

Indicates which part of a hash element to replace, either C<key> or
C<value>.  Defaults to C<value>.  If replacing the key and the source
value is a reference, the value returned by
L<Scalar::Util::refaddr|Scalar::Util/reffadr> will be used.

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

__END__


#pod =head1 SYNOPSIS
#pod
#pod # EXAMPLE: ./examples/synopsis.pl
#pod
#pod =head1 DESCRIPTION
#pod
#pod B<Data::Edit::Struct> provides a high-level interface for editing data
#pod within complex data structures.  Edit and source points are specified
#pod via L<Data::DPath> paths.
#pod
#pod The I<destination> structure is the structure to be edited.  If data
#pod are to be inserted into the structure, they are extracted from the
#pod I<source> structure.  See L</Data Copying> for the copying policy.
#pod
#pod The following actions may be performed on the destination structure:
#pod
#pod =over
#pod
#pod =item  * C<shift> - remove one or more elements from the front of an array
#pod
#pod =item  * C<pop> - remove one or more elements from the end of an array
#pod
#pod =item  * C<splice> - invoke C<splice> on an array
#pod
#pod =item  * C<insert> - insert elements into an array or a hash
#pod
#pod =item  * C<delete> - delete array or hash elements
#pod
#pod =item  * C<replace> - replace array or hash elements (and in the latter case keys)
#pod
#pod =back
#pod
#pod =head2 Elements I<vs.> Containers
#pod
#pod B<Data::Edit::Struct> operates on elements in the destination
#pod structure by following a L<Data::DPath> path.  For example, if
#pod
#pod # EXAMPLE: ./examples/ex1_0.pl
#pod
#pod then a data path of
#pod
#pod  /bar/*[0]
#pod
#pod identifies the first element in the C<bar> array.  That element may be
#pod treated either as a I<container> or as an I<element> (this is
#pod specified by the L</dtype> option).
#pod
#pod In the above example, C<< $dest->{bar}[0] >> resolves to a scalar, so
#pod by default it is treated as an element.  However C<< $dest->{bar[1]}
#pod >> resolves to a hashref.  When operating on it, should it be treated
#pod as an opaque object, or as container?  For example,
#pod
#pod # EXAMPLE: ./examples/ex1_1.pl
#pod
#pod Should C<$src> be inserted I<into> element 2, as in
#pod
#pod # COMMAND: perl ./examples/run ex1_0.pl ex1_1.pl  dump_dest.pl
#pod
#pod or should it be inserted I<before> element 2 in C<bar>, as in?
#pod
#pod # COMMAND: perl ./examples/run ex1_0.pl ex1_2.pl  dump_dest.pl
#pod
#pod The first behavior treats it as a I<container>, the second as an
#pod I<element>.  By default destination paths which resolve to hash or
#pod array references are treated as B<containers>, so the above code
#pod generates the first behavior.  To explicitly indicate how a path
#pod should be treated, use the C<< dtype >> option.  For example,
#pod
#pod # EXAMPLE: ./examples/ex1_2.pl
#pod
#pod results in
#pod
#pod # COMMAND: perl ./examples/run ex1_0.pl ex1_2.pl  dump_dest.pl
#pod
#pod Source structures may have the same ambiguity. In the above example,
#pod note that the I<contents> of the hash in the source path are inserted,
#pod not the reference itself.  This is because non-blessed references in
#pod sources are by default considered to be containers, and their contents
#pod are copied.  To treat a source reference as an opaque element, use the
#pod L</stype> option to specify it as such:
#pod
#pod # EXAMPLE: ./examples/ex1_3.pl
#pod
#pod which results in
#pod
#pod # COMMAND: perl ./examples/run ex1_0.pl ex1_3.pl  dump_dest.pl
#pod
#pod Note that C<dpath> was set to I<element>, otherwise C<edit> would have
#pod attempted to insert the source hashref (not its contents) into the
#pod destination hash, which would have failed, as insertion into a hash
#pod requires a multiple of two elements (i.e., C<< $key, $value >>).
#pod
#pod =head2 Source Transformations
#pod
#pod Data extracted from the source structure may undergo transformations
#pod prior to being inserted into the destination structure.  There are
#pod several predefined transformations and the caller may specify a
#pod callback to perform their own.
#pod
#pod Most of the transformations have to do with multiple values being
#pod returned by the source path.  For example,
#pod
#pod # EXAMPLE: ./examples/sxfrm1_0.pl
#pod
#pod would result in multiple extracted values:
#pod
#pod # COMMAND: perl ./examples/run examples/sxfrm1_0.pl  examples/sxfrm1_1.pl
#pod
#pod By default multiple values are not allowed, but a source
#pod transformation (specified by the C<sxfrm> option ) may be used to
#pod change that behavior.  The provided transforms are:
#pod
#pod =over
#pod
#pod =item C<array>
#pod
#pod The values are assembled into an array.  The C<stype>
#pod parameter is used to determine whether that array is treated as a
#pod container or an element.
#pod
#pod =item C<hash>
#pod
#pod The items are assembled into a hash.  The C<stype> parameter is used
#pod to determine whether that hash is treated as a container or an
#pod element.  Keys are derived from the data:
#pod
#pod =over
#pod
#pod =item * Keys for hash values will be their hash keys
#pod
#pod =item * Keys for array values will be their array indices
#pod
#pod =back
#pod
#pod If there is a I<single> value, a hash key may be specified via the
#pod C<key> option to the C<sxfrm_args> option.
#pod
#pod =item C<iterate>
#pod
#pod The edit action is applied independently to each source value in turn.
#pod
#pod
#pod =item I<coderef>
#pod
#pod If C<sxfrm> is a code reference, it will be called to generate the
#pod source values.  See L</Source Callbacks> for more information.
#pod
#pod =back
#pod
#pod
#pod =head2 Source Callbacks
#pod
#pod If the C<sxfrm> option is a code reference, it is called to generate
#pod the source values.  It must return an array which contains I<references>
#pod to the values (even if they are already references).  For example,
#pod to return a hash:
#pod
#pod   my %src = ( foo => 1 );
#pod   return [ \\%hash ];
#pod
#pod It is called with the arguments
#pod
#pod =over
#pod
#pod =item C<$ctx>
#pod
#pod
#pod A L</Data::DPath::Context> object representing the source structure.
#pod
#pod =item C<$spath>
#pod
#pod The source path.  Unless otherwise specified, this defaults to C</>,
#pod I<except> when the source is not a plain array or plain
#pod hash, in which case the source is embedded in an array, and C<spath> is set to C</*[0]>.
#pod
#pod This is because L</Data::DPath> requires a container to be at the root
#pod of the source structure, and anything other than a plain array or hash
#pod is most likely a blessed object or a scalar, both of which should be
#pod treated as elements.
#pod
#pod =item C<$args>
#pod
#pod The value of the C<sxfrm_args> option.
#pod
#pod =back
#pod
#pod =head2 Data Copying
#pod
#pod By defult, copying of data from the source structure is done
#pod I<shallowly>, e.g. references to arrays or hashes are not copied
#pod recursively.  This may cause problems if further modifications are
#pod made to the destination structure which may, through references,
#pod alter the source structure.
#pod
#pod For example, given the following input structures:
#pod
#pod # EXAMPLE: ./examples/copy1_0.pl
#pod
#pod and this edit operation:
#pod
#pod # EXAMPLE: ./examples/copy1_1.pl
#pod
#pod We get a destination structure that looks like this:
#pod
#pod # COMMAND: perl ./examples/run copy1_0.pl copy1_1.pl  dump_dest.pl
#pod
#pod But if later we change C<$dest>,
#pod
#pod # EXAMPLE: ./examples/copy1_2.pl
#pod
#pod the source structure is also changed:
#pod
#pod # COMMAND: perl ./examples/run copy1_0.pl copy1_1.pl  copy1_2.pl dump_src.pl
#pod
#pod To avoid this possible problem, C<Data::Edit::Struct> can be passed
#pod the L<< C<clone>|/clone >> option, which will instruct it how to
#pod copy data.
#pod
#pod
#pod =head1 SUBROUTINES
#pod
#pod =head2  edit ( $action, $params )
#pod
#pod Edit a data structure.  The available actions are discussed below.
#pod
#pod Destination structure parameters are:
#pod
#pod =over
#pod
#pod =item C<dest>
#pod
#pod A reference to a structure or a L<< Data::DPath::Context >> object.
#pod
#pod =item C<dpath>
#pod
#pod A string representing the data path. This may result in multiple
#pod extracted values from the structure; the action will be applied to
#pod each in turn.
#pod
#pod =item C<dtype>
#pod
#pod May be C<auto>, C<element> or C<container>, to treat the extracted
#pod values either as elements or containers.  If C<auto>, non-blessed
#pod arrays and hashes are treated as containers.
#pod
#pod =back
#pod
#pod Some actions require a source structure; parameters related
#pod to that are:
#pod
#pod =over
#pod
#pod =item C<src>
#pod
#pod A reference to a structure or a L<Data::DPath::Context> object.
#pod
#pod =item C<spath>
#pod
#pod A string representing the source path. This may result in multiple
#pod extracted values from the structure; the C<sxfrm> option provides
#pod the context for how to interpret these values.
#pod
#pod =item C<stype>
#pod
#pod May be C<auto>, C<element> or C<container>, to treat the extracted
#pod values either as elements or containers.  If C<auto>, non-blessed
#pod arrays and hashes are treated as containers.
#pod
#pod =item C<sxfrm>
#pod
#pod A transformation to be applied to the data extracted from the
#pod source. The available values are
#pod
#pod =over
#pod
#pod =item C<array>
#pod
#pod =item C<hash>
#pod
#pod =item C<iterate>
#pod
#pod =item I<coderef>
#pod
#pod =back
#pod
#pod See L</Source Transformations> for more information.
#pod
#pod =item C<clone>
#pod
#pod This may be a boolean or a code reference.  If a boolean, and true,
#pod L<Storable/dclone> is used to clone the source structure.  If set to a
#pod code reference, it is called with a I<reference> to the structure to
#pod be cloned.  It should return a I<reference> to the cloned structure.
#pod
#pod =back
#pod
#pod Actions may have additional parameters
#pod
#pod =head3 C<pop>
#pod
#pod Remove one or more elements from the end of an array.  The destination
#pod structure must be an array. Additional parameters are:
#pod
#pod
#pod =over
#pod
#pod =item C<length>
#pod
#pod The number of elements to remove.  Defaults to C<1>.
#pod
#pod =back
#pod
#pod
#pod =head3 C<shift>
#pod
#pod Remove one or more elements from the front of an array.  The
#pod destination structure must be an array. Additional parameters are:
#pod
#pod
#pod =over
#pod
#pod =item C<length>
#pod
#pod The number of elements to remove.  Defaults to C<1>.
#pod
#pod =back
#pod
#pod
#pod =head3 C<splice>
#pod
#pod Perform a L<splice|perlfunc/splice> operation on an array, e.g.
#pod
#pod   splice( @$dest, $offset, $length, @$src );
#pod
#pod The C<$offset> and C<$length> parameters are provided by the C<offset>
#pod and C<length> options.
#pod
#pod The destination structure may be an array or an array element.  In the
#pod latter case, the actual offset passed to splice is the sum of the
#pod index of the array element and the value provided by the C<offset>
#pod option.
#pod
#pod A source structure is optional, and may be an array or a hash.
#pod
#pod =head3 C<insert>
#pod
#pod Insert a source structure into the destination structure.  The result
#pod depends upon whether the point at which to insert is to be treated as
#pod a container or an element.
#pod
#pod =over
#pod
#pod =item container
#pod
#pod =over
#pod
#pod =item Hash
#pod
#pod If the container is a hash, the source must be a container (either
#pod array or hash), and must contain an even number of elements.  Each
#pod sequential pair of values is treated as a key, value pair.
#pod
#pod =item Array
#pod
#pod If the container is an array, the source may be either a container or
#pod an element. The following options are available:
#pod
#pod =over
#pod
#pod =item C<offset>
#pod
#pod The offset into the array of the insertion point.  Defaults to C<0>.
#pod See L</anchor>.
#pod
#pod =item C<anchor>
#pod
#pod Indicates which end of the array the C<offset> parameter is relative to.
#pod May be C<first> or C<last>.  It defaults to C<first>.
#pod
#pod =item C<pad>
#pod
#pod If the array must be enlarged to accomodate the specified insertion point, fill the new
#pod values with this value.  Defaults to C<undef>.
#pod
#pod =item C<insert>
#pod
#pod Indicates which side of the insertion point data will be inserted. May
#pod be either C<before> or C<after>.  It defaults to C<before>.
#pod
#pod =back
#pod
#pod =back
#pod
#pod =item element
#pod
#pod The insertion point must be an array value. The source may be either a
#pod container or an element. The following options are avaliable:
#pod
#pod =over
#pod
#pod =item C<offset>
#pod
#pod Move the insertion point by this value.
#pod
#pod =item C<pad>
#pod
#pod If the array must be enlarged to accomodate the specified insertion point, fill the new
#pod values with this value.  Defaults to C<undef>.
#pod
#pod =item C<insert>
#pod
#pod Indicates which side of the insertion point data will be inserted. May
#pod be either C<before> or C<after>.  It defaults to C<before>.
#pod
#pod =back
#pod
#pod =back
#pod
#pod =head2 C<delete>
#pod
#pod Remove an array or hash value.
#pod
#pod =head2 C<replace>
#pod
#pod Replace an array or hash element, or a hash key. The source data is
#pod always treated as an element. It takes the following options:
#pod
#pod =over
#pod
#pod
#pod =item C<replace>
#pod
#pod Indicates which part of a hash element to replace, either C<key> or
#pod C<value>.  Defaults to C<value>.  If replacing the key and the source
#pod value is a reference, the value returned by
#pod L<Scalar::Util::refaddr|Scalar::Util/reffadr> will be used.
#pod
#pod =back
