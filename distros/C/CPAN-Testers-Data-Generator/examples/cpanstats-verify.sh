#!/usr/bin/bash

EXT1=(".readme" ".txt" ".htm" ".pdf" ".tar" ".gz" ".zip" ".asc" ".patch"  \
     ".par" ".ppm" ".pl" ".pod" ".ppd" ".jar" ".bin" ".ppt" ".rar" ".exe" \
     ".meta" ".png" ".diff" ".xsd" ".md5" ".ptk" ".sxw" ".deb" ".sql"     \
     ".rpm" ".vim" ".dtd" ".bat" ".sx" ".test" ".exculsions" ".srctree"   \
     ".png" ".html" ".conf" ".el" ".mod")
MAX=${#EXT1[*]}
echo >logs/xx.delete
for((ext=0;ext<MAX;ext++)); do
  echo "Checking... ${ext}/${MAX} = ${EXT1[${ext}]}"
  perl bin/cpanstats-select -distversion=${EXT1[${ext}]} >>logs/xx.delete
  perl bin/cpanstats-select -distro=${EXT1[${ext}]} >>logs/xx.delete
done

EXT2=(".pm" ".cgi")
MAX=${#EXT2[*]}
for((ext=0;ext<MAX;ext++)); do
  echo "Checking... ${ext}/${MAX} = ${EXT2[${ext}]}"
  perl bin/cpanstats-select -distversion=${EXT2[${ext}]} | egrep \
    -v "(Net_TCLink|RDBMS|N?et_SSLeay|CGI|Text-Password-Pronouncable).pm" \
    >>logs/xx.delete
  perl bin/cpanstats-select -distro=${EXT2[${ext}]} | egrep \
    -v "(Net_TCLink|RDBMS|N?et_SSLeay|CGI|Text-Password-Pronouncable).pm" \
    >>logs/xx.delete
done

EXT3=(".php")
MAX=${#EXT3[*]}
for((ext=0;ext<MAX;ext++)); do
  echo "Checking... ${ext}/${MAX} = ${EXT3[${ext}]}"
  perl bin/cpanstats-select -distversion=${EXT3[${ext}]} | egrep \
    -v "Test.php" \
    >>logs/xx.delete
  perl bin/cpanstats-select -distro=${EXT3[${ext}]} | egrep \
    -v "Test.php" \
    >>logs/xx.delete
done
