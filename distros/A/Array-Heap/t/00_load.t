BEGIN { $| = 1; print "1..16\n"; }
END {print "not ok 1\n" unless $loaded;}
use Array::Heap;
$loaded = 1;
print "ok 1\n";

@h = (9,8,7,4,3,5,6,1,2);
make_heap @h;
print "@h" eq "1 2 5 3 7 8 6 9 4" ? "ok 2\n" : "not ok 2 # @h\n";

@g = map +(pop_heap @h), 1..9;
print "@g" eq "1 2 3 4 5 6 7 8 9" ? "ok 3\n" : "not ok 3 # @g\n";

push_heap @i, 1,2,3,5,6,7,9,8,4;
print "@i" eq "1 2 3 4 6 7 9 8 5" ? "ok 4\n" : "not ok 4 # @i\n";

@g = map +(pop_heap @i), 1..9;
print "@g" eq "1 2 3 4 5 6 7 8 9" ? "ok 5\n" : "not ok 5 # @g\n";

@h = (9,8,7,4,3,5,6,1,2);
make_heap_cmp { $b <=> $a } @h;
print "@h" eq "9 8 7 4 3 5 6 1 2" ? "ok 6\n" : "not ok 6 # @h\n";

@g = map +(pop_heap_cmp { $b <=> $a } @h), 1..9;
print "@g" eq "9 8 7 6 5 4 3 2 1" ? "ok 7\n" : "not ok 7 # @g\n";

@h = (2,1,6,5,3,4,7,8,9);
make_heap_cmp { $a <=> $b } @h;
print "@h" eq "1 2 4 5 3 6 7 8 9" ? "ok 8\n" : "not ok 8 # @h\n";

@h = ([4, "hi"], 3, [7], [9,5], [0]);
make_heap @h;
print $h[0][0] == 0 ? "ok 9\n" : "not ok 9\n";
print $h[1]    == 3 ? "ok 10\n" : "not ok 10\n";
print $h[2][0] == 7 ? "ok 11\n" : "not ok 11\n";
print $h[3][0] == 9 ? "ok 12\n" : "not ok 12\n";
print $h[4][0] == 4 ? "ok 13\n" : "not ok 13\n";

print @g == 9 ? "ok 14\n" : "not ok 14\n";
print @i == 0 ? "ok 15\n" : "not ok 15\n";
print @h == 5 ? "ok 16\n" : "not ok 16\n";

