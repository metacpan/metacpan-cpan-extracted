#!/usr/bin/perl
$table = '/var/local/gna/uu-gna/tables/test.dbedit';
$dir = '/home/joe';
$form_file = $dir . '/test.dbedit.html';

use lib "/var/local/gna/uu-gna/forms";

use CGI qw(:cgi-lib);
require 'gna-lib.pl';
require 'gna-rdb-edit.pl';
require 'gna-fill-form.pl';
require 'test.dbedit.pl';

# This is the list of key columns.  Entries with identical key columns are 
# assumed to be identical
@keycols = ("a", "b", "c");
# This is the list of attributes
#
# Attributes are invisibles tags which are included in the form
#

%attrib = ();

# This is the list of parameters
# Parameters control various elements of the form
# 

%params = (
   "scan_table", $table,
    "scan_page_length", 0, # length of page 0 if no paging
   "scan_marker", "(edit)",
   "form_file", $form_file,
   "append_marker", "Append record");


&gna_rdb_edit($table, "", *keycols, *scancols, *attrib, *params);
