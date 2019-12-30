BEGIN { pop @INC if $INC[-1] eq '.' }
use strict;
use warnings;
use App::Prove;
use AsposeSlidesCloud::SlidesApi;
use AsposeSlidesCloud::TestUtils;

my $app = App::Prove->new;
$app->process_args(@ARGV);
exit( $app->run ? 0 : 1 );
