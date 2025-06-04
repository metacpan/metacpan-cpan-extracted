#!/usr/bin/env bash

set -x;
startts=$(date +%s)
failures=()

mkdir -p $BS_ROOT/{pkgbuild,pkgmeta,pkgdest,log,src,srcpkg}

parse_repopkgstr() {
  local pkgrepostr="$1"
  local pkgrepo="${pkgrepostr%%/*}";
  local pkgstr="${pkgrepostr##"$pkgrepo/"}"

  if [[ -z "${pkgrepostr//$pkgrepo/}" ]]; then
    pkgrepo=""
  fi

  #echo "$pkgrepo"
  echo "$pkgstr"
}

resolve_pkgbase() {
  pkgstr=$1
  pacinfo="$(pacinfo "$pkgstr" <&-)"

  [[ $err -ne 0 ]] && return $err

  $(perl -e 'use v5.40; my (%matches) = $ARGV[0] =~ /(Base|Repository):\s+([a-z0-9\-]+)/g; say join "\n", map { "export pkg" . lc substr($_, 0, 4) . "=$matches{$_}" } keys %matches' "$pacinfo")

  [[ $? -ne 0 ]] && return $?
  echo "$pkgrepo/$pkgbase"
}

get_pkgbuild() {
  local pkg="$1"
  #local target="$2"
  
  (cd $BS_ROOT/pkgbuild

   pkgctl repo clone --protocol=https "$pkg"
   [[ "$?" -eq 0 ]] && return 0

   aur fetch -r "$pkg"
   [[ "$?" -eq 0 ]] && return 0
  
   return $?)
}

sync_pkgbuild() {
  local pkg="$1"

  (cd $pkg || return $?
  
   git stash -a
   git pull --all)
}

#sync_pkgbuild() {
#  (pkg="$1"
#   target="$2"
#   currbranch="$(git branch)" 
#  
#  cd "$BS_ROOT/pkgbuild/$pkg"
#
#   git switch -c buildpkg-$(epoch)
#   git add -A
#   git commit -S -m "Unsynced changed prior to running buildpkg.sh"
#
#   if [[ ! -d "$BS_ROOT/pkgmeta/$(basename $pkg)" ]]; then
#     git clone --bare . "$BS_ROOT/pkgmeta/$(basename $pkg)"
#     git remote add bs-pkgmeta "$BS_ROOT/pkgmeta/$(basename $pkg)"
#   else
#     git push bs-pkgmeta --all
#     [[ $? -ne 0 ]] && git push --all "$BS_ROOT/pkgmeta/$(basename $pkg)"
#   fi
#
#   git pull --all -f --rebase
#   git mergetool
#   git rebase --continue
#
#   return $?)
#}

run_makepkg() {
  local pkg="$1"

  (cd "$BS_ROOT/pkgbuild/$pkgbase" || continue

    gpg --import keys/pgp/*
    makepkg --allsource
    makepkg -LAfis

    [[ $? -ne 0 ]] && failures+=("$pkgbase")

    echo "$(makepkg --packagelist)" \
      >> "makepkgs_success_$(date +%s).txt"

    cd "$BS_ROOT/pkgbuild")
}

makepkgs() {
  for pkg in $@; do
    local repopkgbase_str="$(resolve_pkgbase "$pkg")"
    local pkgbase="$(parse_repopkgstr "$pkg")"

    if [[ -d "$pkgbase" ]]; then
      sync_pkgbuild "$pkgbase"
    else
      get_pkgbuild "$pkgbase"
    fi
    
    [[ $? -ne 0 ]] && continue

    run_makepkg "$pkg"

  done 2>&1 | tee -a "makepkg_error_$startts.txt";

  echo "" >> "makepkg_error_$startts.txt"
  
  echo "==========================================" \
    >> "makepkg_error_$startts.txt"
  
  echo "${failures[@]}" >> "makepkg_error_$startts.txt"
}

makepkgs "$@"
