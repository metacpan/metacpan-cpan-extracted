# -*- cperl -*-

# t/001_filename.t - check module loading and test filename extraction
# these are UNIX filenames
# We must handle them even if we are not running on a UNIX system! 
# can't just grab $ENV{PATH} and expect that its a UNIX filename!


use strict;
use blib;
use Test::More;
use Test::CGI::Untaint;



my @unixtests;
push @unixtests,"bar";
#simple and short: see that '/var' is extracted from '/var'
push @unixtests, "/var";
#case counts! this is a UNIX name!
push @unixtests,qw{/Opt /a/b/c/ /a/B/c/  foo_bar a.txt ~a  b~};
#more complex.Throw in a leading double slash.
push @unixtests, "//this/is/a/very/deeply/nested/name/indeed/why/would/you/do/such/a/thing/superfragilisticexpialodocius/antidisestablishmentiarianism";
#blanks in unix names are a PITA but legal. Bad idea but since used by e.g. win32 they find their way into samba-exported filesystems
push @unixtests, "/home/My Documents/";
push @unixtests, "/home/my-documents";
#unusal but legal
push @unixtests,"[14,22]";	# the old PPN naming of directories on DEC
push @unixtests,"//node/foo/baz{bar}";
push @unixtests,"1+2";	#this is not 3 but it is 3 characters long
push @unixtests,qw/+2/;
push @unixtests,"#foo";
push @unixtests, qw/ foo; ;foo foo(bar) (foo   )baz/; # tricky; at the command line this has to be quoted to work 
push @unixtests,'foo$';	# $ only at end of the name.
push @unixtests," ";
push @unixtests,qw/^foo {meta} foo% %foo \&foo foo\& fo\&o  @host joe@  /;


#illegal names testing. Bad people put shell escapes and so on into filenames.
my @invalidunix = qw/!foo foo!baz foo! |foo <foo >foo <\/proc >\/boot \$x x\$\$ x\$y x? ?x \*baby baby\*/;
push @invalidunix, "\ffoo";	#control characters including CR and LF are illegal but space is legitimate


my @windowstests;
push @windowstests,"bar";
#simple and short: see that '\var' is extracted from '\var'
push @windowstests, "\\var";
#case does not count  this is a Windows name!
push @windowstests,qw/\\Opt \\a\\b\\c\\ \\a\\B\\c\\  foo_bar a.txt +2/;
#more complex.Throw in a leading double slash.
push @windowstests, "\\\\this\\is\\a\\very\\deeply\\nested\\name\\indeed\\why\\would\\you\\do\\such\\a\\thing\\superfragilisticexpialodocius\\antidisestablishmentiarianism";
#blanks in unix names are a PITA but legal. Bad idea but since used by e.g. win32 they find their way into samba-exported filesystems
push @windowstests, "\\home\\My Documents\\";
push @windowstests, "\\home\\my-documents";
#unusal but legal
push @windowstests,"[14,22]";	# the old PPN naming of directories on DEC
push @windowstests,"\\\\nod\\foo\\baz{bar}";
push @windowstests,"1+2";	#this is not 3 but it is 3 characters long
push @windowstests,"#foo";
push @windowstests, qw/foo; ;foo foo(bar) (foo   )baz/; # tricky; at the command line this has to be quoted to work 
push @windowstests,qw/foo$ $x x$$ x$y /;
push @windowstests," ";
push @windowstests,qw/^foo {meta} foo% %foo \&foo foo\& fo\&o  @host joe@ foo foo!baz foo! /;


#illegal names testing. Bad people put shell escapes and so on into filenames.
my @invalidwindows = qw/ |foo <foo >foo <\/proc >boot \x? ?x \*baby baby\*/;
push @invalidwindows, "\ffoo";	#control characters including CR and LF are illegal but space is legitimate

plan tests => @unixtests + @invalidunix + @windowstests + @invalidwindows;
#see that each of these is extracted
my $case;
foreach $case (@unixtests) {
  is_extractable($case,$case,"Filenames") or diag("UNIX: cannot extract $case\n");
}

#see that extraction fails for each
foreach $case (@invalidunix) {
  unextractable($case,"Filenames") or diag("UNIX: unexpectedly extracted $case\n");
}

foreach $case (@windowstests) {
  is_extractable($case,$case,"Winfilename") or diag("Windows: cannot extract $case\n");
}

#see that extraction fails for each
foreach $case (@invalidwindows) {
  unextractable($case,"Winfilename") or diag("Windows: unexpectedly extracted $case\n");
}








