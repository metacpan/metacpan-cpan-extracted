package A::Foo::Bar;

use strict;
use warnings;

use base 'Template::Declare';
use Template::Declare::Tags;

template 'A/Foo/Bar' => sub { html {} };
template 'A/Foo/Bar/Baz' => sub { html {} };
