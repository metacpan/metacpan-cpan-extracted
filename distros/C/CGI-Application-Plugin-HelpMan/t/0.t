use Test::Simple 'no_plan';
use strict;
use lib './lib';
use warnings;
use Cwd;
ok(1);
=for

use CGI::Application::HelpMan;
$ENV{CGI_APP_RETURN_ONLY} = 1;

$CGI::Application::Plugin::HelpMan::DEBUG =  1;
my $t = new CGI::Application::HelpMan;
ok($t,'instanced');
ok($t->run);

ok(1);

=cut


my $worked=0;
my $total=0;

use CGI::Application::Plugin::HelpMan ':ALL';
#CGI::Application::Plugin::HelpMan->DEBUG(1);
$CGI::Application::Plugin::HelpMan::DEBUG =  1;

my @queries = (
'DBI',
'CGI::Application',
' CGI::Application',
'CGI Application',
'CGI/Application.pm',
'File::Copy',
'perldoc',
' Carp',
'Test/Simple.pm',
'File::Path',
'Cwd',

);


mkdir './t/tmp';
my $tmpd =  Cwd::abs_path('./t/tmp');
ok($tmpd,'temp dir returns abs path');
ok( -d $tmpd, 'temp dir exists');

require Pod::Simple::Search;
my $pss = Pod::Simple::Search->new;
for (@queries){
   my $pssabs = ( $pss->find($_)    || '' );
   my $hmabs  = ( __find_abs($_) || '' );
   $total++;
   
   ok(1,"'$_'\n\tpss : $pssabs\n\thmp : $hmabs\n");
   
   $hmabs or next;

   my $html = __abs_path_doc_to_html($hmabs, $tmpd ) or next;
   $worked++ if $html;   
   ok($html);
   
   

}



ok( $worked, " [$worked/$total], were fully resolved how we need it. If this is 0, this software will not work on this system.")
   or die("None worked, 0 were found and made docs of- this won't work on your system.");



