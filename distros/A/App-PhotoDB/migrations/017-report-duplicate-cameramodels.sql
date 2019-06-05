CREATE 
    OR REPLACE ALGORITHM = UNDEFINED 
VIEW `report_duplicate_cameramodels` AS
    SELECT 
        `CAMERAMODEL`.`cameramodel_id` AS `Camera Model ID`,
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `CAMERAMODEL`.`model`) AS `Camera`,
        `MOUNT`.`mount` AS `Mount`,
        `LENS`.`model` AS `Lens`,
        `FORMAT`.`format` AS `Format`,
        `CAMERAMODEL`.`introduced` AS `Introduced`,
        `CAMERAMODEL`.`notes` AS `Notes`
    FROM
        ((((`CAMERAMODEL`
        JOIN `MANUFACTURER` ON ((`CAMERAMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)))
        LEFT JOIN `MOUNT` ON ((`CAMERAMODEL`.`mount_id` = `MOUNT`.`mount_id`)))
        LEFT JOIN `FORMAT` ON ((`CAMERAMODEL`.`format_id` = `FORMAT`.`format_id`)))
        LEFT JOIN `LENS` ON ((`CAMERAMODEL`.`lens_id` = `LENS`.`lens_id`)))
    WHERE
        `CAMERAMODEL`.`model` IN (SELECT 
                `CAMERAMODEL`.`model`
            FROM
                `CAMERAMODEL`
            GROUP BY `CAMERAMODEL`.`model`
            HAVING (COUNT(`CAMERAMODEL`.`model`) > 1))
    ORDER BY `CAMERAMODEL`.`model`;
