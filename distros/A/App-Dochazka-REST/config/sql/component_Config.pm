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
# sql/component_Config.pm
#
# SQL statements related to components

#
set( 'SQL_COMPONENT_SELECT_ALL', q/
      SELECT cid, path, source, acl, validations
      FROM components
      / );

#
set( 'SQL_COMPONENT_SELECT_ALL_NO_SOURCE', q/
      SELECT cid, path, acl, validations
      FROM components
      / );

# 
set( 'SQL_COMPONENT_SELECT_BY_CID', q/
      SELECT cid, path, source, acl, validations
      FROM components WHERE cid = ?
      / );

# 
set( 'SQL_COMPONENT_SELECT_BY_PATH', q/
      SELECT cid, path, source, acl, validations
      FROM components WHERE path = ?
      / );

#
set( 'SQL_COMPONENT_INSERT', q/
      INSERT INTO components 
                (path, source, acl, validations)
      VALUES    (?, ?, ?, ?) 
      RETURNING  cid, path, source, acl, validations
      / );

set( 'SQL_COMPONENT_UPDATE', q/
      UPDATE components 
      SET path = ?, source = ?, acl = ?, validations = ?
      WHERE cid = ?
      RETURNING  cid, path, source, acl, validations
      / );

set( 'SQL_COMPONENT_DELETE', q/
      DELETE FROM components
      WHERE cid = ?
      RETURNING  cid, path, source, acl, validations
      / );
      

# -----------------------------------
# DO NOT EDIT ANYTHING BELOW THIS LINE
# -----------------------------------
use strict;
use warnings;

1;
