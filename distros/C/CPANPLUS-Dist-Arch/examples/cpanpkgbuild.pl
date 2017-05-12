#!/usr/bin/perl

use CPANPLUS::Backend;
use CPANPLUS::Dist::Arch;

if(@ARGV < 1){
    print STDERR "usage: cpanpkgbuild.pl [module]\n";
    exit 2;
}

$m = shift;
$cb = new CPANPLUS::Backend;
$x  = $cb->module_tree($m);
if(!$x){
    print STDERR "error: module not found: $m\n";
    exit 100;
}

$cb->configure_object->set_conf('prereqs' => 0);
$x->fetch('verbose' => 0);
$x->extract('verbose' => 0);
$y = $x->dist('target' => 'prepare', 'format' => 'CPANPLUS::Dist::Arch');
if(!$y){
    print STDERR "error: failed to prepare distribution\n";
    exit 1;
}

print $y->get_pkgbuild();
exit 0;
