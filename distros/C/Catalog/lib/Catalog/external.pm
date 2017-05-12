#
#   Copyright (C) 1997, 1998
#   	Free Software Foundation, Inc.
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
# $Header: /cvsroot/Catalog/Catalog/lib/Catalog/external.pm,v 1.6 1999/07/02 12:11:48 loic Exp $
#
package Catalog::external;

use strict;

use XML::DOM;
use XML::Parser;
use Unicode::String;
use Unicode::Map8;
use Catalog::tools::tools;
use MD5;

sub new {
    my($class, %args) = @_;

    my($self) = {};
    bless($self, $class);

    return $self;
}

sub load {
    my($self, $catalog, $name, $file) = @_;

    $self->{'catalog'} = $catalog;
    $self->{'name'} = $name;

    #
    # Load charset conversion map
    #
    my($map) = Unicode::Map8->new($catalog->{'encoding'});
    error("$catalog->{'encoding'} is not known to Map8") if(!defined($map));
    $self->{'map'} = $map;

    #
    # Open file for reading extracts
    #
    no strict 'refs';
    $self->{'FILE'} = $file;
    open($self->{'FILE'}, "<$file") or error("cannot open $file for reading : $!");
    #
    # Simple parser to find bounds of extracts to read
    # handle() is called by Start.
    #
    delete($self->{'start'});
    my($parser) = XML::Parser->new(Handlers => {
	'Start' => sub { $self->Start(@_); },
	'End' => sub { $self->End(@_); },
	'XMLDecl' => sub { $self->XMLDecl(@_); }
    }
				   );
    $self->{'DOM'} = XML::DOM::Parser->new();

    eval { $parser->parsefile($file); };
    my($error) = $@;
    close($self->{'FILE'});
    error($error) if($error);
}

sub unload {
    my($self, $catalog, $name, $file) = @_;
    my($catalog_row) = $catalog->cinfo()->{$name};
    error("catalog $name does not exists") if(!defined($catalog_row));

    open(FILE, ">$file") or error("cannot open $file for writing : $!");
    my($schema) = $catalog->db()->schema('catalog_schema', 'catalog_unload');
    $schema =~ s/NAME/$name/g;
    $catalog->db()->exec($schema);
    eval {
	$self->unload_head($catalog, $catalog_row);
	$self->unload_body($catalog, $catalog_row);
	$self->unload_symlinks($catalog, $catalog_row);
	$self->unload_auth($catalog, $catalog_row);
	$self->unload_extra($catalog, $catalog_row);
	$self->unload_tail($catalog, $catalog_row);
    };
    my($error) = $@;
    close(FILE);
    $catalog->db()->exec("drop table catalog_unload_$name");
    error($error) if($error);
}

sub unload_head {
    my($self, $catalog, $catalog_row) = @_;

    print FILE "<?xml version=\"1.0\" encoding=\"$catalog->{'encoding'}\" ?>\n";
    print FILE <<EOF;
<RDF xmlns:rdf="http://www.w3.org/TR/1999/REC-rdf-syntax-19990222#"
     xmlns="http://www.ecila.fr/">
EOF

    print FILE "\n";
    my($schema) = $catalog->db()->table_schema($catalog_row->{'tablename'});
    print FILE <<EOF;
 <Table>
  <![CDATA[
$schema
  ]]>
 </Table>
EOF

    print FILE "\n";
    print FILE " <Catalog>\n";
    my($key, $value);
    while(($key, $value) = each(%$catalog_row)) {
	next if($key eq 'rowid' || $key eq 'root');
	next if(!$value);
	$value = $self->escape($value);
	print FILE "  <$key>$value</$key>\n";
    }
    print FILE " </Catalog>\n";
}

sub unload_extra { }

sub unload_body {
    my($self, $catalog, $catalog_row) = @_;

    my($name) = $catalog_row->{'name'};
    my($table) = $catalog_row->{'tablename'};
    my($primary_key) = $catalog->db()->info_table($table)->{'_primary_'};
    my($category_table) = "catalog_category_$name";
    my($category2category_table) = "catalog_category2category_$name";
    my($entry2category_table) = "catalog_entry2category_$name";
    my($unload_table) = "catalog_unload_$name";

    $catalog->db()->exec("insert into catalog_unload_$name select $primary_key from $table");

    my($func) = sub {
	my($id, $name, $pathname, $path) = @_;

	print FILE "\n";

	print FILE " <Category>\n";
	my($category_row) = $catalog->db()->exec_select_one("select * from $category_table where rowid = $id");
	my($parent) = $catalog->db()->exec_select_one("select up from $category2category_table where down = $id and (info is null or not find_in_set('symlink', info))")->{'up'};
	$category_row->{'parent'} = $parent;
	$category_row->{'name'} = $pathname;
	delete($category_row->{'count'});
	$self->unload_record($category_row);
	print FILE " </Category>\n";

	$self->unload_body_entries($table, $catalog, $entry2category_table, $unload_table, $primary_key, $id);

	$catalog->gauge();

	return 1;
    };

    $self->unload_body_entries($table, $catalog, $entry2category_table, $unload_table, $primary_key, $catalog_row->{'root'});
    $catalog->walk_categories($name, $func);
}

