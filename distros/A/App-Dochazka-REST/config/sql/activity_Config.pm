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
# sql/activity_Config.pm
#
# SQL statements related to activities

#
set( 'SQL_ACTIVITY_SELECT_ALL_INCLUDING_DISABLED', q/
      SELECT aid, code, long_desc, remark, disabled
      FROM activities
      / );

#
set( 'SQL_ACTIVITY_SELECT_ALL_EXCEPT_DISABLED', q/
      SELECT aid, code, long_desc, remark, disabled
      FROM activities WHERE disabled != TRUE
      / );

# 
set( 'SQL_ACTIVITY_SELECT_BY_AID', q/
      SELECT aid, code, long_desc, remark, disabled
      FROM activities WHERE aid = ?
      / );

# 
set( 'SQL_ACTIVITY_SELECT_BY_AID_NOT_DISABLED', q/
      SELECT aid, code, long_desc, remark, disabled
      FROM activities WHERE aid = ? and disabled != TRUE
      / );

#
set( 'SQL_ACTIVITY_SELECT_BY_CODE', q/
      SELECT aid, code, long_desc, remark, disabled
      FROM activities WHERE code = upper(?)
      / );

#
set( 'SQL_ACTIVITY_SELECT_BY_CODE_NOT_DISABLED', q/
      SELECT aid, code, long_desc, remark, disabled
      FROM activities WHERE code = upper(?) and disabled != TRUE
      / );

#
set( 'SQL_ACTIVITY_INSERT', q/
      INSERT INTO activities 
                (code, long_desc, remark, disabled)
      VALUES    (upper(?), ?, ?, FALSE) 
      RETURNING  aid, code, long_desc, remark, disabled
      / );

set( 'SQL_ACTIVITY_UPDATE', q/
      UPDATE activities 
      SET code = upper(?), long_desc = ?, remark = ?, disabled = ?
      WHERE aid = ?
      RETURNING  aid, code, long_desc, remark, disabled
      / );

set( 'SQL_ACTIVITY_DELETE', q/
      DELETE FROM activities
      WHERE aid = ?
      RETURNING  aid, code, long_desc, remark, disabled
      / );
      

# -----------------------------------
# DO NOT EDIT ANYTHING BELOW THIS LINE
# -----------------------------------
use strict;
use warnings;

1;
