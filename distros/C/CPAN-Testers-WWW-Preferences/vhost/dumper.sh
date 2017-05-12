mysqldump -u barbie --skip-add-locks --add-drop-table --skip-disable-keys --skip-extended-insert cpanprefs >cgi-bin/db/cpanprefs-backup.sql
mysqldump -u barbie --skip-add-locks --add-drop-table --skip-disable-keys --skip-extended-insert --no-data cpanprefs >cgi-bin/db/cpanprefs-schema.sql
