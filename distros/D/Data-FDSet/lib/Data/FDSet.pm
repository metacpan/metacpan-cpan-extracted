package Data::FDSet;

use strict;
use warnings;

our $VERSION;
BEGIN {
    $VERSION = '0.02';
}

=encoding utf-8

=head1 NAME

Data::FDSet - Syntactic sugar for L<select()|perlfunc/select> masks

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This little module makes working with 4-argument L<select()|perlfunc/select>
a bit easier by providing object methods to do the typical operations done
on the bitmasks in connection with that function. These methods parallel
the functions that C provides to handle C<struct fd_set>.

=cut

#----------------------------------------------------------------------

=head1 INTERFACE NOTE

A Data::FDSet object is a blessed scalar reference to a bitmask.
Unlike with most Perl objects, you may safely reference the object
internals, e.g., by doing

    $$rout_obj = $rin;

… to replace the bitmask contents. (For this reason, this class defines
no method to do the above.)

=head1 METHODS

=head2 $obj = I<CLASS>->new( [ $BITMASK ] );

Instantiates this class. $BITMASK may optionally be passed to
initialize the object state.

=cut

sub new {
    my ($class) = @_;

    my $sr = defined($_[1]) ? \$_[1] : \do { my $v = q<> };

    return bless $sr, $class;
}

=head2 $obj = I<OBJ>->evacuate()

Empty out the object. Analogous to L<FD_ZERO(2)>.

Returns I<OBJ>.

=cut

sub evacuate {
    ${ $_[0] } = q<>;

    return $_[0];
}

=head2 $obj = I<OBJ>->add( $FD_OR_FH [, $FD_OR_FH, .. ] )

Add one or more file descriptors to the object.
Accepts either Perl filehandles or file descriptors.
Analogous to L<FD_SET(2)>.

=cut

sub add {
    for my $arg ( @_[ 1 .. $#_ ] ) {
        vec( ${ $_[0] }, defined(fileno($arg)) ? fileno($arg) : $arg, 1 ) = 1;
    }

    return $_[0];
}

=head2 $obj = I<OBJ>->remove( $FD_OR_FH [, $FD_OR_FH, .. ] )

The complement of C<add()>.
Analogous to L<FD_CLR(2)>.

=cut

sub remove {
    for my $arg ( @_[ 1 .. $#_ ] ) {
        vec( ${ $_[0] }, defined(fileno($arg)) ? fileno($arg) : $arg, 1 ) = 0;
    }

    return $_[0];
}

=head2 $yn = I<OBJ>->has( $FD_OR_FH )

Tests for a file descriptor’s presence in the object.
Accepts either a Perl filehandles or a file descriptor.
Analogous to L<FD_ISSET(2)>.

=cut

sub has {
    return vec( ${ $_[0] }, defined(fileno($_[1])) ? fileno($_[1]) : $_[1], 1 );
}

=head2 $fds_ar = I<OBJ>->get_fds()

Returns a reference to an array of the file descriptors that are
in the object.

=cut

sub get_fds {
    my $max = 8 * length(${ $_[0] }) - 1;

    my @fds;

    for my $fd ( 0 .. $max ) {
        if ( vec(${ $_[0] }, $fd, 1) ) {
            push @fds, $fd;
        }
    }

    return \@fds;
}

1;
