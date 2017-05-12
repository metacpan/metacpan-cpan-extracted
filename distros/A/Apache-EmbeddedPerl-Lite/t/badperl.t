#
# badperl.t
#

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

package Apache::EmbeddedPerl::TestPackage;

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}

use Apache::EmbeddedPerl::Lite qw(embedded);
use vars qw(@ISA);

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

my $file = 'badperl.html';
#my $file = 'badsyntax.html';
#my $file = 'goodperl_1.html';
#my $file = 'goodperl_2.html';
#my $file = 'goodperl_3.html';
#my $file = 'noperl.html';


my $warn = '';
my $printout = '';
my $rv;

{
	package Apache::EmbeddedPerl::TestPackage::Alone;
	sub print {
	  shift;	# to waste method pointer
	  foreach(@_) {
	    $printout .= $_;
	  }
	}
}

@ISA = qw( Apache::EmbeddedPerl::TestPackage::Alone );

my $r = bless {}, __PACKAGE__;
{
	local $SIG{__WARN__} = sub { $warn .= $_[0] };

	$rv = embedded(__PACKAGE__,$r,'testfiles/'. $file);
	my $exp = 500;
	print "got: $rv, exp: $exp\nnot "
		unless $rv == $exp;
	&ok;

	$exp = q|Apache::EmbeddedPerl::TestPackage embedded: failed testfiles/badperl.html line 6
Global symbol "$c" requires explicit package name at (eval 1) line 5, <F> line 13.
Global symbol "$ref" requires explicit package name at (eval 1) line 5, <F> line 13.
Global symbol "$ref" requires explicit package name at (eval 1) line 7, <F> line 13.
|;
	print "got:\n$warn\nexp:\n$exp\nnot "
		unless $warn eq $exp;
	&ok;

	$exp = '<!DOCTYPE html>
<html>
<body>
This file contains perl that will not compile.

';
	print "got:\n$printout\nexp:\n$exp\nnot "
		unless $printout eq $exp;
	&ok;
}
