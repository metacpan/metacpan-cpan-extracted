#!/usr/bin/perl
use lib qw(../lib);
use Cvs::Simple::Cmd;

cvs init;
cvs checkout test
cvs -d :ext: update .
cvs -d :ext: update -jOLD -jNEW file.pl
cvs diff -c file.pl
cvs diff -c -rTAG1 -rTAG2 file.pl

cvs diff -u file.pl
exit;

__END__
