CREATE 
    OR REPLACE ALGORITHM = UNDEFINED 
VIEW `choose_lensmodel` AS
    SELECT 
        `LENSMODEL`.`lensmodel_id` AS `id`,
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `LENSMODEL`.`model`) AS `opt`,
        `LENSMODEL`.`mount_id` AS `mount_id`,
        `MANUFACTURER`.`manufacturer_id` AS `manufacturer_id`
    FROM
        (`LENSMODEL`
        JOIN `MANUFACTURER` ON ((`LENSMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)))
    ORDER BY (CONCAT(`MANUFACTURER`.`manufacturer`,
            ' ',
            `LENSMODEL`.`model`) COLLATE utf8mb4_general_ci);
