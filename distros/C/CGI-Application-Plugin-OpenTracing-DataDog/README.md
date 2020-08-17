# CGI::Application::Plugin::OpenTracing::DataDog

Use OpenTracing in CGI Applications with DataDog implementation

## SYNOPSIS

inside your CGI Application

```
package MyCGI;

use strict;
use warnings;

use base qw/CGI::Application/;

use CGI::Application::Plugin::OpenTracing::DataDog;

...

```

## DESCRIPTION

This will bootstrap the DataDog Implementation for OpenTracing and handle all
the default settings on behalf you.

See CGI::Application::Plugin::OpenTracing for more information.

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
