package CGI::Portal::Scripts::profile;
# Copyright (c) 2008 Alexander David P. All rights reserved.
#
# Profile page

use strict;

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

            # Join user fields for SQL
    my $fields = join(',', @{$self->{'conf'}{'user_additional'}});

            # Select users info
    $r = $self->{'rdb'}->exec("select $fields from $self->{'conf'}{'user_table'} where $self->{'conf'}{'user_user_field'}=" . $self->{'rdb'}->escape($self->{'user'}) . " limit 1")->fetch;

            # Assign template vars
    $self->CGI::Portal::Scripts::profile::input_html();

            # Assign tmpl
    $self->assign_tmpl("profile.html");
  }
}

            # Assign templ vars
sub input_html {
  my $self = shift;
  my @states = qw(Other AL AK AZ AR CA CO CT DC DE FL GA HI ID IL IN IA KS KY LA ME MD MA MI MN MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA RI SC SD TN TX UT VA VT WA WV WI WY);

            # Template vars for user fields
  my $c = 0;
  foreach my $f (@{$self->{'conf'}{'user_additional'}}) {
    my $value = $self->{'in'}{$f} || $r->[$c];
    $self->{'tmpl_vars'}{$f} = $value;
    $c++;
  }

            # Default state
  my $state_input = $self->{'in'}{'state'} || $r->[5];

            # HTML select for state
  my $state = "<select name=state>";
  foreach my $s (@states){
    if ($s ne $state_input){
      $state .=  "<option>$s";
    }else{
      $state .=  "<option selected>$s";
    }
  }
  $state .= "</select>";

            # Assign to template var state
  $self->{'tmpl_vars'}{'state'} = $state;
}