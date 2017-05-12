mysqldump -u secret -p --skip-add-locks --add-drop-table --skip-disable-keys --skip-extended-insert cpanwiki >cgi-bin/db/cpanwiki-backup.sql
mysqldump -u secret -p --create-options --add-drop-table --no-data cpanwiki >cgi-bin/db/cpanwiki-schema.sql

