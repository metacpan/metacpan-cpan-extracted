#!/bin/sh

NOTES_DIR=$1

for FILE in $NOTES_DIR/*; do
    echo "Stripping $FILE";
    attr -r simplenote.key $FILE;
    attr -r simplenote.tags $FILE;
    attr -r simplenote.systemtags $FILE;
done

