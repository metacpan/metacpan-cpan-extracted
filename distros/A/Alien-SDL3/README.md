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

To avoid compiling entire windowing and dependency stacks from scratch, ensure your system meets the following
platform-specific prerequisites:

## Linux (Ubuntu / Debian)

Install the core build tools and X11/Wayland development libraries:

```
sudo apt-get install -y --no-install-recommends \
  cmake ninja-build pkgconf curl \
  libx11-dev libxcb1-dev libxext-dev libxfixes-dev libxcursor-dev libxrandr-dev \
  libxi-dev libxrender-dev libxss-dev libxkbcommon-dev libwayland-dev
```

To compile satellite libraries (SDL3\_image, SDL3\_mixer, SDL3\_ttf) against system codecs:

```
sudo apt-get install -y --no-install-recommends \
  libpng-dev libjpeg-dev libtiff-dev libwebp-dev libfreetype6-dev \
  libogg-dev libvorbis-dev libflac-dev libopus-dev libopusfile-dev \
  libsndfile1-dev libasound2-dev libpulse-dev libpipewire-0.3-dev \
  libudev-dev libdbus-1-dev libgl1-mesa-dev libegl1-mesa-dev \
  libibus-1.0-dev zlib1g-dev libbz2-dev
```

On Ubuntu 25.10+, system SDL3 packages can be installed directly:

```
sudo apt-get install -y libsdl3-dev libsdl3-image-dev libsdl3-ttf-dev libsdl3-mixer-dev
```

## macOS

Install Homebrew packages to satisfy system checks and build dependencies:

```
brew install sdl3 sdl3_image sdl3_ttf sdl3_mixer cmake pkg-config
brew install freetype libpng libtiff webp jpeg-turbo libogg libvorbis flac opus libsndfile
```

## Windows

Strawberry Perl provides everything needed out-of-the-box. Alien::SDL3 will download official prebuilt SDL3 MinGW
binaries matching your Perl architecture.

If using vcpkg instead:

```
vcpkg install sdl3 sdl3-image sdl3-ttf sdl3-mixer
choco install make -y
```

## FreeBSD

```
pkg install -y perl5 lang/gcc gmake git cmake ninja unzip pkgconf curl \
  libX11 libxcb libXext libXfixes libXcursor libXrandr libXi \
  libXrender libXScrnSaver libxkbcommon wayland xorgproto
```

**Note:** `gmake` is required by Alien::Xmake. Set `export XMAKE_ROOT=y` if building as root.

## OpenBSD

```
pkg_add git cmake ninja gmake curl unzip
```

Xenocara X11 and Clang ship with the base system. `git` and `gmake` are required.

## NetBSD

```
export PKG_PATH="https://ftp.netbsd.org/pub/pkgsrc/packages/NetBSD/$(uname -m)/10.0/All"
pkg_add -U perl gmake git-base cmake ninja-build unzip pkgconf m4 curl
```

If base X11 is not installed, unpack the `xbase.tar.xz` and `xcomp.tar.xz` sets into `/usr/X11R7`, alias
`xscrnsaver.pc` to `xss.pc`, and export:

```
export PATH="/usr/pkg/bin:/usr/pkg/sbin:$PATH"
export PKG_CONFIG_PATH="/usr/X11R7/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export CMAKE_PREFIX_PATH="/usr/X11R7${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"
```

## DragonFly BSD

```
pkg install -y perl5 gcc curl gmake libunistring git cmake ninja unzip pkgconf \
  libX11 libxcb libXext libXfixes libXcursor libXrandr libXi libXrender \
  libXScrnSaver libxkbcommon wayland xorgproto
```

Pre-installing X11 packages prevents source builds of libxcb that fail on DragonFly BSD.

## Solaris / illumos

Install developer tools, CMake, GNU tar, and X11 packages via IPS:

```
pkg install -v --accept perl-538 gcc developer/build/make developer/build/cmake archiver/gnu-tar bash git
pkg install -v --accept \
  x11/header/x11-protocols x11/library/libx11 x11/library/libxcb \
  x11/library/libxext x11/library/libxfixes x11/library/libxcursor \
  x11/library/libxrandr x11/library/libxi x11/library/libxrender \
  x11/library/libxscrnsaver x11/library/libxtst x11/library/libxkbcommon
```

**Crucial:** Solaris `/usr/bin/tar` lacks GNU `-C` extract support. Place GNU tar on PATH ahead of system tar:

```
mkdir -p /tmp/gnutar && ln -sf /usr/bin/gtar /tmp/gnutar/tar
export PATH="/tmp/gnutar:$PATH"
```

# See Also

The project's repo: [https://github.com/Perl-SDL3/](https://github.com/Perl-SDL3/)

The SDL3 Wiki: [https://wiki.libsdl.org/SDL3/FrontPage](https://wiki.libsdl.org/SDL3/FrontPage)

[SDL3](https://metacpan.org/pod/SDL3)

[Affix](https://metacpan.org/pod/Affix)

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2\. Other copyrights, terms, and conditions may apply to data transmitted through this module.

# AUTHOR

Sanko Robinson - [https://github.com/sanko](https://github.com/sanko)
