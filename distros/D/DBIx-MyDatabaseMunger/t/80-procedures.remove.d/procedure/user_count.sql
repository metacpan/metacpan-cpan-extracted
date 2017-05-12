CREATE DEFINER=`example`@`localhost` PROCEDURE `user_count`(OUT number INT)
BEGIN
    SELECT COUNT(*) FROM User;
END
