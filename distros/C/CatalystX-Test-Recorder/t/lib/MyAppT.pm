#
# This file is part of CatalystX-Test-Recorder
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package MyAppT;
use Moose;
extends 'Catalyst';
__PACKAGE__->config( { 'CatalystX::Test::Recorder' => { template => 't/src/template.tt', namespace => 'foobar' }, setup_components => {search_extra => ['MyApp']} }  );
__PACKAGE__->setup(qw(+CatalystX::Test::Recorder));
1;