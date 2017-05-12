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
# $Header: /cvsroot/Catalog/Catalog/lib/Catalog/implementation.pm,v 1.7 1999/07/02 13:36:53 loic Exp $
#
package Catalog::implementation;
use strict;

use vars qw(@tablelist_theme @tablelist_alpha @tablelist_date);

@tablelist_theme = qw(catalog_entry2category catalog_category catalog_category2category catalog_path);
@tablelist_alpha = qw(catalog_alpha);
@tablelist_date = qw(catalog_date);

use MD5;
use Text::Query;
use File::Path;
use Catalog::tools::tools;
use Catalog::path qw(path_simplify_component);

sub new {
    my($type) = @_;

    my($self) = {};
    bless($self, $type);
    $self->initialize();
    return $self;
}

sub initialize {
    my($self) = @_;

    $self->{'db'} = Catalog::db->new() if(!defined($self->{'db'}));
    my($db) = $self->{'db'};
    $db->resources_load('catalog_schema', 'Catalog::schema');
}

#
# Load info for all catalogs. Refreshed when catalog edited/removed/created
#
sub cinfo {
    my($self) = @_;

    if(!exists($self->{'ccatalog'})) {
	my($tables) = $self->db()->tables();
	my($catalog) = grep(/^catalog$/, @$tables);
	if(defined($catalog)) {
	    $self->{'csetup'} = 'yes';
	    my($rows) = $self->db()->exec_select("select rowid,name,tablename,navigation,info,fieldname,cwhere,corder,unix_timestamp(updated) as updated,root,dump,dumplocation from catalog");

	    if(@$rows) {
		$self->{'ccatalog'} = { map { $_->{'name'} => $_ } @$rows };
	    } else {
		$self->{'ccatalog'} = undef;
	    }
	    $self->{'ctables'} = [ grep(!/^catalog/, @$tables) ];
	}
    }

    return $self->{'ccatalog'};
}

#
# Create needed structures for a catalog to work
#
sub csetup_api {
    my($self) = @_;

    $self->db()->exec($self->db()->schema('catalog_schema', 'catalog'));
    $self->db()->exec($self->db()->schema('catalog_schema', 'catalog_auth'));
    $self->db()->exec($self->db()->schema('catalog_schema', 'catalog_auth_properties'));
    $self->cinfo_clear();
}

#
# import XML representation
#
sub cimport_api {
    my($self, $name, $file) = @_;

    my($external) = Catalog::external->new();
    $external->load($self, $name, $file);
}

#
# Export XML representation
#
sub cexport_api {
    my($self, $name, $file) = @_;

    my($external) = Catalog::external->new();
    $external->unload($self, $name, $file);
}

#
# Create demo data table
#
sub cdemo_api {
    my($self) = @_;

    $self->cerror("The urldemo table already exists") if($self->db()->info_table("urldemo"));
    $self->db()->exec($self->db()->schema('catalog_schema', 'urldemo'));
}

#
# Create a symbolic link
#
sub categorysymlink_api {
    my($self, $name, $up, $down) = @_;
    #
    # Link the created category to its parent
    #
    $self->db()->insert("catalog_category2category_$name",
			'info' => 'hidden,symlink',
			'up' => $up,
			'down' => $down);
}

#
# Destroy a catalog with sanity check
#
sub cdestroy_api {
    my($self, $name) = @_;

    my($ccatalog) = $self->cinfo();

    if(exists($ccatalog->{$name})) {
	$self->cdestroy_real($name);
    }
}

#
# Destroy a catalog
#
sub cdestroy_real {
    my($self, $name) = @_;

    my($tables) = $self->db()->tables();

    my($table);
    foreach $table (@tablelist_theme, @tablelist_alpha, @tablelist_date) {
	my($real) = "${table}_$name";
	if(grep(/^$real$/, @$tables)) {
	    $self->db()->exec("drop table $real");
	}
    }
    $self->db()->exec("delete from catalog where name = '$name'");
    $self->cinfo_clear();
}

#
# Force recalculation of the cached data for alpha catalog
#
sub calpha_count_api {
    my($self, $name) = @_;
    
    $self->db()->update("catalog", "name = '$name'",
			'updated' => 0);
}

