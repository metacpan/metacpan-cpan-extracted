# NAME

Alien::SDL3 - Build and Install SDL3 and Satellite Libraries

# SYNOPSIS

```perl
use Alien::SDL3; # Don't.
```

# DESCRIPTION

Alien::SDL3 locates or builds:

- [SDL3](https://github.com/libsdl-org/SDL/): Cross-platform development library designed to provide low level access to audio, keyboard, mouse, joystick, and graphics hardware via OpenGL/Direct3D/Metal/Vulkan.
- [SDL\_image](https://github.com/libsdl-org/SDL_image): Load image files (bmp, gif, jpg, many others) into an SDL\_Surface or SDL\_Texture.
- [SDL\_mixer](https://github.com/libsdl-org/SDL_mixer): Load audio files (wav, mp3, ogg, many others), mix multiple sounds, apply effects to them.
- [SDL\_ttf](https://github.com/libsdl-org/SDL_ttf): Load font files (ttf, etc) and render text with them.

It is not meant for direct use but nothing is stopping you from using it. Whip up something cool, I guess. If you're
not sure, just ignore it for now.

# METHODS

## `dynamic_libs( )`

```perl
my @libs = Alien::SDL3->dynamic_libs;
```

Returns a list of the dynamic library or shared object files.

# Prerequisites

Alien::SDL3 will attempt to locate your system install of SDL3 but will build it from source if not found.

The build system will try to get the system in a state where everything compiles (grabs cmake, etc. automatically).

Depending on your platform, certain development dependencies must be present. The X11 or Wayland development libraries
are required on Linux, \*BSD, etc.

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2\. Other copyrights, terms, and conditions may apply to data transmitted through this module.

# AUTHOR

Sanko Robinson - [https://github.com/sanko](https://github.com/sanko)
