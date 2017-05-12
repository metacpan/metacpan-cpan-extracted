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
# $Header: /cvsroot/Catalog/Catalog/lib/Catalog/dmoz.pm,v 1.10 2000/01/27 18:15:14 loic Exp $
#
package Catalog::dmoz;

use strict;
use vars qw(@ISA @tablelist_theme %default_templates $head);

use Catalog;
use Catalog::tools::tools;

@ISA = qw(Catalog);

@tablelist_theme = qw(catalog_related catalog_newsgroup);

$head = "
<body bgcolor=#ffffff>
";

#
# Built in templates
#
%default_templates
    = (
       'cimport.html' => template_parse('inline cimport', "$head
<title>Load a DMOZ catalog</title>

<center><h1>Load a DMOZ catalog</h1></center>

<center><h3><font color=red>_COMMENT_</font></h3></center>

Follow the instructions below to build your own DMOZ catalog. We do
not use the XML loader for two reasons : the dmoz data is not really
XML and needs checking and directly loading into the database using
the <i>load data infile</i> is much faster.

<p>
<ul>
<li> Load files content.rdf.gz and structure.rdf.gz from <a href=http://dmoz.org/rdf.html>http://dmoz.org/rdf.html</a>
and make sure they are in the same directory (let's say ~/dmoz).
<li> cd ~/dmoz
<li> convert_dmoz -exclude '^/Adult' -what content content.rdf.gz
<li> It prints a dot from time to time to show that it does not hang.
<li> It creates the following files:
     <ul>
     <li> category.txt (table catalog_category_dmoz)
     <li> entry2category.txt (table catalog_entry2category_dmoz)
     <li> category2category.txt (table catalog_category2category_dmoz)
     <li> dmozrecords.txt (table dmozrecords)
     </ul>
<li> Load the files into the database using the following command
<pre>
convert_dmoz -load all ~/dmoz
</pre>
<li> Click on <b>browse</b> link in the Control Panel and check that
     the catalog displays well. <b>Warning</b> the first time you click
     on <b>browse</b> Catalog will rebuild some internal tables and it
     will take some time to display. While working Catalog sends white
     space characters to keep the connection busy and prevent timeouts.
     These characters also tells you that Catalog is working and not hanging.
     One character is printed for each category. If you have 200 000 categories
     you should expect to download 200KB.
<li> Click on the <b>count</b> link in the Control Panel to calculate
     how many entries each category contains. It taks about the same time
     to complete.
     One character is printed for each category. If you have 200 000 categories
     you should expect to download 200KB.
<li> Check the FAQ in the documentation if you have problems and search 
     the <a href=http://www.egroups.com/group/sengacatalog/info.html>Catalog mailing list</a>
     for discussion on similar problems.
</ul>
</form>
"),
);

sub initialize {
    my($self) = @_;

    $self->SUPER::initialize();

    my($templates) = $self->{'templates'};
    %$templates = ( %$templates, %default_templates );

    my($db) = $self->{'db'};
    $db->resources_load('dmoz_schema', 'Catalog::dmoz::schema');
}

sub cbuild_theme {
    my($self, $name, $rowid) = @_;

    my($ret) = $self->SUPER::cbuild_theme($name, $rowid);

    #
    # Create catalog tables
    #
    my($table);
    foreach $table (@tablelist_theme) {
	my($schema) = $self->db()->schema('dmoz_schema', $table);
	$schema =~ s/NAME/$name/g;
	$self->db()->exec($schema);
    }

    return $ret;
}

sub cdestroy_real {
    my($self, $name) = @_;

    my($ret) = $self->SUPER::cdestroy_real($name);

    my($tables) = $self->db()->tables();

    my($table);
    foreach $table (@tablelist_theme) {
	my($real) = "${table}_$name";
	if(grep(/^$real$/, @$tables)) {
	    $self->db()->exec("drop table $real");
	}
    }
    
    return $ret;
}

#
# Create needed structures for a catalog to work
#
sub csetup_api {
    my($self) = @_;

    $self->SUPER::csetup_api();

    $self->db()->exec($self->db()->schema('dmoz_schema', 'dmozrecords'));
    $self->cbuild_api('name' => 'dmoz',
		      'tablename' => 'dmozrecords',
		      'navigation' => 'theme');

    $self->cinfo_clear();
}

#
# Implement specific actions when loading/unloading
#
package Catalog::dmoz::external;

use strict;
use vars qw(@ISA);

@ISA = qw(Catalog::external);

sub Related {
    my($self, $element) = @_;

    my($record) = $self->torecord($element);
    
    my($catalog) = $self->{'catalog'};
    my($name) = $self->{'name'};

    $catalog->db()->insert("catalog_related_$name",
			   %$record);
}

sub Newsgroup {
    my($self, $element) = @_;

    my($record) = $self->torecord($element);
    
    my($catalog) = $self->{'catalog'};
    my($name) = $self->{'name'};

    $catalog->db()->insert("catalog_newsgroup_$name",
			   %$record);
}

1;
# Local Variables: ***
# mode: perl ***
# End: ***
