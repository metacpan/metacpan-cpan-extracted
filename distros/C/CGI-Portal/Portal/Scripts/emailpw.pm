package CGI::Portal::Scripts::emailpw;
# Copyright (c) 2008 Alexander David P. All rights reserved.
#
# Reset password page 

use strict;

use CGI::Portal::Scripts;

use vars qw(@ISA $VERSION);

$VERSION = "0.12";

@ISA = qw(CGI::Portal::Scripts);

1;

sub launch {
  my $self = shift;

            # Assign tmpl
  $self->assign_tmpl("emailpw.html");
}