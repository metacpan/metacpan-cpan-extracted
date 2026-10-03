# Vendored nghttp3 source

This directory contains the source used for the fallback libnghttp3 build.

## nghttp3

Version:

    1.18.0

Upstream tag:

    v1.18.0

Upstream repository:

    https://github.com/ngtcp2/nghttp3

The nghttp3 files in this directory are copied from that tag.

## sfparse

nghttp3 1.18.0 uses sfparse as a submodule.

The vendored sfparse revision is:

    4b313cfd2e1b389ae632b36dcd50402307289af2

Upstream repository:

    https://github.com/ngtcp2/sfparse

The sfparse files are copied from that revision.

## What is included

Only files needed to build libnghttp3 with CMake are included.

Upstream examples, tests, fuzzing data, and other development files are not
needed by Alien::nghttp3 and are left out.

The nghttp3 and sfparse license files are included with the vendored source.
