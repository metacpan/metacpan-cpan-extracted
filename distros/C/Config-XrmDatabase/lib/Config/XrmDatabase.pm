package Config::XrmDatabase;

# ABSTRACT: Pure Perl X Resource Manager Database

use v5.26;
use warnings;

our $VERSION = '0.04';

use Feature::Compat::Try;

use Config::XrmDatabase::Failure ':all';
use Config::XrmDatabase::Util ':all';
use Config::XrmDatabase::Types -all;
use Types::Standard qw( Object Str Optional HashRef );
use Type::Params qw( compile_named );
use Ref::Util;

use Moo;

use namespace::clean;

use MooX::StrictConstructor;

use experimental qw( signatures postderef declared_refs refaliasing );

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
    $db = $db->{$_} //= {} for $name->@*;
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

sub query ( $self, $class, $name, %iopt ) {

    state $check = compile_named(
        { head => [ Str, Str ] },
        return_value => Optional[QueryReturnValue],
        on_failure => Optional[OnQueryFailure],
    );

    ( $class, $name, my \%opt ) = $check->( $class, $name, %iopt );

    $opt{on_failure} //= $self->_query_on_failure;
    $opt{return_value} //= $self->_query_return_value;

    ( $class, $name ) = map { parse_fq_resource_name( $_ ) } $class, $name;

    components_failure->throw(
        "class and name must have the same number of components" )
      if @$class != @$name;

    my $return_all = $opt{return_value} eq QUERY_RETURN_ALL;

    my $match = [];
    my @qargs = ( $class, $name, $return_all, $match );
    my $retval = $self->_query( $self->_db, 0, \@qargs );

    if ( ! defined $retval ) {
        return $opt{on_failure}->( $name, $class )
          if Ref::Util::is_coderef( $opt{on_failure} );

        query_failure->throw(
            "unable to match name: '$name'; class : '$class'" )
          if $opt{on_failure} eq QUERY_ON_FAILURE_THROW;

        return undef;
    }

    return $opt{return_value} eq QUERY_RETURN_VALUE ? $$retval : $retval;
}

sub _query ( $self, $db, $idx, $args ) {

    my ( \$class, \$name, \$return_all, \$match ) = map { \$_ } $args->@*;

    my $_query = __SUB__;

    # things are simple if we're looking for the last component; it must
    # match exactly.  this might be able to be inlined in the exact match
    # checks below to avoid a recursive call, but this is clearer.
    if ( $idx + 1 == @$name ) {
        for my $component ( $name->[$idx], $class->[$idx] ) {
            if (   exists $db->{$component}
                && exists $db->{$component}{ +VALUE } )
            {
                push $match->@*, $component;
                my $entry = $db->{$component};
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
        }
        return undef;
    }

    # otherwise need to possibly check lower level components

    # exactly named components
    for my $component ( $name->[$idx], $class->[$idx] ) {
        if ( my $subdb = $db->{$component} ) {
            push $match->@*, $component;
            my $res = $self->$_query( $subdb, $idx + 1, $args );
            return $res if defined $res;
            pop $match->@*;
        }
    }

    # single wildcard
    if ( my $subdb = $db->{ +SINGLE } ) {
        push $match->@*, SINGLE;
        my $res = $self->$_query( $subdb, $idx + 1, $args );
        return $res if defined $res;
        pop $match->@*;
    }

    if ( my $subdb = $db->{ +LOOSE } ) {
        my $max = @$name;
        push $match->@*, LOOSE;
        for ( my $idx = $idx ; $idx < $max ; ++$idx ) {
            my $res = $self->$_query( $subdb, $idx, $args );
            return $res if defined $res;
        }
        pop $match->@*;
    }

    return undef;
}
















sub read_file ( $class, $file, %opts ) {

    my $self = $class->new( %opts );

    require File::Slurper;

    my @lines;

    try {
        @lines = File::Slurper::read_lines( $file );
    }
    catch ( $e ) {
        file_failure->throw( "error opening $file: $!" );
    }

    my $idx = 0;
    for my $line ( @lines ) {
        ++$idx;
        my ( $var, $value ) = $line =~ /^\s*([^:]+?)\s*:\s*(.*?)\s*$/;
        file_failure->throw(
            sprintf( "%s:%d: unable to parse line", $file, $idx ) )
          unless defined $var and defined $value;
        $self->insert( $var, $value );
    }

    return $self;
}















sub write_file ( $self, $file ) {
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

    File::Slurper::write_text( $file, join( "\n", @records ) );
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
    my $db = delete $args{db}; # this isn't a constructor argument.
    my $clone = Scalar::Util::blessed( $self )->new( \%args );
    $clone->_set__db( $db );
    return $clone;
}




























































my %KV_CONSTANTS;
BEGIN {
    %KV_CONSTANTS = ( map { uc( "KV_$_" ) => $_ }
          qw( all string array value match_count ) );

}
use constant \%KV_CONSTANTS;


sub _to_kv_xx ( $self, %iopt ) {
    %iopt = ( key => KV_STRING, value => KV_VALUE, %iopt );

    state $match = {
        value =>
          qr/^(?<match> @{[ join '|', KV_VALUE, KV_MATCH_COUNT, KV_ALL ]} )$/xi,
        key => qr/^(?<match> @{[ join '|', KV_STRING, KV_ARRAY ]} )$/xi,
    };

    my %opt = map {
        parameter_failure->throw( "illegal value for '$_' option: $iopt{$_}" )
          unless $iopt{$_} =~ $match->{$_};
        $_ => $+{match};
    } qw( key value );

    parameter_failure->throw( "illegal option: $_" )
      for grep !defined $opt{$_}, keys %iopt;

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

    return [ map { [ [ split( /[.]/, $_ ) ], $folded->{$_} ] } keys $folded->%* ]
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
    }
}









