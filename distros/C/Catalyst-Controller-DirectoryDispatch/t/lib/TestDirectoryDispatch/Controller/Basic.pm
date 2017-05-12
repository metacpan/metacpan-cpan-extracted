package TestDirectoryDispatch::Controller::Basic;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::DirectoryDispatch' }

__PACKAGE__->config(
	action => { setup => { Chained => '/base', PathPart => 'basic' } }, # define parent chain action and partpath
	root       => '.',
);

__PACKAGE__->meta->make_immutable;
1;