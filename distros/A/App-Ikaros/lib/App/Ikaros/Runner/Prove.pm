use strict;
use warnings;
use App::Prove;

my $app = App::Prove->new;
$app->process_args(@ARGV);
exit( $app->run ? 0 : 1 );
