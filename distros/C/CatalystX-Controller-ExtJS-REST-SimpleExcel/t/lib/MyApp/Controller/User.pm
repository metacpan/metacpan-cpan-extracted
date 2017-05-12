#
# This file is part of CatalystX-Controller-ExtJS-REST-SimpleExcel
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package
  MyApp::Controller::User;
  
use Moose;
BEGIN { extends 'CatalystX::Controller::ExtJS::REST' };
with 'CatalystX::Controller::ExtJS::Direct';
with 'CatalystX::Controller::ExtJS::REST::SimpleExcel';

__PACKAGE__->config(
    forms => { default => [ map { { name => $_ } } qw(id name password) ]},
    limit => 0,
);


1;