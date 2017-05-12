#!perl

use strict;
use warnings;
use Test::More;


BEGIN {
    use_ok('Data::Validate::VIN');
}

##
## Start with a known good example
##

my $goodvin = '5J6HYJ8V55L009357';
my $good    = new_ok('Data::Validate::VIN' => [$goodvin] );

my %goodpieces = (
    vin        => $goodvin,
    wmi        => substr($goodvin,0,2),
    vds        => substr($goodvin,3,6),
    vis        => substr($goodvin,9,8),
    checkdigit => 5,
    year       => [2005],
);

# check components of the VIN
for ( keys(%goodpieces) ) {
    if ($_ =~ /year/) {
        is_deeply($good->get($_), $goodpieces{$_}, uc($_) . ' get() check - valid VIN');
    }
    else {
        is($good->get($_),$goodpieces{$_}, uc($_) . ' get() check - valid VIN');
    }
}

# make sure there are no errors
is(scalar( @{ $good->errors() } ), 0, 'errors() check - valid VIN');

# finally that we have a valid VIN
is($good->valid(),1,'valid() check - valid VIN');

##
## Now onto some broken VINs
##

my $badvin = $goodvin;
# add some illegal characters
$badvin =~ tr/VY/QI/;

# Should still return an object
my $bad = new_ok('Data::Validate::VIN' => [$badvin]);

# 1 error please
my $baderrs = $bad->errors();

# the error message should refer to the transliteration above
# let's see if it complains about I & Q
like(substr($baderrs->[0],-2), qr/[QI]/, 'Illegal characters found, as expected - invalid VIN');

# Now show us the full error
is( scalar(@$baderrs), 1, 'errors() check - invalid VIN: ' . "@$baderrs" );

# see what get() has to offer from this guy
badGets($bad,$badvin);

# finally for this object, valid test
is($bad->valid(),undef, 'valid() check - invalid VIN');


# now try a short VIN

my $shortvin = $goodvin;
chop($shortvin);

my $short = new_ok('Data::Validate::VIN' => [$shortvin]);

# 1 error please
my $shorterrs = $short->errors();

# make sure only 1 error was thrown
is( scalar(@$shorterrs),1, 'errors() check - invalid VIN: ' . "@$shorterrs" );

# the error should be about the length of the VIN
like($shorterrs->[0], qr/length/i, 'VIN too short, as expected - invalid VIN');

# what does get() get us?
badGets($short,$shortvin);

# and the valid check
is($short->valid(),undef,'valid() check - invalid VIN');

# test short VIN & illegal characters
my $verybadvin = $goodvin;
$verybadvin =~ tr/VY/QI/;
chop($verybadvin);

my $verybad = new_ok('Data::Validate::VIN' => [$verybadvin]);

# 2 errors please.
my $verybaderrs = $verybad->errors();

# make sure 2 errors were thrown
is( scalar(@$verybaderrs),2, 'errors() check - invalid VIN: ' . join("; " => @$verybaderrs) );

# test each error
for (@$verybaderrs) {
    like($_,qr/(?:Illegal|length)/, "Expected error - invalid VIN: $_");
}

# and get()
badGets($verybad,$verybadvin);

# test an unknown WMI. this also will break the check digit, so let's look for that too
my $badwmivin = $goodvin;
$badwmivin =~ s/^\S{2}/HA/;

my $badwmi = new_ok('Data::Validate::VIN' => [$badwmivin]);

# make sure we got 2 errors
my $badwmierrs = $badwmi->errors();
is( scalar(@$badwmierrs),2,'errors() check - invalid VIN: ' . join("; " => @$badwmierrs) );

# check the error messages themselves
for (@$badwmierrs) {
    like($_,qr/(?:WMI|Checkdigit)/, "Expected error - invalid VIN: $_");
}

# check a VIN with a bad char in 10th position
my $bad10thvin = $goodvin;
substr($bad10thvin,9,1,'U');

my $bad10th = new_ok('Data::Validate::VIN' => [$bad10thvin]);

# should have 2 errors: 10th position & check digit
my $bad10therrs = $bad10th->errors();
is( scalar(@$bad10therrs),2,'errors() check - invalid VIN: ' . join("; " => @$bad10therrs) );

# check the error messages
for (@$bad10therrs) {
    like($_,qr/(?:10th|Checkdigit)/,"Expected error - invalid VIN: $_");
}

# check for both undef and empty string passed
for ('',undef) {
    my $empty = new_ok('Data::Validate::VIN' => [$_]);
    my $emptyerrs = $empty->errors();
    is( scalar(@$emptyerrs),1,'errors() check - invalid VIN: ' . "@$emptyerrs" );
    like($emptyerrs->[0],qr/No VIN supplied/,'Expected error - invalid VIN: ' . $emptyerrs->[0]);
}

for ('$', '#', '123', '^&') {
    my $verybad2 = new_ok('Data::Validate::VIN' => [$_]);
    my $verybaderrs2 = $verybad2->errors();
    ok scalar(@$verybaderrs2), "Invalid: $_";
}

done_testing();

sub badGets {
    my($obj,$_vin) = @_;

    for(qw{vin wmi vds vis checkdigit year}) {
        if ($_ =~/vin/) {
            is($obj->get($_),$_vin, uc($_) . ' get() check - invalid VIN');
        }
        else {
            is($obj->get($_),undef,uc($_) . ' get() check - invalid VIN');
        }
    }
    return;
}
