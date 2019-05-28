# Class::EHierarchy -- Base class for hierarchally ordered objects
#
# (c) 2017, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: lib/Class/EHierarchy.pm, 2.01 2019/05/23 07:29:49 acorliss Exp $
#
#    This software is licensed under the same terms as Perl, itself.
#    Please see http://dev.perl.org/licenses/ for more information.
#
#####################################################################

#####################################################################
#
# Environment definitions
#
#####################################################################

package Class::EHierarchy;

use 5.008003;

use strict;
use warnings;
use vars qw($VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS);
use base qw(Exporter);
use Carp;
use Scalar::Util qw(weaken);

($VERSION) = ( q$Revision: 2.01 $ =~ /(\d+(?:\.(\d+))+)/sm );

# Ordinal indexes for the @objects element records
use constant CEH_OREF    => 0;
use constant CEH_PID     => 1;
use constant CEH_PKG     => 2;
use constant CEH_CLASSES => 3;
use constant CEH_CREF    => 4;

# Ordinal indexes for the @properties element records
use constant CEH_PATTR => 0;
use constant CEH_PNAME => 1;
use constant CEH_PPKG  => 1;
use constant CEH_PVAL  => 2;

# Property attribute masks
use constant CEH_PATTR_SCOPE => 7;
use constant CEH_PATTR_TYPE  => 504;

# Property attribute scopes
use constant CEH_PUB   => 1;
use constant CEH_RESTR => 2;
use constant CEH_PRIV  => 4;

# Property attribute types
use constant CEH_SCALAR => 8;
use constant CEH_ARRAY  => 16;
use constant CEH_HASH   => 32;
use constant CEH_CODE   => 64;
use constant CEH_REF    => 128;
use constant CEH_GLOB   => 256;

# Property flags
use constant CEH_NO_UNDEF => 512;

@EXPORT    = qw();
@EXPORT_OK = qw(CEH_PUB CEH_RESTR CEH_PRIV CEH_SCALAR CEH_ARRAY
    CEH_HASH CEH_CODE CEH_REF CEH_GLOB CEH_NO_UNDEF _declProperty
    _declMethod );
%EXPORT_TAGS = ( all => [@EXPORT_OK] );

#####################################################################
#
# Module code follows
#
#####################################################################

##########################################################
# Hierarchal code support
##########################################################

{

    # Array of object references and metadata
    my @objects;

    # Array of recycled IDs availabe for use
    my @recoveredIDs;

    sub _dumpObjects {

        # Purpose:  Provides a list of objects
        # Returns:  List of refs
        # Usage:    @objects = _dumpObjects();

        return map { $$_[CEH_OREF] } grep {defined} @objects;
    }

    sub _getID {

        # Purpose:  Generates and assigns a unique ID to the passed
        #           object, and initializes the internal records
        # Returns:  Integer
        # Usage:    $id = _genID();

        my $obj = CORE::shift;
        my $id = @recoveredIDs ? CORE::shift @recoveredIDs : $#objects + 1;

        $$obj                      = $id;
        $objects[$id]              = [];
        $objects[$id][CEH_CREF]    = [];
        $objects[$id][CEH_CLASSES] = [];
        $objects[$id][CEH_OREF]    = $obj;
        $objects[$id][CEH_PKG]     = ref $obj;
        weaken( $objects[$$obj][CEH_OREF] );

        $id = '0 but true' if $id == 0;

        # Build object class list
        {
            no strict 'refs';

            my ( $isaref, $tclass, $nclass, @classes, $n, $l );
            my $class = ref $obj;

            # Get the first level of classes we're subclassed from
            $isaref = *{"${class}::ISA"}{ARRAY};
            $isaref = [] unless defined $isaref;
            foreach $tclass (@$isaref) {
                CORE::push @classes, $tclass
                    if $tclass ne __PACKAGE__
                        and "$tclass"->isa(__PACKAGE__);
            }

            # Now, recurse into parent classes.
            $n = 0;
            $l = scalar @classes;
            while ( $n < $l ) {
                foreach $tclass ( @classes[ $n .. ( $l - 1 ) ] ) {
                    $isaref = *{"${tclass}::ISA"}{ARRAY};
                    $isaref = [] unless defined $isaref;
                    foreach $nclass (@$isaref) {
                        CORE::push @classes, $nclass
                            if $nclass ne __PACKAGE__
                                and "$nclass"->isa(__PACKAGE__);
                    }
                }
                $n = scalar @classes - $l + 1;
                $l = scalar @classes;
            }

            # Add our current class
            CORE::push @classes, $class;

            # Save the list
            foreach (@classes) { _addClass( $obj, $_ ) }
        }

        return $id;
    }

    sub _delID {

        # Purpose:  Recovers the ID for re-use while deleting the
        #           old data structures
        # Returns:  Boolean
        # Usage:    _recoverID($id);

        my $obj      = CORE::shift;
        my $pid      = $objects[$$obj][CEH_PID];
        my @children = @{ $objects[$$obj][CEH_CREF] };

        # Have the parent disown this child
        _disown( $objects[$pid][CEH_OREF], $obj ) if defined $pid;
        _disown( $obj, $objects[$_][CEH_OREF] ) if @children;

        # Clean up internal data structures
        $objects[$$obj] = undef;
        CORE::push @recoveredIDs, $$obj;

        return 1;
    }

    sub isStale {

        # Purpose:  Checks to see if the object reference is
        #           stale
        # Returns:  Boolean
        # Usage:    $rv = $obj->isStale;

        my $obj = CORE::shift;

        return not( defined $obj
            and defined $objects[$$obj]
            and defined $objects[$$obj][CEH_OREF]
            and $obj eq $objects[$$obj][CEH_OREF] );
    }

    sub _addClass {

        # Purpose:  Records a super class for the object
        # Returns:  Boolean
        # Usage:    $rv = _addClass($obj, $class);

        my $obj   = CORE::shift;
        my $class = CORE::shift;

        CORE::push @{ $objects[$$obj][CEH_CLASSES] }, $class
            if defined $class
                and not grep /^$class$/s, @{ $objects[$$obj][CEH_CLASSES] };

        return 1;
    }

    sub _getClasses {

        # Purpose:  Returns a list of classes
        # Returns:  Array
        # Usage:    @classes = _getClasses($obj);

        my $obj = CORE::shift;

        return @{ $objects[$$obj][CEH_CLASSES] };
    }

    sub _adopt {

        # Purpose:  Updates the object records to establish the relationship
        # Returns:  Boolean
        # Usage:    $rv = _adopt($parent, @children);

        my $obj     = CORE::shift;
        my @orphans = @_;
        my $rv      = 1;
        my $child;

        foreach $child (@orphans) {
            next if $child->isStale;
            if ( !defined $objects[$$child][CEH_PID] ) {

                # Eligible for adoption, record the relationship
                $objects[$$child][CEH_PID] = $$obj;
                CORE::push @{ $objects[$$obj][CEH_CREF] }, $child;

            } else {

                # Already adopted
                if ( $objects[$$child][CEH_PID] != $$obj ) {
                    $@ = "object $$child already adopted by another parent";
                    carp $@;
                    $rv = 0;
                }
            }
        }

        # Merge aliases
        $obj->_mergeAliases;

        return $rv;
    }

    sub _disown {

        # Purpose:  Severs the relationship between the parent and children
        # Returns:  Boolean
        # Usage:    $rv = _disown($parent, @children);

        my $obj     = CORE::shift;
        my @orphans = @_;
        my $rv      = 1;
        my ($child);

        foreach $child (@orphans) {
            if ( defined $objects[$$child][CEH_PID]
                and $objects[$$child][CEH_PID] == $$obj ) {

                # A little alias glue code
                $child->_pruneAliases();

                # Emancipate the child
                $objects[$$child][CEH_PID] = undef;
                $objects[$$obj][CEH_CREF] =
                    [ grep { $_ != $child } @{ $objects[$$obj][CEH_CREF] } ];

                # More alias glue code
                $child->_mergeAliases();
            }
        }

        return $rv;
    }

    sub parent {

        # Purpose:  Returns a reference to the parent object
        # Returns:  Object reference/undef
        # Usage:    $ref = $obj->parent;

        my $obj = CORE::shift;
        my $parent;

        if ( $obj->isStale ) {
            $@ = 'parent method called on stale object';
            carp $@;
        } else {
            $parent = $objects[$$obj][CEH_PID];
            $parent =
                defined $parent
                ? $objects[$parent][CEH_OREF]
                : undef;
        }

        return $parent;
    }

    sub children {

        # Purpose:  Returns a list of child objects
        # Returns:  List of object references
        # Usage:    @children = $obj->children;

        my $obj = CORE::shift;
        my @children;

        if ( $obj->isStale ) {
            $@ = 'children method called on stale object';
            carp $@;
        } else {
            @children = @{ $objects[$$obj][CEH_CREF] };
        }

        return @children;
    }

    sub siblings {

        # Purpose:  Returns a list of siblings
        # Returns:  List of object references
        # Usage:    @sibling = $obj->siblings;

        my $obj = CORE::shift;
        my $parent;

        if ( $obj->isStale ) {
            $@ = 'siblings method called on stale object';
            carp $@;
        } else {
            $parent = $objects[$$obj][CEH_PID];
            $parent = $objects[$parent][CEH_OREF] if defined $parent;
        }

        return defined $parent ? $parent->children : ();
    }

    sub root {

        # Purpose:  Returns the root object of the tree
        # Returns:  Object reference
        # Usage:    $root = $obj->root;

        my $obj = CORE::shift;
        my $pid = $objects[$$obj][CEH_PID];
        my $parent;

        if ( $obj->isStale ) {
            $@ = 'root method called on stale object';
            carp $@;
        } else {

            # Walk up the tree until we find an undefined PID
            $pid = $objects[$$obj][CEH_PID];
            while ( defined $pid ) {
                $parent = $objects[$pid][CEH_OREF];
                $pid    = $objects[$$parent][CEH_PID];
            }

            # The object is the root if no parent was ever found
            $parent = $obj unless defined $parent;
        }

        return $parent;
    }

    sub _getRefById {

        # Purpose:  Returns an object reference by id from the objects array
        # Returns:  Reference
        # Usage:    $obj = _getRefById($index);

        my $id = CORE::shift;

        return defined $id ? $objects[$id][CEH_OREF] : undef;
    }

}

