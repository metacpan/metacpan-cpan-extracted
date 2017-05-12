
use lib "/home/ken/modules/Apache-SSI/blib/lib";
use Apache::SSI;
use Benchmark;

my $text = '<!--#perl sub="sub {$_[0]*2-$_[1]}" args=5,7 pass_request=no-->';
$p = new Apache::SSI($text);

timethis(10000, '$::p->get_output()');
