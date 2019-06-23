CREATE 
    OR REPLACE ALGORITHM = UNDEFINED 
VIEW `info_series` AS
    SELECT 
        `SERIES_MEMBER`.`series_id` AS `Series ID`,
        CONCAT(`CM`.`manufacturer`,
                ' ',
                `CAMERAMODEL`.`model`) COLLATE utf8mb4_unicode_ci AS `Model`
    FROM
        ((`SERIES_MEMBER`
        LEFT JOIN `CAMERAMODEL` ON (`SERIES_MEMBER`.`cameramodel_id` = `CAMERAMODEL`.`cameramodel_id`))
        LEFT JOIN `MANUFACTURER` `CM` ON (`CAMERAMODEL`.`manufacturer_id` = `CM`.`manufacturer_id`))
    WHERE
        `CAMERAMODEL`.`model` IS NOT NULL 
    UNION SELECT 
        `SERIES_MEMBER`.`series_id` AS `Series ID`,
        CONCAT(`LM`.`manufacturer`,
                ' ',
                `LENSMODEL`.`model`) COLLATE utf8mb4_unicode_ci AS `Model`
    FROM
        ((`SERIES_MEMBER`
        LEFT JOIN `LENSMODEL` ON (`SERIES_MEMBER`.`lensmodel_id` = `LENSMODEL`.`lensmodel_id`))
        LEFT JOIN `MANUFACTURER` `LM` ON (`LENSMODEL`.`manufacturer_id` = `LM`.`manufacturer_id`))
    WHERE
        `LENSMODEL`.`model` IS NOT NULL;
