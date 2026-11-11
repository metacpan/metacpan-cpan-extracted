package Config::XrmDatabase;

# ABSTRACT: Pure Perl X Resource Manager Database

use v5.26;
use warnings;

our $VERSION = '0.09';

use Feature::Compat::Try;

use Config::XrmDatabase::Failure ':all';
use Config::XrmDatabase::Util ':all';
use Config::XrmDatabase::Types -all;
use Types::Standard qw( Object Str Optional HashRef );
use Type::Params    qw( compile_named );
use Ref::Util;

use Moo;

use namespace::clean;

use MooX::StrictConstructor;

use experimental qw( signatures postderef declared_refs refaliasing );
use if $] >= 5.034, 'experimental', 'try';

has _db => (
    is       => 'rwp',
    init_arg => undef,
    default  => sub { {} },
);

has _query_return_value => (
    is       => 'ro',
    isa      => QueryReturnValue,
    init_arg => 'query_return_value',
    coerce   => 1,
    default  => 'value',
);

has _query_on_failure => (
    is       => 'ro',
    isa      => OnQueryFailure,
    init_arg => 'query_on_failure',
    coerce   => 1,
    default  => 'undef',
);

# fake attribute so we can use MooX::StrictConstructor
has _insert => (
    is        => 'ro',
    isa       => HashRef,
    init_arg  => 'insert',
    predicate => 1,
    clearer   => 1,
);


































sub BUILD ( $self, $ ) {
    if ( $self->_has_insert ) {
        my $kv = $self->_insert;
        $self->insert( $_, $kv->{$_} ) for keys %$kv;
        $self->_clear_insert;
    }
}















sub insert ( $self, $name, $value ) {

    $name = parse_resource_name( $name );
    my $db = $self->_db;
    $db                   = $db->{$_} //= {} for $name->@*;
    $db->{ +VALUE }       = $value;
    $db->{ +MATCH_COUNT } = 0;
}




































































































no namespace::clean;
use constant {
    QUERY_RETURN_VALUE     => 'value',
    QUERY_RETURN_REFERENCE => 'reference',
    QUERY_RETURN_ALL       => 'all',
    QUERY_ON_FAILURE_THROW => 'throw',
    QUERY_ON_FAILURE_UNDEF => 'undef',
};
use namespace::clean;

# recursive query helper.  The query method is a front-end.
my sub _query ( $db, $idx, $class, $name, $match, $return_all ) {

    my $is_last_level = $idx + 1 == @$name;

    # this level's component may be bound directly ('.') or via a '*'
    # which matches zero components.
    my @parents = ( [$db], $db->{ +LOOSE } ? [ $db->{ +LOOSE }, LOOSE ] : () );

    # name·.  >  name·*  >  class·.  >  class·*  >  ?·.  >  ?·*
    # ('?' can't be the last component)
    for my $component ( $name->[$idx], $class->[$idx], $is_last_level ? () : SINGLE ) {
        for my $parent ( @parents ) {
            my ( $subdb, @binding ) = @$parent;
            my $entry = $subdb->{$component} // next;

            push $match->@*, @binding, $component;

            if ( !$is_last_level ) {
                my $res = __SUB__->( $entry, $idx + 1, $class, $name, $match, $return_all );
                return $res if defined $res;
            }
            elsif ( exists $entry->{ +VALUE } ) {
                ++$entry->{ +MATCH_COUNT };
                my $value = $entry->{ +VALUE };
                return $return_all
                  ? {
                    value       => $value,
                    match_count => $entry->{ +MATCH_COUNT },
                    key         => $match,
                  }
                  : \$value;
            }

            splice $match->@*, -( 1 + @binding );
        }
    }

    # '*' which matches one or more components
    if ( !$is_last_level and my $subdb = $db->{ +LOOSE } ) {
        push $match->@*, LOOSE;
        for my $next ( $idx + 1 .. $#$name ) {
            my $res = __SUB__->( $subdb, $next, $class, $name, $match, $return_all );
            return $res if defined $res;
        }
        pop $match->@*;
    }

    return undef;
}

