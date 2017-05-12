#!/bin/bash

# Note see also tests in t/ which may eventually replace these.

source ./test-setup.sh

#--------------------------
# Test begins
#--------------------------
echo "testing biotree ...";

echo -ne "-r "; if $BIOTREE -r 'JD1' test-files/test-biotree.dnd > /dev/null 2> /dev/null; then echo "works"; else echo "failed"; fi
echo -ne "-M "; if $BIOTREE -M test-files/test-biotree.dnd > /dev/null 2> /dev/null; then echo "works"; else echo "failed"; fi


# cat  tt.bash | sed 's/(^.+ )(-. )(.+$)/echo -ne "\2"; if \1\2\3 \> \/dev\/null 2\> \/dev\/null; then echo "works"; else echo "failed"; fi/'

testEnd=`date`;
echo "-------------";
echo "testing ends: $testEnd.";
exit;
