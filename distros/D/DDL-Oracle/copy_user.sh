# $Id: copy_user.sh,v 1.2 2000/11/11 07:48:59 rvsutherland Exp $

copy_user.pl > copy_user.sql

if [ $? -gt 0 ]
then
  exit 1
fi

sqlplus -s /  << EOF | tee copy_user.log
  @ copy_user.sql
EOF

# $Log: copy_user.sh,v $
# Revision 1.2  2000/11/11 07:48:59  rvsutherland
# Added CVS tags
#

