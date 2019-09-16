# NAME

Data::FDSet - Syntactic sugar for [select()](https://metacpan.org/pod/perlfunc#select) masks

# SYNOPSIS

Object-oriented syntax:

    my $fdset = Data::FDSet->new();

    # These accept either filehandles or file descriptors:
    $fdset->add( $some_filehandle, fileno($other_fh) );
    $fdset->remove( $other_fh );

    my $rout = Data::FDSet->new();

    my $got = select( $$rout = $$fdset, undef, undef, 10 );

    if ($got > 1) {
        my $fds_to_read_ar = $rout->get_fds();
    }

Or, if you’d rather avoid object-oriented syntax:

    my $rout = q<>;
    Data::FDSet::add(\$rout, $some_filehandle, fileno($other_fh))

    my $fds_to_read_ar = Data::FDSet::get_fds(\$rout);

# DESCRIPTION

This little module makes working with 4-argument [select()](https://metacpan.org/pod/perlfunc#select)
a bit easier by providing object methods to do the typical operations done
on the bitmasks in connection with that function. These methods parallel
the functions that C provides to handle `struct fd_set`.

# INTERFACE NOTE

A Data::FDSet object is a blessed scalar reference to a bitmask.
Unlike with most Perl objects, you may safely reference the object
internals, e.g., by doing

    $$rout_obj = $rin;

… to replace the bitmask contents. (For this reason, this class defines
no method to do the above.)

# METHODS

## $obj = _CLASS_->new( \[ $BITMASK \] );

Instantiates this class. $BITMASK may optionally be passed to
initialize the object state.

## $obj = _OBJ_->evacuate()

Empty out the object. Analogous to [FD\_ZERO(2)](http://man.he.net/man2/FD_ZERO).

Returns _OBJ_.

## $obj = _OBJ_->add( $FD\_OR\_FH \[, $FD\_OR\_FH, .. \] )

Add one or more file descriptors to the object.
Accepts either Perl filehandles or file descriptors.
Analogous to [FD\_SET(2)](http://man.he.net/man2/FD_SET).

## $obj = _OBJ_->remove( $FD\_OR\_FH \[, $FD\_OR\_FH, .. \] )

The complement of `add()`.
Analogous to [FD\_CLR(2)](http://man.he.net/man2/FD_CLR).

## $yn = _OBJ_->has( $FD\_OR\_FH )

Tests for a file descriptor’s presence in the object.
Accepts either a Perl filehandles or a file descriptor.
Analogous to [FD\_ISSET(2)](http://man.he.net/man2/FD_ISSET).

## $fds\_ar = _OBJ_->get\_fds()

Returns a reference to an array of the file descriptors that are
in the object.
