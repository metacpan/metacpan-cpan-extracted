CREATE DEFINER=`example`@`localhost` PROCEDURE `create_user`(IN name VARCHAR(64), IN email VARCHAR(64), OUT id INT UNSIGNED)
BEGIN
    INSERT INTO User (name,email) VALUES (name,email);
    SELECT LAST_INSERT_ID() INTO id;
END
