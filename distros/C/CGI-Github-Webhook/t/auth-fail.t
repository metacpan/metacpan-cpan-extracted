#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

use Test::More;
use File::Temp qw(tempfile tempdir);
use File::Basename;
use File::Slurper qw(read_text);
use Test::File;

if ($^O eq 'dos' or $^O eq 'os2' or $^O eq 'MSWin32' ) {
    plan skip_all => 'these tests do not work on dos-ish systems';
} else {
    plan tests => 3;
}

my ($fh1, $tmplog) = tempfile();
my ($fh2, $tmpout) = tempfile();
my $tmpdir = tempdir( CLEANUP => 1 );
my $dir = dirname($0);
my $secret = 'invalid';

isnt(system("$^X -I$dir/../lib $dir/cgi/basic.pl 'echo foo' $secret $tmplog".
          "> $tmpout 2>&1"),
   0, 'system exited with non-zero');
is(read_text($tmpout),
   "Content-Type: text/plain; charset=utf-8\r\n\r\nAuthentication failed\n",
   "CGI output as expected");
my $log = read_text($tmplog);
$log =~ s/^Date:.*/Date:/;
$log =~ s:^.*/auto/share/module/:.../auto/share/module/:m;

my $badge = "$tmpdir/badge.svg";
is($log, "Date:
Remote IP: localhost (127.0.0.1)
\$VAR1 = {
          'payload' => 'none'
        };
\$VAR2 = '<no-x-hub-signature>';
\$VAR3 = 'sha1=352413c630849ecc0028758fdfab7186260106a9';
Authentication failed
", "CGI log file as expected");
