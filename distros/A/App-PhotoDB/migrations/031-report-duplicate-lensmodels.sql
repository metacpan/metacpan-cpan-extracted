CREATE 
    OR REPLACE ALGORITHM = UNDEFINED 
VIEW `report_duplicate_lensmodels` AS
    SELECT
        `LENSMODEL`.`lensmodel_id` AS `Lens Model ID`,
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `LENSMODEL`.`model`) AS `Lens`,
        `MOUNT`.`mount` AS `Mount`,
        `LENSMODEL`.`introduced` AS `Introduced`,
        `LENSMODEL`.`notes` AS `Notes`
    FROM
        ((`LENSMODEL`
        JOIN `MANUFACTURER` ON ((`LENSMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)))
        LEFT JOIN `MOUNT` ON ((`LENSMODEL`.`mount_id` = `MOUNT`.`mount_id`)))
    WHERE
        `LENSMODEL`.`model` IN (SELECT
                `LENSMODEL`.`model`
            FROM
                `LENSMODEL`
            GROUP BY `LENSMODEL`.`model`
            HAVING (COUNT(`LENSMODEL`.`model`) > 1))
    ORDER BY `LENSMODEL`.`model`;
