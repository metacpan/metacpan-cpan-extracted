#!/bin/sh

MANPAGE=$1

[ -z "$MANPAGE" ] && echo "usage: one-man-page <manpage>" 1>&2 && exit 1

[ -e "one-page-$MANPAGE" ] && rm -rf "one-page-$MANPAGE"

mkdir "one-page-$MANPAGE"

man $MANPAGE \
    | bin/clean-utf8-man.pl \
    | tee clean-utf8-$MANPAGE.html \
    | rman -f HTML -r off \
    | tee untidy-$MANPAGE.html \
    | tidy -asxml -utf8 -bare -f tidy.errors \
    | tee tidy-$MANPAGE.html \
    | bin/mangle-rman-html.pl -title "$MANPAGE" \
    > one-page-$MANPAGE/$MANPAGE.html

make-epub -output $MANPAGE.epub \
          -creator 'Mathias Weidner' \
	  -publisher 'Mathias Weidner' \
          -title 'Initramfs Man Pages' \
	  -rights 'CC BY-SA 3.0' \
	  -level2 '_tag:h2' \
          -tocdepth 2 \
	  one-page-$MANPAGE

epubcheck $MANPAGE.epub
