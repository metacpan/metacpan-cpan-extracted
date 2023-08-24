# Alien-Ruby

## Description

Alien::Ruby is a Perl distribution, and is meant to be installed as a prerequisite for other Perl distributions which rely on the Ruby programming language. The purpose of this distribution is to check if Ruby is already installed, and if not then to download and install it.

## Installation

```
$ cpanm Alien::Ruby
```

## Developers Only

```
# install dependencies
$ dzil authordeps --missing | cpanm
$ dzil listdeps | cpanm

# build distribution
$ dzil build

# test distribution
$ dzil test
```
