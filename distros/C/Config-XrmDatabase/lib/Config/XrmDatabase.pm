package Config::XrmDatabase;

# ABSTRACT: Pure Perl X Resource Manager Database

use v5.20;

use strict;
use warnings;

use experimental qw( signatures postderef );

use Feature::Compat::Try;

our $VERSION = '0.02';

use Config::XrmDatabase::Failure ':all';
use Config::XrmDatabase::Constants  ':all';

my %META = (
    VALUE()      => 'value',
    MATCH_COUNT()  => 'match_count'
);
my %RMETA = (
    fc( 'value' ) => VALUE,
    fc( 'match_count' ) => MATCH_COUNT,
);
my $META_QR = qr/@{[ join '|', map { quotemeta } keys %META ]}/;


use namespace::clean;









sub new ( $class ) { bless {}, $class }

sub _normalize_key( $key ) {
    $key =~ s/[$TIGHT]?[$LOOSE][$TIGHT]?/$LOOSE/g;
    return $key;
}

sub _name_arr_to_name ( $name_arr ) {

    # name_arr might have undef's at the end, as it could have grown
    # and shrunk
    return _normalize_key( join( +TIGHT, grep { defined } @$name_arr ) );
}

sub _parse_resource_name ( $name ) {

    {
        my $last = substr( $name, -1 );
        key_failure->throw(
            "last component of name may not be a binding operator: $name" )
          if $last eq TIGHT || $last eq SINGLE || $last eq LOOSE;
    }

    # all consecutive '.' characters are replaced with a single one.
    $name =~ s/[$TIGHT]+/$TIGHT/g;

    # any combination of '.' and '*' is replaced with a '*'
    $name =~ s/[${TIGHT}${LOOSE}]{2,}/$LOOSE/g;

    # toss out fields:
    #   - the tight binding operator; that is the default.
    #   - empty fields correspond to two sequential binding operators
    #     or a leading binding operator

    return [
        grep { $_ ne TIGHT && $_ ne '' }
          split( /([${TIGHT}${SINGLE}${LOOSE}])/, $name ) ];
}

sub _parse_fq_resource_name ( $name ) {

    key_failure->throw(
        "cannot have '$LOOSE' or '$SINGLE' binding operators in a fully qualified name: $name"
      )
      if index( $name, SINGLE ) != -1
      or index( $name, LOOSE ) != -1;

    key_failure->throw(
        "cannot have multiple sequential '$TIGHT' binding operators in a fully qualified name: $name"
    ) if $name =~ /[$TIGHT]{2,}/;

    key_failure->throw(
        "last component of a fully qualified name must not be a binding operator: $name"
    ) if substr( $name, -1 ) eq TIGHT;

    key_failure->throw(
        "first component of a fully qualified name must not be a binding operator: $name"
    ) if substr( $name, 0, 1 ) eq TIGHT;

    return [ split( /[$TIGHT]/, $name ) ];
}











sub insert ( $self, $name, $value ) {

    $name = _parse_resource_name( $name );
    my $db = $self;
    # use Data::Dump; dd $self;
    $db = $db->{$_} //= {} for $name->@*;
    $DB::single = ! ref $db;

    $db->{ +VALUE }     = $value;
    $db->{ +MATCH_COUNT } = 0;
}













sub query ( $self, $class, $name ) {

    ( $class, $name ) = map { _parse_fq_resource_name( $_ ) } $class, $name;

    components_failure->throw(
        "class and name must have the same number of components" )
      if @$class != @$name;

    return $self->_query( $class, $name );
}

sub _query ( $self, $class, $name, $idx = 0, $match = [] ) {

    # things are simple if we're looking for the last component; it must
    # match exactly
    if ( $idx + 1 == @$name ) {
        for my $component ( $name->[$idx], $class->[$idx] ) {
            if (   exists $self->{$component}
                && exists $self->{$component}{ +VALUE } )
            {
                $match->[$idx] = $component;
                my $entry = $self->{$component};
                ++$entry->{ +MATCH_COUNT };
                return {
                    value => $self->{$component}{ +VALUE },
                    match => _name_arr_to_name( $match ),
                };
            }
        }
        return undef;
    }

    # otherwise need to possible check lower level components

    # exactly named components
    for my $component ( $name->[$idx], $class->[$idx] ) {
        if ( my $subdb = $self->{$component} ) {
            $match->[$idx] = $component;
            my $res = __SUB__->( $subdb, $class, $name, $idx + 1, $match );
            return $res if defined $res;
        }
    }

    # single wildcard
    if ( my $subdb = $self->{ +SINGLE } ) {
        $match->[$idx] = SINGLE;
        my $res = __SUB__->( $subdb, $class, $name, $idx + 1, $match );
        return $res if defined $res;
    }

    if ( my $subdb = $self->{ +LOOSE } ) {
        my $max = @$name;
        $match->[$idx] = LOOSE;
        for ( my $idx = $idx ; $idx < $max ; ++$idx ) {
            my $res = __SUB__->( $subdb, $class, $name, $idx, $match );
            return $res if defined $res;
        }
    }

    return undef;
}














