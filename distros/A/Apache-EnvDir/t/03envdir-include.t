use strict;
use warnings FATAL => 'all';
use FindBin ();
use File::Spec::Functions qw(catfile catdir);


use Apache::Test qw(plan ok have_lwp have_module);
use Apache::TestRequest qw(GET);
use Apache::TestUtil qw(t_cmp t_write_file);
my $docroot = Apache::Test::config()->{vars}->{documentroot};
my $response;

plan tests => 8, [qw(include perl Apache::EnvDir)];

for(my $i=1; $i<5; $i++) {
  t_write_file(catfile($docroot, "test$i.shtml"),
               qq|<!--#echo var="ONETEST$i"-->|);
  $response = GET "/test$i.shtml";
  ok ($response->code == 200
   && $response->content_type =~ m|text/plain|
   && $response->content =~ m/^\d$/);
}

for(my $i=1; $i<5; $i++) {
  if (open OUT, ">$FindBin::Bin/envdir/TEST$i") {
    printf OUT "%d", $i + 1;
    close(OUT);

    $response = GET "/test$i.shtml";
    ok ($response->code == 200
     && $response->content_type =~ m|text/plain|
     && t_cmp($response->content, $i+1));
  } else { ok 0; }
}
