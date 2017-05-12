#!/bin/bash

./add_database.pl server5.hosting.reg.ru user_0000434578 oBffquIb db_name111 db_usersss45555 pass
#./add_www_domain.pl server5.hosting.reg.ru user_0000434578 oBffquIb suxx777.us
#./add_mailbox.pl server5.hosting.reg.ru user_0000434578 oBffquIb t1est@server6-host1.regrutestuser.ru qqqq
exit 0

perl -Ilib ./vdsmanager.pl --host=127.0.0.1 --username=admin  --password=qqqq  \
 --nodeid=1 --vpspassword=qwerty --owner=admin --preset=OVZ-1 --os=centos-5-x86_64 \
 --name=mymegavps7.ru
