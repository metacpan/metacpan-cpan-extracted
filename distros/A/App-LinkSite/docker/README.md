# App::LinkSite Docker image

The Docker image contains Perl and a released App::LinkSite distribution,
including its templates and dependencies. It lets you build a static site
without installing Perl modules on the host.

## Use an image

Prepare `links.json` and any configured images in a content directory, then
run from that directory:

```sh
docker run --rm -v "$PWD:/links" davorg/links:latest linksite
```

The image's working directory is `/links`; the bind mount makes your input
available there and receives the output in `docs/`. Generated files may be
owned by the container user. Without the final `linksite` argument, the
default command prints the installed module version instead of building.

The release helper also creates version tags such as `davorg/links:links_0.2.0`.
Use a version tag when you need to select a particular release. See
[the user guide](../README.md) for the JSON format and hosting limitations.

## Build an image locally

From the repository root, with Docker and network access available:

```sh
docker build --build-arg LINKSITE_VERSION=0.2.0 -f docker/Dockerfile -t linksite-local .
docker run --rm linksite-local
```

Choose a version published on CPAN. `LINKSITE_VERSION` is required for the
Dockerfile's `cpanm -n App::LinkSite@...` command. Tests are skipped during
that installation. The base is `perl:latest`.

This build installs the selected version **from CPAN**. The Dockerfile does
not copy or install source from the checkout, so it does not validate local
Perl or template edits. Use the source-tree preview in
[CONTRIBUTING.md](../CONTRIBUTING.md) to test those changes.

Optional `BUILD_DATE` and `GIT_COMMIT` build arguments populate OCI labels.
The Dockerfile's source label currently names `davorg/app-linksite`, while
this repository's package metadata names `davorg-cpan/app-linksite`.

## Publish release images

`docker/build` is a maintainer release script. Run it from the repository
root only when you intend to publish and have Docker Hub push access:

```sh
sh docker/build
```

It reads `VERSION_FROM` from `Makefile.PL`, extracts that module's version,
converts the version for comparison with CPAN's package index, and checks
that the indexed App::LinkSite version matches. It then gathers the Git
revision and UTC build date and runs `docker buildx build --push` with tags
`davorg/links:latest` and `davorg/links:links_<version>`.

The script needs Perl (including `version`), `curl`, `gunzip`, `awk`, Git,
Docker Buildx, network access, and registry authentication. Because it checks
the current CPAN index, an older published version may no longer match that
index. The explicit local build command above does not perform this index
check and does not push an image.
