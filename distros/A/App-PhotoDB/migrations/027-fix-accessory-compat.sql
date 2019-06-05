CREATE 
    OR REPLACE ALGORITHM = UNDEFINED 
VIEW `choose_accessory_compat` AS
    SELECT 
        `ACCESSORY`.`accessory_id` AS `id`,
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `ACCESSORY`.`model`,
                ' (',
                `ACCESSORY_TYPE`.`accessory_type`,
                ')') AS `opt`,
        `ACCESSORY_COMPAT`.`cameramodel_id` AS `cameramodel_id`,
        `ACCESSORY_COMPAT`.`lensmodel_id` AS `lensmodel_id`
    FROM
        (((`ACCESSORY`
        JOIN `ACCESSORY_COMPAT` ON ((`ACCESSORY_COMPAT`.`accessory_id` = `ACCESSORY`.`accessory_id`)))
        JOIN `ACCESSORY_TYPE` ON ((`ACCESSORY`.`accessory_type_id` = `ACCESSORY_TYPE`.`accessory_type_id`)))
        LEFT JOIN `MANUFACTURER` ON ((`ACCESSORY`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`)));
