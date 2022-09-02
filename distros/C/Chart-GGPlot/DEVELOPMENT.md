# Development Notes

## First time setup

1. Checkout project source

1. Install dzil and then dependencies

```
cpanm Dist::Zilla
dzil authordeps | cpanm --notest
dzil listdeps | cpanm --notest
```

## Build and test with dzil

```
# build
dzil build

# test
dzil test
```