#
# Fill the alpha catalog cache
#
sub calpha_count_1_api {
    my($self, $name) = @_;

    my($catalog) = $self->cinfo()->{$name};
    my($table) = $catalog->{'tablename'};
    my($field) = $catalog->{'fieldname'};

    my($where) = $catalog->{'cwhere'};
    if(defined($where) && $where !~ /^\s*$/) {
	$where = "and ($where)";
    } else {
	$where = '';
    }

    my($letter);
    foreach $letter ('0'..'9', 'a'..'z') {
	my($count) = $self->db()->exec_select_one("select count(*) as count from $table where $field like '$letter%' $where")->{'count'};
	$self->db()->update("catalog_alpha_$name", "letter = '$letter'",
			    'count' => $count);
    }
    $self->db()->update("catalog", "name = '$name'",
			'updated' => $self->db()->datetime(time()));
}

#
# Fill the alpha catalog cache
#
sub cdate_count_1_api {
    my($self, $name) = @_;

    my($catalog) = $self->cinfo()->{$name};
    my($table) = $catalog->{'tablename'};
    my($field) = $catalog->{'fieldname'};

    my($where) = $catalog->{'cwhere'};
    if(defined($where) && $where !~ /^\s*$/) {
	$where = "where ($where)";
    } else {
	$where = '';
    }

    $self->db()->exec("delete from catalog_date_$name");

    $self->db()->exec("insert into catalog_date_$name (tag, count) select date_format($field, '%Y') as yyyy, count(rowid) from $table $where group by yyyy order by yyyy");
    $self->db()->exec("insert into catalog_date_$name (tag, count) select date_format($field, '%Y%m') as yyyymm, count(rowid) from $table $where group by yyyymm order by yyyymm");
    $self->db()->exec("insert into catalog_date_$name (tag, count) select date_format($field, '%Y%m%d') as yyyymmdd, count(rowid) from $table $where group by yyyymmdd order by yyyymmdd");

    $self->db()->update("catalog", "name = '$name'",
		  'updated' => $self->db()->datetime(time()));
}

#
# Upgrade from Catalog-0.3 and below : create and populate catalog_path 
# if does not exist
#
sub pathcheck {
    my($self, $name) = @_;
    my($table) = "catalog_path_$name";

    if(!$self->db()->info_table($table)) {
	my($schema) = $self->db()->schema('catalog_schema', 'catalog_path');
	$schema =~ s/NAME/$name/g;
	$self->db()->exec($schema);

	my($catalog) = $self->cinfo()->{$name};
	$self->db()->insert($table,
			    'pathname' => '/',
			    'md5' => MD5->hexhash('/'),
			    'path' => ' ',
			    'id' => $catalog->{'root'});
	my($func) = sub {
	    my($id, $name, $pathname, $path) = @_;

	    $pathname = path_simplify_component("/$pathname/");
	    eval {
		$self->db()->insert($table,
				    'pathname' => $pathname,
				    'md5' => MD5->hexhash($pathname),
				    'path' => ",$path,",
				    'id' => $id
				    );
	    };
	    warn("$@") if($@);
	    $self->gauge();
	    return 1;
	};
	$self->walk_categories($name, $func);
	$self->cinfo_clear();
    }
}

#
# Normalize interval structure
#
sub cdate_normalize {
    my($self, $spec) = @_;

    return if(exists($spec->{'normalized'}));

    my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
    $mon++;

    if($year < 60) {
	$year += 2000;
    } else {
	$year += 1900;
    }

    my($now) = sprintf("$year%02d%02d", $mon, $mday);
    
    $spec->{'from_op'} = '>=';
    $spec->{'to_op'} = '<=';

    #
    # Fill from and to
    #
    if($spec->{'date'}) {
	#
	# A specific day
	#
	$spec->{'from'} = $spec->{'date'};
	$spec->{'to'} = $spec->{'date'};
    } else {
	if(!$spec->{'from'} && !$spec->{'to'}) {
	    #
	    # No date specified, default to all
	    #
	    $spec->{'from'} = "19700101";
	    $spec->{'to'} = $now;
	} elsif($spec->{'from'} && !$spec->{'to'}) {
	    #
	    # From a specified date in the paste up to now
	    #
	    $spec->{'to'} = $now;
	} elsif($spec->{'from'} && !$spec->{'to'}) {
	    #
	    # From the beginning of type up to the specified date
	    #
	    $spec->{'from'} = "19700101";
	} else {
	    #
	    # A specified interval time
	    #
	    ;
	}
    }

    #
    # Normalize date spec from 
    #
    if($spec->{'from'} =~ /^\d\d\d\d$/) {
	$spec->{'from'} .= "0101";
    } elsif($spec->{'from'} =~ /^\d\d\d\d\d\d$/) {
	$spec->{'from'} .= "01";
    }
    #
    # Normalize date spec to 
    #
    if($spec->{'to'} =~ /^\d\d\d\d$/) {
	$spec->{'to'} .= "1231";
    } elsif($spec->{'to'} =~ /^(\d\d\d\d)(\d\d)$/) {
	my($rows) = $self->db()->exec_select("select date_format(date_sub(date_add('$1-$2-01', interval 1 month), interval 1 day), '%Y%m%d') as d");
	$spec->{'to'} = $rows->[0]->{'d'};
    }

    $spec->{'normalized'}++;

#    warn("cdate_normalize " . ostring($spec));

    return $spec;
}

