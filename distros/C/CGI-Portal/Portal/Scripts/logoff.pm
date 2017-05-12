package CGI::Portal::Scripts::logoff;
# Copyright (c) 2008 Alexander David P. All rights reserved.
#
# Remove session

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

            # Remove session
    $self->logoff;
    $self->{'tmpl_vars'}{'result'} = "You are logged off.";
  }

            # Assign tmpl
  $self->assign_tmpl("Sessions.html");
}