package CGI::Portal::Controls::profile;
# Copyright (c) 2008 Alexander David P. All rights reserved.
#
# Update user info

use strict;

use CGI::Portal::Scripts::profile;
use CGI::Portal::Scripts;

use vars qw(@ISA $VERSION);

$VERSION = "0.12";

@ISA = qw(CGI::Portal::Scripts);

my $r;

1;

sub launch {
  my $self = shift;

            # Authenticate
  $self->authenticate_user();
  if ($self->{'user'}){

            # Validate
    unless ($self->input_error("email")){

            # Escape user
      my $user = $self->{'rdb'}->escape($self->{'user'});

            # Loop thru user fields and update
      my $c = 0;
      foreach my $f (@{$self->{'conf'}{'user_additional'}}) {
        my $value = $self->{'rdb'}->escape($self->{'in'}{$f});
        $self->{'rdb'}->exec("update $self->{'conf'}{'user_table'} set $f=$value where $self->{'conf'}{'user_user_field'}=$user");
        $c++;
      }

      $self->{'tmpl_vars'}{'result'} = "Profile is updated.";
    }
  }

            # Redirect
  $self->CGI::Portal::Scripts::profile::launch();
  return;
}

            # Validate
sub input_error {
  my ($self, @requireds)  = @_;
  my $input_error = 0;

            # Loop thru requireds
  foreach my $required (@requireds) {
    if (!$self->{'in'}{$required}){
      $self->{'tmpl_vars'}{"${required}_msg"} = "Field is required";
      $input_error = 1;
    }
  }

  if ($input_error) {
    $self->{'tmpl_vars'}{'result'} = "Missing fields, no changes made.";
  }

  return $input_error;
}