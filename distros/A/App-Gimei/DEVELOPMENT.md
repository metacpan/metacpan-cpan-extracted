# DEVELOPMENT

We use `Minilla` as our authoring tool and `Carton` as our module dependency
manager.

## How to Setup Development Environment
```bash
$ cpanm Carton@v1.0.35
$ carton install --deployment
```

## How to Test
```bash
$ carton exec perl Build.PL
$ carton exec perl Build build
$ carton exec perl Build test
```

## How to Format
```bash
$ carton exec perl author/format.pl
```

## How to release to CPAN
```bash
$ carton exec minil test
$ carton exec -- minil release --dry-run
$ carton exec minil release
```
