-- Run once by the mysql image on an empty data dir (docker-entrypoint-initdb.d),
-- after it has created MYSQL_USER 'dbio'@'%'. Lets dbio create and drop the
-- databases the live suite makes itself (karr k104): the scratch databases
-- dbio_k<NN>_<pid> and the diff's temp databases _dbio_tmp_<pid>_<time>
-- (DBIO::MySQL::Deploy, temp_db_prefix). Database-level, by name pattern;
-- no global privilege. `\_` is a literal underscore, not the LIKE wildcard.
GRANT ALL ON `dbio\_k%`.* TO 'dbio'@'%';
GRANT ALL ON `\_dbio\_tmp\_%`.* TO 'dbio'@'%';
