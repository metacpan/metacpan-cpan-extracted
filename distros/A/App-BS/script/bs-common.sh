#!/usr/bin/env bash

die () {
  args=("$@")
  status=1

  [[ "${args[-1]//[^0-9]+/}" == "${args[-1]}" ]] \
     && [[ "${args[-1]}" -ge 0 ]] && [[ "${args[-1]}" -le 255 ]] \
     && status="${args[-1]}" \
     && unset 'args[-1]'

  for err in "${args[@]}"; do
    >&2 echo " [!!] $err"
  done

  echo ""
  exit $status
}

warn () {
    for err in "$@"; do
      >&2 echo " [!!] $err"
    done
}

say () {
  for msg in "$@"; do
    echo " :: $msg"
  done
}
