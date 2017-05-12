#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use FCGI;

my %env;
my $req = FCGI::Request(\*STDIN, \*STDOUT, \*STDERR, \%env);

while ($req->Accept() >= 0) {
#my $fh = $req->input;
my $in = do { local $/; <STDIN> } // '';
#my %env = %{$req->environment};
my $env = join '', map { "$_=$env{$_}\n" } sort keys %env;
    print <<EOT;
Content-Type: text/plain

$env
$in
EOT
}
