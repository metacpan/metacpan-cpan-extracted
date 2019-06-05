CREATE 
    OR REPLACE ALGORITHM = UNDEFINED 
VIEW `choose_cameramodel_without_metering_data` AS
    SELECT 
        `CAMERAMODEL`.`cameramodel_id` AS `id`,
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `CAMERAMODEL`.`model`) AS `opt`
    FROM
        ((`CAMERA`
        JOIN `CAMERAMODEL` ON ((`CAMERA`.`cameramodel_id` = `CAMERAMODEL`.`cameramodel_id`)))
        JOIN `MANUFACTURER` ON ((`CAMERAMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)))
    WHERE
        ((NOT (`CAMERAMODEL`.`cameramodel_id` IN (SELECT 
                `METERING_MODE_AVAILABLE`.`cameramodel_id`
            FROM
                `METERING_MODE_AVAILABLE`)))
            AND (`CAMERA`.`own` = 1)
            AND (`MANUFACTURER`.`manufacturer_id` <> 20))
    ORDER BY CONCAT(`MANUFACTURER`.`manufacturer`,
            ' ',
            `CAMERAMODEL`.`model`);

DROP VIEW `choose_camera_without_metering_data`;
