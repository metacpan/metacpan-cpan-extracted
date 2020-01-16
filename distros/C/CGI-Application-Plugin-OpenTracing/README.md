# CGI::Application::Plugin::OpenTracing

Use OpenTracing in CGI Applications

## SYNOPSIS

inside your CGI Application

```
package MyCGI;

use strict;
use warnings;

use base qw/CGI::Application/;

use CGI::Application::Plugin::OpenTracing;

...

```

and in the various run-modes:

```
sub some_run_mode {
    my $webapp = shift;
    my $q = $webapp->query;
    
    my $some_id = $q->param('some_id');
    $webapp->get_active_span->add_tag( some_id => $some_id );
    
    ...
    
}
```

## DESCRIPTION

This will bootstrap the OpenTracing Implementation and provide a convenience
method `get_active_span`.

It will create a rootspan, for the duration of the entire execution of the
webapp. On top off that root span, it will create three spans for the phases:
setup, run and teardown.

## Disclaimer

For more information, always check the pod, using `perldoc`. This is just a ...
well, a README, and only documents the module as it initially was conceived.
Things may have turned out a bit differently. And this file may or may not been
updated accordingly.

## LICENSE INFORMATION

This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

This package is distributed in the hope that it will be useful, but it is
provided “as is” and without any express or implied warranties.

For details, see the full text of the license in the file LICENSE.
