#
# This file is part of CatalystX-ExtJS-REST
#
# This software is Copyright (c) 2014 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#

package
  MyApp::Controller::SkipEnd;
  
use base 'CatalystX::Controller::ExtJS::REST';

__PACKAGE__->config(
    form_base_path => [qw(t root forms)],
    list_base_path => [qw(t root lists)],
);

sub load_form : Chained('/') NSFormPathPart CaptureArgs(0) {
    my ( $self, $c ) = @_;

    # Check form existence
    croak ($self->base_file." cannot be found")
        unless (-e $self->base_file);

    $c->stash->{form_name} = 'skipend_test';

    # Create form and load config
    my $form = $self->get_form( $c );
    $form->load_config_file( $self->base_file );

    # Build action from current path
    my $action = $self->action_namespace;
    $form->action( "/".$action );

    # Process empty form
    $form->process();

    # Store form on stash
    $c->stash->{form} = $form;
}

sub edit_record :Chained('load_form') PathPart() Args(0) ActionClass('RenderView') {
    my ( $self, $c ) = @_;
    # Prepare template
    $c->stash->{template} = 'edit_record.tt2.js';

    # The form will be rendered while processing the template
    return;
}

sub _parse_NSFormPathPart_attr {
    my ( $self, $c ) = @_;

    # Split path and add form path
    my @path = split( /\//, $self->action_namespace );
    push @path, 'form';

    return ( PathPart => join('/', @path) );
}

1;