Release checklist for Alien-nghttp2

- Review `Changes` and confirm the release date and summary match the tag.
- Verify `Makefile.PL` metadata matches the PAUSE identity and live GitHub repo.
- Run `perl Makefile.PL`.
- Run `make test`.
- Run `make disttest`.
- Inspect generated `META.json` and `META.yml`.
- Build the tarball with `make dist`.
- Check the tarball contents before upload.
- Upload to PAUSE.
- Confirm PAUSE indexing and MetaCPAN rendering after upload.
