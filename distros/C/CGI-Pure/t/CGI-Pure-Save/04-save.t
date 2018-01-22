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
my $cgi_pure = CGI::Pure->new('init' => 'par=val&par2=val2');
my $obj = CGI::Pure::Save->new('cgi_pure' => $cgi_pure);
my $file = $data_dir->file('params')->s;
open my $ouf, '>', $file || die "Can't open file '$file'.";
my $ret = $obj->save($ouf);
is($ret, undef);
close $ouf;
open my $inf, '<', $file || die "Can't read file '$file'.";
my $inf_string = join q{}, <$inf>;
ok($inf_string eq "par=val\npar2=val2\n=\n" 
	|| $inf_string eq "par2=val2\npar=val\n=\n");
close $inf;
unlink $file;
