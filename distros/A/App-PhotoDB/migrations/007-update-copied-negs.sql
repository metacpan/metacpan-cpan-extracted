DROP procedure IF EXISTS `update_copied_negs`;
CREATE PROCEDURE `update_copied_negs` ()
BEGIN
UPDATE NEGATIVE ORIG
        JOIN
    NEGATIVE COPY ON ORIG.negative_id = COPY.copy_of 
SET 
    COPY.description = ORIG.description,
    COPY.notes = CONCAT('Copied from negative ',
            ORIG.film_id,
            '/',
            ORIG.frame)
WHERE
    COPY.copy_of IS NOT NULL;
END;;
