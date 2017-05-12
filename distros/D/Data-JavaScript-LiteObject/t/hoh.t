######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use Data::JavaScript::LiteObject;
$loaded = 1;
print "ok 1\n";
$/ = "\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
%A = (a=>1.0, z=>26, data=>['alpha',   -1]);
%B = (b=>2.0, y=>25, data=>['beta',    -1.1]);
%C = (c=>3.0, x=>24, data=>['charlie', .1]);

@attrib = qw(a b c x y z data);

my %tests = (
	     2=>{},
	     3=>{attributes=>\@attrib  },
	     4=>{attributes=>\@attrib, lineIN=>4  },
	     5=>{attributes=>\@attrib, lineIN=>4, explode=>1}
	    );

foreach my $k ( sort {$a <=> $b } keys %tests ){
  open(HOH, "t/hoh.$k") ||
    print "not ok $k #Couldn't open reference t/hoh.$k: $!\n" && next;
  $_ = do{ local $/; <HOH> };
  $results[$k] = join('', jsodump(
				  protoName=>"example",
				  dataRef=>{alpha=>\%A,
					    bravo=>\%B,
					    charlie=>\%C},
				  %{$tests{$k}}
				 ));
  print "not " unless $_ eq $results[$k];
  print "ok $k\n";
}
