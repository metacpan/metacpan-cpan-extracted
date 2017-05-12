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


# start
my $g;
ok($g = new CGI::Application::Gallery( 
	PARAMS => { 
		#rel_path_default => '/gallery',
      abs_document_root => cwd().'/t/public_html/gallery',
	},
),'instanced');

ok( $g->run,'run');

ok(  $g->cwr,'got cwr' );

my $abs = $g->cwr->abs_path;
ok($abs, "abs is '$abs'");


ok($abs eq cwd().'/t/public_html/gallery','cwd abs path is gallery');


my $files_loop = $g->_files_loop;
ok($files_loop,'got files loop');

my $dirs_loop = $g->_dirs_loop;
ok($dirs_loop,"got dirs loop");

#### $files_loop
#### $dirs_loop

ok( $g->pager->total_entries == 10,'entries_total() is 10');

my $cp = $g->pager->current_page;
ok($cp, "current page is $cp");
ok($cp == 1, 'current_page is 1');




print STDERR "\n\n\npart 2\n\n";
my $y = CGI::Application::Gallery->new( 
   PARAMS => { abs_document_root => cwd().'/t/public_html/gallery'});
ok($y,'instanced');
$CGI::Application::Gallery::DEBUG = 1;

$y->query->param(  rel_path => '/7.jpg' );

ok( $y->run, 'ran ');

ok($y->get_current_runmode eq 'view','runmode got set to view');










# if we are not interactive, next test fails because CGI_APP_RETURN_ONLY cannot stop
# the thumbnail runmode fromstreaming.. 
# see test # 1 instead
exit;

__END__
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
