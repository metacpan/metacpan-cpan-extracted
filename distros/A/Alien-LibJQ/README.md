# Developer Note and Instruction on Alien::LibJQ

## What This Module is

This module makes perl binding for jq and its static library. JQ is a light-weight command-line JSON processor, refer to its [project page](https://stedolan.github.io/jq/) for more information.

## How to Install

Install as usual:
   ```shell
   perl Makefile.PL
   make
   make test
   make install
   ```

   1. If you are on a windows box you should use 'nmake' rather than 'make'.
   2. If you are using strawberry perl on windows you should use 'gmake'.

## How This Module Performs the Build

   1. Download and extract jq package.
   2. Copy required script/cmake/source files into extracted jq package directory.
   3. Build jq executable and jq/oniguruma static libraries using cmake.
   4. Install both jq and oniguruma artifacts.

## Cmake Advantage

   1. Enhanced compile and link toolchain.
   2. Fix a jq code portability issue (calling POSIX setenv) on windows mingw.

## Windows Build Note

   1. Only strawberry perl is tested.
   2. Alien::cmake3 is required to build using cmake.
   3. It is possible to build this package using autoconf approach on windows:
      1. strawberry is required to provide a working gcc toolchain from mingw.
      2. git windows package is required to offer bash executable on windows, installation path must NOT contain space (thus C:\Program Files not recommended).
      3. run configure using sh/bash executable.
      4. replace all MAKE variable value in generated Makefile by 'gmake' (from strawberry).