sub adopt {

    # Purpose:  Formally adopts the children
    # Returns:  Boolean
    # Usage:    $rv = $obj->adopt(@children);

    my $obj      = CORE::shift;
    my @children = @_;
    my $root     = $obj->root;
    my $rv;

    if ( $obj->isStale ) {
        $rv = 0;
        $@  = 'adopt method called on stale object';
        carp $@;
    } else {
        if ( grep { $$obj == $$_ } @children ) {
            $rv = 0;
            $@  = 'object attempted to adopt itself';
            carp $@;
        } elsif (
            grep {
                $root eq $_
            } @children
            ) {
            $rv = 0;
            $@  = 'object attempted to adopt the root';
            carp $@;
        } elsif (
            grep {
                !defined or !$_->isa(__PACKAGE__)
            } @children
            ) {
            $rv = 0;
            $@  = 'non-eligible values passed as children for adoption';
            carp $@;
        } else {
            $rv = _adopt( $obj, @children );
        }
    }

    return $rv;
}

sub disown {

    # Purpose:  Formally adopts the children
    # Returns:  Boolean
    # Usage:    $rv = $obj->adopt(@children);

    my $obj      = CORE::shift;
    my @children = @_;
    my $rv;

    if ( $obj->isStale ) {
        $rv = 0;
        $@  = 'disown method called on stale object';
        carp $@;
    } else {
        if ( grep { !defined or !$_->isa(__PACKAGE__) } @children ) {
            $rv = 0;
            $@  = 'non-eligible values passed as children for disowning';
            carp $@;
        } else {
            $rv = _disown( $obj, @children );
        }
    }

    return $rv;
}

sub descendents {

    # Purpose:  Returns all descendents of the object
    # Returns:  List of object references
    # Usage:    @descendents = $obj->descendents;

    my $obj = CORE::shift;
    my ( @children, @descendents, $child );

    if ( $obj->isStale ) {
        $@ = 'descendents method called on stale object';
        carp $@;
    } else {
        @children = $obj->children;
        while (@children) {
            $child = CORE::shift @children;
            CORE::push @descendents, $child;
            CORE::push @children,    $child->children;
        }
    }

    return @descendents;
}

sub _initHierarchy {

    # Purpose:  Initializes the object & class hierarchal data for an object
    # Returns:  Boolean
    # Usage:    $rv = _initHierarchy($obj, $class, @args);

    my $obj     = CORE::shift;
    my $class   = CORE::shift;
    my @args    = @_;
    my @classes = _getClasses($obj);
    my ( $rv, $tclass, %classes );

    # uniq the class list and save it
    %classes = map { $_ => 0 } @classes;

    # Begin initialization from the top down
    foreach $tclass ( reverse @classes ) {
        unless ( $classes{$tclass} ) {

            {
                no strict 'refs';

                # call class _initialize()
                $rv =
                    defined *{"${tclass}::_initialize"}
                    ? &{"${tclass}::_initialize"}( $obj, @args )
                    : 1;

            }

            # Track each class initialization so we only do
            # it once
            $classes{$tclass}++;
        }

        last unless $rv;
    }

    return $rv;
}

sub _destrHierarchy {

    # Purpose:  Destroys hierarchal data for an object
    # Returns:  Boolean
    # Usage:    $rv = _destrHierarchy($obj);

    my $obj     = CORE::shift;
    my @classes = _getClasses($obj);
    my $tclass;

    # Attempt to run all the _deconstruct methods
    {
        no strict 'refs';

        foreach $tclass ( reverse @classes ) {
            &{"${tclass}::_deconstruct"}($obj)
                if defined *{"${tclass}::_deconstruct"};
        }
    }

    return 1;
}

##########################################################
# Alias support
##########################################################

