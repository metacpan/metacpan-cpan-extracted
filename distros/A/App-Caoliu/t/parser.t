use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use ojo;
use Mojo::Util 'slurp';
use Cwd qw(abs_path);
use File::Basename;
use File::Spec;
use App::Caoliu;
use Encode qw(encode decode);
use utf8;
use Test::More;

use_ok 'App::Caoliu::Parser';

my $rss  = 'http://t66y.com/rss.php?fid=2';
my $post = 'http://t66y.com/htm_data/15/1309/951593.html';
my $p    = App::Caoliu::Parser->new;
my $caoliu = App::Caoliu->new;
$caoliu->log->debug("hello world");

SKIP: {
    skip 'network problem or download file failed',6
      unless g('www.baidu.com')->code == 200;
    my $current_path = dirname( abs_path(__FILE__) );
    my $xml    = slurp( File::Spec->catfile( $current_path, 'sample','sample.xml' ) );
    my $html   = slurp( File::Spec->catfile( $current_path, 'sample','sample.html' ) );
    my $expect = { link => 'http://c1521.amlong.info/read.php?tid=951514', };
    my $c      = $p->parse_rss($xml);
    is( $c->[0]->{link}, $expect->{link}, 'test parse rss xml link' );
    is( $c->[0]->{category},'亞洲無碼原創區','test parse rss xml category');
    my $x = $p->parse_post($html);
    is(
        $x->{rmdown_link},
'http://www.rmdown.com/link.php?hash=133e33e0a53c9c6b8749b244bddd604afbab82e652a',
        'test rmdown_link of this post'
    );
    is( $x->{format},'MP4','test format of this post page');
    is( $x->{download_link},'http://www.yeyebt.com/link.php?ref=cHL2yDEkPi','test downolad link of post');
    is($x->{name},'DV-1194 敏感身體直哆嗦 中西里菜(中文字幕)','test av title of this post');
}

done_testing();

