#### Edit this line to be the Filename, without the ".pm"

package SampleConfig;

#### Perl setup -- you don't need to edit this part ####
use warnings;
use strict;
use Exporter;
our @ISA = qw(Exporter);
sub new {
   my $pkg = shift;
   my %config = ();

####################  Edit below here!!!  ########################

   # Below are sample config variables.  Not all of them are used with
   # every application.  You can add more to suit your application.

   ## Paths and URLs
   #  Where to find files
   $config{'basedir'}      = "/home/web/myApp";
   $config{'templatedir'}  = "$config{basedir}/tmpls";
   $config{'cgidir'}       = "$config{basedir}/cgi";
   $config{'htmldir'}      = "$config{basedir}/html";
   $config{'libdir'}       = "$config{basedir}/lib";
   $config{'sqldir'}       = "$config{libdir}/sql";

   #  Where to find links
   $config{'baseurl'}      = "http://www.clotho.com/myApp";
   $config{'cgiurl'}       = "$config{baseurl}/cgi";
   $config{'htmlurl'}      = "$config{baseurl}/html";


   ## Mail delivery
   #  If this is set, then the getEmailTemplate() method will send
   #  direct SMTP mail via this host instead of employing the default
   #  sendmail binary program (i.e. CAM::EmailTemplate::SMTP
   #  vs. CAM::EmailTemplate)
   #$config{'mailhost'}     = "mail.foo.com";


   ## Database configuration
   #  How to find the database
   $config{'dbname'}       = "clotho";
   $config{'dbusername'}   = "clotho";
   $config{'dbpassword'}   = "clotho";
   $config{'dbhost'}       = "localhost";

   #  optionally, specify the string manually.  This is checked before
   #  'dbname' and 'dbhost'
   #$config{'dbistr'}       = "DBI:mysql:database=clotho";


   ## CAM::Session setup
   #  What to call our session cookie
   $config{'cookiename'}   = "clotho";

   #  How long until the session expires? (server side session, not
   #  cookie duration!)
   $config{'sessiontime'}  = 2*60*60; # seconds

   #  What database table stores the session data?
   $config{'sessiontable'} = "session"; 


####################  Edit above here!!!  ########################

   return bless(\%config,$pkg);
}
#### Leave this here -- .pm files must end with a "1;" ####
1;
