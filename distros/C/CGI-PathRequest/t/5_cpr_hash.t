use Test::Simple 'no_plan';
use strict;
use Cwd;
use lib './lib';
use CGI::PathRequest;
use CGI;

$ENV{DOCUMENT_ROOT} = cwd()."/t/public_html";

warn("\n");
print STDERR ('='x60, "\n") x 3;
printf STDERR "\n%s\nSTART\n%s\n",'='x60, '-'x60;




my $r = new CGI::PathRequest({ rel_path => '/house.txt' });
ok( my $hash = $r->get_datahash );
## $hash

ok( my $hashprepped = $r->get_datahash_prepped );
## $hashprepped

ok( my $content_encoded = $r->get_content_encoded );
## $content_encoded


ok(my $nav_prepped = $r->nav_prepped, 'nav_prepped');
## $nav_prepped;


## QUERY STRING
for my $rel ( qw{
rel_path=/
rel_path=/house.txt
rel_path=house.txt
rel_path=demo/../oake.jpg
rel_path=demo/./hellokitty.gif
} ) {
   $rel or next;
   $ENV{QUERY_STRING} = $rel;
   print STDERR '-'x60,"\n";
   ok($rel,"set ENV QUERY STRING to '$rel'");
   ### $ENV{QUERY_STRING}

   my $cgi = CGI->new($ENV{QUERY_STRING});
   ok($cgi,'instanced CGI');


   my $r = undef;
   $r = CGI::PathRequest->new({ cgi => $cgi });
   ok($r, 'instanced CGI::PathRequest') or die;


   my $rel_path;
   
   ### testings for doc root 
   if ( $r->is_DOCUMENT_ROOT ){
      ok( ! ($rel_path = $r->rel_path) , 'does not return rel path for DOCUMENT ROOT')
         or warn("returned $rel_path");
   }

   else {
      
      ok( $rel_path = $r->rel_path, 'rel_path() ' );
      warn("got '$rel_path'\n");
      
      ### $rel_path
      my $datahash_prepped = $r->get_datahash_prepped;
      ## $datahash_prepped
      ## done    
   } 

   ### donie
   ### ------
} 


