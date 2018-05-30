#!/usr/bin/perl
# George Mpouras, 4 Oct 2016

use FindBin;
sub Exit { print STDOUT "$_[1]\n$_[0]\n"; print STDOUT $ARGV[2] if $_[1]; exit $_[1] }

Exit('The third argument of the comma separated requested group list is missing', 0) unless exists $ARGV[2];
my  %option;
my ($script_base_name) = $0 =~/([^\\\/]+)$/; $script_base_name =~s/(\..*)$//;

$_ = "$FindBin::Bin/$script_base_name.conf";
Exit("Configuration file $_ is missing", 0) unless -f $_;
open   FILE, '<', $_ or Exit("Could not read file $_ because $!", 0);
while(<FILE>) {next if /^\s*($|#.*)/; next unless /^\s*([^:]+?)\s*:\s*(.*?)\s*$/; $option{$1}=$2}
close  FILE;
Exit("Password file is missing $option{file}", 0) if ! -f $option{file};
Exit("Password htpasswd utility $option{htpasswd} is missing", 0) if ! -f $option{htpasswd};
Exit("Password htpasswd utility $option{htpasswd} is not executable from user ".getpwuid($>), 0) if ! -x $option{htpasswd};

my	$command = "$option{htpasswd} -b -v \Q$option{file}\E ".pack('H*',$ARGV[0]).' '.pack('H*',$ARGV[1]);
my	$message = qx/$command 2>&1/;
chomp	$message;
$message =~/correct\.$/i ? Exit($message,1) : Exit($message,0)