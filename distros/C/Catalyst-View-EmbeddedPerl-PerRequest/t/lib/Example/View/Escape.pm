package Example::View::Escape;

use Moose;
extends 'Catalyst::View::EmbeddedPerl::PerRequest';

__PACKAGE__->config(auto_escape => 1);
__DATA__
%= "<a>hello</a>"