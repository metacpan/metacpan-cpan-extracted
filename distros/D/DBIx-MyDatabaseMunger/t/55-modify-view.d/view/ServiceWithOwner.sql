CREATE
  ALGORITHM=UNDEFINED
  DEFINER=`example`@`localhost`
  SQL SECURITY DEFINER
VIEW `ServiceWithOwner` AS
SELECT
`s`.`name` AS `service_name`,
`s`.`description` AS `service_description`,
`o`.`name` AS `owner_name`
FROM (
    `Service` AS `s` join `User` AS `o` on(
        (
            `s`.`owner_id`= `o`.`id`
        )
    )
)
