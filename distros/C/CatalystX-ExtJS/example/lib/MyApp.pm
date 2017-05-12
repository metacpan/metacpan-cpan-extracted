#
# This file is part of CatalystX-ExtJS
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package MyApp;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

use Catalyst qw/
    Static::Simple
    Unicode::Encoding
/;

extends 'Catalyst';

__PACKAGE__->config(
    name => 'MyApp',
    disable_component_resolution_regex_fallback => 1,
    encoding => 'UTF-8'
);

__PACKAGE__->setup();


1;
