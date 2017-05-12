BEGIN DECLARE stmt longtext;
SET stmt = ( SELECT info FROM INFORMATION_SCHEMA.PROCESSLIST WHERE id = CONNECTION_ID() );
INSERT INTO `ServiceArchive` (
  `id`, `name`, `description`, `owner_id`, `user_management`, `action`, `ctime`, `dbuser`, `mtime`, `revision`, `stmt`, `updid`
) VALUES (
  NEW.`id`, NEW.`name`, NEW.`description`, NEW.`owner_id`, NEW.`user_management`,
  'update', NEW.`ctime`, USER(), NEW.`mtime`, NEW.`revision`, stmt, @updid
);
END;
