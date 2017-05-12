package CatalystX::Crudite::Form::Base;
use HTML::FormHandler::Moose;
extends 'HTML::FormHandler::Model::DBIC';
with 'HTML::FormHandler::Widget::Theme::Bootstrap';

sub is_create_mode {
    my $self = shift;
    $self->ctx && $self->ctx->stash->{set_create_msg};
}

sub is_update_mode {
    my $self = shift;
    $self->ctx && $self->ctx->stash->{set_update_msg};
}

sub submit_button {
    my $self  = shift;
    my $label = 'Save';
    $label = 'Create' if $self->is_create_mode;
    $label = 'Update' if $self->is_update_mode;
    return (
        (   submit => {
                type           => 'Submit',
                widget         => 'ButtonTag',
                element_attr   => { class => [ 'btn', 'btn-primary' ] },
                widget_wrapper => 'None',
                value          => $label
            }
        )
    );
}
1;
