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
# $Header: /cvsroot/Catalog/Catalog/lib/Catalog/dmoz/mysql/schema.pm,v 1.2 2000/01/27 18:08:37 loic Exp $
#
#
# Table schemas
#
package Catalog::dmoz::mysql::schema;
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
                   'dmozrecords' => "
create table dmozrecords (
  #
  # Table management information 
  #
  rowid int auto_increment not null,
  created datetime not null,
  modified timestamp not null,

  info enum ('active', 'inactive') default 'active',
  url char(255),
  title char(255),
  description text,
  priority tinyint,

  unique dmozrecord1 (rowid)
)",
		    'catalog_related' => "
create table catalog_related_NAME (
  #
  # Rowid of father
  #
  up int not null,
  #
  # Rowid of child
  #
  down int not null,

  index catalog_related_NAME1 (up),
  index catalog_related_NAME2 (down)
)
",
		    'catalog_newsgroup' => "
create table catalog_newsgroup_NAME (
  #
  # Table management information 
  #
  rowid int auto_increment not null,
  created datetime not null,
  modified timestamp not null,

  #
  # Rowid of father
  #
  category int not null,
  #
  # Rowid of child
  #
  url varchar(255) not null,

  unique catalog_newsgroup_NAME1 (rowid),
  index catalog_newsgroup_NAME2 (category),
  index catalog_newsgroup_NAME3 (url)
)
",
		    };

1;
# Local Variables: ***
# mode: perl ***
# End: ***
