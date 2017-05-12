BEGIN DECLARE stmt longtext;
SET stmt = ( SELECT info FROM INFORMATION_SCHEMA.PROCESSLIST WHERE id = CONNECTION_ID() );
INSERT INTO `ServiceArchive` (
  `id`, `name`, `description`, `owner_id`, `action`, `ctime`, `dbuser`, `mtime`, `revision`, `stmt`, `updid`
) VALUES (
  OLD.`id`, OLD.`name`, OLD.`description`, OLD.`owner_id`,
  'delete', OLD.`ctime`, USER(), CURRENT_TIMESTAMP, 1 + OLD.`revision`, stmt, @updid
);
END;
