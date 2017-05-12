package CatalystX::RoseIntegrator::Action;

use strict;
use File::Spec;
use Class::Inspector;
use NEXT;

use base qw/Catalyst::Action Class::Accessor::Fast Class::Data::Inheritable/;

sub execute {
    my $self = shift;
    my ($controller, $c) = @_;

    return $self->NEXT::execute(@_)
      unless exists $self->attributes->{ActionClass}
      && $self->attributes->{ActionClass}[0] eq
      $controller->_rinteg_setup->{action};

    unless ($controller->form_name) {
	my $form_name = $self->attributes->{Form}[0] || $self->reverse;
	$form_name =~ s/(\w+)/ucfirst($1)/ge;
	$form_name =~ s,/,,g;
	$form_name =~ s/(Form)?$/Form/g;
	$controller->form_name($form_name);
	$controller->_form_init;
    }

    my $form = $controller->_form;

    $form->init_auto_fields($c);
    $form->init_fields_with_cgi($c->req, no_clear => 1);
    $controller->_process($c) if $form->was_submitted;

    $self->NEXT::execute(@_);

    $form->relabelize($c); # For dynamic language change

    $self->setup_template_vars(@_);
}

1;
