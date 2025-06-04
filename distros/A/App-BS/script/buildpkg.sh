#!/usr/bin/bash
scriptname="$0"

dbgmode="${BS_DEBUG:-$PB_DEBUG}"
[[ -n "$dbgmode" ]] && set -x

set -e
shopt -s nullglob

[[ -n "$BS_PKGSYNC" ]] && sudo pacman -Syy

arch_pkgbuildrepo_uri="https://gitlab.archlinux.org/archlinux/packaging/packages"
aur_repo_uri="https://aur.archlinux.org/"

default_repo="${PB_PKGDEST_REPO:-universe}"
default_carch="${PB_CARCH:-${CARCH:-x86_64}}"
default_targetdir="$HOME/.local/share/bs/etc/default/target"
default_target="${PB_TARGET:-default}"
default_triple="${PB_TRIPLE:-"$default_repo-$default_carch-$default_target"}"

targetdir="${PB_TARGETDIR:-${BS_TARGETDIR:-$default_targetdir}}"
targets=("$targetdir"/*)

queue="$@"
built=()

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
  #target=$2

  #pacinfo "$1"
  pacinfo="$(pacinfo "$pkgstr" <&-)"
  err=$?
  
  [[ $err -ne 0 ]] && return $err

  $(perl -e 'use v5.40; my (%matches) = $ARGV[0] =~ /(Base|Repository):\s+([a-z0-9\-]+)/g; say join "\n", map { "export pkg" . lc substr($_, 0, 4) . "=$matches{$_}" } keys %matches' "$pacinfo")

  [[ $? -ne 0 ]] && return $?
  
  echo "$pkgrepo/$pkgbase"
}

get_pkgbuild() {
  (pkg="$1"
   target="$2"

   cd $BS_ROOT/pkgbuild

   pkgctl repo clone --protocol=https "$pkg"
   [[ "$?" -eq 0 ]] && return 0

   aur fetch -r "$pkg"
   [[ "$?" -eq 0 ]] && return 0
  
   return $?)
}

sync_pkgbuild() {
  (pkg="$1"
   target="$2"
   currbranch="$(git branch)" 
   
   cd "$BS_ROOT/pkgbuild/$pkg"

   git switch -c buildpkg-$(epoch)
   git add -A
   git commit -S -m "Unsynced changed prior to running buildpkg.sh"

   if [[ ! -d "$BS_ROOT/pkgmeta/$(basename $pkg)" ]]; then
     git clone --bare . "$BS_ROOT/pkgmeta/$(basename $pkg)"
     git remote add bs-pkgmeta "$BS_ROOT/pkgmeta/$(basename $pkg)"
   else
     git push bs-pkgmeta --all
     [[ $? -ne 0 ]] && git push --all "$BS_ROOT/pkgmeta/$(basename $pkg)"
   fi
 
   git pull --all -f --rebase
   git mergetool
   git rebase --continue

   return $?)
}

build_pkg() {
  pkg="$1"
  target="$2"

  sudo cp -vaf "$target/"{makepkg.conf,pacman.conf} "$CHROOT/root/etc/"
  sudo cp -vaf "$target/"{makepkg.conf,pacman.conf} "$CHROOT/nameless/etc/"

  startts="$(epoch)"
  localbuilt=()

  cd "$BS_ROOT/pkgbuild/$pkg" || return $?

  say "Adding keys included in $pkg PKGBUILD repo..."
  gpg --verbose --import keys/pgp/*.asc
  
  say "Building $pkg in CHROOT at $CHROOT..."
  makechrootpkg -Cunc -- -CLAfisc

  echo "Updating $pkg .SRCINFO..."
  makepkg --printsrcinfo > ".SRCINFO"
 
  endts=$(epoch)
  
  localbuilt=$("$(makepkg --packagelist)")
  built+=${localbuilt[@]}

  echo "[$scriptname@$startts-$(endts) build manifest:]"
  echo "  >${localbuilt[*]}"
  echo "[/$scriptname@$startts-$(endts) build manifest]"

  return $?
}

for pkg in "${queue[@]}"; do
  repopkgstr=($(resolve_pkgbase "$pkg"))
  repopkg=($(parse_repopkgstr "$repopkgstr"))

  if [[ ! -d "$pkg" ]]; then
    get_pkgbuild "$pkg" "$target"
  else
    sync_pkgbuild "$pkg" "$target"
  fi

  for target in "${targets[@]}"; do
   target_build_pkg_res=()

   while read line; do
      [[ $dbgmode -eq 0 ]] || echo "$line"
      
      [[ -z "${line##  >*}" ]] || continue
      target_build_pkg_res+=("${line##  >}")

      echo "Adding $pkg package archives to $BS_REPO..."
      cd $PKGDEST
      bs-repoadd "${target_build_pkg_res[@]}"
      cd "$BS_ROOT/pkgbuild/$pkg"
    done < <(build_pkg "$pkg" "$target")
  done
  
  cd "$BS_ROOT/pkgbuild"
done

