#!/bin/sh
#
# This script is replaced from the INTERNAL authentication, it is here only as an example.
# It always authorized users no matter the username or the password
# Expect two arguments, the username and the password 
# Prints at standard output as result the three lines
# 
#    0         (succesfull login)
#    null

if [ -z $1 ]; then echo -e "You did not provide username\n"; exit 1; fi
if [ -z $2 ]; then echo -e "You did not provide password\n"; exit 1; fi

echo -e "0\n"
exit 0