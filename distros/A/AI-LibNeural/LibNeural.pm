#
# $Header$
#

package AI::LibNeural;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);

# This allows declaration	use AI::LibNeural ':all';
our %EXPORT_TAGS = ( 'all' => [ qw(
	ALL
	HIDDEN
	INPUT
	OUTPUT
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '0.02';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.
    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/ || $!{EINVAL}) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Your vendor has not defined AI::LibNeural macro $constname";
	}
    }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#	if ($] >= 5.00561) {
#	    *$AUTOLOAD = sub () { $val };
#	}
#	else {
	    *$AUTOLOAD = sub { $val };
#	}
    }
    goto &$AUTOLOAD;
}

bootstrap AI::LibNeural $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

AI::LibNeural - Perl extension libneural

=head1 SYNOPSIS

  use AI::LibNeural;

  my $nn = AI::LibNeural->new( 2, 4, 1 );

  # teach it the logical AND
  $nn->train( [ 0, 0 ], [ 0.05 ], 0.0000000005, 0.2 );
  $nn->train( [ 0, 1 ], [ 0.05 ], 0.0000000005, 0.2 );
  $nn->train( [ 1, 0 ], [ 0.05 ], 0.0000000005, 0.2 );
  $nn->train( [ 1, 1 ], [ 0.95 ], 0.0000000005, 0.2 );

  my $result = $nn->run( [ 1, 1 ] );
  # result should be ~ 0.95
  $result = $nn->run( [ 0, 1 ] );
  # result should be ~ 0.05

  $nn->save('and.mem');

=head1 ABSTRACT

  Perl bindings for the libneural c++ neural netowrk library.

=head1 DESCRIPTION

Provides accessors for the libneural library as a perl object. libneural is a
C++ library that impelements a feed-forward back-proprogation neural network.
The interface is extremely simple and should take no more than a few minutes to
master given a reasonable knowledge of back proprogation neural networks.

=head2 FUNCTIONS

=over

=item $nn = AI:LibNeural->new()

Creates an empty AI::LibNeural object, should only be used when the load method
will be called soon after.

=item $nn = AI::LibNeural->new(FILENAME)

Creates a new AI::LibNeural object from the supplied memory file.

=item $nn = AI::LibNeural->new(INTPUTS,HIDDENS,OUTPUTS)

Creates a new AI::LibNeural object with INPUTS input nodes, HIDDENS hidden
nodes, and OUTPUTS output nodes.

=item $nn->train([I1,I2,...],[O1,O2,...],MINERR,TRAINRATE)

Completes a training cycle for the given inputs I1-IN, with the expected
results of O1-OM, where N is the number of inputs and M is the number of
outputs. MINERR is the mean squared error at the output that you wish to be achieved. TRAINRATE is the learning rate to be used.

=item (O1,O2) = $nn->run([I1,I2,...])

Calculate the corresponding outputs (O1-OM) for the given inputs (I1-ON) based
on the previous training. Should only be called after the network has been
suitably trained.

=item NUM = $nn->get_layersize(WHICH)

Retrieves the number of nodes at the specified layer, WHICH. WHICH should be
one of ALL, INPUT, HIDDEN, OUTPUT. Usefully mainly with a network is loaded
from a file.

=item status = $nn->load(FILENAME)

=item status = $nn->save(FILENAME)

Loads and saves respectively the 'memory,' node configuration and weights,
of the network.  FILENAME should be the location of the file in which the
memory is stored/retrieved.

=back

=head2 EXPORT

None by default

=head2 EXPORT TAGS

=over

=item all

=over

=item ALL

  The total number of nodes on all three layers

=item INPUT

  The number of nodes on the input layer

=item HIDDEN

  The number of nodes on the hidden layer

=item OUTPUT

  The number of nodes on the output layer

=back

=back

=head1 AUTHOR

Ross McFarland E<lt>rmcfarla at neces dot comE<gt>

=head1 SEE ALSO

L<perl>. libneural documentation

=head1 LICENSE

this is based off of code that i based off of other modules i've found in the
distant past. if you are the original author and you recognize this code let
me know and you'll be credited

Copyright (C) 2003 by Ross McFarland

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Library General Public
License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the 
Free Software Foundation, Inc., 59 Temple Place - Suite 330, 
Boston, MA  02111-1307  USA.
