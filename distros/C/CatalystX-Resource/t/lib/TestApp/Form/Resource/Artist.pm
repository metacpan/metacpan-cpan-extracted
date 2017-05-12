package TestApp::Form::Resource::Artist;
use HTML::FormHandler::Moose;
extends 'HTML::FormHandler::Model::DBIC';

has '+enctype'    => ( default => 'multipart/form-data' );
has '+item_class' => ( default => 'Resource::Artist' );

has_field 'name' => (
    type => 'Text',
    required => 1,
    size => 40,
);

has_field 'password' => (
    type => 'Password',
    required => 1,
    size => 40,
    inactive => 1, # we will activate this field with 'activate_fields_create'
);

has_field 'password_repeat' => (
    type => 'PasswordConf',
    required => 1,
    size => 40,
    inactive => 1, # we will activate this field with 'activate_fields_create'
    noupdate => 1,
);

# does not exist in DB, only here to test MergeUploadParams trait
has_field 'picture' => ( 
    type => 'Upload',
);

has_field 'submit' => ( type => 'Submit', value => 'Submit' );

no HTML::FormHandler::Moose;
1;
