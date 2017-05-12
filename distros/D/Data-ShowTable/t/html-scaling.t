#!/usr/bin/env perl

($DIR,$PROG) = $0 =~ m=^(.*/)?([^/]+)$=;
$DIR =~ s=/$== || chop($DIR = `pwd`);

($type,$what) = $PROG =~ /^(\w+)-(\w+)\./;

%types = ( 	list => 'ShowListTable', 
		html => 'ShowHTMLTable',
		box  => 'ShowBoxTable',
		simple => 'ShowSimpleTable',
		table => 'ShowTable',
	);

if (defined $types{$type}) {
  $showSub = $types{$type};
} else {
  die "I don't know about \"$type\" types!\n";
}
$showSub = \&$showSub;

$what = "t/$what" if -d "t" && !-r "$what.pl";
-r "$what.pl" or die "I don't know how to do \"$what\"!\n";

unshift(@INC,'../blib/lib') if -d '../blib/lib';
unshift(@INC,'t') if -d 't';

do "$what.pl";
