#!/bin/sh

set -e

./rebuild-manifest.sh
./repod.sh

git diff
if [ -n "$(git status -s)" ]; then
	echo === GIT is dirty ===
	git status -s
	exit 1
fi

./remake.sh
