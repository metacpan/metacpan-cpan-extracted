use lib 'blib/lib';
use strict;
use warnings;
use Test::More tests => 100;
use Data::Dumper;
use File::Copy qw(copy);
$ENV{BLZFILE} ||= 't/testblz.dat';

my $make_test;
my $from = '00';
my $to = 'A1';
BEGIN {
    use_ok('Business::DE::KontoCheck');
	$| = 1;
	$make_test = ($ARGV[0] && $ARGV[0] eq 'test') ? 0 : 1;
}
$Business::DE::KontoCheck::CACHE_ON = 1;
$Business::DE::KontoCheck::CACHE_ALL = 0;
# write test blz file
my $blzfile = $ENV{BLZFILE};
SKIP: {
    #skip (
    #    "No BLZFILE to test, skip (set env BLZFILE to the path if you want to test)",
    #76) unless defined $blzfile;
    open TEST, "<./t/test.dat" or die $!;
    chomp(my @lines = <TEST>);
    close TEST;
    my $kcheck = Business::DE::KontoCheck->new(
        BLZFILE => $ENV{BLZFILE},
        MODE_BLZ_FILE => 'BANK'
    );
    #my $kcheck = Business::DE::KontoCheck->new(
    #	BLZFILE => "./new.txt",
    #	MODE_BLZ_FILE => 'MINIMAL'
    #);
    exit unless defined $kcheck;
    foreach my $ix (0..$#lines) {
        my ($method, $blz, $knrs) = split /;/, $lines[$ix];
        next if $lines[$ix] =~ m/^#/;
        next if $method lt $from;
        last if $method gt $to;
        my @knrs = grep {m/\d+/} split /[ ,]+/, $knrs;
        my $soll = @knrs;
        my $ist = 0;
        foreach my $kix (0..$#knrs) {
            my $kontonr = $knrs[$kix];
            #print "testing BLZ ($blz), KNR ($kontonr)\n";
            #print "$method\r";
            my $konto = $kcheck->check(
                BLZ     => $blz,
                KONTONR => $kontonr,
            );
            if (my $res = $konto->check) {
                #print "ok $method.$kix\r" unless $make_test;
                #print "Account number ok ($method, $blz, $kontonr)\n" if !$make_test;
                $ist++;
            }
            elsif (!defined $res) {
                # account number invalid
                print "Account number invalid ($method, $blz, $kontonr)\n" if !$make_test;
            }
            else {
                my $err_string = $konto->printErrors();
                my $err_codes = $konto->getErrors();
                if ($err_codes->[0] eq 'ERR_METHOD') {
                    print "ok $method.$kix\r" unless $make_test;
                    print "m$method not implemented yet @$err_codes\n" unless $make_test;
                    $ist++;
                }
                else {
                    warn "blz $blz method $method $err_string";
                    #print "not ok $method.$kix\n";
                    #sleep 1;
                }
            }
        }
        cmp_ok($ist, '==', $soll, "method $method, BLZ $blz");
    }
}
{
    my $kcheck = Business::DE::KontoCheck->new(
        BLZFILE => $ENV{BLZFILE},
        MODE_BLZ_FILE => 'BANK'
    );
    my $konto = $kcheck->get_info_for_blz("10090000");
    #warn Data::Dumper->Dump([\$konto], ['konto']);
    my $name = $konto ? $konto->get_bankname() : '';
    cmp_ok($name, 'eq', 'Berliner Volksbank', "get_bankname");
}
