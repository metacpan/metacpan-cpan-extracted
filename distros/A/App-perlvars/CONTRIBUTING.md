# Contributing to App-perlvars

## Setting up a clone

Install the pre-commit hook once per clone. Run it from anywhere in the repository:

```sh
.githooks/pre-commit --init
```

This sets git's `core.hooksPath` to `.githooks`, so git uses the hooks in that
directory directly. Changes to them take effect without reinstalling. If
`core.hooksPath` is already set to something else, `--init` stops and tells you
how to unset it.

If you installed the hook before it moved to `.githooks/`, you may have a stale
`.git/hooks/pre-commit` symlink pointing at the old `scripts/pre-commit`. Git
ignores `.git/hooks` once `core.hooksPath` is set, but you can delete the
symlink.

## What the hook does

On every commit, the hook:

- refuses commits made directly to `main`, so work happens on a branch and
  lands through a pull request
- runs `precious lint --staged` on the files you are committing

If lint fails, tidy the staged files and commit again:

```sh
precious tidy -q --staged
```

To skip the hook for a single commit, use `git commit --no-verify`.

## Tools

The hook and the `lint` CI workflow use these tools:

- [precious](https://github.com/houseabsolute/precious) and
  [omegasort](https://github.com/houseabsolute/omegasort), which you can
  install with [ubi](https://github.com/houseabsolute/ubi)
- `perltidy` and `perlvars`:

  ```sh
  cpm install --global App::perlvars Perl::Tidy
  ```

`precious.toml` lists the linters and the files each one applies to.

## Running the tests

Install the dependencies, then run the suite:

```sh
dzil listdeps --missing | cpm install --global -
prove -lr t
```

To build the distribution and run the full test suite, including author tests,
use `dzil test`.
