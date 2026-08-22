use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Config ();
use File::Spec ();
use ClamAV::Clamd;
use FakeClamd;

# --- the pointer itself -------------------------------------------------
{
    my $ptr = ClamAV::Clamd::_abi_ptr();

    # != 0, NOT > 0. The address is returned as a UV precisely because a
    # shared object can map with the top bit set - Solaris/illumos amd64
    # loads libraries high, and so does any 32-bit build in the upper
    # 2GB - where a signed read hands back a negative number and a
    # "> 0" check rejects a perfectly usable pointer.
    ok defined $ptr, '_abi_ptr returns something';
    ok $ptr != 0,    '  and it is not NULL';
}

# --- the table drives itself --------------------------------------------
# The provider's own suite must exercise the ABI the way a consumer does,
# not the way the XS above happens to.
{
    my $srv = FakeClamd->new(mode => 'literal',
                             literal => 'stream: Eicar-Test-Signature FOUND');
    my ($ver, $state, $sig, $transport) =
        ClamAV::Clamd::_abi_selftest($srv->path, 'anything');

    is $ver, 1, 'selftest reports the ABI version';
    is $state, 1, '  infected, through the table';
    is $sig, 'Eicar-Test-Signature', '  with the signature';
    is $transport, 2, '  over instream';
    $srv->stop;
}

{
    my $srv = FakeClamd->new(mode => 'literal',
                             literal => 'stream: Heuristics.Encrypted.Zip FOUND');
    my (undef, $state, $sig) = ClamAV::Clamd::_abi_selftest($srv->path, 'x');
    is $state, 2, 'unscannable comes through the table as unscannable';
    is $sig, 'Heuristics.Encrypted.Zip', '  with the heuristic name';
    $srv->stop;
}

{
    my $srv = FakeClamd->new(mode => 'literal', literal => 'stream: OK');
    my (undef, $state, $sig) = ClamAV::Clamd::_abi_selftest($srv->path, 'x');
    is $state, 0, 'clean comes through the table as clean';
    is $sig, undef, '  with no signature';
    $srv->stop;
}

# --- the states are the ones the header promises ------------------------
# A consumer compares against the constants in clamd_abi.h. If these ever
# drift the consumer silently mis-reads every verdict, so they are pinned.
{
    my $srv = FakeClamd->new(mode => 'literal', literal => 'no idea what this is');
    my (undef, $state) = ClamAV::Clamd::_abi_selftest($srv->path, 'x');
    is $state, 3, 'an unrecognised reply is ABI state 3 (error), never 0 (clean)';
    $srv->stop;
}

# --- a SEPARATE COMPILED CONSUMER ---------------------------------------
# The gate. Everything above shares this .so; a real consumer does not.
my $cdir = File::Spec->catdir($FindBin::Bin, 'abi_consumer');

SKIP: {
    skip 'no consumer directory', 1 unless -d $cdir;
    skip 'no make available', 1 unless $Config::Config{make};

    my $blib  = File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'blib');
    my $perl  = $^X;
    my $make  = $Config::Config{make};
    my $log   = File::Spec->catfile($cdir, 'build.log');

    my $ok = do {
        local $ENV{PERL5LIB} = join $Config::Config{path_sep},
            File::Spec->catdir($blib, 'lib'),
            File::Spec->catdir($blib, 'arch'),
            ($ENV{PERL5LIB} // ());
        system(qq{cd "$cdir" && "$perl" Makefile.PL >"$log" 2>&1 && $make >>"$log" 2>&1}) == 0;
    };

    unless ($ok) {
        diag "consumer build failed; see $log";
        if (open my $fh, '<', $log) { diag do { local $/; <$fh> } }
        skip 'could not build the consumer (no compiler?)', 1;
    }

    my $cblib = File::Spec->catdir($cdir, 'blib');
    my $srv   = FakeClamd->new(mode => 'literal',
                               literal => 'stream: Eicar-Test-Signature FOUND');
    my $sock  = $srv->path;

    # Run it in a fresh process: a consumer resolves the ABI at its own
    # boot, which is the thing being tested.
    my $script = <<"PERL";
use lib '@{[ File::Spec->catdir($blib,'lib') ]}', '@{[ File::Spec->catdir($blib,'arch') ]}';
use lib '@{[ File::Spec->catdir($cblib,'lib') ]}', '@{[ File::Spec->catdir($cblib,'arch') ]}';
use ClamAV::Clamd;
use TestConsumer;
my \$v = TestConsumer::abi_version();
my (\$state, \$sig, \$reason) = TestConsumer::scan('$sock', 'payload');
print "version=\$v state=\$state sig=" . (\$sig // '-') . "\\n";
PERL
    # The consumer croaks on skew, and croak writes to STDERR - so both
    # streams have to be captured or the failure looks like silence.
    my $sfile = File::Spec->catfile($cdir, 'run.pl');
    open my $sfh, '>', $sfile or die $!;
    print {$sfh} $script;
    close $sfh;

    my $run = sub {
        my $o = `"$perl" "$sfile" 2>&1`;
        return defined $o ? $o : '';
    };

    my $out = $run->();
    chomp $out;

    like $out, qr/version=1 state=1 sig=Eicar-Test-Signature/,
        'a separately compiled consumer scans through the ABI'
        or diag "consumer said: $out";

    # --- VERSION SKEW ---------------------------------------------------
    # A consumer built against a NEWER table than the provider ships must
    # DEGRADE - refuse clearly - not crash and not silently mis-read a
    # struct whose tail does not exist.
    my $skew = do { local $ENV{CLAMD_ABI_REQUIRE} = 99; $run->() };
    like $skew, qr/ABI version 1, need >= 99/,
        'a consumer wanting a newer ABI refuses with a clear message';
    unlike $skew, qr/state=/, '  and does not proceed to scan';

    # And the other direction: a consumer wanting an OLDER table must
    # keep working. The table is append-only, so a later version is a
    # superset whose prefix stays valid - checking == here instead of >=
    # is what broke Reverse::Proxy 0.04 against Fetch 0.14 on seven
    # CPAN Testers boxes.
    my $older = do { local $ENV{CLAMD_ABI_REQUIRE} = 1; $run->() };
    like $older, qr/state=1/,
        'a consumer built against an older ABI still works (>= not ==)';

    $srv->stop;
}

done_testing;
