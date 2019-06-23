CREATE TABLE `NEGATIVEFORMAT_COMPAT` (
  `format_id` INT NOT NULL COMMENT 'ID of the film format',
  `negative_size_id` INT NOT NULL COMMENT 'ID of the negative size',
  PRIMARY KEY (`format_id`, `negative_size_id`),
  INDEX `negative_size_id_idx` (`negative_size_id` ASC),
  CONSTRAINT `format_id`
    FOREIGN KEY (`format_id`)
    REFERENCES `FORMAT` (`format_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `negative_size_id`
    FOREIGN KEY (`negative_size_id`)
    REFERENCES `NEGATIVE_SIZE` (`negative_size_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
COMMENT = 'Table to record compatibility between film formats and negative sizes';

CREATE
    OR REPLACE ALGORITHM = UNDEFINED
VIEW `choose_negativeformat` AS
    SELECT
        `FORMAT`.`format_id` AS `format_id`,
        `FORMAT`.`format` AS `format`,
        `NEGATIVE_SIZE`.`negative_size_id` AS `negative_size_id`,
        `NEGATIVE_SIZE`.`negative_size` AS `negative_size`
    FROM
        ((`NEGATIVEFORMAT_COMPAT`
        JOIN `FORMAT` ON (`NEGATIVEFORMAT_COMPAT`.`format_id` = `FORMAT`.`format_id`))
        JOIN `NEGATIVE_SIZE` ON (`NEGATIVEFORMAT_COMPAT`.`negative_size_id` = `NEGATIVE_SIZE`.`negative_size_id`));
