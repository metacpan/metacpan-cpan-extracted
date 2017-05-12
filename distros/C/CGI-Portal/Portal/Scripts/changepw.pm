package CGI::Portal::Scripts::changepw;
# Copyright (c) 2008 Alexander David P. All rights reserved.
#
# Change password page

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
    $self->assign_tmpl("changepw.html");
  }
}