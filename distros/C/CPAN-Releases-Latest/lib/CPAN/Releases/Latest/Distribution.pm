package CPAN::Releases::Latest::Distribution;
$CPAN::Releases::Latest::Distribution::VERSION = '0.08';
use 5.006;
use Moo;

has 'distname'          => (is => 'ro');
has 'release'           => (is => 'ro');
has 'developer_release' => (is => 'ro');

1;
