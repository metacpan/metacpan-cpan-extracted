BEGIN { $| = 1; print "1..8\n" }
END { print "not ok 1\n" unless $loaded }
use Fcntl;
use DWH_File;

$loaded = 1;

eval { require 5.005 };
if ( $@ ) {
    print "1..0 # Skip This test requires at least perl 5.005\n";
    exit;
}

########################################################################
# Test array operations
#
# 
########################################################################

tie my %dwh, 'DWH_File', '_test_04', O_RDWR | O_CREAT, 0644;

####### 1 ######

# some arrays to manipulate now and check now and later
$dwh{ a1 } = [ qw( en elefant kom marcherende ) ];
$dwh{ a2 } = [ qw( som en rejselysten flaade ) ];
$dwh{ a3 } = [ qw( du gav os de blomster som lyste imod os ) ];
$dwh{ a4 } = [ qw( hvidt herude ) ];

# some to manipulate now and check later
$dwh{ now_later } = {
        b1 => [ qw( jeg har fanget mig en myg ) ],
        b2 => [ qw( bamse og kylling i natten ) ],
        b3 => [ qw( under den hvide bro ) ],
        b4 => [ qw( staar urt og busk i skjul ) ],
    };

# some to manipulate and check later
$dwh{ later } = [
        [ qw( en yndig og frydefuld sommertid ) ],
        [ qw( jeg kan se paa dine oejne ) ],
        [ qw( og granerne duppes ) ]
    ];

my $shift1 = shift @{ $dwh{ a1 } };

if ( $shift1 eq "en" and @{ $dwh{ a1 } } == 3 and
     $dwh{ a1 }->[ 0 ] eq "elefant" and
     $dwh{ a1 }->[ 1 ] eq "kom" and
     $dwh{ a1 }->[ 2 ] eq "marcherende" ) {
    print "ok 1\n";
}
else { print "not ok 1\n" }

######## 2 #######

my $pop1 = pop @{ $dwh{ a2 } };

if ( $pop1 eq "flaade" and
     @{ $dwh{ a2 } } == 3 and
     $dwh{ a2 }->[ 0 ] eq "som" and
     $dwh{ a2 }->[ 2 ] eq "rejselysten" and
     not defined $dwh{ a2 }->[ 3 ] ) {
    print "ok 2\n";
}
else { print "not ok 2\n" }

######## 3 ########

push @{ $dwh{ a3 } }, qw( med alfelet skoenhed );

if ( @{ $dwh{ a3 } } == 12 and
     $dwh{ a3 }->[ 11 ] eq "skoenhed" and
     $dwh{ a3 }->[ 10 ] eq "alfelet" and
     $dwh{ a3 }->[ 9 ] eq "med" and
     $dwh{ a3 }->[ 8 ] eq "os" and
     $dwh{ a3 }->[ 7 ] eq "imod" and
     $dwh{ a3 }->[ 0 ] eq "du" and
     $dwh{ a3 }->[ 1 ] eq "gav" and
     not defined $dwh{ a3 }->[ 12 ] ) {
    print "ok 3\n";
}
else { print "not ok 3\n" }

######### 4 ########

my @sut = splice @{ $dwh{ a3 } }, 2, 5, qw( huba fyt );

if ( $sut[ 0 ] eq 'os' and
     $sut[ 1 ] eq 'de' and
     $sut[ 2 ] eq 'blomster' and
     $sut[ 3 ] eq 'som' and
     $sut[ 4 ] eq 'lyste' ) {
   print "ok 4\n";
}
else { print "not ok 4\n" }

######### 5 ##########

if ( @{ $dwh{ a3 } } == 9 and
     $dwh{ a3 }->[ 0 ] eq 'du' and
     $dwh{ a3 }->[ 1 ] eq 'gav' and
     $dwh{ a3 }->[ 2 ] eq 'huba' and
     $dwh{ a3 }->[ 3 ] eq 'fyt' and
     $dwh{ a3 }->[ 4 ] eq 'imod' and
     $dwh{ a3 }->[ 5 ] eq 'os' and
     $dwh{ a3 }->[ 6 ] eq 'med' and
     $dwh{ a3 }->[ 7 ] eq 'alfelet' and
     $dwh{ a3 }->[ 8 ] eq 'skoenhed' ) {
   print "ok 5\n";
}
else { print "not ok 5\n" }

######### 6 #########

splice @{ $dwh{ a1 } }, 2, 0, qw( fabu gnema gruf );

if ( @{ $dwh{ a1 } } == 6 and
     $dwh{ a1 }->[ 0 ] eq "elefant" and
     $dwh{ a1 }->[ 1 ] eq "kom" and
     $dwh{ a1 }->[ 2 ] eq "fabu" and
     $dwh{ a1 }->[ 3 ] eq "gnema" and
     $dwh{ a1 }->[ 4 ] eq "gruf" and
     $dwh{ a1 }->[ 5 ] eq "marcherende" ) {
    print "ok 6\n";
}
else { print "not ok 6\n" }

######### 7 #########

splice @{ $dwh{ a3 } }, 2, 3;

if ( @{ $dwh{ a3 } } == 6 and
     $dwh{ a3 }->[ 0 ] eq 'du' and
     $dwh{ a3 }->[ 1 ] eq 'gav' and
     $dwh{ a3 }->[ 2 ] eq 'os' and
     $dwh{ a3 }->[ 3 ] eq 'med' and
     $dwh{ a3 }->[ 4 ] eq 'alfelet' and
     $dwh{ a3 }->[ 5 ] eq 'skoenhed' ) {
   print "ok 7\n";
}
else { print "not ok 7\n" }

######### 8 #########

unshift @{ $dwh{ a4 } }, qw( det er );

if ( @{ $dwh{ a4 } } == 4 and
     $dwh{ a4 }->[ 0 ] eq "det" and
     $dwh{ a4 }->[ 1 ] eq "er" and
     $dwh{ a4 }->[ 2 ] eq "hvidt" and
     $dwh{ a4 }->[ 3 ] eq "herude" ) {
    print "ok 8\n";
} else { print "not ok 8\n" }

# make some changes but don't check results in this script

push @{ $dwh{ now_later }->{ b1 } }, qw( smeltet fedtet af den );
pop @{ $dwh{ now_later }->{ b2 } };
splice @{ $dwh{ now_later }->{ b3 } }, 1, 0, qw( protest og );
shift @{ $dwh{ now_later }->{ b2 } };
unshift @{ $dwh{ now_later }->{ b4 } }, qw( i sne );
splice @{ $dwh{ now_later }->{ b4 } }, 4, 2;

# expected results:
#$dwh{ now_later } = {
#        b1 => [ qw( jeg har fanget mig en myg smeltet fedtet af den ) ],
#        b2 => [ qw( og kylling i ) ],
#        b3 => [ qw( under protest og den hvide bro ) ],
#        b4 => [ qw( i sne staar urt i skjul ) ],
#    };

untie %dwh;
