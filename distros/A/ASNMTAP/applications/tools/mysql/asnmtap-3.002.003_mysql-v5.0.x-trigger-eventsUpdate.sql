# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, asnmtap-3.002.003_mysql-v5.0.x-trigger-eventsUpdate.sql
# ---------------------------------------------------------------------------------------------------------

USE `asnmtap`;

DROP TRIGGER IF EXISTS `eventsUpdate`;

DELIMITER $$

CREATE TRIGGER `eventsUpdate`
AFTER UPDATE ON `events`
FOR EACH ROW
BEGIN
  SET @catalogID = 'CID';

  IF (NEW.catalogID = @catalogID) THEN
    SET @endDateTime    = DATE_ADD(NEW.endDate, INTERVAL TIME_TO_SEC(NEW.endTime) SECOND);
    SET @numberTimeslot = (CEIL((UNIX_TIMESTAMP(@endDateTime) - NEW.timeslot) / NEW.step)) + 1;

    IF (UNIX_TIMESTAMP(NOW()) < NEW.timeslot + (NEW.step * @numberTimeslot)) THEN
      UPDATE `eventsDisplayData` SET `status` = NEW.status, startDate = NEW.startDate, startTime = NEW.startTime, endDate = NEW.endDate, endTime = NEW.endTime, duration = NEW.duration, statusMessage = NEW.statusMessage, perfdata = NEW.perfdata WHERE catalogID = NEW.catalogID AND uKey = NEW.uKey AND timeslot = NEW.timeslot;
    END IF;
  END IF;
END;

$$
DELIMITER ;