package <% dist_module %>;
use Moose;
use namespace::autoclean;
use Catalyst::Runtime 5.80;
extends 'CatalystX::Crudite';
Catalyst->import(
    @CatalystX::Crudite::IMPORT,
    qw(
      StackTrace
      )
);
our $VERSION = '0.01';
our $tmp_dir = '/tmp/<% dist_file %>';
__PACKAGE__->config_app(
    name                     => '<% dist_module %>',
    'Plugin::Static::Simple' => {
        include_path => [ __PACKAGE__->path_to(qw(root static)), $tmp_dir ],
        ignore_extensions => [qw(tmpl tt tt2 xhtml)]
    },
);
__PACKAGE__->setup;
1;
