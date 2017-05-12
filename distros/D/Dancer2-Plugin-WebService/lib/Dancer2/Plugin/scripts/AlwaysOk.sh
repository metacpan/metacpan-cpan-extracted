#!/bin/sh
#
# This script is replaced from the INTERNAL simple authentication
# I leave it here only as an example.
#
# It always authorized user successfully no matter
# the username the password or group membership.
# Wait three arguments
# 
#    hex packed username
#    hex packed password
#    comma delimitted groups that the user should be member at least to one of them
# 
# Printsat standard output the three lines
# 
#    1         (succesfull login)
#    ok
#    the same groups you use as input

if [ -z $1 ]; then echo "You did not define the username";  exit 1 ; fi
if [ -z $2 ]; then echo "You did not define the password";  exit 1 ; fi
if [ -z $3 ]; then echo "You did not define group list"  ;  exit 1 ; fi

echo 1
echo ok
echo $3

exit 0