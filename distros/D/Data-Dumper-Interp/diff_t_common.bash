#!/usr/bin/env bash
set -e -u

build_parent=".."

declare -A common_files=()

for f in "$build_parent"/*/t/*ommon*.pm ; do
  if [ -r "$f" ] ; then common_files+=($(basename "$f") 1); fi
done

diffs_found=""
count=0
for fname in "${!common_files[@]}" ; do
  declare -a files=()
  for f in "$build_parent"/*/t/"$fname" ; do
    if [ -r "$f" ] ; then files+=("$f"); fi
  done
  first="${files[0]}"
  files=("${files[@]:1}") # shift
  ((count++)) || :
  for other in "${files[@]}" ; do
    (set -x; diff "$other" "$first") 2>&1 || diffs_found=yes
    ((count++)) || :
  done
done
if [ -n "$diffs_found" ] ; then
  echo "$count files found. DIFFERENCES FOUND"
  exit 1
else 
  echo "$count files found. No diffs."
  exit 0
fi
