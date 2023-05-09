#!/usr/bin/env bash
set -e -u

build_parent=".."

declare -A common_files=()

for f in "$build_parent"/*/t/*ommon*.pm ; do
  if [ -r "$f" ] ; then common_files+=($(basename "$f") 1); fi
done

totcount=0
diffcount=0
for fname in "${!common_files[@]}" ; do
  declare -a files=()
  for f in "$build_parent"/*/t/"$fname" ; do
    if [ -r "$f" ] ; then files+=("$f"); fi
  done
  first="${files[0]}"
  files=("${files[@]:1}") # shift
  ((totcount++)) || :
  for other in "${files[@]}" ; do
    (diff --brief "$other" "$first") 2>&1 || ((diffcount++)) || :
    ((totcount++)) || :
  done
done
if [ $totcount != 0 ] ; then
  echo "$totcount files: $diffcount are DIFFERENT"
  exit 1
else 
  echo "$totcount files: No diffs."
  exit 0
fi
