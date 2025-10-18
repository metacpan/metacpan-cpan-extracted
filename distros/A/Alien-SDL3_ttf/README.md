# NAME

Alien::SDL3\_ttf - Build and install SDL3\_ttf

# SYNOPSIS

```perl
use Alien::SDL3_ttf; # Don't.
```

# DESCRIPTION

Alien::SDL3\_ttf builds and installs [SDL3\_ttf](https://github.com/libsdl-org/SDL_ttf/).

It is not meant for direct use. Just ignore it for now.

# METHODS

## `dynamic_libs( )`

```perl
my @libs = Alien::SDL3_ttf->dynamic_libs;
```

Returns a list of the dynamic library or shared object files.

# Prerequisites

Depending on your platform, certain development dependencies must be for TrueType font support:

Linux (Debian/Ubuntu):

```
$ sudo apt-get install libfreetype-dev
```

macOS (using Homebrew):

```
$ brew install freetype
```

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2\. Other copyrights, terms, and conditions may apply to data transmitted through this module.

# AUTHOR

Sanko Robinson <sanko@cpan.org>
