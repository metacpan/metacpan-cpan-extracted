#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Digest::MD5;
use IO::File;
use IO::Handle;
use IO::Pipe;
use POSIX qw(strftime);
use File::Path qw(remove_tree);
use Path::Tiny;
use Test::LWP::UserAgent;
use utf8;

#use Data::Dumper;
#use Log::Log4perl;
#use Log::Any::Adapter;
#Log::Log4perl::init('log4perl.conf');
#Log::Any::Adapter->set('Log4perl');

my $pkg;
BEGIN {
    $pkg = 'Catmandu::BagIt';
    use_ok $pkg;
}
require_ok $pkg;

note("in-memory");

note("basic metadata");
{
    my $bagit = Catmandu::BagIt->new;
    ok $bagit , 'new';

    ok !$bagit->path , 'path is null';
    is $bagit->version , '0.97', 'version';
    is $bagit->encoding , 'UTF-8' , 'encoding';
    is $bagit->size , '0.000 KB' , 'size';
    is $bagit->payload_oxum , '0.0' , 'payload_oxum';
    ok $bagit->dirty , 'bag is dirty';
    is ref($bagit->user_agent) , 'LWP::UserAgent' , 'got a user_agent';
}

note("info");
{
    my $bagit = Catmandu::BagIt->new;
    ok $bagit , 'new';

    ok $bagit->add_info('My-First-Tag','one') , 'add_info';
    ok $bagit->add_info('My-First-Tag','two') , 'add_info';
    ok $bagit->add_info('My-Second-Tag','three') , 'add_info';

    is_deeply [sort $bagit->list_info_tags] , [qw(Bag-Size Bagging-Date My-First-Tag My-Second-Tag Payload-Oxum)] , 'list_info_tags';

    my $info = $bagit->get_info('My-First-Tag',',');
    is $info , 'one,two' , 'get_into scalar';

    my @info = $bagit->get_info('My-First-Tag');
    is_deeply [@info] , [qw(one two)] , 'get_info array';

    ok $bagit->remove_info('My-First-Tag') , 'remove_info';

    my $x = $bagit->get_info('My-First-Tag');
    ok !$x , 'get_info is null';

    my @x = $bagit->get_info('My-First-Tag');
    is_deeply [@x] , [] , 'get_info is empty';

    is_deeply [sort $bagit->list_info_tags] , [qw(Bag-Size Bagging-Date My-Second-Tag Payload-Oxum)] , 'list_info_tags';

    ok $bagit->is_dirty , 'the bag is now dirty';
}

note("tag-sums");
{
    my $bagit = Catmandu::BagIt->new;
    ok $bagit , 'new';

    is_deeply [sort $bagit->list_tagsum] , [qw(bag-info.txt bagit.txt manifest-md5.txt)] , 'list_tagsum';

    my $bagit_txt =<<EOF;
BagIt-Version: 0.97
Tag-File-Character-Encoding: UTF-8
EOF

    dies_ok { $bagit->get_tagsum() } 'get_tagsum without parameters dies';

    is $bagit->get_tagsum('bagit.txt') , Digest::MD5::md5_hex($bagit_txt) , 'get_tagsum(bagit.txt)';

    my $today = strftime "%Y-%m-%d", gmtime;
    my $bag_info_txt =<<EOF;
Bagging-Date: $today
Bag-Size: 0.000 KB
Payload-Oxum: 0.0
EOF

    is $bagit->get_tagsum('bag-info.txt') , Digest::MD5::md5_hex($bag_info_txt) , 'get_tagsum(bag-info.txt)';

    my $manifest_txt = "";
    is $bagit->get_tagsum('manifest-md5.txt') , Digest::MD5::md5_hex($manifest_txt) , 'get_tagsum(manifest-md5.txt)';
}

note("checksums");
{
    my $bagit = Catmandu::BagIt->new;
    ok $bagit , 'new';

    is_deeply [ $bagit->list_checksum ] , [] , 'list_checksum';
}