sub read_file ( $class, $file ) {

    my $self = $class->new;

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

    $self->%* = $merger->merge( $self->TO_HASH, $other->T_HASH )->%*;

    return $self;
}










sub clone ( $self ) {
    require Scalar::Util;
    my $clone = Scalar::Util::blessed( $self )->new;
    %$clone = $self->TO_HASH;
    return $clone;
}





























sub to_kv ( $self, $meta = 'value' ) {

    state $fc_all = fc( 'all' );

    my $folded  = $self->_folded;
    my $fc_meta = fc( $meta );

    # return single requested value
    if ( my $component = $RMETA{$fc_meta} ) {

        for my $key ( keys $folded->%* ) {
            if ( $key =~ /^(?<key>.*)[.](?<component>${META_QR})$/ ) {
                # only allow the requested data out
                my $value = delete $folded->{$key};
                $folded->{ $+{key} } = $value
                  if $+{component} eq $component;
            }
        }
    }

    elsif ( $fc_meta eq $fc_all ) {

        for my $key ( keys $folded->%* ) {
            if ( $key =~ /^(?<key>.*)[.](?<component>${META_QR})$/ ) {
                ( $folded->{ $+{key} } //= {} )->{ $META{ $+{component} } }
                  = delete $folded->{$key};
            }
        }
    }

    else {
        parameter_failure->throw( "illegal value for \$meta: $meta" );
    }

    return $folded;
}












sub TO_HASH ( $self ) {
    require Storable;

    # remove the blessedness of $self so dclone creates a plain hash
    return Storable::dclone( {%$self} );
}









sub _folded( $self ) {

    require Hash::Fold;
    my $folded = Hash::Fold->new( delimiter => '.' )->fold( $self->TO_HASH );

    for my $key ( keys %$folded ) {
        my $nkey = _normalize_key( $key );
        $folded->{$nkey} = delete $folded->{$key}
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

version 0.02

=head1 SYNOPSIS

  $db = Config::XrmDatabase->new;
  $db->insert( '*b.c.d', 'v1' );
  $db->query( 'A.B.C.D', 'a.b.c.d' );

=head1 DESCRIPTION

This is a Pure Perl implementation of the X Window Resource Manager
Database (XrmDB).  It allows creation and manipulation of Xrm compliant databases.

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

  $db = Config::XrmDatabase->new;

Construct an empty database.

=head2 read_file

  $db = read_file( $class, $file );

Create a database from a simplified version of the  X Resource Manager database file. Each
record is a single line of the form

  key : value

Multiline values are not parsed.

=head1 METHODS

=head2 insert

  $db->insert( $key, $value );

Insert the C<$key>, C<$value> pair.

C<$match> may be  partially or fully qualified (see L</Match Keys> );

=head2 query

  $db->query( $class, $name );

Query the C<$key>, C<$name> pair.

C<$class> and C<$name> must be fully qualified (see L</Matching> ).

An exception object in class C<Config::XrmDatabase::Failure::illegal::resource::name>

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

  $hash = $db=>to_kv( ?$meta };

Return a copy of the db in C<key>, C<value> form.  The optional C<$meta> parameter
determines what values are returned in C<$hash>.

=over

=item C<value>

The value stored when the DB entry was created..  This is the default.

=item C<match_count>

The number of times the key was successfully matched by queries
against the database.

=item C<all>

A hash containing all of the data associated with the key.  Currently
this includes C<value>, and C<match_count>

=back

=head2 TO_HASH

  $db->TO_HASH;

Convert the DB into a hash.  This replicates the internal DB structure. Useful? Who knows?

See L</to_kv> for a perhaps more useful output.

=begin internals

=method _folded

  $hash = $self->_folded;



=end internals

=head1 EXCEPTIONS

Exception objects which are thrown are in the C<Config::XrmDatabase::Failure> namespace.

They stringify to a detailed message, which is also available via the C<msg> method.

=over

=item key

An illegal key was specified.

=item components

There is a mismatch in components between a key and its class.

=item file

There was an error in reading or writing a file.

=back

=head1 INCOMPATIBILITIES

=over

* This module does B<not> interface with the X Window system.

* This module has a different API.

* This module doesn't assign a locale to a database.

* This module doesn't associate types with values.

* This module can't read or write config files with multi-line values

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
