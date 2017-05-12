# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, asnmtap-3.002.003_mysql-v5.0.x-trigger-events.sql
# ---------------------------------------------------------------------------------------------------------

USE `asnmtap`;

DROP TRIGGER IF EXISTS `events`;

DELIMITER $$

CREATE TRIGGER `events`
AFTER INSERT ON `events`
FOR EACH ROW
BEGIN
  SET @catalogID = 'CID';

  IF (NEW.catalogID = @catalogID) THEN
    SET @endDateTime    = DATE_ADD(NEW.endDate, INTERVAL TIME_TO_SEC(NEW.endTime) SECOND);
    SET @numberTimeslot = (CEIL((UNIX_TIMESTAMP(@endDateTime) - NEW.timeslot) / NEW.step)) + 1;

    IF (UNIX_TIMESTAMP(NOW()) < NEW.timeslot + (NEW.step * @numberTimeslot)) THEN
      REPLACE INTO `eventsDisplayData` (catalogID, uKey, replicationStatus, test, title, `status`, startDate, startTime, endDate, endTime, duration, statusMessage, perfdata, step, timeslot, instability, persistent, downtime, filename) SELECT catalogID, uKey, replicationStatus, test, title, `status`, startDate, startTime, endDate, endTime, duration, statusMessage, perfdata, step, timeslot, instability, persistent, downtime, filename FROM `events` WHERE catalogID = NEW.catalogID AND id = NEW.id;
    END IF;
  END IF;
END;

$$
DELIMITER ;