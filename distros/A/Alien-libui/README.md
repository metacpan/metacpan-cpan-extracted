[![Actions Status](https://github.com/sanko/alien-libui/actions/workflows/linux.yaml/badge.svg)](https://github.com/sanko/alien-libui/actions) [![Actions Status](https://github.com/sanko/alien-libui/actions/workflows/windows.yaml/badge.svg)](https://github.com/sanko/alien-libui/actions) [![Actions Status](https://github.com/sanko/alien-libui/actions/workflows/osx.yaml/badge.svg)](https://github.com/sanko/alien-libui/actions) [![Actions Status](https://github.com/sanko/alien-libui/actions/workflows/freebsd.yaml/badge.svg)](https://github.com/sanko/alien-libui/actions) [![MetaCPAN Release](https://badge.fury.io/pl/Alien-libui.svg)](https://metacpan.org/release/Alien-libui)
# NAME

Alien::libui - Build and Install libui: A portable GUI library

# SYNOPSIS

    use Alien::libui;

# DESCRIPTION

libui is a simple and portable (but not inflexible) GUI library in C that uses
the native GUI technologies of each platform it supports.

# Runtime Requirements

The library is built with `meson` and `ninja` both of which may, in turn, be
provided by Aliens.

In addition to those, platform requirements include:

- Windows - Windows Vista SP2 with Platform Update or newer
- \*nix - GTK+ 3.10 or newer (you must install this according to your platform)
- OS X - OS X 10.8 or newer

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

# AUTHOR

Sanko Robinson <sanko@cpan.org>
