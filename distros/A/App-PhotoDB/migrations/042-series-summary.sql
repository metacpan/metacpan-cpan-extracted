CREATE 
    OR REPLACE ALGORITHM = UNDEFINED 
VIEW `summary_series` AS
    SELECT 
        `SERIES`.`series_id` AS `Series ID`,
        `SERIES`.`name` AS `Series`,
        CONCAT(COUNT(`CAMERA`.`camera_id`),
                '/',
                COUNT(`SERIES_MEMBER`.`cameramodel_id`)) AS `Cameras`,
        CONCAT(COUNT(`LENS`.`lens_id`),
                '/',
                COUNT(`SERIES_MEMBER`.`lensmodel_id`)) AS `Lenses`
    FROM
        (((`SERIES`
        LEFT JOIN `SERIES_MEMBER` ON (`SERIES`.`series_id` = `SERIES_MEMBER`.`series_id`))
        LEFT JOIN `CAMERA` ON (`CAMERA`.`cameramodel_id` = `SERIES_MEMBER`.`cameramodel_id`))
        LEFT JOIN `LENS` ON (`LENS`.`lensmodel_id` = `SERIES_MEMBER`.`lensmodel_id`))
    GROUP BY `SERIES`.`series_id`;
