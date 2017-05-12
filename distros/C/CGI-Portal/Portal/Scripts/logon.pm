package CGI::Portal::Scripts::logon;
# Copyright (c) 2008 Alexander David P. All rights reserved.
#
# Logon Success

use strict;

use CGI::Portal::Scripts;

use vars qw(@ISA $VERSION);

$VERSION = "0.12";

@ISA = qw(CGI::Portal::Scripts);

1;

sub launch {
  my $self = shift;

            # Authenticate
  $self->authenticate_user();
  if ($self->{'user'}){

            # Assign tmpl
    $self->assign_tmpl($self->{'conf'}{'logon_success_html'});
  }
}