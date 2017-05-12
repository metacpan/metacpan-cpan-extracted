package CGI::Portal::Scripts::register;
# Copyright (c) 2008 Alexander David P. All rights reserved.
#
# Registration page

use strict;

use CGI::Portal::Scripts;

use vars qw(@ISA $VERSION);

$VERSION = "0.12";

@ISA = qw(CGI::Portal::Scripts);

1;

sub launch {
  my $self = shift;

            # Assign template var user
  $self->{'tmpl_vars'}{'user'} = $self->{'in'}{'user'};

            # Assign template vars for user fields
  foreach my $f (@{$self->{'conf'}{'user_additional'}}) {
    $self->{'tmpl_vars'}{$f} = $self->{'in'}{$f};
  }

            # HTML select for state
  my @states = qw(Other AL AK AZ AR CA CO CT DC DE FL GA HI ID IL IN IA KS KY LA ME MD MA MI MN MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA RI SC SD TN TX UT VA VT WA WV WI WY);
  my $state = "<select name=state>";
  foreach my $s (@states){
    if ($s ne $self->{'in'}{'state'}){
      $state .=  "<option>$s";
    }else{
      $state .=  "<option selected>$s";
    }
  }
  $state .= "</select>";

            # Assign template var state
  $self->{'tmpl_vars'}{'state'} = $state;

            # Assign tmpl
  $self->assign_tmpl("register.html");
}

sub html_form {
  my $self = shift;
  return <<EOF;
EOF
}