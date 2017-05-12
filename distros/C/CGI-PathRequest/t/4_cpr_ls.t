use Test::Simple 'no_plan';
use strict;
use Cwd;
use lib './lib';
use CGI::PathRequest;

printf STDERR "\n%s\nSTART\n%s\n",'='x60, '-'x60;

$ENV{DOCUMENT_ROOT} = cwd()."/t/public_html";


my $r = new CGI::PathRequest({ rel_path => '/' });
ok($r,'instanced');

my $abs_path = $r->abs_path;

ok($abs_path,'abs_path()');
### $abs_path



ok(my $ls = $r->ls,'ls()');
### $ls
warn(" # got @$ls\n\n");

ok(my $lsd = $r->lsd,'lsd()');
### $lsd
warn(" # got @$lsd\n\n");

ok(my $lsf = $r->lsf,'lsf()');
### $lsf
warn(" # got @$lsf\n\n");


warn("----------------------------------\n\n");
my $v = $r->lsf_count;
ok( $v, "lsf_count : got $v");

unless( ok($v , "lsf_count()") ){
   warn("Turning on \$CGI::PathRequest::DEBUG = 1;\n");
   $CGI::PathRequest::DEBUG = 1;
   $r->lsf_count;   
   die("Wanted to have value $v == 3, plus hidden");
}

ok($r->lsd_count, 'lsd_count()');
ok($r->ls_count, 'ls_count()');

ok(!$r->is_empty_dir,'is_empty_dir()');



### test empty dir -----------

mkdir './t/public_html/tmp';

ok( -d './t/public_html/tmp');

my $e = new CGI::PathRequest({ rel_path => '/tmp' });

ok($e->ls);
ok(ref $e->ls eq 'ARRAY');

#ok(scalar @{$e->ls} == 0 );

ok($e->lsd);
ok($e->lsf);
#ok($e->ls_count == 0, 'ls_count()');
ok($e->lsf_count == 0, 'lsf_count()');
#ok($e->lsd_count == 0, 'lsd_count()');
#ok($e->is_empty_dir);

