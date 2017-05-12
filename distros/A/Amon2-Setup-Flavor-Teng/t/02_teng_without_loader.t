use strict;
use warnings;
use utf8;
use Amon2::Setup::Flavor;
use File::Path ();
use Test::More;
use Test::Requires +{ 'YAML::Tiny' => '1.46' };
use t::TestFlavor;
use t::Util;

my $flavor = Amon2::Setup::Flavor->new({module => 'My::App'});
test_flavor(sub {
    ok(-f 'lib/My/App.pm', 'lib/My/App.pm exists');
    $flavor->write_file('config/development.pl', <<'...');
use File::Spec;
use File::Basename qw(dirname);
my $basedir = File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..'));
my $dbpath;
if ( -d '/home/dotcloud/') {
    $dbpath = "/home/dotcloud/development.db";
} else {
    $dbpath = File::Spec->catfile($basedir, 'db', 'development.db');
}
+{
    'DBI' => [
        "dbi:SQLite:dbname=$dbpath",
        '',
        '',
        +{
            sqlite_unicode => 1,
        }
    ],
};
...

    File::Path::mkpath('db');
    open my $fh, '>:utf8', 'development.db' or die "Cannot open db";
    close $fh;
}, 'TengWithoutLoader');

done_testing;
