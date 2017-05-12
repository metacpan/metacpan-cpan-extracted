#!perl -w
#
# admiral 
# 16/12/2001
#
# 

package CGI::Bus::lngbase::CGI_Bus_tmsql; # Language base
#use CGI::Bus::lngbase::CGI_Bus_tm;
use strict;

1;

sub lngbase {
 my @msg;
#push @msg, CGI::Bus::lngbase::CGI_Bus_tm::lngbase;
 push @msg,
 (-nap=>['Top',    'The topmost level']
 ,-nup=>['Up',     'An upper level']
 ,-nth=>['Reset',  'This application default']
 ,-bck=>['Back',   'Back to previous screen']
 ,-lgn=>['Login',  'Login to the System']
 ,-lst=>['List',   'List records, select records under query condition']
 ,-lsr=>['List',   'List records']
 ,-qry=>['Query',  'Query condition to list records by']
 ,-crt=>['New',    'New record creation to insert it to the database']
 ,-sel=>['Read',   '(Re)read data from database, select record; escape edit mode discarding changes']
 ,-prn=>['Print',  'Printable form']
 ,-edt=>['Edit',   'Edit mode switch']
 ,-frm=>['Form',   'Form reload and review, data recalculation']
 ,-upd=>['Update', 'Update record in the database, save changes']
 ,-del=>['Delete', 'Delete record from the database']
 ,-ins=>['Insert', 'Insert new record into database']
 ,-hlp=>['Help',   'Open Help screen']

 ,'op!let' =>['',       'Operation \'$_\' is not allowed']
 ,'op!acl2'=>['',       'Operation \'$_\' is not allowed by acl to']
 ,'!constr'=>['',       'Constraint violations']
 ,'fldReq' =>['',       'Field \'$_\' value required']
 ,'!rfetch'=>['',       'No data fetched from database']
 ,'rfetch' =>['',       '$_ rows fetched']
 ,'rfetchf'=>['',       'First $_ rows fetched']
 ,'Success'=>['Success','Success operation']
 ,'Failure'=>['Failure','Failure operation']

 ,'Versions'  =>['Versions',  'Versions of record']
 ,'LIST'      =>['LIST',      'Lists of records']
 ,'WHERE'     =>['WHERE',     'WHERE SQL query condition']
 ,'F-TEXT'    =>['F-TEXT',    'Full-Text search, Find text']
 ,'ORDER BY'  =>['ORDER BY',  'ORDER BY SQL query condition clause']
 ,'LIMIT ROWS'=>['LIMIT ROWS','Maximum number of rows to fetch']

 ,'Help'           =>['Help',         '']
 ,'Lists'          =>['Views',	      'Views (lists of records) defined by application']
 ,'Fields'         =>['Fields',       'Data fields defined by application']
 ,'Commands'       =>['Commands',     'Commands may be used']
 ,'Versioning'     =>['Versioning',   'Records versioning settings']
 ,'-vsd-svd'       =>['',             'State versioning disable, \'Edit\' state']
 ,'-vsd-sd'        =>['',             'State record deleted']
 ,'File Store'     =>['File Store',   'File attachments store settings']
 ,'-fsd-url'       =>['',             'File store root']
 ,'-fsd-vsurl'     =>['',             'Old versions store root']
 ,'-fsd-vsd-e'     =>['Edit state',   'Editing of files attached allowed only while record stored with \'edit\' state $_']
 ,'-fsd-vsd-ei'    =>['Templates usage','Use \'edit\' $_ -> \'Insert\' transaction to create record from template and immediately edit files attached']
 );
 @msg
}