{

    # Array of object aliases
    my @aliases;

    # Array of alias maps
    my @amaps;

    sub _initAlias {

        # Purpose:  Initializes alias data for an object
        # Returns:  Boolean
        # Usage:    $rv = _initAlias($obj, $alias);

        my $obj   = CORE::shift;
        my $alias = CORE::shift;

        # Store the object aliases and initialize a private map
        $aliases[$$obj] = $alias;
        $amaps[$$obj] = defined $alias ? { $alias => $$obj } : {};

        return 1;
    }

    sub _destrAlias {

        # Purpose:  Destroys alias data for an object
        # Returns:  Boolean
        # Usage:    $rv = _destrAlias($obj);

        my $obj   = CORE::shift;
        my $alias = $aliases[$$obj];
        my $root  = $obj->root;

        # Remove aliases from root alias map
        delete $amaps[$$root]{$alias}
            if defined $alias and $amaps[$$root]{$alias} == $$obj;

        # Clean up object data
        $aliases[$$obj] = undef;
        $amaps[$$obj]   = undef;

        return 1;
    }

    sub _mergeAliases {

        # Purpose:  Merges an alias with the family tree alias index
        # Returns:  Boolean
        # Usage:    $rv = _mergeAliases($obj);

        my $obj = CORE::shift;
        my $rv  = 1;
        my ( $child, $alias, $root );

        # The alias index is associated with the root of the tree
        $root = $obj->root;
        foreach $child ( $root->descendents ) {

            # Skip objects without an alias
            next unless defined $aliases[$$child];

            # Get the child's private alias index
            $alias = $aliases[$$child];

            # Update the index if the alias is unclaimed
            if ( CORE::exists $amaps[$$root]{$alias}
                and $amaps[$$root]{$alias} != $$child ) {
                $@ = "alias name collision: $alias";
                carp $@;
                $rv = 0;
            } else {
                $amaps[$$root]{$alias} = $$child;
            }

            # Store the child's prefered alias in its private index,
            # regardless
            $amaps[$$child] = { $alias => $$child };
        }

        return $rv;
    }

    sub _pruneAliases {

        # Purpose:  Removes all aliases from this object and its descendents
        # Returns:  Boolean
        # Usage:    $rv = _prunAliases($obj);

        my $obj = CORE::shift;
        my $rv  = 1;
        my ( $root, $child, $alias );

        $root = $obj->root;
        foreach $child ( $obj, $obj->descendents ) {

            # We never prune aliases from an object's own index for itself
            next if $$child == $$root;

            # Get the alias and remove it from the root's index if the
            # alias if valid and pointing to the child in question
            $alias = $aliases[$$child];
            if ( defined $alias ) {
                delete $amaps[$$root]{$alias}
                    if defined $alias
                        and $amaps[$$root]{$alias} == $$child;
            }
        }

        return $rv;
    }

    sub alias {

        # Purpose:  Assigns an alias to an object
        # Returns:  Boolean
        # Usage:    $rv = $obj->alias($name);

        my $obj   = CORE::shift;
        my $alias = CORE::shift;
        my $rv    = 1;
        my $root;

        if ( $obj->isStale ) {
            $rv = 0;
            $@  = 'alias method called on stale object';
            carp $@;
        } else {
            if ( defined $aliases[$$obj] and length $aliases[$$obj] ) {
                $rv = 0;
                $@  = "object already has an alias: $aliases[$$obj]";
                carp $@;
            } elsif ( !defined $alias or !length $alias ) {
                $rv = 0;
                $@  = 'attempt to assign an invalid alias';
                carp $@;
            } else {

                # Get the root and record the alias in the object's private
                # map
                $root                 = $obj->root;
                $aliases[$$obj]       = $alias;
                $amaps[$$obj]{$alias} = $$obj;

                if ( $$root != $$obj ) {

                    # Update the root index
                    #
                    # Make sure no name collisions
                    if ( CORE::exists $amaps[$$root]{$alias}
                        and $amaps[$$root]{$alias} != $$obj ) {
                        $@ = "alias name collision: $alias";
                        carp $@;
                        $rv = 0;
                    } else {
                        $root = $obj->root;
                        $amaps[$$root]{$alias} = $$obj;
                    }
                }
            }
        }

        return $rv;
    }

    sub getByAlias {

        # Purpose:  Returns an object reference associated with a given name
        # Returns:  Reference
        # Usage:    $oref = $obj->getByAlias($alias);

        my $obj   = CORE::shift;
        my $alias = CORE::shift;
        my ( $root, $rv );

        if ( $obj->isStale ) {
            $rv = 0;
            $@  = 'getByAlias method called on stale object';
            carp $@;
        } elsif ( defined $alias ) {
            $root = $obj->root;
            $rv   = $amaps[$$root]{$alias}
                if CORE::exists $amaps[$$root]{$alias};
            $rv = _getRefById($rv) if defined $rv;
        }

        return $rv;
    }

}

##########################################################
# Property/Method support
##########################################################

