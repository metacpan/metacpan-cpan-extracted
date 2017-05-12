use strict;
use warnings;
use utf8;
use autodie;

use Apporo;

use Test::More tests => 6;

my $index_path = "/tmp/p5_apporo_index_01.tsv";
my $out_index;
open ($out_index, "> $index_path");

my $data = << "__DATA__";
Through the Ages: A Story of Civilization	1
Le Havre	2
Caylus	3
Dominion	4
El Grande	5
Tigris & Euphrates	6
Crokinole	7
Go	8
Tichu	9
Ra	10
__DATA__

print $out_index $data;

system("LC_ALL=C sort $index_path > $index_path.sort");
system("mv $index_path.sort $index_path");

close ($out_index);
{
    my $is_there_file = 0;
    my $file_path = $index_path;
    my $file_name = "sample data file";
    if( -f $file_path ) { $is_there_file = 1; }
    is($is_there_file, 1, "write $file_name to /tmp");
    my $file_size = -s $file_path;
    isnt($file_size, 0, "$file_name has data entity");
}

system("apporo_indexer -i $index_path -bt");
{
    my $is_there_file = 0;
    my $file_path = $index_path.".ary";
    my $file_name = "apporo ASCII ary index for first colmun of sample data file";
    if( -f $file_path ) { $is_there_file = 1; }
    is($is_there_file, 1, "write $file_name to /tmp");
    my $file_size = -s $file_path;
    isnt($file_size, 0, "$file_name has data entity");
}

system("apporo_indexer -i $index_path -d");
{
    my $is_there_file = 0;
    my $file_path = $index_path.".did";
    my $file_name = "apporo ASCII did index for sample data file";
    if( -f $file_path ) { $is_there_file = 1; }
    is($is_there_file, 1, "write $file_name to /tmp");
    my $file_size = -s $file_path;
    isnt($file_size, 0, "$file_name has data entity");
}
