#!/bin/sh -f

[ ! -f ARS.xs ] && exit 1

mv ARS.xs ARS-xs.org
mv support.c sprt-c.org
mv supportrev.c sprev-c.org
perl infra/pcpp.pl ARS-xs.org > ARS.xs
perl infra/pcpp.pl sprt-c.org > support.c
perl infra/pcpp.pl sprev-c.org > supportrev.c

echo " "
echo "Source files prep'ed for ActiveState compilation. "
echo " "

exit 0