{

    # Property storage
    my @properties;

    sub __declProperty {

        # Purpose:  Creates a named property record with associated meta data
        # Returns:  Boolean
        # Usage:    $rv = __declProperty($caller, $obj, $name, $attr);

        my $caller = CORE::shift;
        my $obj    = CORE::shift;
        my $name   = CORE::shift;
        my $attr   = CORE::shift;

        # Prepend package scoping in front of private properties
        $name = "$caller*$name" if $attr & CEH_PRIV;

        # Apply default attributes
        $attr |= CEH_SCALAR
            unless ( $attr ^ CEH_PATTR_TYPE ) > 0;
        $attr |= CEH_PUB
            unless ( $attr ^ CEH_PATTR_SCOPE ) > 0;

        # Save the properties
        ${ $properties[$$obj] }{$name}            = [];
        ${ $properties[$$obj] }{$name}[CEH_PATTR] = $attr;
        ${ $properties[$$obj] }{$name}[CEH_PPKG]  = $caller;
        ${ $properties[$$obj] }{$name}[CEH_PVAL] =
              $attr & CEH_ARRAY ? []
            : $attr & CEH_HASH  ? {}
            :                     undef;

        return 1;
    }

    sub _declProperty {

        # Purpose:  Creates a named property record with associated meta data.
        #           This is the public function available for use by
        #           subclasses
        # Returns:  Boolean
        # Usage:    $rv = _declProperty($obj, $name, $attr);

        my $obj    = CORE::shift;
        my $name   = CORE::shift;
        my $attr   = CORE::shift;
        my $caller = caller;
        my $rv     = !$obj->isStale;

        if ($rv) {
            if ( defined $name and length $name ) {
                $rv = __declProperty( $caller, $obj, $name, $attr );
            } else {
                $@ = '_declProperty function called with an invalid property';
                carp $@;
                $rv = 0;
            }
        } else {
            $@ = '_declProperty function called with a stale object';
            carp $@;
        }

        return $rv;
    }

    sub _gatekeeper {

        # Purpose:  Checks for a valid property name, and checks ACLs for the
        #           caller
        # Returns:  Property name if allowed, undef otherwise
        # Usage:    $name = $obj->gatekeeper($caller, $name);

        my $obj    = CORE::shift;
        my $caller = CORE::shift;
        my $name   = CORE::shift;
        my ( $rv, $class, $cscope, $pscope );

        if ( defined $name and length $name ) {

            # Check scope and adjust for privately scoped properties
            $name = "$caller*$name"
                if CORE::exists $properties[$$obj]{"$caller*$name"};

            if ( CORE::exists $properties[$$obj]{$name} ) {

                # Get the property's class
                $class = $properties[$$obj]{$name}[CEH_PPKG];

                # Get the property's scope
                $pscope =
                    $properties[$$obj]{$name}[CEH_PATTR] & CEH_PATTR_SCOPE;

                # Get the caller's scope
                $cscope =
                      $caller eq $class ? CEH_PRIV
                    : "$caller"->isa($class) ? CEH_RESTR
                    :                          CEH_PUB;

                # Set the values if allowed
                if ( $cscope >= $pscope ) {
                    $rv = $name;
                } else {
                    $@ = 'property access violation';
                    carp $@;
                }

            } else {
                $@ = 'method called with an nonexistent property';
                carp $@;
            }
        } else {
            $@ = 'method called with an invalid property name';
            carp $@;
        }

        return $rv;
    }

    sub _setProperty {

        # Purpose:  Sets the named property to the passed values
        # Returns:  Boolean
        # Usage:    $rv = $obj->_setProperty($name, @values);

        my $obj  = CORE::shift;
        my $name = CORE::shift;
        my @val  = @_;
        my ( $rv, $ptype, $pundef, $pref );

        # Get some meta data
        $ptype  = ${ $properties[$$obj] }{$name}[CEH_PATTR] & CEH_PATTR_TYPE;
        $pundef = ${ $properties[$$obj] }{$name}[CEH_PATTR] & CEH_NO_UNDEF;

        if ( $ptype != CEH_ARRAY and $ptype != CEH_HASH ) {
            $pref = ref $val[0];

            # Check for undef restrictions
            $rv = 1 if !$pundef or defined $val[0];

            if ($rv) {

                # Check types for correctness
                $rv =
                      ( !defined $val[0] ) ? 1
                    : $ptype == CEH_SCALAR ? ( $pref eq '' )
                    : $ptype == CEH_CODE   ? ( $pref eq 'CODE' )
                    : $ptype == CEH_GLOB   ? ( $pref eq 'GLOB' )
                    : $ptype == CEH_REF    ? ( length $pref )
                    :                        0;

                $@ = "data type mismatch for $name";
                carp $@ unless $rv;
            }

        } else {

            # No validation for array/hash types
            $rv = 1;
        }

        # Assign the value(s)
        if ($rv) {
            if ( $ptype == CEH_ARRAY ) {
                ${ $properties[$$obj] }{$name}[CEH_PVAL] = [@val];
            } elsif ( $ptype == CEH_HASH ) {
                ${ $properties[$$obj] }{$name}[CEH_PVAL] = {@val};
            } else {
                ${ $properties[$$obj] }{$name}[CEH_PVAL] = $val[0];
            }
        }

        return $rv;
    }

    sub set {

        # Purpose:  Sets the named properties to the passed value(s)
        # Returns:  Boolean
        # Usage:    $rv = $obj->set($name, @values);

        my $obj    = CORE::shift;
        my $name   = CORE::shift;
        my @val    = @_;
        my $caller = caller;
        my $rv     = !$obj->isStale;

        if ($rv) {
            $name = $obj->_gatekeeper( $caller, $name );
            if ( defined $name ) {
                $rv = $obj->_setProperty( $name, @val );
            } else {
                $rv = 0;
            }
        } else {
            $@ = 'set method called on a stale object';
            carp $@;
        }

        return $rv;
    }

    sub _getProperty {

        # Purpose:  Gets the named property's value(s)
        # Returns:  Scalar, Array, Hash, etc.
        # Usage:    @rv = $obj->getProperty($name);

        my $obj  = CORE::shift;
        my $name = CORE::shift;
        my ( @rv, $ptype );

        # Get some meta data
        $ptype = $properties[$$obj]{$name}[CEH_PATTR] & CEH_PATTR_TYPE;

        # Retrieve the content
        @rv =
              $ptype == CEH_HASH  ? %{ $properties[$$obj]{$name}[CEH_PVAL] }
            : $ptype == CEH_ARRAY ? @{ $properties[$$obj]{$name}[CEH_PVAL] }
            :                       ( $properties[$$obj]{$name}[CEH_PVAL] );

        return
              $ptype == CEH_HASH  ? @rv
            : $ptype == CEH_ARRAY ? @rv
            :                       $rv[0];
    }

    sub get {

        # Purpose:  Gets the named property's value(s)
        # Returns:  Scalar, Array, Hash, etc.
        # Usage:    @rv = $obj->get($name);

        my $obj    = CORE::shift;
        my $name   = CORE::shift;
        my $caller = caller;
        my @rv;

        if ( !$obj->isStale ) {
            $name = $obj->_gatekeeper( $caller, $name );
            if ( defined $name ) {
                @rv = $obj->_getProperty($name);
            }
        } else {
            $@ = 'set method called on a stale object';
            carp $@;
        }

        return wantarray ? @rv : $rv[0];
    }

    sub push {

        # Purpose:  Performs a push operation on an array property
        # Returns:  RV of CORE::push or undef
        # Usage:    $rv = $obj->push($name, @values);

        my $obj    = CORE::shift;
        my $name   = CORE::shift;
        my @val    = @_;
        my $caller = caller;
        my $rv     = !$obj->isStale;

        if ($rv) {
            $rv = undef;
            $name = $obj->_gatekeeper( $caller, $name );
            if ( defined $name ) {
                if ( ref $properties[$$obj]{$name}[CEH_PVAL] eq 'ARRAY' ) {
                    $rv = CORE::push @{ $properties[$$obj]{$name}[CEH_PVAL] },
                        @val;
                } else {
                    $@ = 'push attempted on a non-array property';
                    carp $@;
                }
            }
        } else {
            $@ = 'push method called on a stale object';
            carp $@;
        }

        return $rv;
    }

    sub pop {

        # Purpose:  Performs a pop operation on an array property
        # Returns:  RV of CORE::pop or undef
        # Usage:    $rv = $obj->pop($name);

        my $obj    = CORE::shift;
        my $name   = CORE::shift;
        my $caller = caller;
        my $rv     = !$obj->isStale;

        if ($rv) {
            $rv = undef;
            $name = $obj->_gatekeeper( $caller, $name );
            if ( defined $name ) {
                if ( ref $properties[$$obj]{$name}[CEH_PVAL] eq 'ARRAY' ) {
                    $rv = CORE::pop @{ $properties[$$obj]{$name}[CEH_PVAL] };
                } else {
                    $@ = 'pop attempted on a non-array property';
                    carp $@;
                }
            }
        } else {
            $@ = 'pop method called on a stale object';
            carp $@;
        }

        return $rv;
    }

    sub unshift {

        # Purpose:  Performs an unshift operation on an array property
        # Returns:  RV of CORE::unshift or undef
        # Usage:    $rv = $obj->unshift($name, @values);

        my $obj    = CORE::shift;
        my $name   = CORE::shift;
        my @val    = @_;
        my $caller = caller;
        my $rv     = !$obj->isStale;

        if ($rv) {
            $rv = undef;
            $name = $obj->_gatekeeper( $caller, $name );
            if ( defined $name ) {
                if ( ref $properties[$$obj]{$name}[CEH_PVAL] eq 'ARRAY' ) {
                    $rv =
                        CORE::unshift @{ $properties[$$obj]{$name}[CEH_PVAL]
                        },
                        @val;
                } else {
                    $@ = 'unshift attempted on a non-array property';
                    carp $@;
                }
            }
        } else {
            $@ = 'unshift method called on a stale object';
            carp $@;
        }

        return $rv;
    }

    sub shift {

        # Purpose:  Performs a shift operation on an array property
        # Returns:  RV of CORE::shift or undef
        # Usage:    $rv = $obj->shift($name);

        my $obj    = CORE::shift;
        my $name   = CORE::shift;
        my $caller = caller;
        my $rv     = !$obj->isStale;

        if ($rv) {
            $rv = undef;
            $name = $obj->_gatekeeper( $caller, $name );
            if ( defined $name ) {
                if ( ref $properties[$$obj]{$name}[CEH_PVAL] eq 'ARRAY' ) {
                    $rv =
                        CORE::shift @{ $properties[$$obj]{$name}[CEH_PVAL] };
                } else {
                    $@ = 'shift attempted on a non-array property';
                    carp $@;
                }
            }
        } else {
            $@ = 'shift method called on a stale object';
            carp $@;
        }

        return $rv;
    }

    sub exists {

        # Purpose:  Performs an exists operation on a hash property
        # Returns:  RV of CORE::exists or undef
        # Usage:    $rv = $obj->exists($name, $key);

        my $obj    = CORE::shift;
        my $name   = CORE::shift;
        my $key    = CORE::shift;
        my $caller = caller;
        my $rv     = !$obj->isStale;

        if ($rv) {
            $rv = undef;
            $name = $obj->_gatekeeper( $caller, $name );
            if ( defined $name ) {
                if ( ref $properties[$$obj]{$name}[CEH_PVAL] eq 'HASH' ) {
                    $rv =
                        CORE::exists $properties[$$obj]{$name}[CEH_PVAL]
                        {$key};
                } else {
                    $@ = 'exists attempted on a non-hash property';
                    carp $@;
                }
            }
        } else {
            $@ = 'exists method called on a stale object';
            carp $@;
        }

        return $rv;
    }

    sub keys {

        # Purpose:  Performs a keys operation on a hash property
        # Returns:  RV of CORE::keys or empty array
        # Usage:    $rv = $obj->keys($name);

        my $obj    = CORE::shift;
        my $name   = CORE::shift;
        my $caller = caller;
        my @rv;

        if ( !$obj->isStale ) {
            $name = $obj->_gatekeeper( $caller, $name );
            if ( defined $name ) {
                if ( ref $properties[$$obj]{$name}[CEH_PVAL] eq 'HASH' ) {
                    @rv = CORE::keys %{ $properties[$$obj]{$name}[CEH_PVAL] };
                } else {
                    $@ = 'keys attempted on a non-hash property';
                    carp $@;
                }
            }
        } else {
            $@ = 'keys method called on a stale object';
            carp $@;
        }

        return @rv;
    }

    sub merge {

        # Purpose:  Merges the specified ordinal or associated records into
        #           the named property
        # Returns:  Boolean
        # Usage:    $rv = $obj->merge($name, 'foo' => 'bar');
        # Usage:    $rv = $obj->merge($name, 1 => 'bar');

        my $obj     = CORE::shift;
        my $name    = CORE::shift;
        my %updates = @_;
        my $rv      = !$obj->isStale;
        my $caller  = caller;
        my ( $k, $v );

        if ($rv) {
            $name = $obj->_gatekeeper( $caller, $name );
            if ( defined $name ) {
                if ( ref $properties[$$obj]{$name}[CEH_PVAL] eq 'ARRAY' ) {
                    while ( ( $k, $v ) = each %updates ) {
                        $properties[$$obj]{$name}[CEH_PVAL][$k] = $v;
                    }
                } elsif ( ref $properties[$$obj]{$name}[CEH_PVAL] eq 'HASH' )
                {
                    while ( ( $k, $v ) = each %updates ) {
                        $properties[$$obj]{$name}[CEH_PVAL]{$k} = $v;
                    }
                } else {
                    $@ = 'merge attempted on a non-hash/array property';
                    carp $@;
                }
            }
        } else {
            $@ = 'merge method called on a stale object';
            carp $@;
        }

        return $rv;
    }

    sub subset {

        # Purpose:  Returns the associated or ordinal values from the named
        #           property
        # Returns:  Array of values
        # Usage:    @values = $obj->subset($name, qw(foo bar));
        # Usage:    @values = $obj->subset($name, 1, 7);

        my $obj    = CORE::shift;
        my $name   = CORE::shift;
        my @keys   = @_;
        my $caller = caller;
        my ( @rv, $k, $l );

        if ( !$obj->isStale ) {
            $name = $obj->_gatekeeper( $caller, $name );
            if ( defined $name ) {
                if ( ref $properties[$$obj]{$name}[CEH_PVAL] eq 'ARRAY' ) {
                    $l = $#{ $properties[$$obj]{$name}[CEH_PVAL] };
                    foreach $k (@keys) {
                        CORE::push @rv, (
                              $k <= $l
                            ? $properties[$$obj]{$name}[CEH_PVAL][$k]
                            : undef
                            );
                    }
                } elsif ( ref $properties[$$obj]{$name}[CEH_PVAL] eq 'HASH' )
                {
                    foreach $k (@keys) {
                        CORE::push @rv, (
                            CORE::exists $properties[$$obj]{$name}[CEH_PVAL]
                                {$k}
                            ? $properties[$$obj]{$name}[CEH_PVAL]{$k}
                            : undef
                            );
                    }
                } else {
                    $@ = 'subset attempted on a non-hash/array property';
                    carp $@;
                }
            }
        } else {
            $@ = 'subset method called on a stale object';
            carp $@;
        }

        return @rv;
    }

    sub remove {

        # Purpose:  Removes the ordinal or associated values from the named
        #           property
        # Returns:  Boolean
        # Usage:    $rv = $obj->remove($name, qw(foo bar));
        # Usage:    $rv = $obj->remove($name, 5, 8);

        my $obj    = CORE::shift;
        my $name   = CORE::shift;
        my @keys   = @_;
        my $caller = caller;
        my $rv     = !$obj->isStale;
        my ( $k, $l );

        if ($rv) {
            $name = $obj->_gatekeeper( $caller, $name );
            if ( defined $name ) {
                if ( ref $properties[$$obj]{$name}[CEH_PVAL] eq 'ARRAY' ) {
                    $l = $#{ $properties[$$obj]{$name}[CEH_PVAL] };
                    foreach $k ( sort { $b <=> $a } @keys ) {
                        splice @{ $properties[$$obj]{$name}[CEH_PVAL] }, $k, 1
                            unless $k > $l;
                    }
                } elsif ( ref $properties[$$obj]{$name}[CEH_PVAL] eq 'HASH' )
                {
                    foreach $k (@keys) {
                        delete $properties[$$obj]{$name}[CEH_PVAL]{$k};
                    }
                } else {
                    $@ = 'remove attempted on a non-hash/array property';
                    carp $@;
                }
            }
        } else {
            $@ = 'remove method called on a stale object';
            carp $@;
        }

        return $rv;
    }

    sub empty {

        # Purpose:  Empties the named array or hash property
        # Returns:  Boolean
        # Usage:    $rv = $obj->empty($name);

        my $obj    = CORE::shift;
        my $name   = CORE::shift;
        my $caller = caller;
        my $rv     = !$obj->isStale;

        if ($rv) {
            $name = $obj->_gatekeeper( $caller, $name );
            if ( defined $name ) {
                if ( ref $properties[$$obj]{$name}[CEH_PVAL] eq 'ARRAY' ) {
                    @{ $properties[$$obj]{$name}[CEH_PVAL] } = ();
                } elsif ( ref $properties[$$obj]{$name}[CEH_PVAL] eq 'HASH' )
                {
                    %{ $properties[$$obj]{$name}[CEH_PVAL] } = ();
                } else {
                    $@ = 'empty attempted on a non-hash/array property';
                    carp $@;
                }
            }
        } else {
            $@ = 'empty method called on a stale object';
            carp $@;
        }

        return $rv;
    }

    sub properties {

        # Purpose:  Returns a list of property names visible to the caller
        # Returns:  Array of scalars
        # Usage:    @names = $obj->properties;

        my $obj    = CORE::shift;
        my $caller = caller;
        my @pnames = CORE::keys %{ $properties[$$obj] };
        my @rv;

        # Populate with all the public properties
        @rv =
            grep { $properties[$$obj]{$_}[CEH_PATTR] & CEH_PUB } @pnames;

        # Add restricted properties if the caller is a subclass
        if ( $caller eq ref $obj
            or "$caller"->isa($obj) ) {
            CORE::push @rv,
                grep { $properties[$$obj]{$_}[CEH_PATTR] & CEH_RESTR }
                @pnames;
        }

        # Add private properties if the caller is the same class
        if ( $caller eq ref $obj ) {
            foreach ( grep /^\Q$caller*\E/s, @pnames ) {
                CORE::push @rv, $_;
                $rv[$#rv] =~ s/^\Q$caller*\E//s;
            }
        }

        return @rv;
    }

    sub _initProperties {

        # Purpose:  Initializes the property data for the object
        # Returns:  Boolean
        # Usage:    $rv = _initProperties($obj);

        my $obj     = CORE::shift;
        my @classes = _getClasses($obj);
        my $rv      = 1;
        my ( $class, @_properties, $prop, $pattr, $pscope, $pname );

        # Initialize storage
        $properties[$$obj] = {};

        # Load properties from top of class hierarchy down
        foreach $class (@classes) {

            # Get the contents of the class array
            {
                no strict 'refs';

                @_properties =
                    defined *{"${class}::_properties"}
                    ? @{ *{"${class}::_properties"}{ARRAY} }
                    : ();
            }

            # Process the list
            foreach $prop (@_properties) {
                next unless defined $prop;

                unless (
                    __declProperty(
                        $class, $obj, @$prop[ CEH_PNAME, CEH_PATTR ] )
                    ) {
                    $rv = 0;
                    last;
                }

                # Set the default values
                if ( $rv and defined $$prop[CEH_PVAL] ) {

                    # Get the attribute type, scope, and internal prop name
                    $pattr  = $$prop[CEH_PATTR] & CEH_PATTR_TYPE;
                    $pscope = $$prop[CEH_PATTR] & CEH_PATTR_SCOPE;
                    $pname =
                        $pscope == CEH_PRIV
                        ? "${class}::$$prop[CEH_PNAME]"
                        : $$prop[CEH_PNAME];

                    # Store the default values
                    $rv = $obj->_setProperty( $pname,
                          $pattr == CEH_ARRAY ? @{ $$prop[CEH_PVAL] }
                        : $pattr == CEH_HASH  ? %{ $$prop[CEH_PVAL] }
                        :                       $$prop[CEH_PVAL] );
                }

                last unless $rv;
            }

        }

        return $rv;
    }

    sub _destrProperties {

        # Purpose:  Destroys the object's property data
        # Returns:  Boolean
        # Usage:    $rv = _destrProperties($obj);

        my $obj = CORE::shift;

        $properties[$$obj] = undef;

        return 1;
    }

}

{
    my %classes;    # Class => 1
    my %methods;    # Class::Method => 1

    sub __declMethod {

        # Purpose:  Registers a list of methods as scoped
        # Returns:  Boolean
        # Usage:    $rv = __declMethod($class, $attr, $methods);

        my $pkg    = CORE::shift;
        my $attr   = CORE::shift;
        my $method = CORE::shift;
        my $rv     = 1;
        my ( $code, $mfqn );

        if ( defined $attr and defined $method and length $method ) {

            # Quiet some warnings
            no warnings qw(redefine prototype);
            no strict 'refs';

            # Get the fully qualified method name and associated code
            # block
            $mfqn = "${pkg}::${method}";
            $code = *{$mfqn}{CODE};

            # Quick check to see if we've done this already -- if so
            # we skip to the next
            return 1 if CORE::exists $methods{$mfqn};

            if ( defined $code ) {

                # Repackage
                if ( $attr == CEH_PRIV ) {

                    # Private methods
                    *{$mfqn} = sub {
                        my $caller = caller;
                        goto &{$code} if $caller eq $pkg;
                        $@ = 'Attempted to call private method '
                            . "$method from $caller";
                        carp $@;
                        return 0;
                    };

                } elsif ( $attr == CEH_RESTR ) {

                    # Restricted methods
                    *{$mfqn} = sub {
                        my $caller = caller;
                        goto &{$code} if "$caller"->isa($pkg);
                        $@ = 'Attempted to call restricted method '
                            . "$method from $caller";
                        carp $@;
                        return 0;
                    };
                } elsif ( $attr == CEH_PUB ) {

                    # Do nothing

                } else {
                    $@ = 'invalid method declaration';
                    carp $@;
                    $rv = 0;
                }

                # Record our handling of this method
                $methods{$mfqn} = 1 if $rv;

            }

        } else {
            $@ = 'invalid method declaration';
            carp $@;
            $rv = 0;
        }

        return $rv;
    }

    sub _declMethod {

        # Purpose:  Wrapper for __declMethod, this is the public interface
        # Returns:  RV of __declMethod
        # Usage:    $rv = _declMethod($attr, @propNames);

        my $attr   = CORE::shift;
        my $method = CORE::shift;
        my $caller = caller;
        my $rv     = 1;

        if ( defined $method and length $method ) {
            $rv = __declMethod( $caller, $attr, $method );
        } else {
            $@ = '_declMethod function called with an invalid method';
            carp $@;
            $rv = 0;
        }

        return $rv;
    }

    sub _initMethods {

        # Purpose:  Loads methods from @_methods
        # Returns:  Boolean
        # Usage:    $rv = _loadMethods();

        my $obj     = CORE::shift;
        my @classes = _getClasses($obj);
        my $rv      = 1;
        my ( $class, @_methods, $method );

        # Load methods from the top of the class hierarchy down
        foreach $class (@classes) {

            # Skip if the class has already been processed
            next if CORE::exists $classes{$class};

            # Get the contents of the class array
            {
                no strict 'refs';

                @_methods = @{ *{"${class}::_methods"}{ARRAY} }
                    if defined *{"${class}::_methods"};
            }

            # Process the list
            foreach $method (@_methods) {
                next unless defined $method;
                unless (
                    __declMethod( $class, @$method[ CEH_PATTR, CEH_PPKG ] ) )
                {
                    $rv = 0;
                    last;
                }
            }

            # Mark the class as processed
            $classes{$class} = 1;
        }

        return $rv;
    }

}

##########################################################
# Class Constructors/Destructors
##########################################################

sub new {

    # Purpose:  Class constructor for all (sub)classes
    # Returns:  Reference
    # Usage:    $obj = new SUBCLASS;
    my $class = CORE::shift;
    my @args  = @_;
    my $obj   = bless \do { my $anon_scalar }, $class;
    my $rv;

    # Get the next available ID
    $rv = _getID($obj);

    # Initialize alias support
    $rv = _initAlias($obj) if $rv;

    # Initialize property scope support
    $rv = _initProperties($obj) if $rv;

    # Initialize method scope support
    $rv = _initMethods($obj) if $rv;

    # Initialize the hierarchal code support
    $rv = _initHierarchy( $obj, $class, @args ) if $rv;

    return $rv ? $obj : undef;
}

sub conceive {

    # Purpose:  Same as new() but with hierarchal relationships pre-installed
    # Returns:  Reference
    # Usage:    SubClass->conceive($parent, @args);

    my $class = CORE::shift;
    my $pobj  = CORE::shift;
    my @args  = @_;
    my $obj   = bless \do { my $anon_scalar }, $class;
    my $rv    = 1;

    # Get the next available ID
    $rv = _getID($obj) if $rv;

    # Adopt the object before we do anything else
    $rv = $pobj->_adopt($obj) if $rv;

    # Initialize property scope support
    $rv = _initProperties($obj) if $rv;

    # Initialize method scope support
    $rv = _initMethods($obj) if $rv;

    # Initialize the hierarchal code support
    $rv = _initHierarchy( $obj, $class, @args ) if $rv;

    # Disown the object if we've failed initialization
    $pobj->_disown($obj) unless $rv;

    return $rv ? $obj : undef;
}

sub DESTROY {

    # Purpose:  Garbage collection
    # Returns:  Boolean
    # Usage:    $obj->DESTROY();

    my $obj = CORE::shift;
    my ( $class, @classes );

    # Test to see if this is a stale reference
    unless ( !defined $$obj or $obj->isStale ) {

        # Destroy from the top of the tree down
        foreach ( $obj->children ) { $_->DESTROY if defined }

        # Execute hierarchal destructors
        _destrHierarchy($obj);

        # Destroy aliases
        _destrAlias($obj);

        # Destroy properties
        _destrProperties($obj);

        # Recover the ID
        _delID($obj);
    }

    return 1;
}

END {
    foreach ( _dumpObjects() ) { $_->DESTROY if defined }
}

1;

__END__

=head1 NAME

Class::EHierarchy - Base class for hierarchally ordered objects

=head1 VERSION

$Id: lib/Class/EHierarchy.pm, 2.01 2019/05/23 07:29:49 acorliss Exp $

=head1 SYNOPSIS

    package TelDirectory;

    use Class::EHierarchy qw(:all);
    use vars qw(@ISA @_properties @_methods);

    @ISA = qw(Class::EHierarchy);
    @_properties = (
        [ CEH_PRIV | CEH_SCALAR, 'counter',  0 ],
        [ CEH_PUB | CEH_SCALAR,  'first',   '' ],
        [ CEH_PUB | CEH_SCALAR,  'last',    '' ],
        [ CEH_PUB | CEH_ARRAY,   'telephone'   ]
        );
    @_methods = (
        [ CEH_PRIV,    '_incrCounter' ],
        [ CEH_PUB,     'addTel'       ]
        );

    sub _initalize {
        my $obj     = CORE::shift;
        my %args    = @_;
        my $rv      = 1;

        # Statically defined properties and methods are 
        # defined above.  Dynamically generated
        # properties and methods can be done here.

        return $rv;
    }

    ...

    package main;

    use TelDirectory;

    my $entry = new TelDirectory;

    $entry->set('first', 'John');
    $entry->set('last',  'Doe');
    $entry->push('telephone', '555-111-2222', '555-555'5555');

=head1 DESCRIPTION

B<Class::EHierarchy> is intended for use as a base class for objects that need
support for class or object hierarchies.  Additional features are also
provided which can be useful for general property implementation and
manipulation.

=head2 OBJECT HIERARCHIES

Object relationships are often implemented in application code, as well as the
necessary reference storage to keep dependent objects in scope.  This class
attempts to relive the programmer of that necessity.  To that end, the concept
of an object hierarchy is implemented in this class.

An OOP concept for RDBMS data, for instance, could be modeled as a collection
of objects in the paradigm of a family tree.  The root object could be your
DBI connection handle, while all of the internal data structures as child
objects:

  DBH connection 
    +-> views
    |     +-> view1
    +-> tables
          +-> table1
                +-> rows
                |     +-> row1
                +-> columns

Each type of object in the RDBMS is necessarily defined in context of the
parent object.

This class simplifies the formalization of these relationships, which can have
a couple of benefits.  Consider a row object that was retrieved, for example.
If each of the columns was implmented as a property in the object one could
allow in-memory modification of data with a delayed commit.  When the
connection goes out of scope you could code your application to flush those
in-memory modifications back to the database prior to garbage collection.

This is because garbage collection of an object causes a top-down destruction
of the object tree (or, in the depiction above, bottom-up), with the farthest
removed children reaped first.

Another benefit of defined object hierarchies is that you are no longer
required to keep track of and maintain references to every object in the
tree.  Only the root reference needs to be tracked since the root can also
act as an object container.  All children references can be retrieved at any
time via method calls.

An alias system is also implemented to make children retrieval even more
convenient.  Each table, for instance, could be aliased by their table name.
That allows you to retrieve a table object by name, then, instead of iterating
over the collection of tables until you find one with the attributes you're
seeking.

=head2 CLASS HIERARCHIES

Class hierarchies are another concept meant to allieviate some of the tedium
of coding subclasses.  Traditionally, if you subclassed a class that required
any significant initialization, particularly if it relied on internal data
structures, you would be reduced to executing superclass constructors, then
possibly executing code paths again to account for a few changed properties.

This class explicitly separates assignment of properties from initialization,
allowing you to execute those code paths only once.  OOP implemenations of
mathematical constructs, for instance, could significantly alter the values
derived from objects simply by subclassing and overriding some property
values.  The original class' initializer will be run once, but using the new
property values.

In addition to that this class provides both property and method
compartmentalization so that the original class author can limit the
invasiveness of subclasses.  Both methods and properties can be scoped to
restrict access to both.  You can restrict access to use by only the
implementation class, to subclasses, or keep everything publically available.

=head2 ADDITIONAL FEATURES

The class hierarchal features necessarily make objects derived from this class
opaque objects.  Objects aren't blessed hashes, they are scalar references
with all properties stored in class data structures.

The property implementation was made to be flexible to accomodate most needs.
A property can be a scalar value, but it also can be an array, hash, or a
number of specific types of references.

To make non-scalar properties almost as convenient as the raw data structures
many core functions have been implemented as methods.  This is not just a
semantic convenience, it also has the benefit of working directly on the raw
data stored in the class storage.  Data structures aren't copied, altered, and
stored, they are altered in place for performance.

=head1 CONSTANTS

Functions and constants are provided strictly for use by derived classes 
within their defined methods.  To avoid any confusion all of our exportable 
symbols are *not* exported by default.  You have to specifically import the 
B<all> tag set.  Because these functions should not be used outside of the 
subclass they are all preceded by an underscore, like any other private function.

The following constants are provided for use in defining your properties and
methods.

    Scope
    ---------------------------------------------------------
    CEH_PRIV        private scope
    CEH_RESTR       restricted scope
    CEH_PUB         public scope

    Type
    ---------------------------------------------------------
    CEH_SCALAR      scalar value or reference
    CEH_ARRAY       array
    CEH_HASH        hash
    CEH_CODE        code reference
    CEH_GLOB        glob reference
    CEH_REF         object reference

    Flag
    ---------------------------------------------------------
    CEH_NO_UNDEF    No undef values are allowed to be 
                    assigned to the property

You'll note that both I<@_properties> and I<@_methods> are arrays of arrays,
which each subarray containing the elements for each property or method.  The
first element is always the attributes and the second the name of the property
or method.  In the case of the former a third argument is also allowed:  a
default value for the property:

  @_properties = (
        [ CEH_PUB | CEH_SCALAR, 'first',     'John' ],
        [ CEH_PUB | CEH_SCALAR, 'last',      'Doe' ],
        [ CEH_PUB | CEH_ARRAY,  'telephone', 
            [ qw(555-555-1212 555-555-5555) ] ],
    );

Properties lacking a data type attribute default to B<CEH_SCALAR>.  Likewise,
scope defaults to B<CEH_PUB>.  Public methods can be omitted from I<@_methods> 
since they will be assumed to be public.

Methods only support scoping for attributes. Data types and flags are not
applicable to them.

=head1 SUBROUTINES/METHODS

=head2 new

    $obj = new MyClass;

All of the hierarchal features require bootstrapping in order to work.  For
that reason a constructor is provided which performs that work.  If you wish
to provide additional initialization you can place a B<_initialize> method in
your class which will be called after the core bootstrapping is complete.

=head2 _initialize

    $rv = $obj->_initialize(@args);

The use of this method is optional, but if present it will be called during
the execution of the constructor.  The boolean return value will determine if
the constructor is successful or not.  All superclasses with such a method
will be called prior to the final subclass' method, allowing you to layer
multiple levels of initialization.

Initialization is performed I<after> the assignment of default values to
properties.  If your code is dependent on those values this allows you the
opportunity to override certain defaults -- assuming they are visible to the
subclass -- simply by setting those new defaults in the subclass.

As shown, this method is called with all of the arguments passed to the
constructor, and it expects a boolean return value.

=head2 conceive

    $child = MyClass->conceive($parent, @args);

B<conceive> is an alternate constructor that's intended for those subclasses
with are dependent on relationships to parent objects during initialization.

=head2 DESTROY

    $obj->DESTROY;

Object hierarchal features require orderly destruction of children.  For that
purpose a B<DESTROY> method is provided which performs those tasks.  If you
have specific tasks you need performed prior to the final destruction of an
object you can place a B<_deconstruct> method in your subclass.

=head2 _deconstruct

    $rv = $obj->_desconstruct;

B<_deconstruct> is an optional method which, if present, will be called during
the object's B<DESTROY> phase.  It will be called I<after> all children have
completed thier B<DESTROY> phase.  In keeping with the class hierarchal
features all superclasses will have their B<_deconstruct> methods called after
your subclass' method is called, but prior to finishing the B<DESTROY> phase.

=head2 isStale

    $rv = $obj->isStale;

It is possible that you might have stored a reference to a child object in a
tree.  If you were to kick off destruction of the tne entire object tree by
letting the root object's reference go out of scope the entire tree will be
effectively destroyed.  Your stored child reference will not prevent that from
happening.  At that point you effectively have a stale reference to a
non-functioning object.  This method allows you to detect that scenario.

The primary use for this method is as part of your safety checks in your
methods:

    sub my_method {
        my $obj  = shift;
        my @args = @_;
        my $rv   = !$obj->isStale;

        if ($rv) {

            # Do method work here, update $rv, etc.

        } else {
            carp "called my_method on a stale object!";
        }

        return $rv;
    }

It is important to note that this method is used in every public method
provided by this base class.  All method calls will therefore safely fail if
called on a stale object.

=head2 _declProp

    $rv = _declProp($obj, CEH_PUB | CEH_SCALAR | CEH_NO_UNDEF, @propNames);

This function is used to dynamically create named properties while declaring 
their access scope and type.

Constants describing property attributes are OR'ed together, and only one
scope and one type from each list should be used at a time.  Using multiple
types or scopes to describe any particular property will make it essentially
inaccessible.

B<NOTE:>  I<CEH_NO_UNDEF> only applies to psuedo-scalar types like proper
scalars, references, etc.  This has no effect on array members or hash values.

=head2 _declMethod

    $rv = _declMethod(CEH_RESTR, @methods);

This function is is used to create wrappers for those functions whose access 
you want to restrict.  It works along the same lines as properties and uses 
the same scoping constants for the attribute.

Only methods defined within the subclass can have scoping declared.  You
cannot call this method for inherited methods.

B<NOTE:> Since scoping is applied to the class symbol table (B<not> on a 
per object basis) any given method can only be scoped once.  That means you 
can't do crazy things like make public methods private, or vice-versa.

=head2 adopt

    $rv = $obj->adopt($cobj1, $cobj2);

This method attempts to adopt the passed objects as children.  It returns a
boolean value which is true only if all objects were successfully adopted.
Only subclasses for L<Class::EHierarchy> can be adopted.  Any object that
isn't based on this class will cause this method to return a false value.

=head2 disown

    $rv = $obj->disown($cobj1, $cobj2);

This method attempts to disown all the passed objects as children.  It returns
a boolean value based on its success in doing so.  Asking it to disown an
object it had never adopted in the first place will be silently ignored and
still return true.

Disowning objects is a prerequisite for Perl's garbage collection to work and
release those objects completely from memory.  The B<DESTROY> method provided
by this class automatically does this for parent objects going out of scope.
You may still need to do this explicitly if your parent object manages objects
which may need to be released well prior to any garbage collection on the
parent.

=head2 parent

    $parent = $obj->parent;

This method returns a reference to this object's parent object, or undef if it
has no parent.

=head2 children

    @crefs = $obj->children;

This method returns an array of object references to every object that was
adopted by the current object.

=head2 descendents

    @descendents = $obj->descendents;

This method returns an array of object references to every object descended
from the current object.

=head2 siblings

    @crefs = $obj->siblings;

This method returns an array of object references to every object that shares
the same parent as the current object.

=head2 root

    $root = $obj->root;

This method returns a reference to the root object in this object's ancestral
tree.  In other words, the senior most parent in the current hierarchy.

=head2 alias

    $rv = $obj->alias($new_alias);

This method sets the alias for the object, returning a boolean value.
This can be false if the proposed alias is already in use by another 
object in its hierarchy.

=head2 getByAlias

    $ref = $obj->getByAlias($name);

This method returns an object reference from within the object's current
object hierarchy by name.  It will return undef if the alias is not in use.

=head2 set

    $rv  = $obj->set('FooScalar', 'random text or reference');
    $rv  = $obj->set('FooArray', @foo);
    $rv  = $obj->set('FooHash',  %foo);

This method provides a generic property write accessor that abides by the 
scoping attributes given by B<_declProp> or B<@_properties>.  This means 
that basic reference types are checked for during assignment, as well as 
flags like B<CEH_NO_UNDEF>.

=head2 get

    $val = $obj->get('FooScalar');
    @val = $obj->get('FooArray');
    %val = $obj->get('FooHash');

This method provides a generic property read accessor.  This will return an
undef for nonexistent properties.

=head2 properties

    @properties = $obj->properties;

This method returns a list of all registered properties for the current
object.  Property names will be filtered appropriately by the caller's 
context.

=head2 push

    $rv = $obj->push($prop, @values);

This method pushes additional elements onto the specified array property.
It returns the return value from the B<push> function, or undef on
non-existent properties or invalid types.

=head2 pop

    $rv = $obj->pop($prop);

This method pops an element off of the specified array property.  
It returns the return value from the B<pop> function, or undef on
non-existent properties or invalid types.

=head2 unshift

    $rv = $obj->unshift($prop, @values);

This method unshifts additional elements onto the specified array property.
It returns the return value from the B<unshift> function, or undef on
non-existent properties or invalid types.

=head2 shift

    $rv = $obj->shift($prop);

This method shifts an element off of the specified array property.  
It returns the return value from the B<shift> function, or undef on
non-existent properties or invalid types.

=head2 exists

    $rv = $obj->exists($prop, $key);

This method checks for the existence of the specified key in the hash
property.  It returns the return value from the B<exists> function, or 
undef on non-existent properties or invalid types.

=head2 keys

    @keys = $obj->keys($prop);

This method returns a list of keys from the specified hash property. 
It returns the return value from the B<keys> function, or undef on
non-existent properties or invalid types.

=head2 merge

    $obj->merge($prop, foo => bar);
    $obj->merge($prop, 4 => foo, 5 => bar);

This method is a unified method for storing elements in both hashes and 
arrays.  Hashes elements are simply key/value pairs, while array elements 
are provided as ordinal index/value pairs.  It returns a boolean value.

=head2 subset

    @values = $obj->subset($hash, qw(foo bar) );
    @values = $obj->subset($array, 3 .. 5 );

This method is a unified method for retrieving specific element(s) from both
hashes and arrays.  Hash values are retrieved in the order of the specified
keys, while array elements are retrieved in the order of the specified ordinal
indexes.

=head2 remove

    $obj->remove($prop, @keys);
    $obj->remove($prop, 5, 8 .. 10);

This method is a unified method for removing specific elements from both
hashes and arrays.  A list of keys is needed for hash elements, a list of
ordinal indexes is needed for arrays.

B<NOTE:> In the case of arrays please note that an element removed in the
middle of an array does cause the following elements to be shifted
accordingly.  This method is really only useful for removing a few elements at
a time from an array.  Using it for large swaths of elements will likely prove
it to be poorly performing.  You're better of retrieving the entire array
yourself via the B<property> method, splicing what you need, and calling
B<property> again to set the new array contents.

=head2 empty

    $rv = $obj->empty($name);

This is a unified method for emptying both array and hash properties.  This
returns a boolean value.

=head1 DEPENDENCIES

None.

=head1 BUGS AND LIMITATIONS 

=head1 CREDIT

The notion and portions of the implementation of opaque objects were lifted
from Damian Conway's L<Class::Std(3)> module.  Conway has a multitude of great
ideas, and I'm grateful that he shares so much with the community.

=head1 AUTHOR 

Arthur Corliss (corliss@digitalmages.com)

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl, itself. 
Please see http://dev.perl.org/licenses/ for more information.

(c) 2017, Arthur Corliss (corliss@digitalmages.com)

