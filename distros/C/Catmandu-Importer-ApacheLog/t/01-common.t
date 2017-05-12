#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Importer::ApacheLog;

my $file = 't/logs/common.log';
my $importer = Catmandu::Importer::ApacheLog->new( file => $file, formats => [ "common" ] );
my $logs = $importer->to_array();

is_deeply $logs,[{"date"=>"10/Oct/2000","path"=>"/apache_pb.gif","time"=>"13:55:36","proto"=>"HTTP/1.0","datetime"=>"10/Oct/2000:13:55:36 -0700","user"=>"frank","rhost"=>"127.0.0.1","bytes"=>"2326","_log"=>"127.0.0.1 user-identifier frank [10/Oct/2000:13:55:36 -0700] \"GET /apache_pb.gif HTTP/1.0\" 200 2326\n","request"=>"GET /apache_pb.gif HTTP/1.0","status"=>"200","logname"=>"user-identifier","timezone"=>"-0700","method"=>"GET"}];

done_testing 1;
