# -*- Mode: perl -*-
#
# $Id: Storable.pm,v 0.1 2001/04/22 17:57:03 ram Exp $
#
#  Copyright (c) 1998-2001, Raphael Manfredi
#  Copyright (c) 2000-2001, Christophe Dehaudt
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Storable.pm,v $
# Revision 0.1  2001/04/22 17:57:03  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use strict;

package CGI::MxScreen::Serializer::Storable;

require CGI::MxScreen::Serializer;
use vars qw(@ISA);
@ISA = qw(CGI::MxScreen::Serializer);

use Carp::Datum;
use Getargs::Long;
use Storable qw(freeze nfreeze thaw);

#
# ->make
#
# Creation routine.
#
# Arguments:
#   -shared		whether stored data can be read by various architectures
#   -compress	whether stored data should be compressed
#
sub make {
	DFEATURE my $f_;
	my $self = bless {}, shift;
	my ($shared, $compress) = xgetargs(@_,
		-shared		=> ['i', 0],
		-compress	=> ['i', 0],
	);

	my $freezer = $shared ? \&nfreeze : \&freeze;
	$self->_init($freezer, \&thaw, $compress);

	return DVAL $self;
}

1;

=head1 NAME

CGI::MxScreen::Serializer::Storable - Storable serialization

=head1 SYNOPSIS

 # Inherits from CGI::MxScreen::Serializer

 require CGI::MxScreen::Serializer::Storable;

 my $ser = CGI::MxScreen::Serializer::Storable->make(
     -shared     => 1,
     -compress   => 1,
 );

=head1 DESCRIPTION

This module customizes the serialization interface inherited from
C<CGI::MxScreen::Serializer> to use C<Storable>.

Apart from the creation routine documented hereinafter, this class
conforms to the interface described in L<CGI::MxScreen::Serializer>.

The creation routine C<make()> takes the following optional arguments:

=over 4

=item C<-compress> => I<flag>

Whether to compress the serialized form before returning it.
Data will be uncompressed on-the-fly by the C<deserialize> routine.
It is I<false> by default.

This makes compression transparent once configured.

=item C<-shared> => I<flag>

Whether serialized data are expected to be shared across different
architectures.  When I<true>, C<Storable> will use its portable format
to perform the serialization.  Otherwise, data can normally be recovered
only on a compatible architecture.

It is I<false> by default.

=back

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

CGI::MxScreen::Serializer(3), Storable(3).

=cut

