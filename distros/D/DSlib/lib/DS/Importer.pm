#!perl

# ########################################################################## #
# Title:         Data stream importer
# Creation date: 2007-03-05
# Author:        Michael Zedeler
# Description:   Generates data stream data
#                Data Stream class
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Importer.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# #TODO Importers should not by default be constructed with an explicit typespec, since this may be derived from the data source
# ########################################################################## #

package DS::Importer;

use base qw{ DS::Source };

use strict;
use Carp qw{ croak cluck };
require Carp::Assert;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.2 $' =~ /(\d+\.\d+)/;

#TODO Add $row to to constructor

# This method fetches 
sub execute {
    my( $self, $rows ) = @_;
    $rows = -1 unless $rows;
    while( $rows-- != 0 ) {
        my $result = $self->_fetch();
        $self->pass_row( $result );
        # Exit if we just passed end of stream.
        last if not defined( $result );
    }
}

# Fetches one row from underlying data source and returns it to caller.
# When end of data source has been reached, this method MUST return undef on
# all subsequent calls.
# Note that this method doesn't pass anything on to any attached
# target.
# When writing importers, this is the method you will want to override.
# This method is private.
sub _fetch {
    croak("This method must be overridden.");
}

1;

__END__
=pod

=head1 NAME

DS::Importer - component that retrieves data from outside DS and passes it
down a processing chain.

=head1 DESCRIPTION

This is the base class of any component that is supposed to retrieve data
from outside a processing chain and pass it on as rows. The name refers to a
component that imports data into a chain.

=head1 SUPER CLASSES

L<DS::Source>

=head1 METHODS

=head2 execute( $num_rows )

Will call C<fetch> pass the results on by calling C<pass_row> with the result, 
stopping after fetching C<$num_rows> or passing on end of stream (whichever
comes first).

=head2 fetch

This method is supposed to retrieve a row from the underlying data source and
return it. Must return undef to indicate end of stream. Multiple calls after
end of stream should still result in returning undef.

=head2 new( $class, $out_type, $target )

Constructor. Instantiates an object of class C<$class>, returning the type 
C<$out_type>, attaced to the target C<$target>. Besides C<$class>,
any of the parameters can be left out.

=head3 INHERITED METHODS

Methods inherited from L<DS::Source>:

=over

=item attach_target( $target )

=item target( $target )

=item pass_row( $row )

=item out_type( $type )

=back

=head1 SEE ALSO

L<DS::Importer>, L<DS::Transformer>, L<DS::Target>.

=head1 AUTHOR

Written by Michael Zedeler.