sub unload_body_entries {
    my($self, $table, $catalog, $entry2category_table, $unload_table, $primary_key, $id) = @_;

    my($entry2category_rows) = $catalog->db()->exec_select("select row,category from $entry2category_table where category = $id");
    #
    # Stop if category is empty
    #
    return if(!defined($entry2category_rows));

    my($entry2category_row);
    foreach $entry2category_row (@$entry2category_rows) {
	print FILE " <Link>\n";
	$self->unload_record($entry2category_row);
	print FILE " </Link>\n";
    }

    #
    # Select all records that have not been seen already and that 
    # are linked to this category.
    #
    my($table_rows) = $catalog->db()->exec_select("select a.* from $table as a, $entry2category_table as b, $unload_table as c where b.category = $id and b.row = a.$primary_key and c.rowid = a.$primary_key");
    my(@primaries);
    my($table_row);
    foreach $table_row (@$table_rows) {
	print FILE " <Record table=\"$table\">\n";
	$self->unload_record($table_row);
	print FILE " </Record>\n";
	push(@primaries, $table_row->{$primary_key});
    }
    #
    # Delete from unload_table the rowids matching records already 
    # written to file.
    #
    if(@primaries) {
	$catalog->db()->exec("delete from $unload_table where rowid in ( " . join(',', @primaries) . " )");
    }
}

sub unload_symlinks {
    my($self, $catalog, $catalog_row) = @_;

    my($name) = $catalog_row->{'name'};
    my($sql) = "select up,down from catalog_category2category_$name where find_in_set('symlink', info)";
    my($rows) = $catalog->db()->exec_select($sql);
    my($row);
    foreach $row (@$rows) {
	print FILE " <Symlink>\n";
	print FILE "  <up>$row->{'up'}</up>\n";
	print FILE "  <down>$row->{'down'}</down>\n";
	print FILE " </Symlink>\n";
    }
}

sub unload_auth {
    my($self, $catalog, $catalog_row) = @_;

    my($name) = $catalog_row->{'name'};
    my($sql) = "select a.login,b.categorypointer from catalog_auth as a,catalog_auth_properties as b where a.rowid = b.auth";
    my($rows) = $catalog->db()->exec_select($sql);
    my($row);
    foreach $row (@$rows) {
	print FILE " <Auth>\n";
	print FILE "  <login>$row->{'login'}</login>\n";
	print FILE "  <category>$row->{'categorypointer'}</category>\n";
	print FILE " </Auth>\n";
    }
}

sub unload_record {
    my($self, $record) = @_;

    my($key, $value);
    while(($key, $value) = each(%$record)) {
	next if(!$value);
	$value = $self->escape($value);
	print FILE "  <$key>$value</$key>\n";
    }
}

sub unload_tail {
    my($self, $catalog, $catalog_row) = @_;

    print FILE "\n";
    print FILE " <Sync/>\n";
    print FILE "</RDF>\n";
}

#
# Handlers for extract location parser
#
sub XMLDecl {
    my($self, $expat, $version, $encoding, $standalone) = @_;

    if($encoding) {
	$self->{'encoding'} = $encoding;
    }
}

sub Start {
    my($self, $expat, $element, @attlist) = @_;

    if($expat->depth() == 1) {
	$self->extractor($expat);
    }
}

sub End {
    my($self, $expat, $element) = @_;

    if($expat->depth() == 0) {
	$self->extractor($expat);
    }
}

sub extractor {
    my($self, $expat) = @_;

    my($start) = $self->{'start'};
    my($end) = $expat->current_byte();
    if(defined($start)) {
	no strict 'refs';
	sysseek($self->{'FILE'}, $start, 0);
	my($buffer);
	sysread($self->{'FILE'}, $buffer, $end - $start);
	
	eval {
	    $self->handle($buffer);
	};
	if($@) {
	    my($error) = $@;
	    my($line) = $expat->current_line();
	    warn("$self->{'FILE'}: line $line: $error");
	}
    }
    $self->{'start'} = $end;
}

#
# Convert extract to DOM structure and call appropriate function
#
sub handle {
    my($self, $buffer) = @_;
    my($dom) = $self->{'DOM'};
    my(@encoding) = ();
    if(exists($self->{'encoding'})) {
	@encoding = ( 'ProtocolEncoding' => $self->{'encoding'} );
    }
    
    my($doc) = $dom->parse($buffer, @encoding);
    my($element) = $doc->getElementsByTagName("*");
    my($name) = $element->getNodeName();

    $self->${name}($element);

    $doc->dispose();
}

#
# Handlers for each top level tag
#

sub Table {
    my($self, $element) = @_;

    my($schema) = $self->unescape($element->getFirstChild()->getData());
    my($table) = $schema =~ /create\s+table\s+([a-z_]+)/io;
    error("Table is not a create table instruction") if(!$table);

    my($catalog) = $self->{'catalog'};
    
    $catalog->db()->exec("drop table $table") if($catalog->db()->info_table($table));
    $catalog->db()->exec($schema);
}

