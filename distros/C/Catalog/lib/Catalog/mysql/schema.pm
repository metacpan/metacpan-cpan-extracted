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
# $Header: /cvsroot/Catalog/Catalog/lib/Catalog/mysql/schema.pm,v 1.4 2000/01/28 09:15:39 loic Exp $
#
#
# Table schemas
#
package Catalog::mysql::schema;
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
		    'catalog' => "
create table catalog (
  #
  # Table management information 
  #
  rowid int $autoinc,
  created datetime not null,
  modified timestamp not null,

  #
  # Name of the catalog
  #
  name varchar(32) not null,
  #
  # Name of the table whose records are catalogued
  #
  tablename varchar(60) not null,
  #
  # Navigation scheme
  #
  navigation enum ('alpha', 'theme', 'date') default 'theme',
  #
  # State information
  #
  info set ('hideempty'),
  #
  # (alpha, date only) last update time
  #
  updated datetime,
  #
  # Order clause
  #
  corder varchar(128),
  #
  # Where clause
  #
  cwhere varchar(128),
  #
  # (alpha, date only) name of the field for sorting
  #
  fieldname varchar(60),
  #
  # (theme only) rowid of the root in catalog_category_<name>
  #
  root int not null,
  #
  # (theme only) full path name of the location to dump pages
  #
  dump varchar(255),
  #
  # (theme only) the location from which the dumped pages will be accessed
  #
  dumplocation varchar(255),

  unique catalog1 (rowid),
  unique catalog2 (name)
)
",
		    'catalog_auth' => "
create table catalog_auth (
  #
  # Table management information 
  #
  rowid int $autoinc,
  created datetime not null,
  modified timestamp not null,

  #
  # Yes if entry is usable
  #
  active enum ('yes', 'no') default 'no',
  #
  # login name of the editor
  #
  login char(32) not null,

  unique catalog_auth1 (rowid),
  unique catalog_auth2 (login)
)
",
		    'catalog_auth_properties' => "
create table catalog_auth_properties (
  #
  # Table management information 
  #
  rowid int $autoinc,
  created datetime not null,
  modified timestamp not null,

  #
  # Link to user descriptive entry (catalog_auth)
  #
  auth int not null,

  #
  # Authorization global to catalog
  #

  #
  # Allow everything
  #
  superuser char(1) not null default 'n',

  #
  # Authorization bound to a specific catalog
  #

  #
  # Name of the catalog on which this entry applies
  #
  catalogname varchar(32) not null,

  #
  # Allow everything on this catalog
  #
  catalogsuperuser char(1) not null default 'n',

  #
  # Authorization on a specific theme category
  #

  #
  # Link to the category (catalog_category_NAME) 
  #
  categorypointer int not null default 0,
  #
  # Allow sub category add/edit/remove
  #
  categorysubedit char(1) not null default 'n',
  #
  # Allow entries add/edit/remove
  #
  categoryentryedit char(1) not null default 'n',


  unique catalog_auth_categories1 (rowid),
  index catalog_auth_categories2 (auth),
  index catalog_auth_categories3 (catalogname),
  index catalog_auth_categories4 (categorypointer)
)
",
		    'catalog_entry2category' => "
create table catalog_entry2category_NAME (
  #
  # Table management information 
  #
  created datetime not null,
  modified timestamp not null,

  #
  # State information
  #
  info set ('hidden'),
  #
  # Rowid of the record from catalogued table
  #
  row int not null,
  #
  # Rowid of the category
  #
  category int not null,
  #
  # External identifier to synchronize with alien catalogs
  #
  externalid varchar(32) not null default '',

  index catalog_entry2category_NAME2 (created),
  index catalog_entry2category_NAME3 (modified),
  unique catalog_entry2category_NAME4 (row,category),
  index catalog_entry2category_NAME5 (category),
  index catalog_entry2category_NAME6 (externalid)
)
",
		    'catalog_category' => "
create table catalog_category_NAME (
  #
  # Table management information 
  #
  rowid int $autoinc,
  created datetime not null,
  modified timestamp not null,

  #
  # State information
  # root : set on root category
  # displaygrandchild : set if the category is to be shown
  #               if the template that displays the children of
  #               a category also displays grand children.
  #
  info set ('root', 'displaygrandchild'),
  #
  # Full name of the category
  #
  name varchar(255) not null,
  #
  # Total number of records in this category and bellow
  #
  count int default 0,
  #
  # External identifier to synchronize with alien catalogs
  #
  externalid varchar(32) not null default '',

  unique catalog_category_NAME1 (rowid),
  index catalog_category_NAME2 (created),
  index catalog_category_NAME3 (modified),
  index catalog_category_NAME4 (name(122)),
  index catalog_category_NAME5 (externalid)
)
",
		    'catalog_path' => "
create table catalog_path_NAME (
  #
  # Full path name of the category
  #
  pathname text not null,
  #
  # MD5 key of the path name
  #
  md5 char(32) not null,
  #
  # Full path name translated to ids
  #
  path varchar(255) not null,
  #
  # Id of the last component
  #
  id int not null,

  unique catalog_path_NAME1 (md5),
  unique catalog_path_NAME2 (path),
  unique catalog_path_NAME3 (id)
)
",
		    'catalog_alpha' => "
create table catalog_alpha_NAME (
  #
  # Table management information 
  #
  rowid int $autoinc,
  created datetime not null,
  modified timestamp not null,

  #
  # The letter
  #
  letter char(1) not null,
  #
  # Count of records of the catalogued table have
  # a field starting with this letter.
  #
  count int default 0,

  unique catalog_alpha_NAME1 (rowid)
)
",
		    'catalog_date' => "
create table catalog_date_NAME (
  #
  # Table management information 
  #
  rowid int $autoinc,

  #
  # The date interval
  #
  tag char(8) not null,
  #
  # Count of records of the catalogued table have
  # a field starting with this letter.
  #
  count int default 0,

  unique catalog_date_NAME1 (rowid),
  unique catalog_date_NAME2 (tag)
)
",
		    'catalog_category2category' => "
create table catalog_category2category_NAME (
  #
  # Table management information 
  #
  rowid int $autoinc,
  created datetime not null,
  modified timestamp not null,

  #
  # State information
  #
  info set ('hidden', 'symlink'),
  #
  # Rowid of father
  #
  up int not null,
  #
  # Rowid of child
  #
  down int not null,
  #
  # External identifier to synchronize with alien catalogs
  #
  externalid varchar(32) not null default '',

  unique catalog_category2category_NAME1 (rowid),
  index catalog_category2category_NAME2 (created),
  index catalog_category2category_NAME3 (modified),
  unique catalog_category2category_NAME4 (up,down),
  index catalog_category2category_NAME5 (down),
  index catalog_category2category_NAME6 (externalid)
)
",
	            'catalog_unload' => "
create table catalog_unload_NAME (
rowid int not null,
unique catalogunloadNAME (rowid)
)
",
	            'urldemo' => "
create table urldemo (
  #
  # Table management information 
  #
  rowid int $autoinc,
  created datetime not null,
  modified timestamp not null,

  info enum ('active', 'inactive') default 'active',
  url char(128),
  comment char(255),

  unique cdemo1 (rowid)
)
",
		    };

1;
# Local Variables: ***
# mode: perl ***
# End: ***
