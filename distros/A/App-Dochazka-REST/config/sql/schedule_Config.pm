# *************************************************************************
# Copyright (c) 2014-2015, SUSE LLC
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
#
# 3. Neither the name of SUSE LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# *************************************************************************
#
# sql/schedule_Config.pm
#
# SQL statements related to schedules

#
# SQL_SCHEDULE_INSERT
#     SQL to insert a single schedule
#
set( 'SQL_SCHEDULE_INSERT', q/
      INSERT INTO schedules (scode, schedule, remark, disabled) 
      VALUES (?, ?, ?, 'f')
      RETURNING sid, scode, schedule, remark, disabled
      / );

#
# SQL_SCHEDULE_UPDATE
#     SQL query to update scode, remark, and disabled fields of a schedule record
set( 'SQL_SCHEDULE_UPDATE', q/
      UPDATE schedules 
      SET scode = ?, remark = ?, disabled = ?
      WHERE sid = ?
      RETURNING sid, scode, schedule, remark, disabled
      / );

#
# SQL_SCHEDULE_DELETE
#     SQL query to delete a row given a SID
set( 'SQL_SCHEDULE_DELETE', q/
      DELETE FROM schedules WHERE sid = ?
      RETURNING sid, scode, schedule, remark, disabled
      / );

#
# SQL_SCHEDULE_SELECT_BY_SCODE
#     SQL query to retrieve entire row given a SID
set( 'SQL_SCHEDULE_SELECT_BY_SCODE', q/
      SELECT sid, scode, schedule, remark, disabled FROM schedules WHERE scode = ? 
      / );

#
# SQL_SCHEDULE_SELECT_BY_SID
#     SQL query to retrieve entire row given a SID
set( 'SQL_SCHEDULE_SELECT_BY_SID', q/
      SELECT sid, scode, schedule, remark, disabled FROM schedules WHERE sid = ? 
      / );

#
# SQL_SCHEDULES_SELECT_BY_SCHEDULE
#     SQL query to retrieve entire row given a schedule (JSON string)
set( 'SQL_SCHEDULES_SELECT_BY_SCHEDULE', q/
      SELECT sid, scode, schedule, remark, disabled FROM schedules WHERE schedule = ?
      / );

#
# SQL_SCHEDULES_SELECT_SCHEDULE
#     SQL query to retrieve schedule (JSON string) given a SID
set( 'SQL_SCHEDULES_SELECT_SCHEDULE', q/
      SELECT schedule FROM schedules WHERE sid = ?
      / );

#
# SQL_SCHEDULES_SELECT_ALL_INCLUDING_DISABLED
#     SQL query to retrieve all schedule records (JSON strings), including disabled ones
set( 'SQL_SCHEDULES_SELECT_ALL_INCLUDING_DISABLED', q/
      SELECT sid, scode, schedule, remark, disabled 
      FROM schedules
      ORDER BY sid
      / );

#
# SQL_SCHEDULES_SELECT_ALL_EXCEPT_DISABLED
#     SQL query to retrieve all non-disabled schedule records (JSON strings)
set( 'SQL_SCHEDULES_SELECT_ALL_EXCEPT_DISABLED', q/
      SELECT sid, scode, schedule, remark, disabled 
      FROM schedules WHERE disabled != TRUE
      ORDER BY sid
      / );

# -----------------------------------
# DO NOT EDIT ANYTHING BELOW THIS LINE
# -----------------------------------
use strict;
use warnings;

1;
