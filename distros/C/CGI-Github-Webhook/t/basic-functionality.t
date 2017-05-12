#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

use Test::More;
use File::Temp qw(tempfile tempdir);
use Digest::SHA qw(hmac_sha1_hex);
use File::Basename;
use File::Slurper qw(read_text);
use Test::File;

if ($^O eq 'dos' or $^O eq 'os2' or $^O eq 'MSWin32' ) {
    plan skip_all => 'these tests do not work on dos-ish systems';
} else {
    plan tests => 12;
}

my ($fh1, $tmplog) = tempfile();
my ($fh2, $tmpout) = tempfile();
my $tmpdir = tempdir( CLEANUP => 1 );
my $secret = 'bar';
my $json = '{"fnord":"gnarz"}';
my $signature = 'sha1='.hmac_sha1_hex($json, $secret);
my $dir = dirname($0);

$ENV{HTTP_X_HUB_SIGNATURE} = $signature;

is(system("$^X -I$dir/../lib $dir/cgi/basic.pl 'echo foo' $secret $tmplog $tmpdir 'POSTDATA=$json'".
          "> $tmpout 2>&1"),
   0, 'system exited with zero');
is(read_text($tmpout),
   "Content-Type: text/plain; charset=utf-8\r\n\r\nSuccessfully triggered\n",
   "CGI output as expected");
my $log = read_text($tmplog);
$log =~ s/^Date:.*/Date:/;
$log =~ s:^.*/auto/share/module/:.../auto/share/module/:m;

my $badge = "$tmpdir/badge.svg";
is($log, "Date:
Remote IP: localhost (127.0.0.1)
\$VAR1 = {
          'fnord' => 'gnarz'
        };
\$VAR2 = 'sha1=f0265993a0e0c508b277666562b3e36ed3d5695d';
\$VAR3 = 'sha1=f0265993a0e0c508b277666562b3e36ed3d5695d';
foo
.../auto/share/module/CGI-Github-Webhook/success.svg successfully copied to $badge
Successfully triggered
", "CGI log file as expected");

file_exists_ok($badge);
file_readable_ok($badge);
file_contains_like($badge, qr/<svg.*success/s, "'success' and is an SVG file");

# Reset the log file
($fh1, $tmplog) = tempfile();
$tmpdir = tempdir( CLEANUP => 1 );
$badge = "$tmpdir/badge.svg";

isnt(system("$^X -I$dir/../lib $dir/cgi/basic.pl false $secret $tmplog $tmpdir 'POSTDATA=$json'".
            "> $tmpout 2>&1"),
     0, 'system calling false as trigger exited with non-zero');
is(read_text($tmpout),
   "Content-Type: text/plain; charset=utf-8\r\n\r\nTrigger failed\n",
   "CGI output as expected");
$log = read_text($tmplog);
$log =~ s/^Date:.*/Date:/;
$log =~ s:^.*/auto/share/module/:.../auto/share/module/:m;
is($log, "Date:
Remote IP: localhost (127.0.0.1)
\$VAR1 = {
          'fnord' => 'gnarz'
        };
\$VAR2 = 'sha1=f0265993a0e0c508b277666562b3e36ed3d5695d';
\$VAR3 = 'sha1=f0265993a0e0c508b277666562b3e36ed3d5695d';
.../auto/share/module/CGI-Github-Webhook/failed.svg successfully copied to $badge
false >> $tmplog 2>&1 
Trigger failed
child exited with value 1
", "CGI log file as expected");

file_exists_ok($badge);
file_readable_ok($badge);
file_contains_like($badge, qr/<svg.*failed/s, "'failed' and is an SVG file");
