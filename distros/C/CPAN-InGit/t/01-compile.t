#! /usr/bin/perl
use Test2::V0;
use v5.36;

my @pkgs= qw(
   CPAN::InGit
   CPAN::InGit::MirrorTree
   CPAN::InGit::ArchiveTree
);

ok( eval "require $_", $_ )
   or diag $@ && bail_out("Compile error in $_")
   for @pkgs;

diag "Testing on Perl $], $^X\n";

done_testing;
