# Libsass Digest Plugin

Native libsass plugin adding (file) digest functions

## Building

You need to have [libsass] [1] already [compiled] [2] or [installed] [3] as a
shared library (inclusive header files). It is then compiled via `cmake`. See
this example to compile it on windows via [MinGW] [4] Compiler Suite:

```cmd
git clone https://github.com/sass/libsass.git
mingw32-make -C libsass BUILD=shared CC=gcc -j5
git clone https://github.com/mgreter/libsass-digest.git
cd libsass-digest && mkdir build && cd build
cmake -G "MinGW Makefiles" .. -DLIBSASS_DIR="..\..\libsass"
mingw32-make CC=gcc -j5 && dir digest.dll
```

You may define `LIBSASS_INCLUDE_DIR` and `LIBSASS_LIBRARY_DIR` separately!

## API

The following functions are available when you import the digest plugin.

#### String digest functions
- `md5($x)` - Returns the MD5 digest for $x.
- `crc16($x)` - Returns a CRC16 checksum for $x.
- `crc32($x)` - Returns a CRC32 checksum for $x.
- `base64($x)` - Returns the Base64 text of $x.

#### File digest functions
- `md5f($x)` - Returns the MD5 digest for file $x.
- `crc16f($x)` - Returns a CRC16 checksum for file $x.
- `crc32f($x)` - Returns a CRC32 checksum for file $x.
- `base64f($x)` - Returns the Base64 text of file $x.

## Copyright

© 2017 [Marcel Greter] [5]

[1]: https://github.com/sass/libsass
[2]: https://github.com/sass/libsass/wiki/Building-Libsass
[3]: http://libsass.ocbnet.ch/installer/
[4]: http://sourceforge.net/projects/mingw-w64/files/Toolchains%20targetting%20Win32/Personal%20Builds/mingw-builds/
[5]: https://github.com/mgreter

