ALTER TABLE `CAMERA` 
ADD COLUMN `cameramodel_id` INT NULL COMMENT 'ID which specifies the model of camera' AFTER `camera_id`,
ADD INDEX `fk_CAMERA_6_idx` (`cameramodel_id` ASC);
ALTER TABLE `CAMERA` 
ADD CONSTRAINT `fk_CAMERA_6`
  FOREIGN KEY (`cameramodel_id`)
  REFERENCES `CAMERAMODEL` (`cameramodel_id`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

UPDATE `CAMERA` set cameramodel_id = camera_id WHERE cameramodel_id is NULL;
