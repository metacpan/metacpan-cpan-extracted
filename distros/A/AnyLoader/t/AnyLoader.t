# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)
use strict;

use vars qw($Total_tests);

my $loaded;
my $test_num = 1;
BEGIN { $| = 1; $^W = 1; }
END {print "not ok $test_num\n" unless $loaded;}
print "1..$Total_tests\n";
use AnyLoader;
$loaded = 1;
ok(1, 'compile');
######################### End of black magic.

# Utility testing functions.
sub ok {
    my($test, $name) = @_;
    print "not " unless $test;
    print "ok $test_num";
    print " - $name" if defined $name;
    print "\n";
    $test_num++;
}

sub eqarray  {
    my($a1, $a2) = @_;
    return 0 unless @$a1 == @$a2;
    my $ok = 1;
    for (0..$#{$a1}) { 
        unless($a1->[$_] eq $a2->[$_]) {
        $ok = 0;
        last;
        }
    }
    return $ok;
}

# Change this to your # of ok() calls + 1
BEGIN { $Total_tests = 7 }

use AnyLoader;
use FindBin qw($Bin);
use lib ($Bin);

ok( Text::Soundex::soundex('schwern') eq 'S650' );
ok( Testing::AnyLoader::some_func() == 23 );
ok( Testing::AnyLoader::some_other_func() == 42 );

# Test to make sure DESTROY is not messed with.
eval {
    local $SIG{__WARN__} = sub { die @_ };

    my $obj = bless [], "Foo";
    undef $obj;
};
ok( !$@ );

eval {
    local $SIG{ALRM} = sub { die "SUPPLIES!\n" };
    alarm(1);
    Text::Soundex::fooble();
};
alarm(0);

ok( $@ && $@ ne "SUPPLIES!\n" );


eval {
    local $SIG{ALRM} = sub { die "SUPPLIES!\n" };
#    alarm(1);
    Testing::AnyLoader::i_dont_exist();
};
alarm(0);

ok( $@ && $@ ne "SUPPLIES!\n" );
