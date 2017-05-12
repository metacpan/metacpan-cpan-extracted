# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..32\n"; }
END {print "not ok 1\n" unless $loaded;}
@correct = ("3 2 1", "2 3 1", "2 1 3", "3 1 2", "1 3 2", "1 2 3");

use Algorithm::Permute qw(permute);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$perm = Algorithm::Permute->new([1..3]);
print ( $perm ? "ok 2\n" : "not ok 2\n");

# peek..
@peek = $perm->peek;
print "# @peek.\nnot " unless "@peek" eq $correct[0];
print "ok 3\n";

# next..
while (@res = $perm->next) {
    print "# @res.\nnot " unless "@res" eq $correct[$cnt++];
    print ("ok ". ($cnt + 3) . "\n");
}

# reset..
$cnt = 0;
$perm->reset;
while (@res = $perm->next) {
    print "# @res.\nnot " unless "@res" eq $correct[$cnt++];
    print "ok ". ($cnt + 9) . "\n";
}

print $cnt == 6 ? "ok 16\n" : "not ok 16\n";

# Tests for the callback interface by Robin Houston <robin@kitsite.com>

my @array = (1..9);
my $i = 0;
permute { ++$i } @array;

print ($i == 9*8*7*6*5*4*3*2*1 ? "ok 17\n" : "not ok 17\n");
print ($array[0] == 1 ? "ok 18\n" : "not ok 18\n");

@array = ();
$i = 0;
permute { ++$i } @array;
print ($i == 0 ? "ok 19\n" : "not ok 19\n");

@array = ('A'..'E');
my @foo;
permute { @foo = @array; } @array;

my $ok = ( join("", @foo) eq join("", reverse @array) );
print ($ok ? "ok 20\n" : "not ok 20\n");

tie @array, 'TieTest';
permute { $_ = "@array" } @array;
print (TieTest->c() == 600 ? "ok 21\n" : "not ok 21\t# ".TieTest->c()."\n");

untie @array;

##########################################
# test eval block outside of permute block
{
    my @array = (1..2);
    $i = 0;
    eval {
        permute {
            die if (++$i > 1 )
        } @array;
    };
    print "ok 22\n";
    eval { @array = (1..2); };                                      # try to change the array after die()
    print $@ ? 'not ' : '', "ok 23\n";
}

######################################
# test eval block inside permute block
@array = (qw/a r s e/);
$i = 0;
permute {eval {goto foo}; ++$i } @array;
if ($@ =~ /^Can't "goto" out/) {
    print "ok 24\n";
} else {
    foo: print "not ok 24\t# $@\n";
}
print ($i == 24 ? "ok 25\n" : "not ok 25\n");

{
    # test r of n permutation
    my %expected = map { $_ => 1 } qw/2_1 1_2 3_2 2_3 3_1 1_3/;
    my $p = Algorithm::Permute->new([1..3], 2);
    print ($p ? "ok 26\n" : "not ok 26\n");

    my $found;
    while (my @r = $p->next) {
        my $key = join('_', @r);
        # print "key: $key\n";
        $found = delete $expected{$key};
        break unless $found;
    }
    if (not $found or keys(%expected)) {
        print "not ok 27\n";
    } else {
        print "ok 27\n";
    }
}

######################
# test for memory leak

$^O !~ /linux/ || !$ENV{MEMORY_TEST} and do {
    for (28..32) { print "skipping $_: memory leak test\n" }
    exit 0;
};

# OO interface memory leak test
for ($i = 0;  $i < 10000;  $i++) {
    $perm->reset;
    while (@res = $perm->next) { }
    if ($i == 0) {
        $ok = check_mem(1);     # initialize
    }
    elsif ($i % 100  ==  99) {
        !$ok or $ok = check_mem();
    }
}
print $ok ? '' : 'not ', "ok 28\n";

for ($i = 0;  $i < 10000;  $i++) {
    @array = ('A'..'E');
    permute { } @array;

    if ($i == 0) {
        $ok = check_mem(1);     # initialize
    }
    elsif ($i % 100  ==  99) {
        !$ok or $ok = check_mem();
    }
}
print $ok ? '' : 'not ', "ok 29\n";

for ($i = 0;  $i < 10000;  $i++) {
    @array = ('A'..'E');
    eval { permute { die } @array };

    if ($i == 0) {
        $ok = check_mem(1);     # initialize
    }
    elsif ($i % 100  ==  99) {
        !$ok or $ok = check_mem();
    }
}
print $ok ? '' : 'not ', "ok 30\n";

{
    # test A::P destructor
    for ($i = 0;  $i < 10000;  $i++) {
        my $p = Algorithm::Permute->new([1..4]);
        while (@res = $p->next) { }
        if ($i == 0) {
            $ok = check_mem(1);     # initialize
        }
        elsif ($i % 100  ==  99) {
            !$ok or $ok = check_mem();
        }
    }
    print $ok ? '' : 'not ', "ok 31\n";
}

{
    # test A::P destructor, r of n permutation
    for ($i = 0;  $i < 10000;  $i++) {
        my $p = Algorithm::Permute->new([1..4], 3);
        while (@res = $p->next) { }
        if ($i == 0) {
            $ok = check_mem(1);     # initialize
        }
        elsif ($i % 100  ==  99) {
            !$ok or $ok = check_mem();
        }
    }
    print $ok ? '' : 'not ', "ok 32\n";
}

my $c;
package TieTest;
sub TIEARRAY  {bless []}
sub FETCHSIZE {5}
sub FETCH     { ++$c; $_[1]}
sub c         {$c}

package main;
sub check_mem {
    my $initialise = shift;
    # Log Memory Usage
    local $^W;
    my %mem;
    if (open(FH, "/proc/self/status")) {
        my $units;
        while (<FH>) {
            if (/^VmSize.*?(\d+)\W*(\w+)$/) {
                $mem{Total} = $1;
                $units = $2;
            }
            if (/^VmRSS:.*?(\d+)/) {
                $mem{Resident} = $1;
            }
        }
        close FH;

        print("# Mem Total: $mem{Total} $units, Resident: $mem{Resident} $units\n")
            if $ENV{MEMORY_TEST} > 1;

        if ($TOTALMEM != $mem{Total}) {
            warn("LEAK! : ", $mem{Total} - $TOTALMEM, " $units\n") unless $initialise;
            $TOTALMEM = $mem{Total};
            return $initialise ? 1 : 0;
        }

        return 1;
    }
}