note("files");
{
    my $bagit = Catmandu::BagIt->new;
    ok $bagit , 'new';

    is_deeply [ $bagit->list_files ] , [] , 'list_files';

    ok   $bagit->add_file("test1.txt","abcdefghijklmnopqrstuvwxyz") , 'add_file';
    ok ! $bagit->add_file("test1.txt","abcdefghijklmnopqrstuvwxyz") , 'add_file overwrite failed';
    ok ! $bagit->add_file("../../../etc/passwd","boo") , 'add_file illegal path';
    ok ! $bagit->add_file("passwd | dfs ","boo") , 'add_file illegal path';
    ok   $bagit->add_file("test1.txt","abcdefghijklmnopqrstuvwxyz", overwrite => 1) , 'add_file overwrite success';

    ok   $bagit->is_dirty , 'bag is dirty';

    my @files = $bagit->list_files;

    ok @files == 1 , 'count 1 file';

    is $files[0]->filename   , 'test1.txt' , 'file->filename';
    is path($files[0]->path)->slurp_utf8 , 'abcdefghijklmnopqrstuvwxyz' , 'file->data';
    is ref($files[0]->open) , 'IO::File', 'file->fh blessed';

    ok ! $bagit->remove_file("testxxx.txt") , 'remove_file that does not exist failes';
    ok $bagit->remove_file("test1.txt") , 'remove_file';

    @files = $bagit->list_files;
    ok @files == 0 , 'count 0 files';

    ok $bagit->is_dirty , 'bag is still dirty';

    ok $bagit->add_file("日本.txt","日本") , 'add_file utf8';

    is path([$bagit->list_files]->[0]->path)->slurp_utf8 , '日本' , 'utf8 data test';

    dies_ok { $bagit->get_file() } "get_file without parameters";

    my $file = $bagit->get_file("日本.txt");

    ok $file, 'get_file()';

    is path($file->path)->slurp_utf8 , '日本' , 'utf8 data test';

    ok ! $bagit->get_file("日本123.txt") , 'get_file() non existing';

    ok $bagit->remove_file("日本.txt") , 'remove_file';

    ok $bagit->add_file('LICENSE', IO::File->new("LICENSE")) , 'add_file(IO::File)';

    $file = [ $bagit->list_files ]->[0];

    is ref($file->open) , 'IO::File' , 'file->fh is IO::File';
}

note("fetch");
{
    my $bagit = Catmandu::BagIt->new;
    ok $bagit , 'new';

    is_deeply [ $bagit->list_fetch ] , [] , 'list_fetch';

    ok $bagit->add_fetch("http://www.gutenberg.org/cache/epub/1980/pg1980.txt","290000","shortstories.txt") , 'add_fetch';

    my @fetches = $bagit->list_fetch;

    ok @fetches == 1 , 'list_fetch';

    is $fetches[0]->url  , 'http://www.gutenberg.org/cache/epub/1980/pg1980.txt' , 'fetch->url';
    is $fetches[0]->size , 290000 , 'fetch->size';
    is $fetches[0]->filename , 'shortstories.txt' , 'fetch->filename';

    ok $bagit->remove_fetch('shortstories.txt') , 'remove_fetch';

    @fetches = $bagit->list_fetch;

    ok @fetches == 0 , 'list_fetch';

    ok $bagit->is_dirty , 'bag is still dirty';
}

note("complete & valid");
{
    my $bagit = Catmandu::BagIt->new;
    ok $bagit , 'new';

    ok $bagit->dirty , 'dirty';

    ok $bagit->complete , 'complete';

    ok !$bagit->valid , 'valid';

    ok $bagit->errors , 'valid has errors (we need to serialize first)';
}

