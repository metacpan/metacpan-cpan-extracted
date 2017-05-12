
#$Id: xs_subs.t 26 2006-04-16 15:18:52Z demerphq $#

use vars qw/$XTRA/;
use Test::More tests=>10+($XTRA=26);

BEGIN {
    use_ok( 'Data::Dump::Streamer', qw(
        Dump readonly hidden_keys legal_keys lock_keys lock_ref_keys
        lock_keys_plus lock_ref_keys_plus ));
}

# from Scalar::Util readonly.t

ok(readonly(1),'readonly(1)');

my $var = 2;
ok(!readonly($var),'$var = 2; readonly($var)');
ok($var == 2,'$var==2');


ok(readonly("fred"),'readonly("fred")');

$var = "fred";
ok(!readonly($var),'$var = fred; readonly($var)');
ok($var eq "fred",'$var eq "fred"');

$var = \2;
ok(!readonly($var),'$var=\2; readonly($var)');
ok(readonly($$var),'readonly($$var)');
ok(!readonly(*STDOUT),'readonly(*STDOUT)');

# new
SKIP:{
    skip "No locked key semantics before 5.8.0",
        $XTRA
        if $]<5.008;
{
    my %hash=map { $_ => 1 } qw( a b c d e f);
    delete $hash{c};
    lock_keys(%hash);
    ok(Internals::SvREADONLY(%hash),'lock_keys');

    # we do this skip here just to make sure lock_keys is correctly setup.
    skip "Cant tell if a key is locked in 5.8.0",
        $XTRA - 1
        if $]==5.008;

    delete @hash{qw(b e)};
    my @hidden=sort(hidden_keys(%hash));
    my @legal=sort(legal_keys(%hash));
    my @keys=sort(keys(%hash));
    #warn "@legal\n@keys\n";
    is("@hidden","b e",'lock_keys @hidden');
    is("@legal","a b d e f",'lock_keys @legal');
    is("@keys","a d f",'lock_keys @keys');
}
{
    my %hash=(0..9);
    lock_keys(%hash);
    ok(Internals::SvREADONLY(%hash),'lock_keys');
    Hash::Util::unlock_keys(%hash);
    ok(!Internals::SvREADONLY(%hash),'unlock_keys');
}
{
    my %hash=(0..9);
    lock_keys(%hash,keys(%hash),'a'..'f');
    ok(Internals::SvREADONLY(%hash),'lock_keys args');
    my @hidden=sort(hidden_keys(%hash));
    my @legal=sort(legal_keys(%hash));
    my @keys=sort(keys(%hash));
    is("@hidden","a b c d e f",'lock_keys() @hidden');
    is("@legal","0 2 4 6 8 a b c d e f",'lock_keys() @legal');
    is("@keys","0 2 4 6 8",'lock_keys() @keys');
}
{
    my %hash=map { $_ => 1 } qw( a b c d e f);
    delete $hash{c};
    lock_ref_keys(\%hash);
    ok(Internals::SvREADONLY(%hash),'lock_ref_keys');
    delete @hash{qw(b e)};
    my @hidden=sort(hidden_keys(%hash));
    my @legal=sort(legal_keys(%hash));
    my @keys=sort(keys(%hash));
    #warn "@legal\n@keys\n";
    is("@hidden","b e",'lock_ref_keys @hidden');
    is("@legal","a b d e f",'lock_ref_keys @legal');
    is("@keys","a d f",'lock_ref_keys @keys');
}
{
    my %hash=(0..9);
    lock_ref_keys(\%hash,keys %hash,'a'..'f');
    ok(Internals::SvREADONLY(%hash),'lock_ref_keys args');
    my @hidden=sort(hidden_keys(%hash));
    my @legal=sort(legal_keys(%hash));
    my @keys=sort(keys(%hash));
    is("@hidden","a b c d e f",'lock_ref_keys() @hidden');
    is("@legal","0 2 4 6 8 a b c d e f",'lock_ref_keys() @legal');
    is("@keys","0 2 4 6 8",'lock_ref_keys() @keys');
}
{
    my %hash=(0..9);
    lock_ref_keys_plus(\%hash,'a'..'f');
    ok(Internals::SvREADONLY(%hash),'lock_ref_keys args');
    my @hidden=sort(hidden_keys(%hash));
    my @legal=sort(legal_keys(%hash));
    my @keys=sort(keys(%hash));
    is("@hidden","a b c d e f",'lock_ref_keys_plus() @hidden');
    is("@legal","0 2 4 6 8 a b c d e f",'lock_ref_keys_plus() @legal');
    is("@keys","0 2 4 6 8",'lock_ref_keys_plus() @keys');
}
{
    my %hash=(0..9);
    lock_keys_plus(%hash,'a'..'f');
    ok(Internals::SvREADONLY(%hash),'lock_keys args');
    my @hidden=sort(hidden_keys(%hash));
    my @legal=sort(legal_keys(%hash));
    my @keys=sort(keys(%hash));
    is("@hidden","a b c d e f",'lock_keys_plus() @hidden');
    is("@legal","0 2 4 6 8 a b c d e f",'lock_keys_plus() @legal');
    is("@keys","0 2 4 6 8",'lock_keys_plus() @keys');
}
}
