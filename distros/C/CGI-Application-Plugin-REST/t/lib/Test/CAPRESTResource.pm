package Test::CAPRESTResource;
use strict;
use warnings;
use base 'CGI::Application';
use CGI::Application::Plugin::REST qw( :all );

sub setup {
    my ($self) = @_;

    $self->run_modes([ 'default' ]);
    $self->rest_error_mode('error');
    $self->start_mode('default');

    $self->rest_resource('widget');

    $self->rest_resource(resource => 'fidget', prefix => 'foo',
        identifier => 'num',
        in_types => ['application/xml'], out_types => ['text/html']);

    if (defined $self->query->param('noargs')) {
        $self->rest_resource();
    }

    if (defined $self->query->param('bogusargs')) {
        $self->rest_resource('midget', 'gidget', 'apt-get');
    }

    if (defined $self->query->param('bogusresource')) {
        my $resource = {
            prefix     => 'foo',
            identifier => 'num',
        };
        $self->rest_resource($resource);
    }

    if (defined $self->query->param('bogusintypes')) {
        my $resource = {
            resource     => 'midget',
            in_types     => 'foo',
        };
        $self->rest_resource($resource);
    }

    if (defined $self->query->param('bogusouttypes')) {
        my $resource = {
            resource     => 'midget',
            out_types    => 'foo',
        };
        $self->rest_resource($resource);
    }

    return;
}

sub default {
    my ($self) = @_;

    my $q = $self->query;

    return $q->start_html('default') .
           $q->end_html;
}

sub error {
    my ($self) = @_;

    my $q = $self->query;

    return $q->start_html('error') .
           $q->end_html;
}

sub widget_create {
    my ($self) = @_;

    my $q = $self->query;

    return $q->start_html('widget create') .
           $q->end_html;
}


sub widget_destroy {
    my ($self) = @_;

    my $q = $self->query;

    return $q->start_html('widget destroy ' . $self->rest_param('id')) .
           $q->end_html;
}


sub widget_edit {
    my ($self) = @_;

    my $q = $self->query;

    return $q->start_html('widget edit ' . $self->rest_param('id')) .
           $q->end_html;
}


sub widget_index {
    my ($self) = @_;

    my $q = $self->query;

    return $q->start_html('widget index') .
           $q->end_html;
}


sub widget_new {
    my ($self) = @_;

    my $q = $self->query;

    return $q->start_html('widget new') .
           $q->end_html;
}


sub widget_show {
    my ($self) = @_;

    my $q = $self->query;

    return $q->start_html('widget show ' . $self->rest_param('id')) .
           $q->end_html;
}


sub widget_update {
    my ($self) = @_;

    my $q = $self->query;

    return $q->start_html('widget update ' . $self->rest_param('id')) .
           $q->end_html;
}

sub widget_options {
    my ($self) = @_;

    my $q = $self->query;

    return $q->start_html('widget options ') .
           $q->end_html;
}

sub foo_create {
    my ($self) = @_;

    my $q = $self->query;

    return $q->start_html('foo create') .
           $q->end_html;
}


sub foo_destroy {
    my ($self) = @_;

    my $q = $self->query;

    return $q->start_html('foo destroy ' . $self->rest_param('num')) .
           $q->end_html;
}


sub foo_edit {
    my ($self) = @_;

    my $q = $self->query;

    return $q->start_html('foo edit ' . $self->rest_param('num')) .
           $q->end_html;
}


sub foo_index {
    my ($self) = @_;

    my $q = $self->query;

    return $q->start_html('foo index') .
           $q->end_html;
}


sub foo_new {
    my ($self) = @_;

    my $q = $self->query;

    return $q->start_html('foo new') .
           $q->end_html;
}


sub foo_show {
    my ($self) = @_;

    my $q = $self->query;

    return $q->start_html('foo show ' . $self->rest_param('num')) .
           $q->end_html;
}


sub foo_update {
    my ($self) = @_;

    my $q = $self->query;

    return $q->start_html('foo update ' . $self->rest_param('num')) .
           $q->end_html;
}

1;
