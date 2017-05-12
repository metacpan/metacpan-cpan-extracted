package TestDirectoryDispatch::Controller::Filter;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::DirectoryDispatch' }

__PACKAGE__->config(
	action => { setup => { Chained => '/base', PathPart => 'filter' } }, # define parent chain action and partpath
	root       => '.',
	filter     => qr(^\.),
);

__PACKAGE__->meta->make_immutable;
1;