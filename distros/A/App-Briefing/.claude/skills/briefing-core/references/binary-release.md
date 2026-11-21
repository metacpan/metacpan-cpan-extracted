# Binary release

How App::Briefing `<V>` becomes the five standalone assets the starters
download, and how their hashes become the plugin's pins. Sources: `dist.ini`,
`.github/workflows/binaries.yml`, and the bundle's `dzil-binary.yml` at the
40-hex commit that `binaries.yml` pins in `uses:` and `bundle_ref`.

## Publish gate

Every step that leaves the machine needs the maintainer's explicit go-ahead
naming it: `dzil release`, pushing commits or tags, a workflow dispatch, a
release edit, a marketplace update. Reading runs and downloading release files
are local.

## 1. Release the distribution

`dzil release` of `<V>`:

1. uploads the tarball to CPAN;
2. tags `<V>` (bundle `tag_format` `%v`: no `v`) and pushes (`Git::Push`);
3. `Author::GETTY::GitHubRelease` creates release `<V>` as a draft with notes
   from `Changes`, attaches the CPAN tarball, then publishes it. A dist with
   binaries is published with `make_latest` false; the workflow marks it latest
   later, when `<V>` is newer than the current latest release.

The bundle refuses the release without `.github/workflows/binaries.yml`.

## 2. Build, smoke, upload, chain

`release: published` starts `binaries.yml`. Its `binaries` job calls the
pinned `dzil-binary.yml`: `plan`, `build` (five assets from the release's CPAN
tarball, verified), `smoke` (each asset on its native runner,
`scripts/binary-smoke.sh`), then `publish`, which uploads the assets,
`SHA256SUMS`, `install.sh` and `install.ps1` to release `<V>`.

The `chain` job (`tests/test_binary_chain.py`, five native runners) needs the
whole reusable workflow, so it runs after the upload. It is evidence, not a
gate: a red chain run means do not import the pins.

- Event did not fire: `gh workflow run binaries.yml --ref <V> -f tag=<V>`.
- Probe, no release touched (`publish` is skipped; `chain` still runs, on the
  `briefing-probe-<sha7>-<platform>` assets in the run's artifacts):
  `gh workflow run binaries.yml --ref <branch>`.

`SHA256SUMS` lists only names matching `-[0-9][^-]*-<platform>`, so `<V>` must
start with a digit and contain no `-`.

## 3. Record the run evidence

The smoke prints only machine facts; provenance comes from the run record:

```sh
gh api repos/Getty/briefing/actions/runs/<run-id> \
  --jq '{head_sha, head_branch, event, referenced_workflows}'
gh api repos/Getty/briefing/actions/runs/<run-id>/jobs --paginate \
  --jq '.jobs[] | {name, conclusion, labels, runner_name}'
gh run view <run-id> --log --job <job-id>
```

`head_sha` is the source commit; `referenced_workflows` names the reusable
workflow's commit. From each job log take the "Runner Image" block; from each
smoke log the `release_evidence` lines; from each chain log the `chain_timing`
lines. Record them on the release card (no home-directory paths).

## 4. Import the pins

In a new, empty `<dir>`:

```sh
gh release download <V> -R Getty/briefing -p SHA256SUMS -D <dir>
python3 scripts/import-binary-sums.py --version <V> \
  --input <dir>/SHA256SUMS --output "$PWD/bin/briefing-binaries.sha256"
python3 -m unittest tests.test_binary_pins -v
gh release download <V> -R Getty/briefing -p 'briefing-<V>-*' -D <dir>
(repo=$PWD && cd <dir> && sha256sum -c "$repo/bin/briefing-binaries.sha256")
```

`tests.test_binary_pins` tests the importer, not the imported file; the
`sha256sum -c` line checks each published asset against its pin (macOS:
`shasum -a 256 -c`). The pin file is the only place the release's hashes are
trusted from. Neither the starter nor the bootstrap is rebuilt for a new
version: both read `<V>` from the pin file. The pin also names the cache
directory (`<V>/<first 16 hex>/`), so a changed pin for the same `<V>`
provisions into a new directory.

## 5. Commit and ship

The reviewer checks the pin diff and the evidence; the release manager commits
`bin/briefing-binaries.sha256` (and `Changes` if needed). Pushing that commit
and updating the marketplace's plugin version are separate publish-gate
actions. Until users have a plugin version with the pin file installed, they
run the fallback.

Then run the live harness checks in [live-verification.md](live-verification.md)
against the installed copy.
