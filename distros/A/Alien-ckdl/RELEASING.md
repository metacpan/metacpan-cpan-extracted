# Releasing Alien::ckdl to CPAN

This dist uses plain `ExtUtils::MakeMaker` plus
[`cpan-upload`](https://metacpan.org/pod/cpan-upload) (from
`CPAN::Uploader`). No Dist::Zilla, no Minilla, no surprises.

## Per-release checklist

1. Make sure the working tree is clean and on `master`:

   ```sh
   git status
   git pull --ff-only
   ```

2. Bump `$VERSION` in `lib/Alien/ckdl.pm`.

3. Update `Changes`: replace the date on the new version's heading and
   add bullet points describing the changes since the last release.

4. Sanity-build from a clean slate:

   ```sh
   make distclean 2>/dev/null || true
   perl Makefile.PL
   make
   make test
   ```

5. Cut and upload the release:

   ```sh
   make release
   ```

   The `release` target:

   - Runs `make disttest` (builds the tarball, unpacks it, configures
     it, and runs its tests - this is what catches missing
     `MANIFEST` entries before they reach CPAN).
   - Refuses to proceed if the git working tree is dirty.
   - Refuses to proceed if a tag `v$(VERSION)` already exists.
   - Runs `cpan-upload` on the freshly built tarball.

6. Tag and push:

   ```sh
   git commit -am "Release v$(perl -Ilib -MAlien::ckdl -e 'print $Alien::ckdl::VERSION')"
   git tag    "v$(perl -Ilib -MAlien::ckdl -e 'print $Alien::ckdl::VERSION')"
   git push --follow-tags
   ```

7. Wait ~1 hour, then verify on
   [MetaCPAN](https://metacpan.org/dist/Alien-ckdl).

## Recovery

- **Upload failed mid-way.** `cpan-upload` is idempotent against PAUSE
  re-uploads of the *same* tarball; just run `make release` again.
- **Uploaded a broken release.** You have 72 hours to delete it from
  PAUSE via the web UI (`https://pause.perl.org/` -> "Delete
  Files"). After that it's permanent in the BackPAN archive. Either
  way, **never reuse a version number** - bump and re-release.
- **Forgot to bump `$VERSION`.** The `release` target's "tag already
  exists" guard will catch this on the second run, but the tarball
  will already exist locally. Delete it (`rm Alien-ckdl-*.tar.gz`),
  bump the version, and start over.

## Notes on Alien-specific concerns

- The dist tracks upstream `ckdl`'s `main` branch rather than a tagged
  release (see `alienfile`). Each CPAN release therefore captures
  *whatever upstream `main` was on the day of fetch*. Mention the
  upstream commit hash in `Changes` if you want the release to be
  reproducible.
- `make disttest` will perform the full alienfile build (download +
  compile of ckdl) inside the unpacked tarball. Expect the release
  step to take a minute or two and to require network access.
