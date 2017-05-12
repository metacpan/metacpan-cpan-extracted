package ModB;

use Readonly;

Readonly our $foo => "bar";

Readonly our $bar => [qw(baz qux)];

Readonly our $baz => { quux => "foobar" };

1;

