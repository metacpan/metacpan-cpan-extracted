SET NEW.`revision` = OLD.`revision` + 1;
SET NEW.`ctime` = OLD.`ctime`;
SET NEW.`mtime` = CURRENT_TIMESTAMP;
