use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use ojo;
use Cwd 'abs_path';
use File::Basename;
use Test::More;
use YAML 'Dump';

use_ok 'App::Caoliu';

my $caoliu = App::Caoliu->new(target => './downloaded');
$caoliu->proxy('127.0.0.1:8087');
$caoliu->category(['oumei','youma']);

is( ref( $caoliu->parser ), 'App::Caoliu::Parser', 'test caoliu parser' );
is(
    ref( $caoliu->downloader ),
    'App::Caoliu::Downloader',
    'test caoliu downloader object'
);

SKIP: {
    my $current_path = dirname( abs_path(__FILE__) );
    skip 'network problem or download file failed', 3
      unless g('www.baidu.com')->code == 200;
    my @downloaded = $caoliu->reap;
    print Dump \@downloaded;
    is( scalar( @downloaded )>1, 1, 'test download total count' );
}
done_testing();
