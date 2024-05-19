#!/bin/sh
#
# Native Linux user authAuthentication
# Accepts two arguments the username and password as hex string
# You can produce a hex string using e.g the command    echo -n SomePassword | xxd -ps
# 
#   Linux_native_authentication.sh <username as hex string> <password as hex string>
#   Linux_native_authentication.sh 6a6f65                   536f6d6550617373776f7264
#   Linux_native_authentication.sh $(echo -n joe | xxd -ps) $(echo -n SomePassword | xxd -ps)
#
# First we search for the user inside the shadow file e.g.    grep "^SomeUser:" /etc/shadow
#   
#   SomeUser:$6$pCt6qNtCYsozKMDu$3yHSXCHigXoKFSpDn8rDKMowvZktB7my1kvBYalkSu9Q1gHU.00lqM2bD27vISCdkG/G2cMJ9F39f7rZQdzIf1:18329:0:99999:7:8:9:
#   
# this line defines the fields
#   
#   username          SomeUser
#   hashed password   $6$pCt6qNtCYsozKMDu$3yHSXCHigXoKFSpDn8rDKMowvZktB7my1kvBYalkSu9Q1gHU.00lqM2bD27vISCdkG/G2cMJ9F39f7rZQdzIf1
#     algorithm        6
#     salt               pCt6qNtCYsozKMDu
#   last change       18329
#   minimum days      0
#   maximum days      99999
#   warn days         7
#   inactive days     8
#   expire   days     9   
#
# algorithms and its verification code
#   
#   6   SHA-512   -> openssl supported       openssl passwd -6 -salt pCt6qNtCYsozKMDu SomePassword
#   5   SHA-256   -> openssl supported       openssl passwd -5 -salt pCt6qNtCYsozKMDu SomePassword
#   1   md5       -> openssl supported       openssl passwd -1 -salt pCt6qNtCYsozKMDu SomePassword
#   2a  blowfish  -> openssl not supported   perl -e 'print crypt("SomePassword", q[$y$j9T$TMK5KZZg4Z6ivQ7PLCRMF1$fG5Ru6aU8rJRvcE4YHJL75PxH.iKo3mChw8M/UiJrA9])'
#   y   yescrypt  -> openssl not supported   perl -e 'print crypt("SomePassword", q[$y$j9T$TMK5KZZg4Z6ivQ7PLCRMF1$fG5Ru6aU8rJRvcE4YHJL75PxH.iKo3mChw8M/UiJrA9])'
#   7   yescrypt  -> openssl not supported   perl -e 'print crypt("SomePassword", q[$y$j9T$TMK5KZZg4Z6ivQ7PLCRMF1$fG5Ru6aU8rJRvcE4YHJL75PxH.iKo3mChw8M/UiJrA9])'
#
# if the algorithm is supported from the openssl you can run
#
#   openssl passwd -ALGORITHM -salt SALT             PASSWORD         e.g
#   openssl passwd -6         -salt pCt6qNtCYsozKMDu SomePassword
#
# Othelse you must call the crypt(3) from Perl or Python3 e.g.

#   perl -le 'print [ getpwnam("SomeUser") ]->[0]'   # SomeUser
#   perl -le 'print [ getpwnam("SomeUser") ]->[1]'   # $y$j9T$TMK5KZZg4Z6ivQ7PLCRMF1$fG5Ru6aU8rJRvcE4YHJL75PxH.iKo3mChw8M/UiJrA9
#   perl -le 'print crypt("password", q[$y$j9T$TMK5KZZg4Z6ivQ7PLCRMF1$fG5Ru6aU8rJRvcE4YHJL75PxH.iKo3mChw8M/UiJrA9)'
#
# George Bouras , george.mpouras@yandex.com
# 22 Feb 2024


declare -A util=( ["echo"]="/usr/bin/echo")

if [ -z $1 ]; then ${util[echo]} -e "You did not use the 1st argument hex username\n"; exit 1; fi
if [ -z $2 ]; then ${util[echo]} -e "You did not use the 2nd argument hex password\n"; exit 1; fi

# Locate the full path of the utils to avoid alias attacks
for i in openssl id xxd sed grep perl
do
util[$i]=__MISSING

  for dir in /usr/bin /bin /usr/sbin /sbin .
  do
    if [ -f "$dir/$i" ]; then
      util[$i]="$dir/$i"
      break
    fi
  done

  if [ ${util[$i]} == __MISSING ]; then
  ${util[echo]} -e "Missing $i\n"
  exit 1
  fi

done

# Abort if the effective user do not have superpowers
if [ $(${util[id]} -u) -ne 0 ]; then ${util[echo]} -e "Need root or sudo privileges\n"; exit 1; fi

username=$(${util[echo]} -n $1 | ${util[xxd]} -r -ps)
password=$(${util[echo]} -n $2 | ${util[xxd]} -r -ps)

# Check for the username at the /etc/shadow
if ! record=$(${util[grep]} "^$username:" /etc/shadow)
then
  ${util[echo]} Unknown user
  ${util[echo]}
  exit 1
fi

declare -a record=( $(${util[echo]} $record     | ${util[sed]} 's/:/\n/g')   )
declare -a fields=( `${util[echo]} ${record[1]} | ${util[sed]} 's/\\$/\n/g'` )

#  ${util[echo]} "username  : $username or ${record[0]}"
#  ${util[echo]} "password  : $password"
#  ${util[echo]} "hash      : ${record[1]}"
#  ${util[echo]} "algorithm : ${fields[0]}"
#  ${util[echo]} "salt      : ${fields[1]}"


if ([ ${fields[0]} == 6 ] || [ ${fields[0]} == 5 ] || [ ${fields[0]} == 1 ])
then
  hash=$(${util[openssl]} passwd -${fields[0]} -salt ${fields[1]} $password)
else
  hash=$(${util[perl]} -e "print crypt(q[$password], q[${record[1]}])")
fi


if [ $hash == ${record[1]} ]
then
  ${util[echo]} 0
  ${util[id]} -nG ${username} | ${util[sed]} 's/ /,/g'
  exit 0
else
  ${util[echo]} Wrong password
  ${util[echo]}
  exit 1
fi