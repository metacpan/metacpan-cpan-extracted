package TestDirectoryDispatch::Controller::FullPaths;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::DirectoryDispatch' }

__PACKAGE__->config(
	action => { setup => { Chained => '/base', PathPart => 'fullpaths' } }, # define parent chain action and partpath
	root       => '.',
	full_paths => 1,
);

__PACKAGE__->meta->make_immutable;
1;