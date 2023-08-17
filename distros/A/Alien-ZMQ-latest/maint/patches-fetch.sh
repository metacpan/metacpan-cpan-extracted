#!/bin/sh
#
# Requires:
#
#   pkg:deb/debian/wget         (wget)
#   pkg:deb/debian/patchutils   (filterdiff)
#   pkg:deb/debian/moreutils    (sponge)
#   pkg:cpan/dist/File-Rename   (rename)

CURDIR=`dirname "$0"`

set -eu
cd $CURDIR
PATCHES_DIR=../patch
mkdir -p $PATCHES_DIR
wget -P $PATCHES_DIR -ci patch-list
rename -f 's/\Q?full_index=1\E//' $PATCHES_DIR/*.patch*
filterdiff -p1 -x 'tests/*' $PATCHES_DIR/4494.patch | sponge $PATCHES_DIR/4494.patch

filterdiff -p1 -x 'RELICENSE/*' $PATCHES_DIR/4507.patch \
	| perl -0777 -pE 'my $REMOVE = <<EOF;
diff --git a/RELICENSE/daira.md b/RELICENSE/daira.md
new file mode 100644
index 0000000000000000000000000000000000000000..cc841a83fca614f2eccd0aebffe448caa991af81
EOF
s/@{[ quotemeta($REMOVE) ]}//s' \
	| sponge $PATCHES_DIR/4507.patch
