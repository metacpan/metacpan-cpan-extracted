# NAME

Alien::SDL3 - Build and install SDL3

# SYNOPSIS

```perl
use Alien::SDL3; # Don't.
```

# DESCRIPTION

Alien::SDL3 builds and installs [SDL3](https://github.com/libsdl-org/SDL/).

It is not meant for direct use. Just ignore it for now.

# METHODS

## `dynamic_libs( )`

```perl
my @libs = Alien::SDL3->dynamic_libs;
```

Returns a list of the dynamic library or shared object files.

# Prerequisites

Depending on your platform, certain development dependencies must be present.

The X11 or Wayland development libraries are required on Linux, \*BSD, etc.

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2\. Other copyrights, terms, and conditions may apply to data transmitted through this module.

# AUTHOR

Sanko Robinson <sanko@cpan.org>
