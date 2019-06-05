ALTER TABLE `LENS` 
ADD COLUMN `lensmodel_id` INT NULL AFTER `lens_id`,
ADD INDEX `fk_LENS_5_idx` (`lensmodel_id` ASC);
ALTER TABLE `LENS` 
ADD CONSTRAINT `fk_LENS_5`
  FOREIGN KEY (`lensmodel_id`)
  REFERENCES `LENSMODEL` (`lensmodel_id`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

UPDATE `LENS` set lensmodel_id = lens_id WHERE lensmodel_id is NULL;
