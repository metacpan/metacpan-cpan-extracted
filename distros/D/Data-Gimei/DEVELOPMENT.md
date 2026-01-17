# DEVELOPMENT

We use `Minilla` as our authoring tool and `Carton` for managing module
dependencies.

## Development Environment
```bash
$ cpanm Carton
$ carton install
```

## How to Test
```bash
$ carton exec perl Build.PL
$ carton exec perl Build build
$ carton exec perl Build test
```

## How to Format
```bash
$ author/format.sh
```

## How to Release to CPAN
```bash
$ carton exec minil release
```
