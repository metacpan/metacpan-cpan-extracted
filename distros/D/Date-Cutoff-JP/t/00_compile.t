use strict;
use Test::More 0.98 tests => 27;

use lib './lib';

use_ok $_ for qw(Date::Cutoff::JP);                                                     # 1
my $dco = new_ok('Date::Cutoff::JP');                                                   # 2

is eval{ $dco->cutoff(-1) }, undef, "Fail to assign too small cutoff";                  # 3
like $@, qr/^unvalid cutoff was set: -1/, "correct error was caught";                   # 4
is eval{ $dco->cutoff(29) }, undef, "Fail to assign too big cutoff";                    # 5
like $@, qr/^unvalid cutoff was set: 29/, "correct error was caught";                   # 6

is eval{ $dco->payday(-1) }, undef, "Fail to assign too small payday";                  # 7
like $@, qr/^unvalid payday was set: -1/, "correct error was caught";                   # 8
is eval{ $dco->payday(29) }, undef, "Fail to assign too big payday";                    # 9
like $@, qr/^unvalid payday was set: 29/, "correct error was caught";                   #10

is eval{ $dco->late(-1) }, undef, "Fail to assign too small lateness";                  #11
like $@, qr/^unvalid lateness was set: -1/, "correct error was caught";                 #12
is eval{ $dco->late(4) }, undef, "Fail to assign too big lateness";                     #13
like $@, qr/^unvalid lateness was set: 4/, "correct error was caught";                  #14

$dco = Date::Cutoff::JP->new({ cutoff => 10, late => 0 }); # payday is 0 automatically

is eval{ $dco->payday(1) }, undef, "Fail to assign too ealier payday";                  #15
like $@, qr/^payday must be after cuttoff/, "correct error was caught";                 #16
is eval{ $dco->payday(10) }, undef, "Fail to assign payday that is equal to cutoff";    #17
like $@, qr/^payday must be after cuttoff/, "correct error was caught";                 #18
is $dco->payday(0), 0, "Succeed to assign payday correctly with 0";                     #19
is $dco->payday(11), 11, "Succeed to assign payday correctly";                          #20
is eval{ $dco->cutoff(20) }, undef, "Fail to assign too later cutoff";                  #21
like $@, qr/^cuttoff must be before payday/, "correct error was caught";                #22
is eval{ $dco->cutoff(0) }, undef, "Fail to assign too later cutoff with 0";            #23
like $@, qr/^cuttoff must be before payday/, "correct error was caught";                #24
is $dco->cutoff(1), 1, "Succeed to assign cutoff correctly";                            #25

$dco = Date::Cutoff::JP->new(); # use default
is eval{ $dco->late(0) }, undef, "Fail to assign invalid lateness";                     #26
like $@, qr/^payday is before cuttoff in same month/, "correct error was caught";       #27


done_testing;
