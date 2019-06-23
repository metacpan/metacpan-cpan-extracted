CREATE 
    OR REPLACE ALGORITHM = UNDEFINED 
VIEW `report_duplicate_cameras` AS
    SELECT 
        COUNT(`CAMERA`.`camera_id`) AS `Qty`,
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `CAMERAMODEL`.`model`) AS `Camera model`,
        GROUP_CONCAT(DISTINCT `CAMERA`.`camera_id`
            SEPARATOR ', ') AS `Camera IDs`,
        GROUP_CONCAT(DISTINCT `CAMERA`.`serial`
            SEPARATOR ', ') AS `Serial numbers`
    FROM
        ((`CAMERA`
        JOIN `CAMERAMODEL` ON (`CAMERA`.`cameramodel_id` = `CAMERAMODEL`.`cameramodel_id`))
        JOIN `MANUFACTURER` ON (`CAMERAMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`))
    WHERE
        `CAMERA`.`own` = 1
    GROUP BY `CAMERA`.`cameramodel_id`
    HAVING COUNT(`CAMERA`.`camera_id`) > 1;

CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `report_duplicate_lenses` AS
    SELECT
        COUNT(`LENS`.`lens_id`) AS `Qty`,
        CONCAT(`MANUFACTURER`.`manufacturer`,
                ' ',
                `LENSMODEL`.`model`) AS `Lens model`,
        GROUP_CONCAT(DISTINCT `LENS`.`lens_id`
            SEPARATOR ', ') AS `Lens IDs`,
        GROUP_CONCAT(DISTINCT `LENS`.`serial`
            SEPARATOR ', ') AS `Serial numbers`
    FROM
        ((`LENS`
        JOIN `LENSMODEL` ON (`LENS`.`lensmodel_id` = `LENSMODEL`.`lensmodel_id`))
        JOIN `MANUFACTURER` ON (`LENSMODEL`.`manufacturer_id` = `MANUFACTURER`.`manufacturer_id`))
    WHERE
        `LENS`.`own` = 1
    GROUP BY `LENS`.`lensmodel_id`
    HAVING COUNT(`LENS`.`lens_id`) > 1;
