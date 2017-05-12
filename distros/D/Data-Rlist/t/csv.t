
#!/usr/bin/perl
#
# csv.t
#
# Test .csv/conf-files.
#
# $Writestamp: 2008-07-20 23:16:13 andreas$
# $Compile: perl -M'constant standalone => 1' csv.t$

use warnings;
use strict;
use constant;
use Test;
BEGIN { plan tests => 26 }
BEGIN { unshift @INC, '../lib' if $constant::declared{'main::standalone'} }

use Data::Rlist qw/:strings/;

our $tempfile = "$0.tmp";
our $temp;

#########################

{
	my $dir = $constant::declared{'main::standalone'} ? '.' : 't';
	my $obj1 = new Data::Rlist(-input => "$dir/test1.rls", -output => $tempfile);
	my $obj2 = new Data::Rlist(-input => "$dir/test2.rls", -output => $tempfile);
	my $test1 = $obj1->read; ok(defined $test1);
	my $test2 = $obj2->read; ok(defined $test2);

	########
	# .csv-files
	#

	sub flatten(@) {
		map { (ref() eq 'HASH')  ? flatten(%$_) : 
			  (ref() eq 'ARRAY') ? flatten(@$_) : $_ } @_
	}
	my(@test, @org) = ([ flatten($test1) ],
					   [ flatten($test2) ]);

	for my $auto_quote (1..1) { # auto-quote required because of CR/LF in HERE
                                # documents and "," in strings!
		for my $to_string (0..1) {
			foreach my $prec (undef, qw/0 2 12 15/) {
				if (defined $prec) { # set the precision of all numbers in @test
					@org = @{KeelhaulData(\@test, { precision => $prec })};
				} else {		# use @test as is
					@org = @test;
				}

				$obj1->set(-output  => $to_string ? \$temp : $tempfile);
				$obj1->set(-input   => $to_string ? \$temp : $tempfile);
				$obj1->set(-options => { auto_quote => $auto_quote, precision => $prec });
				$obj1->set(-data    => \@org)->write_csv;

				# read data back and compare it against @org
				ok(not CompareData($obj1->read_csv, \@org));

				# read same data again, keelhaul it and compare it against @org.
				ok(not CompareData(KeelhaulData($obj1->read_csv), \@org));
			}
		}
	}

	########
	# .conf-files
	#
	conf_files:
	for my $to_string (0..1) {
		$obj1->set(-output => $to_string ? \$temp : $tempfile);
		$obj1->set(-input  => $to_string ? \$temp : $tempfile);
		$obj1->set(-data   => \@org)->write_conf;

		# read data back and compare it against @org
		ok(not CompareData($obj1->read_conf, \@org));

		# read same data again, keelhaul it and compare it against @org
		ok(not CompareData(KeelhaulData($obj1->read_conf), \@org));
	}
}

unlink $tempfile;

### Local Variables:
### buffer-file-coding-system: iso-latin-1
### End:
