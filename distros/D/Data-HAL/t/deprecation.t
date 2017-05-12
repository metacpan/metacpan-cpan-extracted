use strictures;
use Data::HAL qw();
use File::Slurp qw(read_file);
use Log::Any::Adapter qw();
use Log::Any::Adapter::FileHandle qw();
use Test::More import => [qw(done_testing is)];

my $log;
open my $fh, '>', \$log;
Log::Any::Adapter->set('FileHandle', fh => $fh);
Data::HAL->from_json(scalar read_file 't/example3.json');
is $log, qq{[warning] The link (relation: "widgets", href: "/widgets") }
  . "is deprecated, see <http://example.com/blog/2013/09/no-more-widgets>\n";
done_testing;
