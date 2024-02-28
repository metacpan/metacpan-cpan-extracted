# Dancer2::Controllers

A wrapper for exporting [Dancer2](https://metacpan.org/pod/Dancer2) routes in various controller esq, modules.

Similar to how Spring-Boot declares their routes, except without annotations.

## Example

```perl
package MyApp::Controller;

use Moose;

BEGIN { extends 'Dancer2::Controllers::Controller' }

sub hello_world : Route(get => /) {
    "Hello World!";
}

sub foo : Route(get => /foo) {
    "Foo!"
}

1;

use Dancer2;
use Dancer2::Controllers;

set port => 8080;

controllers( ['MyApp::Controller'] );

dance;
```

## License

Dancer2::Controllers is free software, licensed under the MIT license.
