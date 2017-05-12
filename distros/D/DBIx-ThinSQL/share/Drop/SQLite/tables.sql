PRAGMA writable_schema = 1;

delete from sqlite_master where type = 'table';
delete from sqlite_master where type = 'index';
delete from sqlite_master where type = 'trigger';

PRAGMA writable_schema = 0;

VACUUM;

PRAGMA INTEGRITY_CHECK;
