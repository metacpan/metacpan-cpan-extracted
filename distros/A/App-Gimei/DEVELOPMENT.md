# DEVELOPMENT

We use `Minilla` as our authoring tool and `Carton` as our module dependency
manager.

For private instance methods, prefix the method name with an underscore.
For example, _parse().

We considered using `App::Yath`, a test harness CLI, but it does not support
Windows and was therefore not adopted.

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

## How to REPL(Read-Eval-Print-Loop)
```bash
$ carton exec -- reply -Iblib/lib
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

## Docker
```bash
$ docker build -t gimei .
$ docker run --rm -it -v$PWD:/gimei gimei bash -l
```

## cpanfile.snapshot

Generate cpanfile.snapshot on macOS.
Generating it on Ubuntu will result in missing libraries required on macOS.