#
# Return an interval structure that is the intersection of two intervals
#
sub cdate_intersection {
    my($self, $i1, $i2) = @_;

    return {
	'from' => ($i1->{'from'} > $i2->{'from'} ? $i1->{'from'} : $i2->{'from'}),
	'to' => ($i1->{'to'} < $i2->{'to'} ? $i1->{'to'} : $i2->{'to'}),
    };
}

#
# Recalculate counts for each category
#
sub category_count_api {
    my($self, $name) = @_;

    my($catalog) = $self->cinfo()->{$name};
    my($where) = $catalog->{'cwhere'};
    if(defined($where) && $where !~ /^\s*$/) {
	$where = "and ($where)";
    } else {
	$where = '';
    }

    $self->db()->update("catalog_category_$name", "",
		  'count' => 0);
    $self->category_count_1($name, $where, $catalog->{'tablename'}, $catalog->{'root'});
}

#
# Recalculate counts for each category subroutine
#
sub category_count_1 {
    my($self, $name, $where, $table, $id) = @_;

    my($count) = $self->db()->exec_select_one(qq{
	select count(*)
	from $table, catalog_entry2category_$name
	where ($table.rowid = catalog_entry2category_$name.row
		and catalog_entry2category_$name.category = $id)
		$where
    })->{'count(*)'};

    dbg("found $count entries at id $id", "catalog");

    my($rows) = $self->db()->exec_select(qq{
	select b.down
	from catalog_category2category_$name as b
	where b.up = $id and (b.info is null or not find_in_set('symlink', b.info))
    });
    my($row);
    foreach $row (@$rows) {
	$count += $self->category_count_1($name, $where, $table, $row->{down});
	$self->gauge();
    }

    $self->db()->update("catalog_category_$name", "rowid = $id",
		  'count' => $count);
    
    return $count;
}

#
# Dump theme catalog in file tree
#
sub cdump_api {
    my($self, $name, $path, $layout) = @_;

    $path =~ s:/$::o;
    if(-d $path) {
	system("/bin/rm","-fr",$path);
    }
    mkdir($path, 0777) or $self->cerror("cannot mkdir $path : $!");

    my($rows) = $self->db()->exec_select("select pathname from catalog_path_$name");
    my($row);
    foreach $row (@$rows) {
	my($content) = &$layout($row->{'pathname'});
	my($dir) = "$path$row->{'pathname'}";
	mkpath($dir);
	my($file) = "${dir}index.html";
	open(FILE, ">$file") or error("cannot open $file for writing : $!");
	print FILE $content;
	close(FILE);
    }
}

#
# Select rowid's of catalogued table that match a category id
# Can be subclassed to implement filtering
#
sub select_entry_rows {
    my ($self, $name, $id) = @_;
    # was: my($rows) = $self->db()->exec_select(qq{
    #	select $table.rowid
    #	from $table, catalog_entry2category_$name
    #	where $table.rowid = catalog_entry2category_$name.row
    #	  and catalog_entry2category_$name.category = $id
    #});
    my($rows) = $self->db()->exec_select(qq{
	select row
	from   catalog_entry2category_$name
	where  category = $id
    });
    return $rows ? [ map { $_->{'row'} } @$rows ] : undef;
}

#
# HTML walk records of a theme catalog, call $func on each record
#
sub walk_api {
    my($self, $name, $func, @ids) = @_;
    
    if(!@ids) {
	my($catalog) = $self->cinfo()->{$name};
	push(@ids, $catalog->{'root'});
    }

    my($id);
    foreach $id (@ids) {
	$self->walk_1($func, $name, $id);
    }
}

#
# Walk records of a theme catalog starting at $id
#
sub walk_1 {
    my($self, $func, $name, $id) = @_;

    my ($row_ids) = $self->select_entry_rows($name, $id);
    my ($row_id);
    foreach $row_id (@$row_ids) {
	return if !&$func($row_id);
    }

    my ($cat_ids) = $self->select_linked_categories($name, $id);
    my $cat_id;
    foreach $cat_id (@$cat_ids) {
	$self->walk_1($func, $name, $cat_id);
    }
}


