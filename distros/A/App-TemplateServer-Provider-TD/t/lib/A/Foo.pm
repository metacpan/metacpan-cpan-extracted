package A::Foo;

use strict;
use warnings;

use base 'Template::Declare';
use Template::Declare::Tags;

template 'A/Foo' => sub { html {} };
