package Example::View::NoEscape;

use Moose;
extends 'Catalyst::View::EmbeddedPerl::PerRequest';

__DATA__
%= "<a>hello</a>"