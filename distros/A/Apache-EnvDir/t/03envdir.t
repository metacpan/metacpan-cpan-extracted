use strict;
use warnings FATAL => 'all';
use FindBin ();

use Apache::Test qw(plan ok have_lwp have_module);
use Apache::TestRequest qw(GET);
use Apache::TestUtil qw(t_cmp t_write_file);

plan tests => 8, [qw(perl Apache::EnvDir)];
my $response;

for(my $i=1; $i<5; $i++) {
  $response = GET "/perl/env.pl?env=ONETEST$i";
  ok ($response->code == 200
   && $response->content_type =~ m|text/plain|
   && $response->content =~ m/^\d$/);
}

for(my $i=1; $i<5; $i++) {
  if (open OUT, ">$FindBin::Bin/envdir/TEST$i") {
    printf OUT "%d", $i + 1;
    close(OUT);

    $response = GET "/perl/env.pl?env=ONETEST$i";
    ok ($response->code == 200
     && $response->content_type =~ m|text/plain|
     && t_cmp($response->content, $i+1));
  } else { ok 0; }
}
