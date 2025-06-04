#!/usr/bin/env bash

scriptdir="${0//\/$(basename "$0")/}"
if [[ -f "$scriptdir/bs-common.sh" ]]; then
  . "$scriptdir/bs-common.sh"
else
  echo "Error: Required file bs-common.sh not found in $scriptdir" >&2
  exit 1
fi

[[ "${DEBUG:=0}" -eq 1 ]] && set -x

startdir="$(pwd)"
arch_packaging_repo_base="https://gitlab.archlinux.org/archlinux/packaging/packages"

pkgbuild_dir="${BS_ROOT:=/bs}/pkgbuild"
repo_container="${BS_ROOT:=/bs}/repo"
pkgdest="${BS_ROOT:=/bs}/pkgdest"
logdir="${BS_ROOT:=/bs}/log"

fetch_aur_pkg() {
  pkgbase="$1"
  PLENV_VERSION=system

  out="$(
    env PLENV_VERSION=system \
      aur fetch -r "$pkgbase"
  )"
  echo "$out"

  return "${out[*]: -1:0}"
}

get_update_pkgbuild() {
  repo="$1"
  pkgbase="$2"

  if [[ ! -d "$pkgbase" ]]; then
    git clone "$arch_packaging_repo_base/$pkgbase.git"
    err="${?:-0}"

    [[ "${err:-0}" -eq 0 ]] && return 0

    warn "Failed to fetch '$pkgbase' from '$repo'"

    err=$(fetch_aur_pkg "$pkgbase")

    if [[ "$err" -ne 0 ]]; then
      warn "Failed to fetch '$pkgbase' from AUR"

      for repo in "${BS_REPOS[@]}"; do
        git clone "$BS_USERREPO_BASE_URI/$repo/$pkgbase.git"
        err="${?:-0}"

        if [[ "${err:-0}" -ne 0 ]]; then
          warn "Failed to clone '$pkgbase' from user added repo '$repo"
        fi
      done
    fi
  fi
}

expac_query_dbs() {
  pkgstr="$1"
  shift
  userdb=("$@")
  pkgchoices=()

  for db in Q S "${userdb[@]}"; do
    pkgchoices+=("$(expac "-${db}s" '%r\/%e' "^$pkgstr")")
  done

  echo "${pkgchoices[@]}"
  return ${?:-0}
}

package_choice() {
  pkgchoices=("$@")
  first="${pkgchoices[*]: -1:0}"

  choice=(
    "${first//\/*/}"
    "${first//*\//}"
  )

  [[ ${DEBUG:-0} -ne 0 ]] && warn "pkgchoices: ${pkgchoices[*]}"
  [[ ${DEBUG:-0} -ne 0 ]] && warn "choice: ${choice[*]}"
  first=(${first//\//"\n"})
  echo "${choice[@]}"
  return ${?:-0}

  #local i=0
  #for pkgrepo in "${pkgchoices[@]}"; do
  #  printf "\(%d.\) %s\n" "$((++i))" "$pkgrepo"
  #done

  #echo ${pkgchoices[*]:0:1}
}

enter_pkgbuild_repo() {
  pkgbase="$1"
  get_update_pkgbuild "$pkgbase"

  branches=($(git branch --all))
  curr_branch="${branches[*]:0:1}"
  new_branch="$curr_branch-$(date +%s)"

  git switch -c "$new_branch"
  git add -A
  git commit -S -m "Unsynced changes pre-rebase and rebuild"
  git push "$new_branch"

  for branch in "${branches[@]}"; do
    [[ -z "${branch//main|master/}" ]] || continue

    git switch "$curr_branch"
    git pull "$branch" --rebase
    err="${?:-0}"

    while [[ "${err:-0}" -ne 0 ]]; do
      git mergetool
      err="${?:-0}"
      git rebase --continue
      err="${?:-0}"
    done

    git push "$curr_branch"
  done
}

do_makechrootpkg() {
  pkgbase="$1"
  [[ -z "$pkgbase" ]] && warn "No pkgbase provided." && return 1
  cleanchroot="${2:=0}"
  cleanbuilddir="${3:=0}"

  local makechrootpkg_opts=(makechrootpkg
    -Cun${cleanchroot:+c}
    -r"$CHROOT" - -sifAL${cleanbuilddir:+Cc})

  echo "$("${makechrootpkg_opts[@]}")"
  return "${?:-0}"
}

do_bsrepoadd() {
  pkgbase="$1"

  local bsrepoadd_opts=(
    env BS_CLOBBER=1
    bs-repoadd "$PKGDEST/$pkgbase"
  )

  echo "$("${bsrepoadd_opts[@]}")"
}

handle_pkgspec() {
  local pkgspec="$1"

  # FIX ME: First result is probably what we want unless the user declares
  # otherwise in the current local git config or a bs-repo-conf.toml file in
  # the repo root
  pkgchoices=($(expac_query_dbs "$pkgspec"))
  pkgchoice=($(package_choice "${pkgchoices[@]}"))

  # Fairly sure pactree includes the provided pkgspec compliant string in the
  # results...
  pkgtree=($(pactree -lus "${pkgchoice[*]: -1:0}"))

  for dep_pkgspec in "${pkgtree[@]}"; do
    handle_pkgspec "$dep_pkgspec"
  done

  enter_pkgbuild_repo "${pkgchoice[*]: -1:0}" "${makechrootpkg_opts[@]}"
  local err="${?:-0}"

  [[ ${err:-0} -ne 0 ]] && echo "$("${bsrepoadd_opts[@]}")"
  return $?
}

for pkgspec in "$@"; do
  cd "$pkgbuild_dir" || die "Failed to change back to PKGBUILD directory" $?
  handle_pkgspec "$pkgspec"
done

cd "$startdir" || die "Failed to change back to starting directory" $?
