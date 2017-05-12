use Test::Simple 'no_plan';
use strict;
use lib './lib';

use warnings;
use Cwd::Ext ':all'; #qw(abs_path_nd abs_path_is_in abs_path_is_in_nd);
use Cwd qw/abs_path cwd/;

unless( symlinks_supported() ){
   ok 1,'You system does not support symlinks';
   exit;
}


my $cwd = cwd();
my $hard = $cwd.'/t/HardAsset';
my $soft = $cwd.'/t/SoftAsset';
mkdir $hard;


ok symlink("$hard/",$soft), "linked $soft to $hard";


ok -l $soft;
ok -d $hard;

my $subsoft = $cwd.'/t/SoftAsset/Sub1';
mkdir $subsoft;
ok( abs_path_nd( './t/SoftAsset/Sub1' ) eq "$cwd/t/SoftAsset/Sub1" );

ok( abs_path( './t/SoftAsset/Sub1' ) eq "$cwd/t/HardAsset/Sub1" );

ok abs_path_is_in($subsoft, $hard), "d $subsoft is in hard";
ok abs_path_is_in($subsoft, $soft), "d $subsoft is in soft, because both resolve symlinks";

ok abs_path_is_in_nd($subsoft, $soft), "subsoft is in soft with no symlink resolve";
ok !abs_path_is_in_nd($subsoft, $hard), "subsoft is NOT in hard if we do not resolve";




ok rmdir $subsoft;
ok unlink $soft;
ok rmdir $hard;
