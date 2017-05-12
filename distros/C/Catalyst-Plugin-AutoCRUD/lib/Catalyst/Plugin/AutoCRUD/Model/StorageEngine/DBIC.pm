package Catalyst::Plugin::AutoCRUD::Model::StorageEngine::DBIC;
{
  $Catalyst::Plugin::AutoCRUD::Model::StorageEngine::DBIC::VERSION = '2.143070';
}

use strict;
use warnings;

use base 'Catalyst::Model';

__PACKAGE__->mk_classdata(_schema_cache => {});

use Catalyst::Plugin::AutoCRUD::Model::StorageEngine::DBIC::CRUD;
use Catalyst::Plugin::AutoCRUD::Model::StorageEngine::DBIC::Metadata;

1;
