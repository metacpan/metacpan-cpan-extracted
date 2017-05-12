package Catalyst::Plugin::AutoCRUD::View::JSON;
{
  $Catalyst::Plugin::AutoCRUD::View::JSON::VERSION = '2.143070';
}

use strict;
use warnings;

use base 'Catalyst::View::JSON';

__PACKAGE__->config(
    expose_stash => 'json_data',
);

1;
