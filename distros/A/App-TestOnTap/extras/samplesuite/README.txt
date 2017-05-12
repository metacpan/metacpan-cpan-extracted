This is just a sample 'test suite' with tests that are generally
just simulations and so suitable for playing around with mechanisms.

When run, it demonstrates dependencies and parallelism. It also has a 'skip'
configuration for demonstration as well as assorted bits and bobs in some
'tests' in order to demonstrate various items.

Some noteworthy things:
 * All tests and in particular 'req_u2d_TMP.pl', checks for a a really old
   Test::More to account for the lack of 'done_testing()'. The 'req' test
   shows a full skip due to this.

 * Some tests are merely saying 'pass' once, others use some randomization
   for number of tests and time spent
   
 * The init.pl test will print the commandline if given 'NOTE' or 'DIAG' with
   note() and diag() respectively.
   
 * The long.pl test will bail out after one test if given 'BAILOUT'

Running it as-is:
	testontap samplesuite
	
Use parallelism:
	testontap --jobs 10 samplesuite
	
Avoid one long-running test:
	testontap --jobs 10 --skip "eq(long.pl)" samplesuite
	
Trigger a bail out:
	testontap samplesuite BAILOUT
	
Trigger a note and diag printout of args (verbose is needed to see note's):
	testontap -v samplesuite fee NOTE fie DIAG foo
