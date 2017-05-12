package TestDirectoryDispatch::Controller::DataRoot;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::DirectoryDispatch' }

__PACKAGE__->config(
	action => { setup => { Chained => '/base', PathPart => 'dataroot' } }, # define parent chain action and partpath
	root       => '.',
	data_root  => 'test',
);

__PACKAGE__->meta->make_immutable;
1;