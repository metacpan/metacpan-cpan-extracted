package TrueTestApp;

use strict;
use warnings;

use Catalyst::Runtime 5.80;

use parent qw/Catalyst/;
use Catalyst qw/ Cache/;

__PACKAGE__->config(
   name => 'TestApp',
   'Plugin::Cache' => {
      backend => {
         class => "Catalyst::Plugin::Cache::Backend::Memory",
      },
   },
);

__PACKAGE__->setup();

1;
