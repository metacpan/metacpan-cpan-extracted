use Test::Simple 'no_plan';
use lib './lib';
use CGI::Application::Gallery;
use Cwd;
use File::Path;

#use Smart::Comments '###','####';

$ENV{CGI_APP_RETURN_ONLY} = 1;


# setup
ok(1,'setup to test');
File::Path::rmtree( cwd().'/t/public_html');
File::Path::mkpath( cwd().'/t/public_html/gallery');


mkdir cwd().'/t/public_html/gallery/subd1';
for (<t/public_html_src/gallery/*.jpg>){
	`cp "$_" ./t/public_html/gallery/`;
   `cp "$_" ./t/public_html/gallery/subd1/`;
}
$ENV{DOCUMENT_ROOT} = cwd().'/t/public_html';
$ENV{CGI_APP_RETURN_ONLY} = 1;







# if we are not interactive, next test fails because CGI_APP_RETURN_ONLY cannot stop
# the thumbnail runmode fromstreaming.. 


print STDERR "\n=================================================\nPART3 THUMB \n\n\n";

my $e = CGI::Application::Gallery->new( 
   PARAMS => { abs_document_root => cwd().'/t/public_html/gallery'});
ok($e,'instanced');
$CGI::Application::Gallery::DEBUG = 1;

# try thumbnail
$e->query->param( rm => 'thumbnail' );
$e->query->param( rel_path => '/7.jpg' );


my $abss = cwd().'/t/public_html/gallery/7.jpg';
my $abse = $e->abs_path;
ok($abse eq $abss, "abs [$abse] is $abss");

ok( $e->run, 'thumbnail rm run()');

my $rmnow = $e->get_current_runmode;
ok( $rmnow ) or die;
ok( $rmnow eq 'thumbnail',"rmnow $rmnow");



# END and cleanup
ok( File::Path::rmtree( cwd().'/t/public_html'), 'cleanup');