note("reading operations demo01 (valid bag)");
{
    dies_ok { Catmandu::BagIt->read() } "read without parameters dies";

    ok ! Catmandu::BagIt->read("bag/123123123") , "read on non-existing returned undef";

    my $bagit = Catmandu::BagIt->read("bags/demo01");

    ok $bagit , 'read(bags/demo01)';
    ok $bagit->complete , 'complete';
    ok $bagit->valid , 'valid';
    ok !$bagit->errors , 'no errors';
    ok !$bagit->is_holey , 'bag is not holey';
    ok !$bagit->is_dirty , 'bag is not dirty';
    is $bagit->path , 'bags/demo01' , 'path';
    is $bagit->version , '0.97', 'version';
    is $bagit->encoding , 'UTF-8' , 'encoding';
    like $bagit->size , qr/\d+.\d+ KB/ , 'size';
    is $bagit->payload_oxum , '92877.1' , 'payload_oxum';

    is $bagit->get_info('Bag-Size') , '90.8 KB' , 'Bag-Size info';
    is $bagit->get_info('Bagging-Date') , '2014-10-03' , 'Bagging-Date info';
    is $bagit->get_info('Payload-Oxum') , '92877.1' , 'Payload-Oxum info';

    my @list_files = $bagit->list_files;

    ok @list_files == 1 , 'list_files';

    my $file = $list_files[0];

    is ref($file)  , 'Catmandu::BagIt::Payload' , 'file is a payload';
    is $file->filename , 'Catmandu-0.9204.tar.gz' , 'file->filename';
    is ref($file->open) , 'IO::File' , 'file->fh';

    dies_ok { $bagit->get_checksum } "get_checksum without parameters";

    is $bagit->get_checksum($file->filename) , 'c8accb44741272d63f6e0d72f34b0fde' , 'get_checksum';

    my @checksums = $bagit->list_checksum;

    ok @checksums == 1 , 'list_checksum';
    is $checksums[0] , 'Catmandu-0.9204.tar.gz' , 'list_checksum content';

    my @tagsums = sort $bagit->list_tagsum;

    ok @tagsums == 3 , 'list_tagsum';

    is_deeply [ @tagsums ] , [qw(bag-info.txt bagit.txt manifest-md5.txt)] , 'list_tagsum content';

    is $bagit->get_tagsum($tagsums[0]) , '74a18a1c9f491f7f2360cbd25bb2143e' , 'get_tagsum';
    is $bagit->get_tagsum($tagsums[1]) , '9e5ad981e0d29adc278f6a294b8c2aca' , 'get_tagsum';
    is $bagit->get_tagsum($tagsums[2]) , '1022d7f2b7e65ab49c3aeabc407ce7d9' , 'get_tagsum';
}

note("reading operations demo02 (invalid bag)");
{
    my $bagit = Catmandu::BagIt->read("bags/demo02");

    ok $bagit , 'read(bags/demo02)';
    ok !$bagit->complete , 'bag is not complete';
    ok !$bagit->valid , 'bag is not valid';
    ok $bagit->errors , 'bag contains errors';
    ok !$bagit->is_holey , 'bag is not holey';
    ok !$bagit->is_dirty , 'bag is not dirty';
    is $bagit->path , 'bags/demo02' , 'path';
    is $bagit->version , '0.97', 'version';
    is $bagit->encoding , 'UTF-8' , 'encoding';
    like $bagit->size , qr/\d+.\d+ KB/ , 'size';
    is $bagit->payload_oxum , '0.2' , 'payload_oxum';

    is $bagit->get_info('Bag-Size') , '39.6 KB' , 'Bag-Size info';
    is $bagit->get_info('Bagging-Date') , '2014-10-03' , 'Bagging-Date info';
    is $bagit->get_info('Payload-Oxum') , '40447.19' , 'Payload-Oxum info';

    my $text = "\"Well, Prince, so Genoa and Lucca are now just family estates "  .
               "of the Buonapartes. But I warn you, if you don't tell me that "   .
               "this means war, if you still try to defend the infamies and "     .
               "horrors perpetrated by that Antichrist- I really believe he is "  .
               "Antichrist- I will have nothing more to do with you and you are " .
               "no longer my friend, no longer my 'faithful slave,' as you call " .
               "yourself! But how do you do? I see I have frightened you- sit "   .
               "down and tell me all the news.\"";

    is $bagit->get_info('Test') , $text , 'Test info';

    my @list_files = sort { $a->filename cmp $b->filename } $bagit->list_files;

    ok @list_files == 2 , 'list_files';

    is $list_files[0]->filename , 'empty.txt' , 'file->filename';
    is $list_files[1]->filename , 'ignore' , 'file->filename';

    my @info = $bagit->list_info_tags;

    is_deeply [@info] , [qw(Payload-Oxum Bagging-Date Bag-Size Test)] , 'list_info_tags';
}

note("reading operations demo03 (holey bag)");
{
    my $bagit = Catmandu::BagIt->read("bags/demo03");
    ok $bagit , 'read(bags/demo03)';
    ok !$bagit->complete , 'bag is not complete';
    ok $bagit->valid , 'bag is not valid';
    ok !$bagit->is_dirty , 'bag is not dirty';
    ok !$bagit->errors , 'bag contains errors';
    ok $bagit->is_holey , 'bag is holey';

    my @fetches = $bagit->list_fetch;

    ok @fetches == 1 , 'list_fetch';

    ok ref($fetches[0]) eq 'Catmandu::BagIt::Fetch' , 'fetch isa Catmandu::BagIt::Fetch';
    is $fetches[0]->url , 'http://tools.ietf.org/rfc/rfc1.txt' , 'fetch->url';
    is $fetches[0]->size , 21088 , 'fetch->size';
    is $fetches[0]->filename , 'rfc1.txt' , 'fetch->filename';
}

