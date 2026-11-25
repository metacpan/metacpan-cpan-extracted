use strict;
use warnings;
use Test::More;
use Bioconda::Packages::Updater;

# The progressive database version: YYYY.M.N, N resets per month.
my $v = Bioconda::Packages::Updater::_next_db_version(undef);
like($v, qr/^\d{4}\.\d{1,2}\.\d+$/, 'version has YYYY.M.N shape');

# Same month increments the patch.
if ($v =~ /^(\d+)\.(\d+)\.(\d+)$/) {
    my ($y, $m) = ($1, $2);
    is(Bioconda::Packages::Updater::_next_db_version("$y.$m.1"), "$y.$m.2",
       'same month bumps patch');
    is(Bioconda::Packages::Updater::_next_db_version("$y.$m.9"), "$y.$m.10",
       'patch goes past 9 (sorts under SemVer, not alphanumerically)');
    # A version from a previous month resets to .1 in the current month.
    my $prevm = $m == 1 ? "$y.12.5" : sprintf('%d.%d.5', $y, $m - 1);
    is(Bioconda::Packages::Updater::_next_db_version($prevm), "$y.$m.1",
       'different month resets patch to 1');
}

# --- content signature: ignores volatile fields, reacts to real changes ------
my $base = {
    samtools => {
        name => 'samtools', current_version => '1.25',
        depends => { run => [{name=>'perl'}] },
        first_seen => 'A', last_seen => 'A', removed_at => undef, downloads => 1,
    },
};
my $sig = \&Bioconda::Packages::Updater::_content_signature;

my $s0 = $sig->($base);

# Changing only volatile fields must NOT change the signature.
my $volatile = {
    samtools => { %{ $base->{samtools} },
                  first_seen => 'B', last_seen => 'Z', downloads => 999999 },
};
is($sig->($volatile), $s0, 'volatile fields (timestamps, downloads) ignored');

# Changing the version IS a real change.
my $changed = {
    samtools => { %{ $base->{samtools} }, current_version => '1.26' },
};
isnt($sig->($changed), $s0, 'a version change changes the signature');

# Adding a package is a real change.
my $added = { %$base, bwa => { name => 'bwa', current_version => '0.7.19' } };
isnt($sig->($added), $s0, 'adding a package changes the signature');

# Changing a dependency is a real change.
my $dep = {
    samtools => { %{ $base->{samtools} },
                  depends => { run => [{name=>'perl'},{name=>'zlib'}] } },
};
isnt($sig->($dep), $s0, 'a dependency change changes the signature');

done_testing;
