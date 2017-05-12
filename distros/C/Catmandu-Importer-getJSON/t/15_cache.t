use strict;
use Test::More;
use lib 't';
use MockFurl;
use File::Temp;
use Digest::MD5 qw(md5_hex);
use Encode;

use Catmandu::Importer::getJSON;

my $dir = File::Temp::tempdir(CLEANUP=>1);
my $counter = 0;
my %args = (
    client => MockFurl::new( 
        content => sub { '{"'.encode_utf8('ä').'":'.$counter++.'}' } 
    ),
    file => \"http://example.org\nhttp://example.com\nhttp://example.org",
);

my $importer = Catmandu::Importer::getJSON->new(%args);
my $a = $importer->to_array;
note explain $a;
is_deeply $a, [{'ä'=>0},{'ä'=>1},{'ä'=>2}], 'cache off'; 

$importer = Catmandu::Importer::getJSON->new(%args, cache => 1);
note explain $Catmandu::Importer::getJSON::CACHE;
is_deeply $importer->to_array, [{'ä'=>3},{'ä'=>4},{'ä'=>3}], 'in-memory cache'; 
note explain $Catmandu::Importer::getJSON::CACHE;

$importer = Catmandu::Importer::getJSON->new(%args, cache => $dir);
is_deeply $importer->to_array, [{'ä'=>5},{'ä'=>6},{'ä'=>5}], 'file cache';

my $file = $dir.'/'.md5_hex("http://example.org").'.json';
open my $fh, "<:utf8", $file;
is <$fh>, '{"ä":5}', 'cache file';

$importer = Catmandu::Importer::getJSON->new(%args, cache => 1);
is_deeply $importer->to_array, [{'ä'=>3},{'ä'=>4},{'ä'=>3}], 'in-memory cache is global'; 

done_testing;
