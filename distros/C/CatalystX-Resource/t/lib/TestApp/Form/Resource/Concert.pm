package TestApp::Form::Resource::Concert;
use HTML::FormHandler::Moose;
extends 'HTML::FormHandler::Model::DBIC';

has '+item_class' => ( default => 'Resource::Concert' );

has_field 'location' => (
    type => 'Text',
    required => 1,
    size => 40,
);

has_field 'submit' => ( type => 'Submit', value => 'Submit' );

no HTML::FormHandler::Moose;
1;
