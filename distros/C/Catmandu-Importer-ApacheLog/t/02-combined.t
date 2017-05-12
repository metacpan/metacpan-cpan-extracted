#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Importer::ApacheLog;

my $file = 't/logs/combined.log';
my $importer = Catmandu::Importer::ApacheLog->new( file => $file, formats => [ "combined" ] );
my $logs = $importer->to_array();

is_deeply $logs, [{"path" => "/local/js/jquery-1.10.1.min.js","method" => "GET","proto" => "HTTP/1.1","date" => "12/May/2016","bytes" => "93057","referer" => "http://shared.ugent.be/local/lib.html","status" => "200","time" => "11:01:45","agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.101 Safari/537.36","request" => "GET /local/js/jquery-1.10.1.min.js HTTP/1.1","datetime" => "12/May/2016:11:01:45 +0200","timezone" => "+0200","logname" => "-","user" => "-","_log" => "157.193.149.236 - - [12/May/2016:11:01:45 +0200] \"GET /local/js/jquery-1.10.1.min.js HTTP/1.1\" 200 93057 \"http://shared.ugent.be/local/lib.html\" \"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.101 Safari/537.36\" \"-\"\n","rhost" => "157.193.149.236"}];

done_testing 1;
