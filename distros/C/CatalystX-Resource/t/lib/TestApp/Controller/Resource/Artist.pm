package TestApp::Controller::Resource::Artist;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Resource::Controller::Resource'; }

__PACKAGE__->config(
    resultset_key          => 'artists',
    resource_key           => 'artist',
    form_class             => 'TestApp::Form::Resource::Artist',
    model                  => 'DB::Resource::Artist',
    redirect_mode          => 'list',
    traits                 => [qw/ Create Show Edit Delete List Form Sortable MergeUploadParams /],
    activate_fields_create => [qw/ password password_repeat /],
    actions                => { base => { PathPart => 'artists', }, },
    error_path             => '/error404',
    prefetch               => 'albums',
);


sub auto : Private {
    my ( $self, $c ) = @_;
    $c->stash->{form_attrs_new} = {
        field_list => [
            my_custom_field => {
                type  => 'Text',
                label => 'my_custom_field_label',
            }
        ],
    };
    $c->stash->{form_attrs_process} = {
        update_field_list => {
            name => {
                label => 'my_custom_name_label',
            }
        }
    };
}

1;