note("write to disk");
{
    my $bagit = Catmandu::BagIt->new;
    ok $bagit , 'new';

    ok $bagit->is_dirty, 'bag is dirty';

    dies_ok { $bagit->write() } "write() without parameters dies";

    ok $bagit->write("t/my-bag") , 'write(t/my-bag)';
    ok $bagit->complete, 'bag is now complete';
    ok $bagit->valid , 'bag is now valid';
    ok !$bagit->is_dirty , 'bag is not dirty anymore';

    ok -d "t/my-bag" , "got a t/my-bag directory";
    ok -d "t/my-bag/data" , "got a t/my-bag/data directory";
    ok -f "t/my-bag/bagit.txt" , "got a t/my-bag/bagit.txt";
    ok -f "t/my-bag/bag-info.txt" , "got a t/my-bag/bag-info.txt";
    ok -f "t/my-bag/manifest-md5.txt" , "got a t/my-bag/manifest-md5.txt";
    ok -f "t/my-bag/tagmanifest-md5.txt" , "got a t/my-bag/tagmanifest-md5.txt";

    my $bagit2 = Catmandu::BagIt->new;
    $bagit2->add_info('Test',123);

    ok ! $bagit2->write("t/my-bag") , 'failed to overwrite existing bag';

    ok $bagit2->is_dirty, 'bag is dirty';

    ok $bagit2->write("t/my-bag", overwrite => 1) , 'write with overwrite';

    ok ! $bagit->is_dirty, 'bag is not dirty anymore';

    my $bagit3 = Catmandu::BagIt->read("t/my-bag");

    ok $bagit3 , 'read';

    ok $bagit3->write("t/my-bag2") , 'create a copy';
    ok $bagit3->complete , 'copy is complete';
    ok $bagit3->valid , 'copy is valid';
    ok !$bagit3->is_dirty , 'bag is not dirty';

    remove_path("t/my-bag");
    remove_path("t/my-bag2");
}

note("update bag");
{
    my $bagit = Catmandu::BagIt->new;

    $bagit->add_info("Test",123);
    $bagit->add_file("test.txt","test123");
    $bagit->add_fetch("http://my.org/data.txt",1024,"data.txt");

    ok $bagit->is_dirty , 'bag is dirty';
    ok $bagit->write("t/my-bag") , 'write bag';

    ok -f "t/my-bag/data/test.txt" , 'got a t/my-bag/data/test.txt';
    ok -f "t/my-bag/fetch.txt" , 'got a t/my-bag/fetch.txt';

    ok $bagit->valid , 'bag is now valid';
    ok !$bagit->is_dirty , 'bag is not dirty anymore';
    ok !$bagit->complete , 'bag is not complete';

    ok $bagit->remove_fetch("data.txt"), 'remove_fetch';
    ok $bagit->write("t/my-bag", overwrite => 1) , 'write bag overwrite';

    ok -f "t/my-bag/data/test.txt" , 'got a t/my-bag/data/test.txt';
    ok ! -f "t/my-bag/fetch.txt" , 'removed the t/my-bag/fetch.txt';

    ok $bagit->complete , 'bag is now complete';

    ok $bagit->add_file("test.txt","test456", overwrite => 1) , 'overwrite file';
    ok $bagit->is_dirty , 'bag is dirty';

    ok $bagit->write("t/my-bag", overwrite => 1) , 'write bag overwrite';

    is path("t/my-bag/data/test.txt")->slurp_utf8 , "test456" , "file content is correctly updated";

    ok $bagit->remove_file("test.txt") , 'remove_file';

    ok $bagit->write("t/my-bag", overwrite => 1) , 'write bag overwrite';

    ok ! -f "t/my-bag/data/test.txt" , 'removed t/my-bag/data/test.txt';

    ok ! $bagit->is_dirty , 'bag is not dirty';

    ok $bagit->complete , 'bag is now complete';

    ok $bagit->add_file("test.txt","test789") , 'adding a new file';

    ok $bagit->write("t/my-bag", overwrite => 1) , 'write bag overwrite';

    ok -f "t/my-bag/data/test.txt" , 'got a t/my-bag/data/test.txt';

    my $fh = IO::File->new("t/poem.txt");

    ok $bagit->add_file("poem.txt",$fh) , 'add_file(IO::File)';

    ok $bagit->add_file("results.txt", sub {
        my $io = shift;
        for (0..9) {
            $io->print($_);
        }
    });

    ok $bagit->write("t/my-bag", overwrite => 1) , 'write bag overwrite';

    ok -f "t/my-bag/data/test.txt" , 'got a t/my-bag/data/test.txt';
    ok -f "t/my-bag/data/poem.txt" , 'got a t/my-bag/data/poem.txt';
    ok -f "t/my-bag/data/results.txt" , 'got a t/my-bag/data/results.txt';

    like path("t/my-bag/data/test.txt")->slurp_utf8 , qr/test789/, 'file content is correct';
    like path("t/my-bag/data/poem.txt")->slurp_utf8 , qr/Violets are blue/ , 'file content is correct';
    like path("t/my-bag/data/results.txt")->slurp_utf8 , qr/0123456789/ , 'file content is correct';

    ok $bagit->add_file("poem.txt",IO::File->new("t/poem2.txt"), overwrite => 1) , 'setting new file content';

    ok $bagit->write("t/my-bag", overwrite => 1) , 'write bag overwrite';

    like path("t/my-bag/data/poem.txt")->slurp_utf8 , qr/The rose is red, the violet's blue/ , 'file content is correct';

    my $payload_oxum = $bagit->payload_oxum;

    is $payload_oxum , '218.3' , 'payload oxum';

    ok $bagit->add_fetch("http://www.gutenberg.org/cache/epub/1980/pg1980.txt","290000","shortstories.txt") , 'adding payload';

    $payload_oxum = $bagit->payload_oxum;

    is $payload_oxum , '290218.4' , 'new payload oxum reflects the fetch file';

    remove_path("t/my-bag");
}

