package Catalyst::Controller::FormBuilder::MultiForm::Action::Mason;

use strict;
use warnings;

use base qw| Catalyst::Controller::FormBuilder::Action::Mason |;

sub setup_template_vars
{
  my $self = shift;
  my ( $controller, $c ) = @_; 
  
  $self->SUPER::setup_template_vars(@_); 
  
  # Get the name of this form from the formbuilder data
  my $form_name = $controller->_formbuilder->name;
  
  # Get configuration data from our formbuilder instance
  my $stash_name     = $controller->_fb_setup->{stash_name};
  my $obj_name       = $controller->_fb_setup->{obj_name};
  my $multiform_name = $controller->_stash_name;
  
  # If a form name is defined, create aliases to this form in our forms hash
  if ( defined $form_name )
  {
    $c->stash->{$multiform_name}{$form_name}{$stash_name} = $c->stash->{$stash_name};
    $c->stash->{$multiform_name}{$form_name}{$obj_name}   = $c->stash->{$obj_name};
  }
}

1;
