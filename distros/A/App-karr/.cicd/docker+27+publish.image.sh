#!/bin/sh
# Publish karr's rolling `edge` images to Docker Hub off the main branch.
# Canonical release tags (latest / %v / user / %v-user) stay owned by
# `dzil release` ([@Author::GETTY::Docker]); this job never touches them, so a
# CI build can never overwrite a released image.
set -eu

test "${CICD_PUBLISH_IMAGE:-false}" = true || exit 78
[ "$CICD_REF" = refs/heads/main ] || exit 78
if [ -z "${CICD_REGISTRY_USER:-}" ] || [ -z "${CICD_REGISTRY_PASSWORD:-}" ]; then
  echo "SimpiCI: no registry credentials; skipping publish" >&2
  exit 78
fi

repo="$(printf '%s' "$CICD_IMAGE_REPOSITORY" | tr '[:upper:]' '[:lower:]')"

printf '%s' "$CICD_REGISTRY_PASSWORD" \
  | docker login "$CICD_REGISTRY" --username "$CICD_REGISTRY_USER" --password-stdin

docker tag "$repo:$CICD_COMMIT"      "$repo:edge"
docker tag "$repo:$CICD_COMMIT-user" "$repo:edge-user"
docker push "$repo:edge"
docker push "$repo:edge-user"
