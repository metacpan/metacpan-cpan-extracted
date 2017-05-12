CREATE
  ALGORITHM=UNDEFINED
  DEFINER=`example`@`localhost`
  SQL SECURITY DEFINER
VIEW `ServiceWithOwner` AS
SELECT
`s`.`name` AS `service_name`,
`o`.`name` AS `owner_name`,
`o`.`email` AS `owner_email`
FROM (
    `Service` AS `s` join `User` AS `o` on(
        (
            `s`.`owner_id`= `o`.`id`
        )
    )
)
