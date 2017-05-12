#!/bin/bash

# Note see also tests in t/ which may eventually replace these.

min_bp_version=1.006
source ./test-setup.sh

#-----------------------------
# Test options, one by one
#-----------------------------

echo "testing bioaln ...";

if $BIOALN -b test-files/test-bioaln.cds > /dev/null 2> /dev/null; then echo "bioaln -b: it works!"; else echo "bioaln -b: failed"; fi
if $BIOALN -i 'fasta' test-files/test-bioaln-pep2dna.nuc > /dev/null 2> /dev/null; then echo "bioaln -i: it works!"; else echo "bioaln -i: failed"; fi
if rm test-files/test-bioaln.cds.slice-*.aln >/dev/null 2>&1; then echo "block files removed"; else echo "block files not found"; fi
if $BIOALN -M test-files/test-bioaln.cds > /dev/null 2> /dev/null; then echo "bioaln -M: it works!"; else echo "bioaln -M: failed"; fi
if $BIOALN -R '3' test-files/test-bioaln.cds > /dev/null 2> /dev/null; then echo "bioaln -R: it works!"; else echo "bioaln -R: failed"; fi
if $BIOALN -S test-files/test-bioaln.cds > /dev/null 2> /dev/null; then echo "bioaln -S: it works!"; else echo "bioaln -S: failed"; fi
if $BIOALN -U test-files/test-bioaln.cds > /dev/null 2> /dev/null; then echo "bioaln -U: it works!"; else echo "bioaln -U: failed"; fi


testEnd=`date`;
echo "-------------";
echo "testing ends: $testEnd.";
exit;