sub select_linked_categories {
    my ($self, $name, $id) = @_;
    # was: ($rows) = $self->db()->exec_select(qq{
    #	select a.rowid
    #	from catalog_category_$name as a, catalog_category2category_$name as b
    #	where a.rowid = b.down and b.up = $id
    #});
    my ($rows) = $self->db()->exec_select(qq{
	select down
	from catalog_category2category_$name
	where up = $id and (info is null or not find_in_set('symlink', info))
    });
    return $rows ? [ map { $_->{down} } @$rows ] : undef;
}

#
# HTML walk categories of a theme catalog, call $func on each category
#
sub walk_categories {
    my($self, $name, $func) = @_;
    
    my($catalog) = $self->cinfo()->{$name};
    my($id) = $catalog->{'root'};

    $self->walk_categories_1($func, $name, $id);
}

#
# Walk categories of a theme catalog, starting at $id
#
sub walk_categories_1 {
    my($self, $func, $name, $id, $path, $pathid) = @_;

    my($rows) = $self->db()->exec_select("select a.rowid,a.name from catalog_category_$name as a, catalog_category2category_$name as b where a.rowid = b.down and b.up = $id and (b.info is null or not find_in_set('symlink', b.info))");

    my($row);
    foreach $row (@$rows) {
	my($path_tmp) = $path ? "$path/$row->{'name'}" : $row->{'name'};
	my($pathid_tmp) = $pathid ? "$pathid,$row->{'rowid'}" : $row->{'rowid'};
	
	return if(!&$func($row->{'rowid'}, $row->{'name'}, $path_tmp, $pathid_tmp));
	$self->walk_categories_1($func, $name, $row->{'rowid'}, $path_tmp, $pathid_tmp);
    }
}

#
# HTML update the category count of the $rowid category and upper
# categories for a theme catalog.
#
sub ccount_api {
    my($self, $name, $rowid, $increment) = @_;

#    warn("update catalog_category_$name set count = count $increment where rowid = $rowid");
    $self->db()->update("catalog_category_$name", "rowid = $rowid",
		  '+= count' => $increment);

    my($rows) = $self->db()->exec_select("select a.rowid from catalog_category_$name as a, catalog_category2category_$name as b where a.rowid = b.up and b.down = $rowid and (b.info is null or not find_in_set('symlink', b.info))");
    my($row);
    foreach $row (@$rows) {
	$self->ccount_api($name, $row->{'rowid'}, $increment);
    }
}

#
# Remove an empty category
#
sub categoryremove_api {
    my($self, $name, $parent, $id, $symlink) = @_;

    my($category) = "catalog_category_$name";
    my($category2category) = "catalog_category2category_$name";
    my($entry2category) = "catalog_entry2category_$name";
    my($row) = $self->db()->exec_select_one("select * from $category where rowid = $id");

    #
    # Sanity checks
    #
    $self->cerror("no category found for id = $id") if(!defined($row));
    if(!defined($symlink)) {
	$self->cerror("category has sub categories") if($self->db()->exec_select_one("select down from $category2category where up = $id"));
	$self->cerror("category is not empty") if($row->{'count'} > 0);
	$self->cerror("entries are still linked to this category") if($self->db()->exec_select_one("select row from $entry2category where category = $id"));
    }

    #
    # Effective deletion
    #
    if(!defined($symlink)) {
	$self->db()->mdelete($category, "rowid = $id");
	$self->db()->mdelete($category2category, "down = $id");
	$self->db()->mdelete("catalog_path_$name", "id = $id");
    } else {
	$self->db()->mdelete($category2category, "down = $id and up = $parent");
    }
}

