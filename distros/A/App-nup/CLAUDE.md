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

## Project Structure

`script/nup` is the main command (bash script) and `lib/App/optex/up.pm`
is the optex module that provides the core multi-column layout functionality.
Both are bundled in this distribution.

- When modifying `up.pm`, check if option documentation in `script/nup` needs updating
- Keep option documentation order consistent between both files