note("mirror fetch");
{
    my $bagit = Catmandu::BagIt->new(user_agent => user_agent() );

    $bagit->add_fetch("http://demo.org/","65","poem.txt");

    dies_ok { $bagit->get_fetch() } 'get_fetch without parameters dies';

    ok ! $bagit->get_fetch("poem123.txt") , 'get_fetch() on non-existing';

    my $fetch = $bagit->get_fetch("poem.txt");

    ok $fetch , 'get_fetch()';

    ok $bagit->write("t/my-bag", overwrite => 1) , 'write bag overwrite';

    ok $bagit->mirror_fetch($fetch) , 'mirror_fetch';

    ok $bagit->write("t/my-bag", overwrite => 1) , 'write bag overwrite';

    ok -r "t/my-bag/data/poem.txt";

    my $size = [stat("t/my-bag/data/poem.txt")]->[7];

    is $size , 65 , 'got the correct size';

    remove_path("t/my-bag");
}

note("lock");
{
    my $bagit = Catmandu::BagIt->read("bags/demo03");

    ok ! $bagit->locked , '!locked';

    $bagit = Catmandu::BagIt->new;

    ok $bagit->write("t/my-bag");

    $bagit->touch("t/my-bag/.lock");

    ok $bagit->locked , 'locked';

    remove_path("t/my-bag");
}

note("pipe");
{
    my $pipe = new IO::Pipe;

    if(my $pid = fork()) { # Parent
        $pipe->reader();

        my $bagit = Catmandu::BagIt->new;

        ok $bagit->add_file("test.txt",$pipe) , 'add_file() pipe';

        ok $bagit->write("t/my-bag") , 'write()';

        my $file = $bagit->get_file("test.txt");

        ok $file;

        is path($file->path)->slurp_utf8 , "Hello, parent!\n" , 'file->data';

        remove_path("t/my-bag");
    }
    elsif(defined $pid) { # Child
        $pipe->writer();

        print $pipe "Hello, parent!\n";

        exit(0);
    }
}

done_testing;

sub remove_path {
    my $path = shift;
    # Stupid chdir trick to make remove_tree work
    chdir("lib");
    if (-d "../$path") {
       remove_tree("../$path");
    }
    chdir("..");
}

sub user_agent  {
    my $ua = Test::LWP::UserAgent->new(agent => 'Test/1.0');

    my $text =<<EOF;
Roses are red,
Violets are blue,
Sugar is sweet,
And so are you.
EOF

    $ua->map_response(
        qr{^http://demo.org/$},
        HTTP::Response->new(
            '200' ,
            'OK' ,
            [ 'Content-Type' => 'text/plain'] ,
            $text
        )
    );

    $ua;
}
