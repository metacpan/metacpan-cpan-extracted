ALTER TABLE `CAMERAMODEL` 
DROP FOREIGN KEY `fk_CAMERAMODEL_9`;
ALTER TABLE `CAMERAMODEL` 
CHANGE COLUMN `lens_id` `lensmodel_id` INT(11) NULL DEFAULT NULL COMMENT 'If fixed_mount is true, specify the lensmodel_id' ,
ADD INDEX `fk_CAMERAMODEL_9_idx` (`lensmodel_id` ASC),
DROP INDEX `fk_CAMERAMODEL_9_idx` ;
ALTER TABLE `CAMERAMODEL` 
ADD CONSTRAINT `fk_CAMERAMODEL_9`
  FOREIGN KEY (`lensmodel_id`)
  REFERENCES `LENSMODEL` (`lensmodel_id`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;


CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `report_duplicate_cameramodels` AS
    SELECT
        `CAMERAMODEL`.`cameramodel_id` AS `Camera Model ID`,
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `CAMERAMODEL`.`model`) AS `Camera`,
        `MOUNT`.`mount` AS `Mount`,
        `LENSMODEL`.`model` AS `Lens`,
        `FORMAT`.`format` AS `Format`,
        `CAMERAMODEL`.`introduced` AS `Introduced`,
        `CAMERAMODEL`.`notes` AS `Notes`
    FROM
        (((((`CAMERAMODEL`
        JOIN `MANUFACTURER` ON (`CAMERAMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`))
        LEFT JOIN `MOUNT` ON (`CAMERAMODEL`.`mount_id` = `MOUNT`.`mount_id`))
        LEFT JOIN `FORMAT` ON (`CAMERAMODEL`.`format_id` = `FORMAT`.`format_id`))
        LEFT JOIN `LENS` ON (`CAMERAMODEL`.`lensmodel_id` = `LENS`.`lens_id`))
        LEFT JOIN `LENSMODEL` ON (`LENS`.`lensmodel_id` = `LENSMODEL`.`lensmodel_id`))
    WHERE
        `CAMERAMODEL`.`model` IN (SELECT
                `CAMERAMODEL`.`model`
            FROM
                `CAMERAMODEL`
            GROUP BY `CAMERAMODEL`.`model`
            HAVING COUNT(`CAMERAMODEL`.`model`) > 1)
    ORDER BY `CAMERAMODEL`.`model`;
