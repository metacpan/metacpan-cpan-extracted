# t/06-hash-nested.t
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);

use Datafile::Hash qw(readhash writehash);

mkdir "$Bin/data"  if ! -d "$Bin/data";
my $deep_file = "$Bin/data/deep.ini";

my %deep = (
    app => {
        name    => 'My App',
        version => '1.0',
        features => {
            login => 'enabled',
            theme => 'dark',
        },
    },
    logging => {
        level => 'debug',
        file  => '"/var/log/app.log"',  # should be quoted on write
    },
);

writehash($deep_file, \%deep);

my %r;
readhash($deep_file, \%r);

is($r{app}{features}{theme}, 'dark', "Deep nesting works");
like($r{logging}{file}, qr/^"?\/var\/log\/app\.log"?$/, "Path preserved");

unlink $deep_file;
done_testing;
