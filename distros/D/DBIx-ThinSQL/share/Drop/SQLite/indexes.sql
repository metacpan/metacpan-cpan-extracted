PRAGMA writable_schema = 1;

delete from sqlite_master where type = 'index';

PRAGMA writable_schema = 0;

VACUUM;

PRAGMA INTEGRITY_CHECK;
