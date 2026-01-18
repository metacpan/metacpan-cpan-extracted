greple -Mtee cat -n -- '^([A-Z].*\n)(.+\n)*' t/SAMPLE.txt --all
greple -Mtee cat -n -- '^([A-Z].*\n)(.+\n)*' t/SAMPLE.txt --all --discrete
greple -Mtee cat -n -- '^([A-Z].*\n)(.+\n)*' t/SAMPLE.txt --all --discrete --bulkmode
greple -Mtee perl -CSAD -pE '$_="($.)$_"' -- '\S+' t/SAMPLE.txt --all
greple -Mtee perl -CSAD -pE '$_=uc' -- '^([A-Z].*\n)(.+\n)*' t/SAMPLE.txt --all
greple -Mtee perl -CSAD -pE '$_=uc' -- '^([A-Z].*\n)(.+\n)*' t/SAMPLE.txt --all --discrete
greple -Mtee perl -CSAD -pE '$_=uc' -- '^([A-Z].*\n)(.+\n)*' t/SAMPLE.txt --all --discrete --bulkmode
greple -Mtee perl -CSAD -pE '$_=uc' -- '^([A-Z].*\n)(.+\n)*' t/SAMPLE.txt --all --fillup
greple -Mtee perl -CSAD -pE '$_=uc' -- '^([A-Z].*\n)(.+\n)*' t/SAMPLE.txt --all --fillup --discrete
greple -Mtee cat -n -- '^(.+\n)+' t/SAMPLE.txt --all --fillup
greple -Mtee cat -n -- '^(.+\n)+' t/SAMPLE.txt --all --fillup --discrete
greple -Mtee cat -n -- '^(.+\n)+' t/SAMPLE.txt --all --fillup --discrete --bulkmode
greple -Mtee perl -CSAD -E 'print sort <>' -- '^(.+\n)+' t/SAMPLE.txt --all --crmode
greple -Mtee '&ansifold' -w 20 -- '^([A-Z].*\n)(.+\n)*' t/SAMPLE.txt --all --discrete
