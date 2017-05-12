# -*- perl -*-
#

use Test::More;

use CGI::Alert;

# Not interested in any email being sent
$SIG{__DIE__}  = 'DEFAULT';
$SIG{__WARN__} = 'DEFAULT';

#
# LHS (key) is what we pass to the import method
# RHS (val) is how we expect to see that interpreted
#
our %tests =
  (
   'hide=/^passw/'	=> '(?^:^passw)',       # Note: new >=5.14 regexs
   'hide=m!^passw!'	=> '(?^:^passw)',
   'hide=^passw'	=> '(?^:^passw)',
   '-hide=^passw'	=> '(?^:^passw)',

   'hide=qr/^passw/i'	=> '(?^i:^passw)',
   'hide=/^aaa(/'	=> 'err:Unmatched \( in regex; marked by <-- HERE',
  );

# 2 tests for each of the above: one to make sure it parses, one to make
# sure it is interpreted correctly.
plan tests => 2 * keys %tests;


my @warnings;
$SIG{__WARN__} = sub { push @warnings, @_ };

for my $t (sort keys %tests) {
    # Reset
    @CGI::Alert::Hide = ();
    @warnings = ();

    # Do it
    CGI::Alert->import( $t );

    # Do we expect an error?
    if ((my $expect = $tests{$t}) =~ m!^err:(.*)!) {
	# Error expected.  Make sure the result matches.
	my $warn_re = qr/$1/;
	if (@warnings == 1) {
	    like $warnings[0], $warn_re, "$t: expected warnings";
	}
	else {
	    fail "$t (1: expected failure!)";
	}
	# (meaningless to check the parsed RE)
	ok 1, "$t (2: results - meaningless)";
    }
    else {
	# No error expected.
	if (@warnings == 0) {
	    pass "$t (1: parsed OK)";
	}
	else {
	    fail "$t (1: did not parse: @warnings)";
	}

	# Make sure the compiled RE matches what we expect.
        # Note the regex transformation hackery: perl 5.14 changed the
        # string representation of compiled regexps:
        #
        #    perl <  5.14  : (?-xism:foo)
        #    perl >= 5.14  : (?^:foo)
        #
        # To deal with both, we transform old-style to new.
        my $got = $CGI::Alert::Hide[0];
        $got =~ s{^\(\?(.*)-[a-z]+:}{(?^$1:};

	is $got, $expect, "$t (2: results)";
    }
}

exit 0;
