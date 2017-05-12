mysqldump -u secret -p --skip-add-locks --add-drop-table --skip-disable-keys --skip-extended-insert cpanblog >cgi-bin/db/cpanblog-backup.sql
mysqldump -u secret -p --create-options --add-drop-table --no-data cpanblog >cgi-bin/db/cpanblog-schema.sql
