use strict;
use warnings;

use CGI::Pure;
use CGI::Pure::Save;
use File::Object;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Directories.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $cgi_pure = CGI::Pure->new;
my $obj = CGI::Pure::Save->new('cgi_pure' => $cgi_pure);
my $file = $data_dir->file('params2')->s;
open my $inf, $file || die "Can't open file '$file'.";
my $ret = $obj->load($inf);
is($ret, undef);
close $inf;
my @params = $cgi_pure->param;
ok((join q{ }, @params) eq 'param1 param2' 
	|| (join q{ }, @params) eq 'param2 param1');
