use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use Bioconda::Packages::DB;

my $dir = tempdir(CLEANUP => 1);

my $data = {
    meta     => { package_count => 1, removed_count => 0 },
    packages => {
        foo => { name => 'foo', current_version => '1.0', is_removed => \0 },
    },
};

# Plain JSON round-trip.
my $plain = File::Spec->catfile($dir, 'db.json');
Bioconda::Packages::DB->save($plain, $data);
ok(-s $plain, 'plain db written');
my $back = Bioconda::Packages::DB->load($plain);
is($back->{packages}{foo}{current_version}, '1.0', 'plain round-trip');

# Gzipped round-trip.
my $gz = File::Spec->catfile($dir, 'db.json.gz');
Bioconda::Packages::DB->save($gz, $data);
ok(-s $gz, 'gz db written');
my $bgz = Bioconda::Packages::DB->load($gz);
is($bgz->{packages}{foo}{current_version}, '1.0', 'gz round-trip');
cmp_ok(-s $gz, '<', -s $plain, 'gz is smaller than plain');

# locate_db honours an explicit path and the env var.
is(Bioconda::Packages::DB->locate_db($plain), $plain, 'explicit path wins');
{
    local $ENV{BIOCONDA_PACKAGES_DB} = $gz;
    is(Bioconda::Packages::DB->locate_db, $gz, 'env var honoured');
}

done_testing;
