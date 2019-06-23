ALTER TABLE `SHUTTER_SPEED_AVAILABLE` 
ADD COLUMN `bulb` INT(1) NULL DEFAULT 0 COMMENT 'Whether this is a manual \"bulb\" shutter speed that can only be accessed in B or T modes' AFTER `shutter_speed`;


