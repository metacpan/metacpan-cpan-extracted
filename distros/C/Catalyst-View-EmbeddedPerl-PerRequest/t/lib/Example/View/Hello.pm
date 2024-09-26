package Example::View::Hello;

use Moose;
extends 'Catalyst::View::EmbeddedPerl::PerRequest';

__DATA__
<p>hello world</p>