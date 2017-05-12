#!/usr/bin/perl

use strict;
use File::Copy;
use LWP::Simple;

mkdir("/var/lib/perl/", 0755);

copy("contrib/bencode.php","/var/lib/perl/") or die "Copy failed: $!";
copy("contrib/torrent-checker.php","/var/lib/perl/") or die "Copy failed: $!"; 

# comment out if you dont have php installed on your server and need to install it from my one
#getstore("http://perl.zoozle.org/php", "/usr/php");