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
# sql/schedintvls_Config.pm
#
# SQL statements related to schedintvls

#
# SQL_SCRATCH_SID
#     SQL to get next value from scratch_sid_seq
#
set( 'SQL_SCRATCH_SID', q/
      SELECT nextval('scratch_sid_seq');
      / );

#
# SQL_SCHEDINTVLS_INSERT
#     SQL to insert a single record in the 'scratchintvls' table
#
set( 'SQL_SCHEDINTVLS_INSERT', q/
      INSERT INTO schedintvls (ssid, intvl)
      VALUES (?, ?)
      / );

#
# SQL_SCHEDINTVLS_SELECT
#     SQL to select all the schedintvls belonging to a given SID,
#     translated, all in one go, resulting in n rows, each containing
#     four columns: low_dow, low_time, high_dow, high_time
set( 'SQL_SCHEDINTVLS_SELECT', q/
      -- ORDER BY intvl sorts the intervals!
      SELECT 
          (translate_schedintvl(int_id)).low_dow, 
          (translate_schedintvl(int_id)).low_time, 
          (translate_schedintvl(int_id)).high_dow, 
          (translate_schedintvl(int_id)).high_time
      FROM (
          SELECT int_id FROM schedintvls WHERE ssid = ?
          ORDER BY intvl
      ) AS int_ids
      / );

#
# SQL_SCHEDINTVLS_DELETE
#     SQL to delete scratch intervals once they are no longer needed
set( 'SQL_SCHEDINTVLS_DELETE', q/
      DELETE FROM schedintvls WHERE ssid = ?
      / );

# -----------------------------------
# DO NOT EDIT ANYTHING BELOW THIS LINE
# -----------------------------------
use strict;
use warnings;

1;
