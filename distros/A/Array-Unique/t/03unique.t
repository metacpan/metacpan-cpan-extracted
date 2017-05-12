
# TODO:
# return @u = (@a, @b);
# this returns strange, (undefined ?) value

use strict;
use warnings;
use Test::More;
plan tests => (29);


# ---------------------------------------------------
# Check if module is loading
# ---------------------------------------------------
eval { require Array::Unique; };
is($@, '', 'Load module Array::Unique');
die $@ if $@;

# ---------------------------------------------------
# New instance creation
# ---------------------------------------------------
my @a;
my $o;

my @b; # help variables
my $b;

eval {$o = tie @a, 'Array::Unique';};
is($@, '', 'tie-ing an array');
die $@ if $@;


@b = @a = qw(a b c a d a b q a);
is(@a, 5, 'length is correct');
is_deeply(\@a, [qw(a b c d q)], 'create an array where there were dupplicates');

is($a[0],  "a", 'fetch the value of element 0');
is($a[3],  "d", 'fetch the value of element 3');
is($a[10],  undef, 'fetch the value of too high index');
is($a[-1], "q", 'fetch the value of element -1');
is($a[-2], "d", 'fetch the value of element -2');



TODO: {
    local $TODO = 'transferes the length of the original list and we
    get undefs at the end';
is(@b, 5, 'length is correct');
is_deeply(\@b, [qw(a b c d q)], 'transfere assignment');
}

@b=@a;
is(@b, 5, 'length is correct');


$b = $a[4] = 'b';
is_deeply(\@a, [qw(a b c d)], 'replace a value with an existing value');
TODO: {
  local $TODO='passing the new value not the one received';
is($b, 'b', 'assigned value gets transfered');

}

$b = $a[1] = 'x';
is_deeply(\@a, [qw(a x c d)], 'replace a value with a new value');
is($b, 'x', 'assigned value gets transfered');


$b = $a[1] = 'd';
is_deeply(\@a, [qw(a d c)], 'replace a value with an existing value');
is($b, 'd', 'assigned value gets transfered');


$b = $a[1] = 'd';
is_deeply(\@a, [qw(a d c)], 'replace a value in the same location');
is($b, 'd', 'assigned value gets transfered');


$b = $a[6] = 'a';
is_deeply(\@a, [qw(a d c)], '');
TODO: {
  local $TODO='passing the new value not the one received';
is($b, 'a', 'assigned value gets transfered');
}



# ---------------------------------------------------
# Set the value of negative indexes
# ---------------------------------------------------
@a = qw(a b c d e);

$b = $a[-1] = "a";
is_deeply(\@a, [qw(a b c d)], 'Set the value of negative indexes, -1');
TODO: {
  local $TODO='passing the new value not the one received';
is($b, 'a', 'assigned value gets transfered');
}

$b = $a[-2] = "d";
is_deeply(\@a, [qw(a b d)], 'Set the value of negative indexes -2');
is($b, 'd', 'assigned value gets transfered');



$#a=1;
is_deeply(\@a, [qw(a b)], 'change the size of the array');

is($#a, 1, 'highest index corect');

is(@a, 2, 'size correct');


=pod

# ---------------------------------------------------
# push
# ---------------------------------------------------
push @a, qw;
ok("@a" eq "a b");
#print "DEBUG: '@a'\n";

push @a, 'c', 'd';
ok("@a" eq "a b c d");
#print "DEBUG: @a\n";

push @a, qw(x y d z a);
ok("@a" eq "a b c d x y z");
#print "DEBUG: @a\n";

=cut


TODO: {
   local $TODO = 'wait';


}
__END__




# ---------------------------------------------------
# splice
# ---------------------------------------------------
my @b = splice(@a, 2, 3);
ok("@b" eq "c d x");
#print "DEBUG: '@b'\n";
ok("@a" eq "a b y z");
#print "DEBUG: '@a'\n";

@b = splice(@a, 2, 1, qw(z a u));
ok("@b" eq "y");
#print "DEBUG: '@b'\n";
ok("@a" eq "a b z u");
#print "DEBUG: '@a'\n";

# ---------------------------------------------------
# splice with negative values
# ---------------------------------------------------
@a = qw(a b c d e f g h i j k l);
@b = splice (@a, -1);
is_deeply(\@b, [qw(l)], '');
#print "DEBUG: '@b'\n";
is_deeply(\@a, [qw(a b c d e f g h i j k)],'');
#print "DEBUG: '@a'\n";

@b = splice (@a, -7, 4, qw(z));
is_deeply(\@b, [qw(e f g h)], '');
#print "DEBUG: '@b'\n";
is_deeply(\@a, [qw(a b c d z i j k)], '');
#print "DEBUG: '@a'\n";


# ---------------------------------------------------
# unshift
# ---------------------------------------------------
@a = qw(a b z u);
unshift @a, qw(d a w);
is_deeply(\@a, [qw(d a w b z u)], '');
#print "DEBUG: '@a'\n";


# ---------------------------------------------------
# pop
# ---------------------------------------------------
my $p = pop(@a);
is($p, "u", '');
is_deeply(\@a, [qw(d a w b z)], '');

# ---------------------------------------------------
# shift
# ---------------------------------------------------
my $s = shift @a;
is($s, "d", '');
is_deeply(\@a, [qw(a w b z)], '');

