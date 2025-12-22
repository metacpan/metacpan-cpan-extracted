# Development Notes for App::nup

## Build System

`lib/App/nup.pm` is auto-generated from `script/nup` by extracting POD sections.

### Before Committing

1. Edit `script/nup` (both code and POD)
2. Run `minil build` to regenerate `lib/App/nup.pm` and `README.md`
3. Commit all files

```bash
minil build
git add script/nup lib/App/nup.pm README.md
git commit -m "..."
git push
```

### Release

1. Update `Changes` (add entries under `{{$NEXT}}`)
2. No need to commit - `minil release` handles everything

```bash
minil release
```

This will:
- Replace `{{$NEXT}}` with version and timestamp
- Run tests
- Commit and create git tag
- Upload to CPAN

## Related Projects

This is a wrapper for `App::optex::up`. When `up.pm` is updated:

- Check if the same changes are needed in `script/nup`
- Keep option documentation order consistent
- Update `cpanfile` if new `App::optex::up` version is required
