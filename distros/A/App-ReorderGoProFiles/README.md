# NAME

App::ReorderGoProFiles - Reorder GoPro files

# SYNOPSIS

    Usage:
          reorder-gopro-files [-c | --copy]
                              [-m | --move]
                              [-f | --force]
                              <files>...

# DESCRIPTION

`reorder-gopro-files` reorders (symlinks, copies or moves) GoPro video files
so it is easier to work with. For example:

    GOPR001.MP4
    GP01001.MP4

is renamed to

    GP001-00.MP4
    GP001-01.MP4

# LICENSE

Copyright (C) vti.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

vti <viacheslav.t@gmail.com>
