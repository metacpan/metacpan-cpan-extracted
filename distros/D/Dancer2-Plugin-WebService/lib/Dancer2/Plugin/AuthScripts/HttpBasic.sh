#!/bin/sh
# Http Basic Authentication against a htpasswd file
# The htpasswd utility must exist somewhere at your path
# First create the htpasswd file and define some users e.g.
#
#	touch       /etc/htpasswd
#	htpasswd -b /etc/htpasswd joe pass1
#	htpasswd -b /etc/htpasswd bob pass2
#
# This script accepts the username and the password as hex packed stings e.g
#
#	echo -n joe   | xxd -ps   # 6a6f65
#	echo -n pass1 | xxd -ps   # 7061737331
#	./HttpBasic.sh 6a6f65 7061737331
#
# If authorized successfully prints
# 
#	0
#	null
#
# if not
#
#	Authorization error
#	null
#
# George Bouras , george.mpouras@yandex.com
# Joan Ntzougani, gravitalsun@hotmail.com
# Athens, Hellas, 12 Jul 2019


declare -A util  # -A is for hashes
declare -a ArrayPath=( `echo $PATH | sed 's/:/\n/g'` )
function LocateFileAtPath()
{
	for i in ${ArrayPath[@]}
	do
		if [ -f "$i/$1" ]; then
		echo "$i/$1"
		return
		fi
	done

exit 1
return
}

# Search for the prerequsite utilites
for i in "htpasswd" "xxd"
do
util[$i]=$(LocateFileAtPath $i)
if [ $? -ne 0 ]; then echo -e "Could not found utility $i at your \$PATH\n"; exit 1; fi
done

# Check if the syntax is ok
if [ -z $1 ]; then echo -e "You did not use the 1st argument (username)\n"; exit 1; else username=$(echo -n $1 | ${util[xxd]} -r -ps); fi
if [ -z $2 ]; then echo -e "You did not use the 2nd argument (password)\n"; exit 1; else password=$(echo -n $2 | ${util[xxd]} -r -ps); fi
if [ -z $3 ]; then echo -e "You did not use the 3rd argument (htpasswd users db file fullpath)\n"; exit 1; else HtpasswdDB=$3; fi

# Check if the file $HtpasswdDB exist
if [ ! -f $HtpasswdDB ]; then echo -e "The users htpasswd $HtpasswdDB file is missing\n"; exit 1; fi

# Authorization check
if "${util[htpasswd]}" -b -v "$HtpasswdDB" $username $password 1> /dev/null 2>&1
then
echo -e "0\n"
else
echo -e "Basic authorization error\n"
fi