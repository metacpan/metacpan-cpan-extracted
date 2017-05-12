mysqldump -u barbie --skip-add-locks --add-drop-table --skip-disable-keys --skip-extended-insert cpanadmin >cgi-bin/db/cpanadmin-backup.sql
#mysqldump -u barbie --skip-add-locks --add-drop-table --skip-disable-keys --skip-extended-insert cpanstats ixaddress tester_address tester_profile >cgi-bin/db/tester-backup.sql
#mysqldump -u barbie --skip-add-locks --add-drop-table --skip-disable-keys --skip-extended-insert testers >cgi-bin/db/testers-backup.sql

mysqldump -u barbie --skip-add-locks --add-drop-table --skip-disable-keys --skip-extended-insert --no-data cpanadmin >cgi-bin/db/cpanadmin-schema.sql
mysqldump -u barbie --skip-add-locks --add-drop-table --skip-disable-keys --skip-extended-insert --no-data testers >cgi-bin/db/testers-schema.sql
#mysqldump -u barbie --skip-add-locks --add-drop-table --skip-disable-keys --skip-extended-insert testers profile address >cgi-bin/db/testers-profile.sql