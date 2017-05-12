# Type map hooks (Not yet implemented)

Users may need to be able to specify hook functions to customize
serialization and deserialization.  This section describes a possible
design for this feature.

There are three possible types of hooks for serializing and deserializing:
key-specific, type-specific and generic.

Doing key-specific hooks correctly really requires maintaining a deep key
representation, which currently doesn't exist.  Precedence vs type-specific
keys is also unclear. Therefore, this is out of scope.

Type-specific hooks are registered based on type: for serializing, the
result of the `ref` call; for deserializing, the BSON type.  Generic hooks
always run for every element encoded or decoded (unless a type-specific
hook applies); they are discouraged due to the overhead this causes.

## Serialization hooks

Serialization hooks fire early in the encode process, before dispatching
based on a value's type.  The hook receives the key and value (or array
index and value).  It must return a new key/value pair if it modifies
either element (it must not modify an array index).  It must return an
empty list if it makes no changes.  If a type changes and there is a hook
for the new type, the new key/value are re-hooked.

Assuming a generic hook is defined as "type" of `*`, the logic in the
BSON encode function would resemble the following:

    # Given that $key, $value exist
    my $type = ref($value);

    HOOK: {
        my ($old_type, $hook, @repl) = $type;
        if ( $hook = $E_HOOKS{$type} and @repl = $hook->( $key, $value ) ) {
            my $old_type = $type;
            ( $key, $value, $type ) = @repl, ref( $repl[1] );
            redo HOOK if $type ne $old_type and exists $E_HOOKS{$type};
        }
        elsif ( $hook = $E_HOOKS{'*'} and @repl = $hook->( $key, $value ) ) {
            # this branch is separate so it never runs after redo HOOK
            my $old_type = $type;
            ( $key, $value, $type ) = @repl, ref( $repl[1] );
            redo HOOK if $type ne $old_type and exists $E_HOOKS{$type};
        }
    }

After hooks have run, if any, the value must be one of the types that BSON
knows how to serialize.

# Deserialization hooks

Deserialization hooks fire at the end of the decoding process.  BSON first
decodes a BSON field to its default Perl type.  The hook receives the key,
the BSON type and the value.  It must return a new key/value pair if it
modifies either element (it must not modify an array index).  It must
return an empty list if it makes no changes.

Assuming a generic hook is defined as "type" of `*`, the logic in the
BSON decode function would resemble the following:

    # Given that $bson_type, $key, $value exist

    if (    my $hook = $D_HOOKS{$bson_type} || $D_HOOKS{'*'}
        and my @repl = $hook->( $bson_type, $key, $value ) )
    {
        ( $key, $value ) = @repl;
    }

After a hook has run, the key and value are stored in the parent
document in the usual fashion.
