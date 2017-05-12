use strict;
my %CFG;

=head1 NAME

Template development config file for CGI::Application::Structured apps.

* Modify dsn, user and password for your database.
* run script/create_dbic_schema.pl from your project root to generate 
  DBIC schema.  (Rerun after every change to database).

=cut 

$CFG{db_schema} = '<tmpl_var main_module>::DB';
$CFG{db_dsn} = "dbi:mysql:mydb_dev";
$CFG{db_user} = "root";
$CFG{db_pw} = "root";
$CFG{tt2_dir} = "templates";
return \%CFG;
