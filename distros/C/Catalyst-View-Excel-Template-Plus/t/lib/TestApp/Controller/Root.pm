package TestApp::Controller::Root;

use strict;
use warnings;
use parent 'Catalyst::Controller';

sub test_one : Global {
    my ($self, $c) = @_;

    $c->stash->{template} = 'test_one.xml.tmpl';

    $c->stash->{message} = 'Hello (Excel) World';

    $c->forward('TestApp::View::Excel');
}

sub test_two : Global {
    my ($self, $c) = @_;

    $c->stash->{template} = 'test_two.xml.tmpl';
    $c->stash->{message} = 'Hello (Excel) World';

    $c->stash->{excel_filename} = 'test';
    $c->stash->{excel_disposition} = 'attachment';

    $c->forward('TestApp::View::Excel');
}

1;
