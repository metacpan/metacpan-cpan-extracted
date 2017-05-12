package CGI::Portal::Scripts::Footer;
# Copyright (c) 2008 Alexander David P. All rights reserved.
#
# Code for footer

use strict;

use CGI::Portal::Scripts;

use vars qw(@ISA $VERSION);

$VERSION = "0.12";

@ISA = qw(CGI::Portal::Scripts);

1;

sub launch {
  my ($self, $e) = @_;

            # Assign tmpl
  $self->assign_tmpl($e->{'conf'}{'footer_html'});
}