sub _folded ( $self, $normalize_names = 1 ) {

    # Hash::Fold is overkill
    require Hash::Fold;
    my $folded = Hash::Fold->new( delimiter => '.' )->fold( $self->TO_HASH->{db} );

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

version 0.04

=head1 SYNOPSIS

  $db = Config::XrmDatabase->new;
  $db->insert( '*b.c.d', 'v1' );
  $db->query( 'A.B.C.D', 'a.b.c.d' );

=head1 DESCRIPTION

This is a Pure Perl implementation of the X Window Resource Manager
Database (XrmDB).  It allows creation and manipulation of Xrm compliant databases.

B<Warning!> The XrmDB refers to names and resources.  These days they
are more typically called keys and values.  The terminology used below
(and sometimes in the names of subroutines and methods) mixes these
two approaches, sometimes a bit too liberally.  Subroutine and method
names will probably change to make things more consistent.

=head2 Why another configuration database?

The XrmDB differs from typical key-value stores by allowing stored
keys to be either fully or partially qualified.  For example, the
partially qualified key

    *.c.d

will match a query for the keys C<a.c.d>, C<a.b.c.d>.  Keys are
composed of multiple components separated by the C<.> character.  If
the component is C<?> it will match any single component; a component
of C<*> matches any number (including none).

=head2 Matching

Matching a search key against the database is a component by component
operation, starting with the leftmost component.  The component in the
search key is checked against the same level component in the database
keys.  First the keys with non-wildcard components are compared; if
there is an exact match, the search moves on to the next component in
the matching database key.

At this point, XrmDB adds another dimension to the search.  Keys
belong to a I<class>, which has the same number of components as the
key.  When an exact match against the search key component is not
found, the database is searched for an exact match for the same level
component in the class.

Only after that fails does the algorithm switch to database keys with
wildcard components.  The same order of comparison is performed; first
against the component in the search key, and if that fails, to the
component in the class.

For example, given a search key of

 xmh.toc.messagefunctions.incorporate.activeForeground'

with a class of

 Xmh.Paned.Box.Command.Foreground

the database is first searched for keys which begin with C<xmh>.  If
that fails, the database is searched for keys which begin with C<Xmh>.
If that fails, keys which start with a C<?> wildcard are searched, and
then those which start with C<*>.  The C<*> components can match an arbitrary
number of components in the search key and class.

If a match is found, the search moves on to the next unmatched
component and the algorithm is repeated.

=head2 Classes

Why the extra C<class>?

Assigning keys to a class provides an ability to distinguish between two
similarly structured keys. It essentially creates namespaces for keys so
that values can be created based on which namespace a key belongs to,
rather than the content of the key.

Let's say that you have a bunch of keys which end in C<Foreground>:

  a.b.c.Foreground
  d.e.f.Foreground
  x.y.z.Foreground

and you want to set a value for any keys which end in C<Foreground>:

  *.Foreground : 'yellow'

To specify a separate value for each one could set

  a.b.c.Foreground : 'red'
  d.e.f.Foreground : 'blue'
  x.y.z.Foreground : 'green'

Let's say that  C<a.b.c.Foreground> and C<d.e.f.Foreground> are in the same class, C<U.V.W.Foreground>,
and all keys in that class should have the same value:

  U.V.W.Foreground : 'red'
  x.y.z.Foreground : 'green'

At some point, a new hierarchy of keys that begin with C<g> is added
to that class, but they should has a different value:

  g.V.W.Foreground : 'magenta'

You could try this:

  g.?.?.Foreground : 'magenta'

But that would affect I<all> keys that begin with C<g> but aren't in that class.

Classes help bring some order, but this system can become very
confusing if some discipline isn't maintained.

=head1 CLASS METHODS

=head2 new

  $db = Config::XrmDatabase->new( \%args );

The class constructor; it constructs an empty database.

The available constructor arguments are:

=over

=item C<query_return_value>

This option sets the default value for the L</query> method's
C<return_value> parameter.
It defaults to the string C<value>.
See L</query> for more details.

=item C<query_on_failure>

This option sets the default value for the L</query> method's
C<on_failure> parameter.
It defaults to the string C<undef>.
See L</query> for more details.

=item C<insert> I<hash>

Populate the database with the supplied data.

=back

=head2 read_file

  $db = read_file( $class, $file, %opts );

Create a database from a simplified version of the  X Resource Manager database file. Each
record is a single line of the form

  key : value

Multiline values are not parsed.

C<%opts> is passed to the class constructor.

=head1 METHODS

=head2 insert

  $db->insert( $key, $value );

Insert the C<$key>, C<$value> pair.

C<$match> may be  partially or fully qualified (see L</Match Keys> );

=head2 query

  $value = $db->query( $class, $name, %options );

Query the C<$class>, C<$name> pair. C<$class> and C<$name> must be
fully qualified (see L</Matching> ).  If no match was found,
C<undef> is returned.  To disambiguate an actual value of C<undef>,
use the C<< value => 'all' >> option.

Default values for some options can be set when the database object is
constructed. See L</new>. The following options are recognized:

=over

=item C<return_value>

This option determines what is returned.  The following string values are accepted.

=over

=item C<value>

The value stored in the DB.  This is the default.

=item C<reference>

A reference to the value.  This allows disambiguation between an C<undef> returned
as a value and an C<undef> returned to indicate there was no match, e.g.,

   $db->insert( 'key', undef );
   $value = $db->query('foo', return_value => 'reference' );
   die( "no match unless defined $value" );
   $value = $$value;
   say "defined = ", defined $value ? 'yes' : 'no';

=item C<all>

A hash containing all of the data associated with the database entry.
Currently this includes

=over

=item C<value>

The value stored in the DB.

=item C<key>

An internal representation of the key which matched.  Use
L<Config::XrmDatabase::Util::name_arr_to_str> to convert it to a
normalized string.

=item C<match_count>

The number of times this key was matched.

=back

=back

=item C<on_failure>

The action to be taken if the query fails.  The following values are
accepted:

=over

=item The string C<'throw'>

An exception of class B<Config::XrmDatabase::Failure::query> is thrown.

=item The string C<'undef'>

The undefined value is returned.

=item A reference to a subroutine

The reference will be called as

   return $subref->( $name, $class );

Note that the subroutine's return value will be returned by L<query>.

=back

=back

=head2 write_file

  $db->write_file( $file );

Write a simplified form of an X Resource Manager database file.

Each record is a single line of the form

  key : value

Multiline values are not supported, and will create an unparseable file.

=head2 merge

  $db1->merge( $db2);

Merge another database into the existing one.  Common entries are
overwritten.

=head2 clone

  $db1 = $db->clone;

Return a detached clone.

=head2 to_kv

  \%hash = $db->to_kv( \%opt );

Return a copy of the db as a hash.

The optional C<%opt> hash determines the content of the returned
values.  Keys are returned as normalized strings, equivalent to the form
accepted by L</insert>.

It takes the following entries:

=over

=item C<value>

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

  \@array = $db->to_kv_arr( value => $VALUE );

Return a copy of the db as a list of key, value pairs.
The pairs are stored in an array, e.g.

  @array = ( [ $key, $value ], [ $key, $value ], ... );

Keys are returned as array references whose elements are the
individual components (including wildcards), e.g.

  @array = ( [ [ 'a', '*', 'c' ], $value ], ... );

The optional C<%opt> hash determines the content of the returned values.
It takes the following entries:

=over

=item C<value>

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

  $db->TO_HASH;

Convert the DB object into a hash.  Useful? Who knows?

See L</to_kv> for a perhaps more useful output.

=for Pod::Coverage BUILD

=begin internals

=method _to_kv_xx

  \@array_of_array_of_pairs = $db->_to_kv_xx( key => 'array', value => $VALUE );
  \%hash = $db->_to_kv_xx( key => 'string', value => $VALUE );

Return a copy of the db as either an array of key-value pairs or as a
hash.  C<%options> determines the form and content of the keys and
values. It takes the following entries:
=over

=item C<key>

This specifies the form of the returned keys.

=over

=item C<string>

Keys are returned as a stringified versions, equivalent to the form
accepted by L</insert>.  This is the default.

=item C<array>

Keys are returned as array references whose elements are the
individual components (including wildcards).

=back

=item C<value>

This option determines the form and content of the returned keys.

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

=back

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

This module can't read or write config files with multi-line values

=back

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-config-xrmdatabase@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=Config-XrmDatabase

=head2 Source

Source is available at

  https://gitlab.com/djerius/config-xrmdatabase

and may be cloned from

  https://gitlab.com/djerius/config-xrmdatabase.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<https://x.org/releases/current/doc/libX11/libX11/libX11.html#Resource_Manager_Functions|https://x.org/releases/current/doc/libX11/libX11/libX11.html#Resource_Manager_Functions>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
