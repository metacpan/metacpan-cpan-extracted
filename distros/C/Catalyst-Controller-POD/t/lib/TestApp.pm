#
# This file is part of Catalyst-Controller-POD
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package TestApp;

use strict;
use warnings;

use Catalyst::Runtime '5.70';

use parent qw/Catalyst/;

__PACKAGE__->config( name => 'TestApp' ,
"Controller::Root" => {}
);
__PACKAGE__->setup(qw/Static::Simple/);


1;
