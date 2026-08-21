# Release Instructions

To set up:
```
cpanm Dist::Zilla
dzil authordeps | cpanm
```

To build a new release:
```
dzil build
```

To locally install a new release for testing:
```
dzil install
```

To upload a new release:
```
dzil release
```

To manually override the release version e.g. for a major/minor version bump:
```
V=X.Y.0 dzil release
```
