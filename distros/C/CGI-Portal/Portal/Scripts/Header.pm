package CGI::Portal::Scripts::Header;
# Copyright (c) 2008 Alexander David P. All rights reserved.
#
# Code for header

use strict;

use CGI::Portal::Scripts;

use vars qw(@ISA $VERSION);

$VERSION = "0.12";

@ISA = qw(CGI::Portal::Scripts);
1;

sub launch {
  my ($self, $e) = @_;

            # Assign tmpl
  $self->{'tmpl_vars'}{'result'} = $e->{'tmpl_vars'}{'result'};

            # Assign tmpl
  $self->assign_tmpl($e->{'conf'}{'header_html'});
}