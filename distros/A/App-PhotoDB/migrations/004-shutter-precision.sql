ALTER TABLE `SHUTTER_SPEED` CHANGE COLUMN `duration` `duration` DECIMAL(9,5) NULL DEFAULT NULL COMMENT 'Shutter speed in decimal notation, e.g. 0.04' ;
UPDATE `SHUTTER_SPEED` set `duration`=`shutter_speed` where `duration` = 99.99999 and `shutter_speed` REGEXP '^[0-9]+$';