sub Link {
    my($self, $element) = @_;

    my($record) = $self->torecord($element);

    my($catalog) = $self->{'catalog'};
    my($name) = $self->{'name'};

    $catalog->db()->insert("catalog_entry2category_$name",
		     %$record);
}

sub Catalog {
    my($self, $element) = @_;

    my($record) = $self->torecord($element);

    my($catalog) = $self->{'catalog'};
    my($name) = $self->{'name'};

    if(defined($name)) {
	$record->{'name'} = $name;
    } else {
	$self->{'name'} = $name = $record->{'name'};
	if(!defined($name)) {
	    error("catalog has no name");
	}
    }

    $catalog->cdestroy_api($name);
    $catalog->cbuild_api(%$record);

    $self->{'tablename'} = $record->{'tablename'};
}

sub Category {
    my($self, $element) = @_;

    my($parent);
    my(%record);
    my($node);
    foreach $node ($element->getElementsByTagName("*")) {
	my($child) = $node->getFirstChild();
	next if(!defined($child));
	my($field) = $node->getNodeName();
	my($value) = $self->unescape($child->getData());
	if($field eq 'name') {
	    $value =~ s:.*/::;
	}
	if($field eq 'parent') {
	    $parent = $value;
	} else {
	    $record{$field} = $value;
	}
    }

    my($catalog) = $self->{'catalog'};
    my($name) = $self->{'name'};
    my($rowid) = $catalog->db()->insert("catalog_category_$name",
					%record);
    $catalog->db()->insert("catalog_category2category_$name",
			   'up' => $parent,
			   'down' => $rowid);

    $catalog->gauge();
}

sub Symlink {
    my($self, $element) = @_;

    my($record) = $self->torecord($element);

    my($catalog) = $self->{'catalog'};
    my($name) = $self->{'name'};
    $record->{'down'} = $self->resolv_path($record->{'down'});

    eval {
	$catalog->db()->insert("catalog_category2category_$name",
			       'info' => 'symlink',
			       %$record);
    };
}

sub Auth {
    my($self, $element) = @_;

    my($record) = $self->torecord($element);

    my($catalog) = $self->{'catalog'};
    my($name) = $self->{'name'};
    
    my($auth);
    my($row) = $catalog->db()->exec_select_one("select rowid from catalog_auth where login = '$record->{'login'}'");
    if(defined($row)) {
	$auth = $row->{'rowid'};
    } else {
	$auth = $catalog->db()->insert("catalog_auth",
				       'login' => $record->{'login'});
    }

    $catalog->db()->insert("catalog_auth_properties",
			   'auth' => $auth,
			   'catalogname' => $name,
			   'categorypointer' => $record->{'category'});
}

sub Record {
    my($self, $element) = @_;

    my($record) = $self->torecord($element);

    my($table) = $element->getAttribute("table");
    error("missing table name") if(!$table);

    my($catalog) = $self->{'catalog'};

    $catalog->db()->insert($table,
			   %$record);
}

sub Sync {
    my($self, $element) = @_;

    my($catalog) = $self->{'catalog'};
    my($name) = $self->{'name'};

    #
    # Rebuild computed data
    #
#    warn("Sync: start");
    $catalog->db()->exec("drop table catalog_path_$name");
#    warn("Sync: rebuild catalog_path_$name");
    $catalog->pathcheck($name);
#    warn("Sync: restore category counts");
    $catalog->category_count_api($name);
#    warn("Sync: done");
}

#
# If path is a char string instead of an numerical id, convert it
#
sub resolv_path {
    my($self, $path) = @_;

    if($path =~ m|^/|o) {
	my($catalog) = $self->{'catalog'};
	my($name) = $self->{'name'};
        $path .= "/" if($path !~ m|/$|o);
	my($md5) = MD5->hexhash($catalog->path2url($path));
	my($row) = $catalog->db()->exec_select_one("select id from catalog_path_$name where md5 = '$md5'");
	if(!$row) {
	    dbg("skip $path : not found in catalog_path_$name", "normal");
	    return;
	}
	$path = $row->{'id'};
    }

    return $path;
}

sub torecord {
    my($self, $element) = @_;

    my(%record);
    my($node);
    foreach $node ($element->getElementsByTagName("*")) {
	my($field) = $node->getNodeName();
	my($value) = $self->unescape($node->getFirstChild()->getData());
	$record{$field} = $value;
    }

    return \%record;
}

sub unescape {
    my($self, $string) = @_;

    #
    # Convert utf8 -> utf16
    #
    my($ustr) = Unicode::String->new();
    $ustr->utf8($string);
    my($u16) = $ustr->utf16();
    #
    # Map to 8bit charset defined by $catalog->{'encoding'}
    #
    my($map) = $self->{'map'};
    $string = $map->to8($u16);

    return Catalog::tools::cgi::myunescapeHTML($string);
}

sub escape {
    my($self, $string) = @_;
    
    return Catalog::tools::cgi::myescapeHTML($string);
}

1;
# Local Variables: ***
# mode: perl ***
# End: ***
