SET NEW.`revision` = (
  SELECT IFNULL( MAX(`revision`) + 1, 0 )
  FROM `ServiceArchive`
  WHERE `id` = NEW.`id`
);
SET NEW.`ctime` = CURRENT_TIMESTAMP;
SET NEW.`mtime` = CURRENT_TIMESTAMP;
