package App::NetdiscoX::Web::Plugin::JackReport;
 
our $VERSION = '0.01';
 
use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Extensible;
use DBI;

use App::Netdisco::Web::Plugin;
 
use File::ShareDir 'dist_dir';
register_template_path(
  dist_dir( 'App-NetdiscoX-Web-Plugin-JackReport' ));

register_report({
  category => 'Port',
  tag => 'jackreport',
  label => 'Jack Report',
});

get '/ajax/content/report/jackreport' => require_login sub {
my $q = param('q');
my $f = param('f');

sub connect_db {

my $driver = config->{plugin_jackreport}{driver};
my $database = config->{plugin_jackreport}{database};
my $database_host = config->{plugin_jackreport}{database_host};
my $dsn = "DBI:$driver:host=$database_host\;sid=$database";
my $userid = config->{plugin_jackreport}{username};
my $password = config->{plugin_jackreport}{password};

  my $dbh = DBI->connect($dsn, $userid, $password ) or
     die $DBI::errstr;
 
  return $dbh;

}

my $dbh = connect_db();

my $sql;
my $sth;

if($q =~ /^\s*$/)
{

$sql = "SELECT BLDG, BUILDING, ROOM, JACK, PORT, DEVICE, EMAIL, REMARKS 
                        FROM NETDISCO_VW";

$sth = $dbh->prepare($sql);

}
else
{

$sql = "SELECT BLDG, BUILDING, ROOM, JACK, PORT, DEVICE, EMAIL, REMARKS 
                        FROM NETDISCO_VW WHERE DEVICE = ? AND PORT = ?";

$sth = $dbh->prepare($sql);

$sth->bind_param(1, "$q");
$sth->bind_param(2, "$f");

}

$sth->execute() or die $DBI::errstr;

my $results = $sth->fetchall_arrayref;

$sth->finish();

template 'jackreport.tt', { results => $results },
       	    { layout  => undef };

};

register_css('jackreport');
register_javascript('jackreport');
 
=head1 NAME
 
App::NetdiscoX::Web::Plugin::JackReport - External database with information regarding patches
 
=head1 SYNOPSIS
 
 # in your ~/environments/deployment.yml file
   
 extra_web_plugins:
   - X::JackReport
  
 plugin_jackreport:
   database_host: 'database.host.tld'
   driver: 'Driver_type(Oracle,Pg)'
   database: 'dbname'
   username: 'userid'
   password: 'passwd'

 
=head1 Description
 
This is a plugin for the L<App::Netdisco> network management application.
It adds a report to the Reports menu under Port, Jack Search. This provides a full
datatable of the jack search database.
 
=head1 AUTHOR
 
Frederik Reenders <f.reenders@utwente.nl>
 
=head1 COPYRIGHT AND LICENSE
  
Copyright (C) 2014 by F. Reenders

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.
 
=cut
 
true;
