use strict;
use warnings;
use utf8;
use autodie;

use Apporo;

use Test::More tests => 9;

my $index_path = "/tmp/p5_apporo_index_01.tsv";
{
    my $is_there_file = 0;
    my $file_path = $index_path;
    my $file_name = "sample data file";
    if( -f $file_path ) { $is_there_file = 1; }
    is($is_there_file, 1, "write $file_name to /tmp");
    my $file_size = -s $file_path;
    isnt($file_size, 0, "$file_name has data entity");
}
{
    my $is_there_file = 0;
    my $file_path = $index_path.".ary";
    my $file_name = "apporo ary index for sample data file";
    if( -f $file_path ) { $is_there_file = 1; }
    is($is_there_file, 1, "write $file_name to /tmp");
    my $file_size = -s $file_path;
    isnt($file_size, 0, "$file_name has data entity");
}
{
    my $is_there_file = 0;
    my $file_path = $index_path.".did";
    my $file_name = "apporo did index for sample data file";
    if( -f $file_path ) { $is_there_file = 1; }
    is($is_there_file, 1, "write $file_name to /tmp");
    my $file_size = -s $file_path;
    isnt($file_size, 0, "$file_name has data entity");
}

my $conf_path = "/tmp/p5_apporo_conf_02.tsv";
my $out_conf;
open ($out_conf, "> $conf_path");

my $conf = << "__CONF__";
ngram_length	2
is_pre	true
is_suf	true
is_utf8	false
dist_threshold	0.0
index_path	/tmp/p5_apporo_index_01.tsv
dist_func	edit
entry_buf_len	1024
engine	tsubomi
result_num	10
bucket_size	2000
is_surface	true
is_kana	false
is_roman	false
is_mecab	false
is_juman	false
is_kytea	false
__CONF__

print $out_conf $conf;

close ($out_conf);

{
    my $is_there_file = 0;
    my $file_path = $conf_path;
    my $file_name = "configure file(ASCII, 2-gram, insert dummy character to head and tail of query e.t.c.) of apporo search";
    if( -f $file_path ) { $is_there_file = 1; }
    is($is_there_file, 1, "write $file_name to /tmp");
    my $file_size = -s $file_path;
    isnt($file_size, 0, "$file_name has data entity");
}

my $app = Apporo->new($conf_path);

{
    my $query = "dominion";
    my @arr = @{$app->retrieve($query)};
    my @res = (
        "0.875	Dominion	4",
        "0.333333	Crokinole	7",
        "0.121951	Through the Ages: A Story of Civilization	1",
    );
    my %hash_res = ();
    for (my $i = 0; $i <= $#res; $i++) {
        $res[$i] = $res[$i];
        my @cels = split /\t/, $res[$i];
        my $key = $cels[0].$cels[1];
        $hash_res{$key} = $res[$i];
    }
    my %hash_arr = ();
    for (my $i = 0; $i <= $#arr; $i++) {
        my @cels = split /\t/, $arr[$i];
        my $key = $cels[0].$cels[1];
        $hash_arr{$key} = $arr[$i];
    }
    is_deeply(\%hash_arr, \%hash_res, "get the result from the indexes whose index points are all charactors of first column '$query' query");
}
