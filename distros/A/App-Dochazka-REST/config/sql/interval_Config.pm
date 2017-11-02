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
# sql/interval_Config.pm
#
# SQL statements related to attendance intervals

# 
set( 'SQL_INTERVAL_SELECT_BY_IID', q/
      SELECT iid, eid, aid, intvl, long_desc, remark
      FROM intervals WHERE iid = ?
      / );

#
set( 'SQL_INTERVAL_SELECT_BY_EID_AND_TSRANGE', q/
      SELECT i.iid, i.eid, i.aid, a.code, i.intvl, i.long_desc, i.remark
      FROM intervals i, activities a WHERE i.eid = ? AND i.intvl <@ ? AND i.aid = a.aid
      ORDER BY i.intvl
      LIMIT ?
      / );

#
set( 'SQL_INTERVAL_SELECT_BY_EID_AND_TSRANGE_PARTIAL_INTERVALS', q/
      SELECT i.iid, i.eid, i.aid, a.code, i.intvl, i.long_desc, i.remark
      FROM intervals i, activities a WHERE i.eid = ? AND i.intvl && ? AND i.aid = a.aid
      EXCEPT
      SELECT i.iid, i.eid, i.aid, a.code, i.intvl, i.long_desc, i.remark
      FROM intervals i, activities a WHERE i.eid = ? AND i.intvl <@ ? AND i.aid = a.aid
      ORDER BY 5
      / );

#
set( 'SQL_INTERVAL_SELECT_BY_EID_AND_TSRANGE_INCLUSIVE', q/
      SELECT i.iid, i.eid, i.aid, a.code, i.intvl, i.long_desc, i.remark
      FROM intervals i, activities a WHERE i.eid = ? AND i.intvl && ? AND i.aid = a.aid
      ORDER BY i.intvl
      LIMIT ?
      / );

#
set( 'SQL_INTERVAL_SELECT_COUNT_BY_EID_AND_TSRANGE', q/
      SELECT count(*) FROM intervals WHERE eid = ? AND intvl && ? 
      LIMIT ?
      / );

#
set( 'SQL_INTERVAL_DELETE_BY_EID_AND_TSRANGE', q/
      DELETE FROM intervals WHERE eid = ? AND intvl <@ ? 
      / );

#
set( 'SQL_INTERVAL_INSERT', q/
      INSERT INTO intervals
                (eid, aid, intvl, long_desc, remark)
      VALUES    (?,   ?,   ?,     ?,         ?) 
      RETURNING  iid, eid, aid, intvl, long_desc, remark
      / );

#
set( 'SQL_INTERVAL_UPDATE', q/
      UPDATE intervals SET eid = ?, aid = ?, intvl = ?, long_desc = ?, remark = ?
      WHERE iid = ?
      RETURNING  iid, eid, aid, intvl, long_desc, remark
      / );

#
set( 'SQL_INTERVAL_DELETE', q/
      DELETE FROM intervals
      WHERE iid = ?
      RETURNING  iid, eid, aid, intvl, long_desc, remark
      / );
      

# -----------------------------------
# DO NOT EDIT ANYTHING BELOW THIS LINE
# -----------------------------------
use strict;
use warnings;

1;
