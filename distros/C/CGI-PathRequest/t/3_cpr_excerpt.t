use Test::Simple tests=>3;
use strict;
use Cwd;
use lib './lib';
use CGI::PathRequest;
#use Smart::Comments '###';
$ENV{DOCUMENT_ROOT} = cwd()."/t/public_html";

ok( my $r = new CGI::PathRequest({ rel_path=> 'demo/civil.txt' }),'construct instance');

my $content =  $r->get_content;
ok( $content ,'get content');
### $content

my $excerpt = $r->get_excerpt;
ok( $excerpt ,'get excerpt' );
### $excerpt



