CREATE 
    OR REPLACE ALGORITHM = UNDEFINED 
VIEW `cameralens_compat` AS
    SELECT 
        `CAMERA`.`camera_id` AS `camera_id`,
        `CAMERAMODEL`.`cameramodel_id` AS `cameramodel_id`,
        CONCAT(`CM`.`manufacturer`,
                ' ',
                `CAMERAMODEL`.`model`,
                IF(`CAMERA`.`serial`,
                    CONCAT(' (#', `CAMERA`.`serial`, ')'),
                    '')) AS `camera`,
        `LENS`.`lens_id` AS `lens_id`,
        `LENSMODEL`.`lensmodel_id` AS `lensmodel_id`,
        CONCAT(`LM`.`manufacturer`,
                ' ',
                `LENSMODEL`.`model`,
                IF(`LENS`.`serial`,
                    CONCAT(' (#', `LENS`.`serial`, ')'),
                    '')) AS `lens`,
        `MOUNT`.`mount_id` AS `mount_id`
    FROM
        ((((((`CAMERA`
        JOIN `CAMERAMODEL` ON (`CAMERA`.`cameramodel_id` = `CAMERAMODEL`.`cameramodel_id`))
        JOIN `MOUNT` ON (`CAMERAMODEL`.`mount_id` = `MOUNT`.`mount_id`))
        JOIN `LENSMODEL` ON (`MOUNT`.`mount_id` = `LENSMODEL`.`mount_id`))
        JOIN `LENS` ON (`LENSMODEL`.`lensmodel_id` = `LENS`.`lensmodel_id`))
        JOIN `MANUFACTURER` `CM` ON (`CAMERAMODEL`.`manufacturer_id` = `CM`.`manufacturer_id`))
        JOIN `MANUFACTURER` `LM` ON (`LENSMODEL`.`manufacturer_id` = `LM`.`manufacturer_id`))
    WHERE
        `CAMERA`.`own` = 1 AND `LENS`.`own` = 1;
