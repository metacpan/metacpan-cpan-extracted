#
#   Copyright (C) 1998, 1999 Loic Dachary
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the
#   Free Software Foundation; either version 2, or (at your option) any
#   later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, 675 Mass Ave, Cambridge, MA 02139, USA. 
#
# 
# $Header: /cvsroot/Catalog/Catalog/lib/Catalog/tools/mysql/schema.pm,v 1.1 1999/05/15 14:20:50 ecila40 Exp $
#
#
# Table schemas
#
package Catalog::tools::mysql::schema;
use vars qw($resource);

#
# 3.21 reverse of 3.22 syntax :-(
#
if(exists($ENV{'MYSQL_OLD'})) {
    $autoinc = "not null auto_increment";
} else {
    $autoinc = "auto_increment not null";
}

$resource = {
		    'sqledit_requests' => "
create table sqledit_requests (
  rowid int $autoinc,

  rwhere varchar(255),
  rtable char(64),
  rlinks varchar(255),
  rorder char(64),
  rparams varchar(255),
  label char(32),

  unique sqledit_requests1 (rowid)
)
",
		    };

1;
# Local Variables: ***
# mode: perl ***
# End: ***
