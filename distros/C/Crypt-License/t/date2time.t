# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..16\n"; }
END {print "not ok 1\n" unless $loaded;}
use Time::Local;
use License;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $test = 2;

my %good_strings = (
#	string			response
        'June 6, 1987', timelocal(gmtime(550022399)),
        '7/1/02',       timelocal(gmtime(1025567999)),
        '1 14 99',      timelocal(gmtime(916358399)),
        '5-4 2005',     timelocal(gmtime(1115251199)),
        '12-23-89',     timelocal(gmtime(630460799)),
        'Dec 4 2000',   timelocal(gmtime(975974399)),
);

my @bad_strings = (
	'a-1-127',
	'1.2 3 98',
	'3 a 99',
	'3 3 a',
	'0 3 99',
	'13 3 99',
	'12 0 99',
	'12 32 99',
	'12 31 2070',
);

foreach(sort keys %good_strings) {
  my $rv = Crypt::License::date2time($_);
  my $t;
  print "\n   sent $_ want ", ($t=localtime($good_strings{$_})),
	"\n\texpected\t$good_strings{$_}\n\tgot\t$rv\nnot "
	unless $rv eq $good_strings{$_};
  print "ok $test\n";
  ++$test;
}

foreach(@bad_strings) {
  my $rv = Crypt::License::date2time($_);
  my $t;
  print "\n   sent $_ got time for |$rv| ", ($t=localtime($rv)),
	"\nnot " if $rv;
  print "ok $test\n";
  ++$test;
}
