#!/bin/sh
# Build karr's two runtime images from the multi-stage Dockerfile:
#   runtime-root -- default entrypoint that drops privileges to whoever owns /work
#   runtime-user -- fixed uid 1000
# Both live in the same repository, told apart by tag ("" vs "-user"). This job
# only builds (validation on every push/PR); docker+27+publish.image.sh pushes.
set -eu

repo="$(printf '%s' "$CICD_IMAGE_REPOSITORY" | tr '[:upper:]' '[:lower:]')"
test -n "$repo"

build() {
  # $1 = Dockerfile target, $2 = full image:tag
  if docker info 2>&1 | grep -qi podman; then
    DOCKER_BUILDKIT=0 docker build --file Dockerfile --build-arg KARR_SRC=checkout --target "$1" --tag "$2" .
  else
    docker build --file Dockerfile --build-arg KARR_SRC=checkout --target "$1" --tag "$2" .
  fi
}

build runtime-root "$repo:$CICD_COMMIT"
build runtime-user "$repo:$CICD_COMMIT-user"
