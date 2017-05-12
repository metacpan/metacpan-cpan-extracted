package TestApp::Controller::Test;

use strict;
use base qw| TestApp::Controller::Base |;

__PACKAGE__->config
(
  'Controller::FormBuilder::MultiForm' => 
  {
    stash_name  => 'forms',
    template_type => $TestApp::template_type,
  },
);


# Standard Catalyst::Controller::FormBuilder style
sub standard : Local Form
{
  my ( $self, $c ) = @_;
  
  my $form = $self->formbuilder;
  
  if ( $form->submitted )
  {
    return $c->response->body( _show_form_details($form) );
  }
}

# MultiForm style with a single form
sub one_form : Local Form('test/foo')
{
  my ( $self, $c ) = @_;
  
  my $form = $self->formbuilder;
  
  if ( $form->submitted )
  {
    return $c->response->body( _show_form_details($form) );
  }
}

# MultiForm style with multiple forms
sub two_forms : Local Form('test/foo')
{
  my ( $self, $c ) = @_;
  
  my $foo_form = $self->formbuilder;
  
  if ( $foo_form->submitted )
  {
    return $c->response->body( _show_form_details($foo_form) );
  }
  
  my $bar_form = $c->forward('/test/bar');
  
  if ( $bar_form->submitted )
  {
    return $c->response->body( _show_form_details($bar_form) );
  }
}

# Multiple forms with one standard style and one MultiForm style
sub hybrid : Local Form('test/standard')
{
  my ( $self, $c ) = @_;
  
  my $standard_form = $self->formbuilder;
  
  if ( $standard_form->submitted )
  {
    return $c->response->body( _show_form_details($standard_form) );
  }
  
  my $foo_form = $c->forward('/test/foo');
  
  if ( $foo_form->submitted )
  {
    return $c->response->body( _show_form_details($foo_form) );
  }
  
  my $bar_form = $c->forward('/test/bar');
  
  if ( $bar_form->submitted )
  {
    return $c->response->body( _show_form_details($bar_form) );
  }
}


# Return the foo form
sub foo : Local Form
{
  my ( $self, $c ) = @_;
  return $self->formbuilder;
}

# Return the bar form
sub bar : Local Form
{
  my ( $self, $c ) = @_;
  return $self->formbuilder;
}

# Utility method to spit out form data
# Returns form data like this:
#  form:[form name]
#  [field]:[field value]
sub _show_form_details
{
  my $form = shift;
  
  # Add the form name
  my $results = 'form:' . $form->name . "\n";
  
  # Add each field and value
  foreach my $field ( $form->fields )
  { $results .= $field . ':' . $form->fields($field) . "\n"; }
  
  # Return the whole mess in a <pre> tag
  return "<pre>$results</pre>";
}

1;