sub query ( $self, $class, $name, %iopt ) {

    state $check = compile_named(
        { head => [ Str, Str ] },
        return_value => Optional [QueryReturnValue],
        on_failure   => Optional [OnQueryFailure],
    );

    ( $class, $name, my \%opt ) = $check->( $class, $name, %iopt );

    $opt{on_failure}   //= $self->_query_on_failure;
    $opt{return_value} //= $self->_query_return_value;

    ( $class, $name ) = map { parse_fq_resource_name( $_ ) } $class, $name;

    components_failure->throw( 'class and name must have the same number of components' )
      if @$class != @$name;

    my $return_all = $opt{return_value} eq QUERY_RETURN_ALL;

    my $match  = [];
    my $retval = _query( $self->_db, 0, $class, $name, $match, $return_all );

    if ( !defined $retval ) {
        return $opt{on_failure}->( $name, $class )
          if Ref::Util::is_coderef( $opt{on_failure} );

        query_failure->throw(
            "unable to match name: '@{[ name_arr_to_str($name) ]} '; class : '@{[ name_arr_to_str($class) ]}'" )
          if $opt{on_failure} eq QUERY_ON_FAILURE_THROW;

        return undef;
    }

    return $opt{return_value} eq QUERY_RETURN_VALUE ? $$retval : $retval;
}




















sub read_file ( $class, $file, %opts ) {

    my $self = $class->new( %opts );

    require File::Slurper;

    my @lines;

    try {
        @lines = File::Slurper::read_lines( $file );
    }
    catch ( $e ) {
        file_failure->throw( "$e: error opening $file: $!" );
    }

    my $idx = 0;
    for my $line ( @lines ) {
        ++$idx;
        my ( $var, $value ) = $line =~ /^\s*([^:]+?)\s*:\s*(.*?)\s*$/;
        file_failure->throw( sprintf( '%s:%d: unable to parse line', $file, $idx ) )
          unless defined $var and defined $value;
        $self->insert( $var, $value );
    }

    return $self;
}










sub write_file ( $self, $file ) {
    require File::Slurper;
    File::Slurper::write_text( $file, $self->to_string );
}
















sub to_string ( $self ) {

    my $folded = $self->_folded;
    my @records;

    for my $key ( keys $folded->%* ) {
        my $value = $folded->{$key};

        if ( $key =~ /^(?<key>.*)[.](?<component>${META_QR})$/ ) {
            next unless $+{component} eq VALUE;
            $key = $+{key};
        }

        push @records, "$key : $value";
    }

    return @records ? join( "\n", @records, q{} ) : q{};
}












sub merge ( $self, $other ) {

    require Hash::Merge;
    my $merger = Hash::Merge->new( 'RIGHT_PRECEDENT' );

    $self->_db->%* = $merger->merge( $self->TO_HASH->{db}, $other->TO_HASH->{db} )->%*;

    return $self;
}










sub clone ( $self ) {
    require Scalar::Util;

    my \%args = $self->TO_HASH;
    my $db    = delete $args{db};                                # this isn't a constructor argument.
    my $clone = Scalar::Util::blessed( $self )->new( \%args );
    $clone->_set__db( $db );
    return $clone;
}




























































my %KV_CONSTANTS;
BEGIN {
    %KV_CONSTANTS = ( map { uc( "KV_$_" ) => $_ } qw( all string array value match_count ) );

}
use constant \%KV_CONSTANTS;


