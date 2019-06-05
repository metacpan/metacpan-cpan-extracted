CREATE 
    OR REPLACE ALGORITHM = UNDEFINED 
VIEW `choose_cameramodel` AS
    SELECT
        `CAMERAMODEL`.`cameramodel_id` AS `id`,
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `CAMERAMODEL`.`model`) AS `opt`,
        `CAMERAMODEL`.`mount_id` AS `mount_id`,
        `MANUFACTURER`.`manufacturer_id` AS `manufacturer_id`
    FROM
        (`CAMERAMODEL`
        JOIN `MANUFACTURER` ON ((`CAMERAMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)))
    ORDER BY (CONCAT(`MANUFACTURER`.`manufacturer`,
            ' ',
            `CAMERAMODEL`.`model`) COLLATE utf8mb4_general_ci);