#
# The category record has been edited, update catalog structure
# accordingly.
#
sub categoryedit_api {
    my($self, $name, $child) = @_;

    my($child_length) = length($child);
    #
    # Replace the name of the category in path table
    #
    my($category) = $self->db()->exec_select_one("select name from catalog_category_$name where rowid = $child");
    my($category_name) = path_simplify_component($category->{'name'});
    my($rows) = $self->db()->exec_select("select pathname,path,id from catalog_path_$name where path like '%,$child,%'");
    my($row);
    foreach $row (@$rows) {
	#
	# Find position of component to replace by searching the $child in path. Position
	# is stored in $count.
	#
	my($i) = 0;
	my($count) = 1;
	do { $count++; $i++; } while(($i = index($row->{'path'}, ',', $i)) &&
				     substr($row->{'path'}, $i + 1, $child_length) ne $child);
	$i++;
#	warn("child = $child, found = " . substr($row->{'path'}, $i, $child_length) . "\n");
	#
	# Find exact position and length of component to replace by counting the / in pathname
	# (skip $count of them).
	#
	$i = 0;
	while($count) { $i = index($row->{'pathname'}, '/', $i); $i++; $count--; }
	my($name_length) = index($row->{'pathname'}, '/', $i) - $i;
#	warn("child = $child, found = " . substr($row->{'pathname'}, $i, $name_length) . "\n");
	#
	# Substitute old category name with new one
	#
	substr($row->{'pathname'}, $i, $name_length, $category_name);
#	warn("changed to $row->{'pathname'}");
	#
	# Change in table and update the md5 key
	#
	$self->db()->update("catalog_path_$name", "id = $row->{'id'}",
			    'pathname' => $row->{'pathname'},
			    'md5' => MD5->hexhash($row->{'pathname'}));
    }
}

#
# Create a new sub category
#
sub categoryinsert_api {
    my($self, $name, $up_id, $down_id) = @_;

    $self->db()->insert("catalog_category2category_$name",
		  'info' => 'hidden',
		  'up' => $up_id,
		  'down' => $down_id);
    #
    # Create the path entry
    #
    my($down_category) = $self->db()->exec_select_one("select rowid,name from catalog_category_$name where rowid = $down_id");
    my($up_path) = $self->db()->exec_select_one("select * from catalog_path_$name where id = $up_id");
    my($pathname) = "$up_path->{'pathname'}$down_category->{'name'}/";
    $pathname = path_simplify_component($pathname);
    my($path) = $up_path->{'path'} ? "$up_path->{'path'}$down_category->{'rowid'}," : ",$down_category->{'rowid'},";
    $self->db()->insert("catalog_path_$name",
		  'pathname' => $pathname,
		  'md5' => MD5->hexhash($pathname),
		  'path' => $path,
		  'id' => $down_category->{'rowid'}
		  );
}

#
# Remove catalog entry and all links to categories step 2
#
sub centryremove_all_api {
    my($self, $name, $primary_value) = @_;

    #
    # Remove all the links between the entry and the categories
    #
    my($rows) = $self->db()->exec_select("select category from catalog_entry2category_$name where row = $primary_value");
    if(defined($rows)) {
	my($row);
	foreach $row (@$rows) {
	    my($id) = $row->{'category'};
	    
	    $self->db()->mdelete("catalog_entry2category_$name",
			   "row = $primary_value and category = $id");
	    $self->ccount_api($name, $id, '-1');
	}
    }
    #
    # Remove the entry itself
    #
    my($ccatalog) = $self->cinfo();
    my($table) = $ccatalog->{$name}->{'tablename'};
    my($primary_key) = $self->db()->info_table($table)->{'_primary_'};
    $self->db()->mdelete($table, "$primary_key = $primary_value");
}

#
# Remove link between current category and record
#
sub centryremove_api {
    my($self, $name, $id, $row) = @_;

    $self->db()->mdelete("catalog_entry2category_$name",
			 "row = $row and category = $id");
    $self->ccount_api($name, $id, '-1');
}

#
# HTML Create a record and link to current category
#
sub centryinsert_api {
    my($self, $name, $id, $row) = @_;

    $self->db()->insert("catalog_entry2category_$name",
			'info' => 'hidden',
			'row' => $row,
			'category' => $id);
    $self->ccount_api($name, $id, '+1');
}

#
# Create a date/alpha/theme catalog with sanity checks
#
sub cbuild_api {
    my($self, %record) = @_;

    my($error) = $self->cbuild_check($record{'name'},
				     $record{'tablename'},
				     $record{'navigation'},
				     'step2',
				     $record{'fieldname'});
    
    error($error) if(defined($error));
    
    my($rowid) = $self->db()->insert("catalog",
			       %record);

    $self->cbuild_real($rowid,
		       $record{'name'},
		       $record{'tablename'},
		       $record{'navigation'},
		       $record{'fieldname'});

    $self->cinfo_clear();
}

