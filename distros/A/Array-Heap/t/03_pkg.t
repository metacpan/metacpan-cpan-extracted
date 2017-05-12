print "1..2\n";

use Array::Heap;

package a;

our @b;
our @a = qw(a b c);
Array::Heap::make_heap_cmp { $b cmp $a } @a;

print $a[0] eq "c" ? "" : "not ", "ok 1\n";

package b;

our @b;
our @a = qw(a b c);
Array::Heap::make_heap_cmp { $b cmp $a } @a;
print $a[0] eq "c" ? "" : "not ", "ok 2\n";
