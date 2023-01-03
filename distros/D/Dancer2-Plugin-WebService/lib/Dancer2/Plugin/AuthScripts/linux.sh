#!/bin/sh
# Authenticate users using the native Linux auth
#   linux.sh 6a6f65 736f6d6570617373
#
# George Bouras , george.mpouras@yandex.com
# 21 Jan 2021

if [ -z $1 ]; then echo -e "You did not use the 1st argument (username)\n"; exit 1; fi
if [ -z $2 ]; then echo -e "You did not use the 2nd argument (password)\n"; exit 1; fi

# Quick find files
function LocateFileAtPath() {
	for i in /usr/bin /bin /usr/sbin /sbin ./
	do
		if [ -f "$i/$1" ]; then
		echo "$i/$1"
		return
		fi
	done
exit 1
}

declare -A util  # -A is for hashes

# Search for the prerequsite utilites
for i in openssl id xxd
do
util[$i]=$(LocateFileAtPath $i)
if [ $? -ne 0 ]; then echo "$i is missing"; exit 1; fi
done

# Abort if the effective user do not have superpowers
if [ $(${util[id]} -u) -ne 0 ]; then echo -e "Need root or sudo privileges\n"; exit 1; fi

username=$(echo -n $1 | ${util[xxd]} -r -ps)
password=$(echo -n $2 | ${util[xxd]} -r -ps)

# Check for the username at the /etc/shadow
if ! record=$(grep $username: /etc/shadow); then echo -e "User $username do not exist\n"; exit 1; fi

declare -a record=(`echo $record    | sed 's/:/\n/g'`)
declare -a hash=(`echo ${record[1]} | sed 's/\\$/\n/g'`)

# ${record[0]}	$username
# ${record[1]}  $?$salt$hashed password
# ${hash[0]}    encryption method
# ${hash[1]}    salt
# ${hash[2]}    hashed password

if [ ${record[1]} != $(echo $password | ${util[openssl]} passwd -${hash[0]} -salt ${hash[1]} -stdin) ]; then
echo -e "wrong password\n";
exit 1
else
echo 0
${util[id]} -nG ${record[0]} | sed 's/ /,/g'
fi