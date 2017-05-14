# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Chromosome.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
# use Carp;
# use blib;



use lib 't';
use TestDB qw($ECOLI_SPECIES);
use Bio::Genex;
use Bio::Genex::HTMLUtils;
use CGI qw(:standard);
$loaded = 1;
my $i = 1;
print "ok ", $i++, "\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $q = new CGI(foo=>'bar');

#
# check that post_process() doesn't interfere with unknown attributes
%tags = (foo => 'bar');
%new_tags = post_process($q,%tags);
print "not " unless $new_tags{foo} eq 'bar';
print "ok ", $i++, "\n";

#
# check that post_process() does manipulate a known attribute
%tags = (spc_fk => $ECOLI_SPECIES);
%new_tags = post_process($q,%tags);
print "not " unless $new_tags{spc_fk} =~ m|<a.*</a>|i;
print "ok ", $i++, "\n";

#
# check that post_process() filters login names and passwords
%tags = (login => 'foo', password => 'bar');
%new_tags = post_process($q,%tags);
print "not " unless $new_tags{login} eq '&nbsp;' && 
  $new_tags{password} eq '&nbsp;';
print "ok ", $i++, "\n";


1;
