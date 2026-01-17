# DEVELOPMENT

We use `Minilla` as our authoring tool and `Carmel` as our module dependency
manager.

## How to Setup Development Environment
```bash
$ cpanm Carmel@v0.1.56
$ carmel install
```

## How to Test
```bash
$ carmel exec perl Build.PL
$ carmel exec perl Build build
$ carmel exec perl Build test
```

## How to Format
```bash
$ author/format.sh
```

## How to release to CPAN
```bash
$ carmel exec minil release
```