#
# Create a date/alpha/theme catalog
#
sub cbuild_real {
    my($self, $rowid, $name, $table, $navigation, $field) = @_;
    
    eval {
	if(!$navigation || $navigation =~ /theme/) {
	    $self->cbuild_theme($name, $rowid);
	} elsif($navigation eq 'date') {
	    $self->cbuild_date($name, $rowid, $field);
	} else {
	    $self->cbuild_alpha($name, $rowid, $field);
	}
    };
    #
    # Construction of the catalog failed, rewind
    #
    if($@) {
	my($error) = $@;
	$self->db()->exec("delete from catalog where rowid = $rowid");
	error($error);
    }

    $self->cinfo_clear();
}

#
# Create an alpha catalog
#
sub cbuild_alpha {
    my($self, $name, $rowid, $field) = @_;

    #
    # Create catalog tables
    #
    my($table);
    foreach $table (@tablelist_alpha) {
	my($schema) = $self->db()->schema('catalog_schema', $table);
	$schema =~ s/NAME/$name/g;
	$self->db()->exec($schema);
    }

    my($letter);
    foreach $letter ('0'..'9', 'a'..'z') {
	$self->db()->insert("catalog_alpha_$name",
		      'letter' => $letter);
    }
}

#
# Create a date catalog
#
sub cbuild_date {
    my($self, $name, $rowid, $field) = @_;

    #
    # Create catalog tables
    #
    my($table);
    foreach $table (@tablelist_date) {
	my($schema) = $self->db()->schema('catalog_schema', $table);
	$schema =~ s/NAME/$name/g;
	$self->db()->exec($schema);
    }
}

#
# Sanity checks on catalog creation parameters
#
sub cbuild_check {
    my($self, $name, $table, $navigation, $step, $field) = @_;

    return undef if($::opt_fake);

    if($step eq 'step2') {
	my($name_quoted) = $self->db()->quote($name);
	return "you must specify the name of the catalog (name)" if(!$name);
    }
    return "you must specify a table name (tablename)" if(!$table);
    return "the table $table does not exist (tablename)" if(!grep($table eq $_, @{$self->db()->tables()}));
    
    if($navigation eq 'theme') {
	my($info) = $self->db()->info_table($table);
	if(!exists($info->{'_primary_'}) ||
	   $info->{'_primary_'} ne 'rowid' ||
	   $info->{$info->{'_primary_'}}->{'type'} ne 'int') {
	    return "the table $table does not have a unique primary numerical key named rowid";
	}

    } elsif($step eq 'step2' &&
	    ($navigation eq 'date' ||
	     $navigation eq 'alpha')) {
	my($info) = $self->db()->info_table($table);
	return "a field name must be specified for date catalogs (fieldname)" if(!$field);
	return "$field is not a field of $table (fieldname)" if(!exists($info->{$field}));
	if($navigation eq 'date') {
	    return "$field of table $table is not a field of type date or time" if($info->{$field}->{'type'} ne 'date' && $info->{$field}->{'type'} ne 'time');
	} elsif($navigation eq 'alpha') {
	    return "$field of table $table is not a field of type char" if($info->{$field}->{'type'} ne 'char');
	}
    }
    return undef;
}

#
# Create a theme catalog
#
sub cbuild_theme {
    my($self, $name, $rowid) = @_;

    #
    # Create catalog tables
    #
    my($table);
    foreach $table (@tablelist_theme) {
	my($schema) = $self->db()->schema('catalog_schema', $table);
	$schema =~ s/NAME/$name/g;
	$self->db()->exec($schema);
    }
    #
    # Create root of catalog
    #
    my($root_rowid) = $self->db()->insert("catalog_category_$name",
				    'info' => 'root',
				    'name' => '');

    $self->db()->insert("catalog_path_$name",
		  'pathname' => '/',
		  'md5' => MD5->hexhash('/'),
		  'path' => ' ',
		  'id' => $root_rowid);
    #
    # Register root in catalog table
    #
    $self->db()->update("catalog", "rowid = '$rowid'",
		  'root' => $root_rowid);
    
}

sub csearch_parse {
    my($self, $words, $querymode, $fields_searched, $select) = @_;

    my($parse_package) = (!defined($querymode) || $querymode eq 'simple') ? 'Text::Query::ParseSimple' : 'Text::Query::ParseAdvanced';

    my($query) = Text::Query->new($words,
				  -parse => $parse_package,
				  -build => 'Text::Query::BuildSQLMySQL',
				  -fields_searched => $fields_searched,
				  -select => $select);

    return $query->matchexp();
}

#
# Basic error handling mechanism
#
sub cerror {
    my($self) = shift;
    error(@_);
}

1;
# Local Variables: ***
# mode: perl ***
# End: ***
