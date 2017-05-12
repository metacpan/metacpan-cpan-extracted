#
# This file is part of CatalystX-Test-Recorder
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package MyApp;
use Moose;
extends 'Catalyst';
__PACKAGE__->config( 'CatalystX::Test::Recorder' => { skip => [qr/^static/], namespace => 'recorder' } );
__PACKAGE__->setup(qw(+CatalystX::Test::Recorder));
1;