sub _to_kv_xx ( $self, %iopt ) {
    %iopt = ( key => KV_STRING, value => KV_VALUE, %iopt );

    state $match = {
        ## no critic (ComplexRegexes)
        value => qr/^(?<match> @{[ join '|', KV_VALUE, KV_MATCH_COUNT, KV_ALL ]} )$/xi,
        key   => qr/^(?<match> @{[ join '|', KV_STRING, KV_ARRAY ]} )$/xi,
    };

    ## no critic (ComplexMappings)
    my %opt = map {
        parameter_failure->throw( "illegal value for '$_' option: $iopt{$_}" )
          unless $iopt{$_} =~ $match->{$_};
        $_ => $+{match};
    } qw( key value );

    parameter_failure->throw( "illegal option: $_" ) for grep !defined $opt{$_}, keys %iopt;

    # don't clean out excess TIGHT characters if we'll need to later
    # split it into components.  otherwise we'd have to run
    # parse_resource_name all over again.
    my $normalize_keys = $opt{key} eq KV_STRING;
    my $folded         = $self->_folded( $normalize_keys );

    # first get values
    # return single requested value
    if ( my $component = $RMETA{ $opt{value} } ) {

        for my $key ( keys $folded->%* ) {
            if ( $key =~ /^(?<key>.*)[.](?<component>${META_QR})$/ ) {
                # only allow the requested data out
                my $value = delete $folded->{$key};
                $folded->{ $+{key} } = $value
                  if $+{component} eq $component;
            }
        }
    }

    elsif ( $opt{value} eq KV_ALL ) {

        for my $key ( keys $folded->%* ) {
            if ( $key =~ /^(?<key>.*)[.](?<component>${META_QR})$/ ) {
                ( $folded->{ $+{key} } //= {} )->{ $META{ $+{component} } }
                  = delete $folded->{$key};
            }
        }
    }

    # shouldn't get here
    else {
        internal_failure->throw( "internal error: unexpected value for 'value': $iopt{value}" );
    }

    return $folded
      if $opt{key} eq KV_STRING;

    return [ map { [ [ split( /[.]/ ) ], $folded->{$_} ] } keys $folded->%* ]
      if $opt{key} eq KV_ARRAY;

    internal_failure->throw( "internal error: unexpected value for 'key': $iopt{key}" );
}









































sub to_kv ( $self, %opt ) {
    $self->_to_kv_xx( %opt, key => 'string' );
}













































sub to_kv_arr ( $self, %opt ) {
    $self->_to_kv_xx( %opt, key => 'array' );
}














sub TO_HASH ( $self ) {
    require Storable;

    {
        query_return_value => $self->_query_return_value,
        query_on_failure   => $self->_query_on_failure,
        db                 => Storable::dclone( $self->_db ),
    };
}









sub _folded ( $self, $normalize_names = 1 ) {

    # Hash::Fold is overkill
    require Hash::Fold;
    my $folded = Hash::Fold->new( delimiter => q{.} )->fold( $self->TO_HASH->{db} );

    return $folded unless $normalize_names;

    for my $key ( keys %$folded ) {
        my $nkey = normalize_key( $key );
        $folded->{$nkey} = delete $folded->{$key};
    }

    return $folded;
}






1;

#
# This file is part of Config-XrmDatabase
#
# This software is Copyright (c) 2021 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory Xrm XrmDB unparseable

=head1 NAME

Config::XrmDatabase - Pure Perl X Resource Manager Database

=head1 VERSION

version 0.09

=head1 SYNOPSIS

  $db = Config::XrmDatabase->new;
  $db->insert( '*b.c.d', 'v1' );
  $db->query( 'A.B.C.D', 'a.b.c.d' );

=head1 DESCRIPTION

This is a pure Perl implementation of the X Window Resource Manager
Database (XrmDB).  It allows creation and manipulation of Xrm
compliant databases.

B<Warning!> The XrmDB refers to names and resources.  These days they
are more typically called keys and values.  The terminology used below
(and sometimes in the names of subroutines and methods) mixes these
two approaches, sometimes a bit too liberally.

The XrmDB differs from typical key-value stores in that a stored key
may be only partially specified, so that a single entry can provide
the value for many different queries.

=head2 Keys

A key is a sequence of I<components> (such as C<editor>, C<toolbar>,
and C<foreground>) separated by I<bindings>.  A binding says how the
components on either side of it are related:

=over

=item C<.>

The next component must follow immediately.  C<editor.foreground>
matches only C<editor.foreground>.

=item C<*>

Any number of components, I<including none>, may come between.
C<editor*foreground> matches C<editor.foreground>,
C<editor.toolbar.foreground>, C<editor.toolbar.save.foreground>, and
so on.

=back

A key which begins with C<*> may match starting at any level:
C<*foreground> matches C<foreground>, C<toolbar.foreground>, and
C<editor.toolbar.save.foreground>.  A key which doesn't begin with a
binding must match starting at the first level.

Separately from bindings, a component may be the placeholder C<?>,
which stands for exactly one component, whatever it is.
C<editor.?.foreground> matches C<editor.toolbar.foreground> and
C<editor.menu.foreground>, but not C<editor.foreground> or
C<editor.toolbar.save.foreground>.

C<?> and C<*> are easily confused.  C<?> I<is> a component, and always
takes the place of exactly one level.  C<*> is a binding; it sits
I<between> components and can span any number of levels, including
none.

The last component of a key must be a name or class component; a key
may not end in C<?> or in a binding.  A key containing neither C<?>
nor C<*> is I<fully qualified>.

(N.B., the X Window System documentation calls C<.> a I<tight> binding and
C<*> a I<loose> binding.)

=head2 Names and classes

Each key that is queried has a I<class>, a parallel key with the same
number of components.  Classes provide a second way of addressing a
key: a stored key may refer to a level by the name's component or by
the class's component.  A class essentially creates a namespace, so
that values can be assigned based on which namespace a key belongs to
rather than on the content of the key.

Let's say that you have a number of keys that end in C<Foreground>:

  a.b.c.Foreground
  d.e.f.Foreground
  x.y.z.Foreground

and you want to set a value for any keys which end in C<Foreground>:

  *Foreground : 'yellow'

To give each one its own value:

  a.b.c.Foreground : 'red'
  d.e.f.Foreground : 'blue'
  x.y.z.Foreground : 'green'

Let's say that C<a.b.c.Foreground> and C<d.e.f.Foreground> are in the
same class, C<U.V.W.Foreground>, and all keys in that class should
have the same value:

  U.V.W.Foreground : 'red'
  x.y.z.Foreground : 'green'

At some point, a new hierarchy of keys that begin with C<g> is added
to that class, but they should have a different value:

  g.V.W.Foreground : 'magenta'

You could try this:

  g.?.?.Foreground : 'magenta'

But that would affect I<all> keys that begin with C<g>, not just those
in that class.

Classes help bring some order, but this system can become very
confusing if some discipline isn't maintained.

=head2 Matching

L</query> is given a fully qualified name and its fully qualified
class, which must have the same number of components.  They are
compared with the stored keys one level at a time, from left to
right.  A stored key's component matches a level if it is the name's
component, the class's component, or C<?>; alternatively, a C<*> in
the stored key may span the level.

More than one stored key may match a query.  When that happens,
precedence rules choose the one whose value is returned.

=head3 Precedence at a single level

Consider a query for the name C<editor.toolbar.save.foreground> with
the class C<Editor.Box.Button.Foreground>.  Each of the following keys
matches it.  They differ only in how they match the third level (name
C<save>, class C<Button>), and are listed from highest to lowest
precedence:

=over

=item 1.

The name, immediately following the previous level

  editor.toolbar.save.foreground

=item 2.

The name, following a C<*> which spans no components

  editor.toolbar*save.foreground

=item 3.

The class, immediately following the previous level

  editor.toolbar.Button.foreground

=item 4.

The class, following a C<*> which spans no components

  editor.toolbar*Button.foreground

=item 5.

C<?>, immediately following the previous level

  editor.toolbar.?.foreground

=item 6.

C<?>, following a C<*> which spans no components

  editor.toolbar*?.foreground

=item 7.

The level is spanned by a C<*>, so the key has no component there

  editor.toolbar*foreground

=back

In other words:

=over

=item *

Any component that matches the level (name, class, or C<?>) beats
spanning the level with a C<*>.

=item *

A name beats a class, and a class beats C<?>, regardless of the
binding which precedes them.

=item *

Between two otherwise equal matches, a component which immediately
follows the previous level (C<.>) beats one which follows a C<*>.

=back

Note that a C<*> which spans no components does not cause a level to
be skipped.  In rules 2, 4, and 6, the key still has a component at
the third level, and it is that component which is compared.

=head3 Precedence across levels

Levels are compared from left to right, and the first level at which
two keys differ decides between them; later levels matter only if all
earlier ones are the same.  For example, using the same query of name
C<editor.toolbar.save.foreground> with class
C<Editor.Box.Button.Foreground>:

  editor*save.foreground
  editor.toolbar.?.foreground

the second key wins.  At the second level it matches C<toolbar> by
name (rule 1), while the first key spans that level with a C<*> (rule
7).  That the first key matches C<save> by name at the third level,
while the second key only matches it with C<?>, doesn't matter.

Similarly, of

  Editor.toolbar.save.foreground
  editor*foreground

the second key wins, even though the first is much more specific.  At
the first level, C<editor> matches by name (rule 1), while C<Editor>
only matches by class (rule 3).

=head1 CLASS METHODS

=head2 new

  $db = Config::XrmDatabase->new( \%args );

Construct and return a new database.

Available constructor arguments are:

=over

=item C<query_return_value> I<string>

Set the default value for the L</query> method's C<return_value>
parameter.  It defaults to the string C<value>.  See L</query> for
more details.

=item C<query_on_failure> I<string> | I<coderef>

Set the default value for the L</query> method's C<on_failure>
parameter.  It defaults to the string C<undef>.  See L</query> for
more details.

=item C<insert> I<hash>

Populate the database with the provided key-value pairs.

=back

=head2 read_file

  $db = Config::XrmDatabase->read_file( $file, %opts );

Create a database from a simplified version of the X Resource Manager
database file. Each record is a single line of the form

  key : value

Whitespace around the key and the value is removed.  Blank lines,
comments, and multi-line values are not supported; an exception of
class B<Config::XrmDatabase::Failure::file> is thrown if a line can't
be parsed or the file can't be read.

C<%opts> is passed to the class constructor.

=head1 METHODS

=head2 insert

  $db->insert( $key, $value );

Insert the C<$key>, C<$value> pair.

C<$key> may be partially or fully qualified (see L</Keys>).  If
C<$key> is already in the database, its value is replaced and its
match count is reset to zero.  An exception of class
B<Config::XrmDatabase::Failure::key> is thrown if C<$key> is not
valid.

=head2 query

  $value = $db->query( $class, $name, %options );

Query the C<$class>, C<$name> pair. C<$class> and C<$name> must be
fully qualified (see L</Matching>).  If no match was found, the
result depends upon the C<on_failure> option; by default C<undef> is
returned.  To distinguish a stored value of C<undef> from a failed
match, use the C<< return_value => 'reference' >> or
C<< return_value => 'all' >> options, or C<< on_failure => 'throw' >>.

An exception of class B<Config::XrmDatabase::Failure::key> is thrown
if C<$class> or C<$name> is not fully qualified, and one of class
B<Config::XrmDatabase::Failure::components> if they don't have the
same number of components.

Default values for some options can be set when the database object is
constructed. See L</new>. The following options are recognized:

=over

=item C<return_value> I<string>

What is returned.  The following are accepted:

=over

=item C<value>

C<query> returns the value stored in the DB.  This is the default.

=item C<reference>

C<query> returns a reference to the value.  This allows disambiguation
between an C<undef> returned as a value and an C<undef> returned to
indicate there was no match, e.g.,

   $db->insert( 'key', undef );
   $value = $db->query( 'Key', 'key', return_value => 'reference' );
   die( "no match\n" ) unless defined $value;
   say "defined = ", defined $$value ? 'yes' : 'no';

=item C<all>

C<query> returns a hashref with the following entries:

=over

=item C<value>

The value stored in the DB.

=item C<key>

The key which matched, as an array of its components and C<*>
bindings (the internal representation).  Use
L<Config::XrmDatabase::Util/name_arr_to_str> to convert it to a
normalized string.

=item C<match_count>

The number of times this key has been matched, including this query.

=back

=back

=item C<on_failure>

The action to be taken if the query fails.  The following values are
accepted:

=over

=item The string C<throw>

An exception of class B<Config::XrmDatabase::Failure::query> is thrown.

=item The string C<undef>

The undefined value is returned.

=item A reference to a subroutine

C<query> will return the results of calling the subroutine, e.g.

   return $subref->( $name, $class );

C<$name> and C<$class> are passed as arrays of their components
(the internal representation).  Use
L<Config::XrmDatabase::Util/name_arr_to_str> to convert them to
strings.

=back

=back

=head2 write_file

  $db->write_file( $file );

Write a simplified form of an X Resource Manager database file.  See L</to_string>
for the format.

=head2 to_string

  $string = $db->to_string( );

Encode a simplified form of an X Resource Manager database as a string.

Each record is a single line of the form

  key : value

Records are in no particular order.  Multi-line values are not
supported, and will create an unparseable result.

=head2 merge

  $db1->merge( $db2 );

Merge another database into the existing one, and return the existing
one.  Entries in C<$db1> which are also in C<$db2> are replaced by
those in C<$db2>, including their match counts.

=head2 clone

  $db1 = $db->clone;

Return a detached clone.

=head2 to_kv

  \%hash = $db->to_kv( %opt );

Return a copy of the db as a hashref.

The optional C<%opt> hash determines the content of the returned
values.  Keys are returned as normalized strings, equivalent to the form
accepted by L</insert>.

It takes the following entries:

=over

=item C<value> I<string>

This option determines the form and content of the returned values.

=over

=item C<value>

The value stored when the DB entry was created.  This is the default.

=item C<match_count>

The number of times the key was successfully matched by queries
against the database.

=item C<all>

A hash containing all of the data associated with the key.  Currently
this includes C<value> and C<match_count>

=back

=back

=head2 to_kv_arr

  \@array = $db->to_kv_arr( %opt );

Return a copy of the db as an arrayref of key, value pairs, e.g.

  @array = ( [ $key, $value ], [ $key, $value ], ... );

Keys are returned as array references whose elements are the
individual components (including wildcards), e.g.

  @array = ( [ [ 'a', '*', 'c' ], $value ], ... );

The optional C<%opt> hash determines the content of the returned values.
It takes the following entries:

=over

=item C<value> I<string>

This option determines the form and content of the returned values.

=over

=item C<value>

The value stored when the DB entry was created.  This is the default.

=item C<match_count>

The number of times the key was successfully matched by queries
against the database.

=item C<all>

A hash containing all of the data associated with the key.  Currently
this includes C<value> and C<match_count>

=back

=back

=head2 TO_HASH

  \%hash = $db->TO_HASH;

Convert the DB object into a hashref with entries
C<query_return_value> and C<query_on_failure> (the constructor
options), and C<db> (a copy of the internal representation of the
database).  Useful? Who knows?

See L</to_kv> for a perhaps more useful output.

=head1 EXCEPTIONS

Exception objects which are thrown are in the C<Config::XrmDatabase::Failure> namespace.

They stringify to a detailed message, which is also available via the C<msg> method.

=over

=item components

There is a mismatch in components between a key and its class.

=item file

There was an error in reading or writing a file.

=item internal

Something went wrong that shouldn't have

=item key

An illegal key was specified.

=item parameter

Something was wrong with a passed in parameter

=item query

A query failed to match, and the C<on_failure> option was C<throw>.

=back

=for Pod::Coverage BUILD

=begin internals

=method _to_kv_xx

  \@array_of_array_of_pairs = $db->_to_kv_xx( key => 'array', value => $VALUE );
  \%hash = $db->_to_kv_xx( key => 'string', value => $VALUE );

Return a copy of the db as either an array of key-value pairs or as a
hashref.  C<%options> determines the form and content of the keys and
values. It takes the following entries:
=over

=item C<key> I<string>

This specifies the form of the returned keys.

=over

=item C<string>

Keys are returned as a stringified versions, equivalent to the form
accepted by L</insert>.  This is the default.

=item C<array>

Keys are returned as array references whose elements are the
individual components (including wildcards).

=back

=item C<value> I<string>

This option determines the form and content of the returned values.

=over

=item C<value>

The value stored when the DB entry was created.  This is the default.

=item C<match_count>

The number of times the key was successfully matched by queries
against the database.

=item C<all>

A hash containing all of the data associated with the key.  Currently
this includes C<value> and C<match_count>

=back

=back

=end internals

=begin internals

=method _folded

  $hash = $self->_folded;



=end internals

=head1 INCOMPATIBILITIES

=over

=item *

This module does B<not> interface with the X Window system.

=item *

This module has a different API.

=item *

This module doesn't assign a locale to a database.

=item *

This module doesn't associate types with values.

=item *

This module reads and writes a simplified file format: one C<key : value>
record per line.  It doesn't support multi-line values, comments, blank
lines, C<#include> directives, or escape sequences in values.

=back

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-config-xrmdatabase@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Config-XrmDatabase>

=head2 Source

Source is available at

  https://gitlab.com/djerius/config-xrmdatabase

and may be cloned from

  https://gitlab.com/djerius/config-xrmdatabase.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<https://x.org/releases/current/doc/libX11/libX11/libX11.html#Resource_Manager_Functions>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
