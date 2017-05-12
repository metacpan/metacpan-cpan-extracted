#!/bin/zsh
set -e
fn=$1
errfn=${fn//.d*/.err}
function die { echo 1>&2 $*; exit 1 }

[[ -r $fn ]] || die "No such file $fn"

../script/perlminlint $fn |& sed -e "s,$PWD/,," > $errfn

echo $errfn is created
