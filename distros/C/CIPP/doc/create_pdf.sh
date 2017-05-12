#!/bin/sh

if [ -f lib/CIPP/Manual.pm ]
then
	cd doc
fi

if [ ! -f ../lib/CIPP/Manual.pm ]
then
	echo "Please change into the doc/ directory and execeute"
	echo "the create_pdf.sh command there."
	exit 1
fi

POD2HTML=$(which pod2html)
PS2PDF=$(which ps2pdf)

if [ -z "$POD2HTML" ]
then
	echo "Command 'pod2html' not found. Aborted."
	exit 1
fi

if [ -z "$PS2PDF" ]
then
	echo "Command 'ps2pdf' not found. Aborted."
	exit 1
fi

echo "Creating PDF documentation from CIPP::Manual..."

cat ../lib/CIPP/Manual.pm |
	./podfilter.pl | \
	$POD2HTML --noindex | \
	./htmlfilter.pl | \
	./html2ps -f html2psrc \
	> Manual.ps && \
	$PS2PDF Manual.ps Manual.pdf && \
	rm -f Manual.ps pod2html-dircache pod2html-itemcache && \
	echo "File docs/Manual.pdf successfully created."


