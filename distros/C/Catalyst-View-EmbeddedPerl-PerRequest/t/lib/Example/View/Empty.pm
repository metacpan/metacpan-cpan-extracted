package Example::View::Empty;

use Moose;
use MooseX::MethodAttributes;

extends 'Catalyst::View::EmbeddedPerl::PerRequest';


__PACKAGE__->meta->make_immutable;
__PACKAGE__->config(
  auto_escape => 1,
);

__DATA__
<%= $content =%>\
