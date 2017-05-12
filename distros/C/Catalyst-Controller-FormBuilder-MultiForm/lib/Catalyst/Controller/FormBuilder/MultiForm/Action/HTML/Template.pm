package Catalyst::Controller::FormBuilder::MultiForm::Action::HTML::Template;

use strict;
use warnings;

use base qw| Catalyst::Controller::FormBuilder::Action::HTML::Template |;

sub setup_template_vars
{
  my $self = shift;
  my ( $controller, $c ) = @_; 
  
  $self->SUPER::setup_template_vars(@_); 
  
  my %FORM_VARS  = %Catalyst::Controller::FormBuilder::Action::HTML::Template::FORM_VARS;
  my %FIELD_VARS = %Catalyst::Controller::FormBuilder::Action::HTML::Template::FIELD_VARS;
  
  # Get the name of this form from the formbuilder data
  my $form_name = $controller->_formbuilder->name;
  
  # Don't do anything else if the form does not have a name defined
  return unless defined $form_name;
  
  # Holds the template vars we are going to build with the form name prefixed
  my %form_template_vars;
  
  # Create a copy of all the form variables in the template, prefixed with 
  # the form name
  foreach my $template_var ( keys %FORM_VARS )
  {
    $form_template_vars{"$form_name-$template_var"} = $c->stash->{$template_var};
  }
  
  # Iterate over each field in the form, and create a copy of each field
  # variable in the template, prefixed with the form name
  foreach my $field ( $controller->_formbuilder->fields )
  {
    foreach my $template_var ( %FIELD_VARS )
    {
      # Adjust the template var to include the real field name
      my $adjusted_template_var = sprintf($template_var, $field);
      
      $form_template_vars{"$form_name-$adjusted_template_var"} = $c->stash->{$adjusted_template_var};
    }
  }
  
  # Add our new form name prefixed template values to the stash
  while ( my ( $param, $tag ) = each %form_template_vars ) 
  { $c->stash->{$param} = $tag; }
}

1;
