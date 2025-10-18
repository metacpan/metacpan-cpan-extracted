# NAME

Alien::SDL3\_image - Build and install SDL3\_image

# SYNOPSIS

```perl
use Alien::SDL3_image; # Don't.
```

# DESCRIPTION

Alien::SDL3\_image builds and installs [SDL2\_image](https://github.com/libsdl-org/SDL_image/).

It is not meant for direct use. Just ignore it for now.

# METHODS

## `dynamic_libs( )`

```perl
my @libs = Alien::SDL3_image->dynamic_libs;
```

Returns a list of the dynamic library or shared object files.

# Prerequisites

Depending on your platform, certain development dependencies must be present.

These are required for building `SDL2_image` for image loading support:

Linux (Debian/Ubuntu):

```
$ sudo apt-get install libpng-dev libjpeg-dev libwebp-dev
```

macOS (using Homebrew):

```
$ brew install libpng jpeg-turbo libwebp
```

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2\. Other copyrights, terms, and conditions may apply to data transmitted through this module.

# AUTHOR

Sanko Robinson <sanko@cpan.org>
