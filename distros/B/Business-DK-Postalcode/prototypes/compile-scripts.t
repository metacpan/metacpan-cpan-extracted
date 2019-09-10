#!/usr/bin/env perl

use Test::More;
use FindBin qw($Bin);
use lib ("$Bin/../lib", "$Bin/../scripts");
use Path::Tiny;

# try to import every .pm file in /lib
my $dir = path('bin/');
my $iter = $dir->iterator({
            recurse         => 1,
            follow_symlinks => 0,
           }); 
while (my $path = $iter->())
{
  next if $path->is_dir || $path !~ /\.pl$/;
  BAIL_OUT( "$path does not compile" ) unless require_ok( $path );
}
done_testing;