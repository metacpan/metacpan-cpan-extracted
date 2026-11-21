# The committed LICENSE file

Read when the build aborts over `LICENSE`, when picking up an older distribution, after
changing `license`, `copyright_holder` or `copyright_year`, or when a forge shows the
distribution as unlicensed.

The bundle expects `LICENSE` to be a **committed file in the repository**. It removes
`[License]` from `@Basic` and adds `[LicenseFile]`, which aborts the build when that file
is missing or no longer matches the distribution's `license`, `copyright_holder` and
`copyright_year`:

```
[@Author::GETTY/LicenseFile] no LICENSE in the distribution:
run 'dzil genlicense' and commit the file
```

Write it once, then track it:

```bash
dzil genlicense
git add LICENSE
```

**The `git add` is not optional.** The bundle gathers through `Git::GatherDir`, which
sees only tracked files, so a LICENSE left untracked in the working directory fails with
the identical message — which reads as though `genlicense` did nothing.

Re-run `genlicense` after changing `license`, `copyright_holder` or `copyright_year`.
Checking the file against them is the whole point of the plugin: a committed LICENSE
otherwise keeps serving the old licence silently, with no warning and no build failure.

The target is the repository, not the tarball. GitHub, Gitea and Forgejo detect a
licence only from a committed `LICENSE`, and a generated one never exists outside the
build — which is why a distribution built the default way shows up as unlicensed on its
own project page. `genlicense` writes the bare licence text, not the `fulltext` that
`[License]` generates: the copyright notice `fulltext` prefixes is enough to make GitHub
report `NOASSERTION` instead of naming the licence.

Distributions last built before the bundle added `[LicenseFile]` fail on their next
build. When picking up an older dist, `ls LICENSE` is cheaper than diagnosing it
mid-release. For a dist that deliberately ships no committed LICENSE,
`generate_license = 1` restores the generated file and adds no check.
