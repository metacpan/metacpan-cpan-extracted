cvs status | perl -ne 'print "$1\n" if m@Repository revision.*/cvsroot/stag/data-stag/(.*),v@' > MANIFEST
