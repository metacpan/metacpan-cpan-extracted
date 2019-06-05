CREATE 
    OR REPLACE ALGORITHM = UNDEFINED 
VIEW `choose_cameramodel_without_metering_data` AS
    SELECT 
        `CAMERAMODEL`.`cameramodel_id` AS `id`,
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `CAMERAMODEL`.`model`) AS `opt`
    FROM
        (`CAMERAMODEL`
        JOIN `MANUFACTURER` ON ((`CAMERAMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)))
    WHERE
        ((NOT (`CAMERAMODEL`.`cameramodel_id` IN (SELECT 
                `METERING_MODE_AVAILABLE`.`cameramodel_id`
            FROM
                `METERING_MODE_AVAILABLE`)))
            AND (`MANUFACTURER`.`manufacturer_id` <> 20))
    ORDER BY CONCAT(`MANUFACTURER`.`manufacturer`,
            ' ',
            `CAMERAMODEL`.`model`);


CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `choose_cameramodel_without_exposure_programs` AS
    SELECT
        `CAMERAMODEL`.`cameramodel_id` AS `id`,
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `CAMERAMODEL`.`model`) AS `opt`
    FROM
        (`CAMERAMODEL`
        JOIN `MANUFACTURER` ON ((`CAMERAMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)))
    WHERE
        ((NOT (`CAMERAMODEL`.`cameramodel_id` IN (SELECT
                `EXPOSURE_PROGRAM_AVAILABLE`.`cameramodel_id`
            FROM
                `EXPOSURE_PROGRAM_AVAILABLE`)))
            AND (`MANUFACTURER`.`manufacturer_id` <> 20))
    ORDER BY CONCAT(`MANUFACTURER`.`manufacturer`,
            ' ',
            `CAMERAMODEL`.`model`);


CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `choose_cameramodel_without_shutter_data` AS
    SELECT
        `CAMERAMODEL`.`cameramodel_id` AS `id`,
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `CAMERAMODEL`.`model`) AS `opt`
    FROM
        (`CAMERAMODEL`
        JOIN `MANUFACTURER` ON ((`CAMERAMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)))
    WHERE
        ((NOT (`CAMERAMODEL`.`cameramodel_id` IN (SELECT
                `SHUTTER_SPEED_AVAILABLE`.`cameramodel_id`
            FROM
                `SHUTTER_SPEED_AVAILABLE`)))
            AND (`CAMERAMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)
            AND (`MANUFACTURER`.`manufacturer_id` <> 20))
    ORDER BY CONCAT(`MANUFACTURER`.`manufacturer`,
            ' ',
            `CAMERAMODEL`.`model`);
