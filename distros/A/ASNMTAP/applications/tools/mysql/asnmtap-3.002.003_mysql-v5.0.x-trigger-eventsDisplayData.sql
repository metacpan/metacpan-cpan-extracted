# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, asnmtap-3.002.003_mysql-v5.0.x-trigger-eventsDisplayData.sql
# ---------------------------------------------------------------------------------------------------------

USE `asnmtap`;

DROP TRIGGER IF EXISTS `eventsDisplayData`;

DELIMITER $$

CREATE TRIGGER `eventsDisplayData`
BEFORE INSERT ON `eventsDisplayData`
FOR EACH ROW
BEGIN
  SET @catalogID   = 'CID';
  SET @ROWS        = 9;
  SET @posTimeslot = 0;

  IF (NEW.catalogID = @catalogID) THEN
    SELECT posTimeslot + 1
      FROM eventsChangesLogData
      WHERE catalogID = NEW.catalogID AND uKey = NEW.uKey
      INTO @posTimeslot;

    SET NEW.posTimeslot = @posTimeslot;

    IF (NEW.posTimeslot % @ROWS) THEN
      SET NEW.posTimeslot = NEW.posTimeslot % @ROWS;
    ELSE
      SET NEW.posTimeslot = @ROWS;
    END IF;

    UPDATE eventsChangesLogData SET posTimeslot = NEW.posTimeslot WHERE catalogID = NEW.catalogID AND uKey = NEW.uKey;
  END IF;
END;

$$
DELIMITER ;
