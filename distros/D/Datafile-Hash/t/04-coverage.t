# t/04-coverage.t
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);

use Datafile::Hash qw(readhash writehash);

mkdir "$Bin/data"  if ! -d "$Bin/data";
my $flat_file = "$Bin/data/hash_flat.txt";
my $ini_file  = "$Bin/data/config.ini";

my %data = (
    host     => 'localhost',
    port     => 8080,
    debug    => 'true',
);

my %config = (
    global   => { debug => 'on' },
    database => {
        host => 'db.example.com',
        port => 5432,
        name => 'app#db',
    },
    cache => {
        type => 're dis',
        ttl  => 3600,
        xxx  => '',
    },
);
my ($rc,$msgs);
my %read=();

($rc)=writehash($flat_file, \%data, {
    comment_char => '#',
    group        => 0,  # flat
    # all other defaults to satify coverage
    prot         => 0660,
    backup       => 1,
    verbose      => 1,
});
ok $rc > 0, 'write succeeded';
ok -f $flat_file, 'file created';

($rc, $msgs) = readhash($flat_file, \%read, {
    comment_char => '#',
    group        => 1,  # flat
    # all other defaults to satify coverage
    skip_empty   => 0,
    skip_headers => 1,
    key_fields   => 1,
    comment_char => '#',
    verbose      => 1,
});
ok($rc > 0, "Read flat entries");

($rc, $msgs) = readhash($flat_file, undef, {
    delimiter    => ':',
});
is($rc, -1, "no hash field given on 2nd parameter");

($rc, $msgs) = readhash($flat_file, \%read, {
    delimiter    => ':',
    search       => 'aaaaa',
    key_fields   => 15,
});
is($rc, 0, "force key fields to large");

($rc) = writehash($flat_file, \%data, {
    delimiter    => ':',
    # all other defaults to satify coverage
    prot         => 0660,
    skip_headers => 1,
    backup       => 1,
    verbose      => 1,
});
is($rc, 3, "duplicate write");
ok($rc > 0, 'write succeeded');
ok -f $flat_file.'.bak', 'backup file created';
unlink $flat_file.'.bak'  if -f $flat_file.'.bak';

unlink $flat_file;
($rc, $msgs) = readhash($flat_file, \%read, {
    delimiter    => ':',
    search       => 'aaaaa',
});
is($rc, 0, "file does not exists");

writehash($flat_file, \%data, {
    delimiter    => ';',
    comment_char => '%',
    comment      => ['aaaa', 'bbb'],
    # all other defaults to satify coverage
    prot         => 0660,
    skip_headers => 1,
    backup       => 0,
    verbose      => 1,
});
($rc, $msgs) = readhash($flat_file, \%read, {
    delimiter    => ';',
    comment_char => '#',
    search       => ['aaaaa',undef,'/b..[bc]ccc/','localhost'],
});
is($rc, 0, "0 entries found");

writehash($flat_file, undef, {
    delimiter    => ';',
});
is($rc, 0, "no hash field given as param 2");
unlink $flat_file;

($rc) = writehash('/tmpiohoihoi/aaa.xxx', \%data, {
    delimiter    => ':',
});
is($rc, 0, "filedirectory not correct");

#### ini part for more coverage ####

writehash($ini_file, \%config, {
    # all other defaults to satify coverage
    prot         => 0660,
    skip_headers => 1,
    backup       => 0,
});

writehash($ini_file, \%config, {
    # all other defaults to satify coverage
    prot         => 0660,
    skip_headers => 1,
    backup       => 1,
    verbose      => 1,
});
ok -f $ini_file.'.bak', 'backup file created';
unlink $ini_file.'.bak'  if -f $ini_file.'.bak';

($rc, $msgs) = readhash($ini_file, \%read, {
    delimiter    => ':',
    comment_char => '#',
    group        => 1,  # flat
    # all other defaults to satify coverage
    skip_empty   => 0,
    skip_headers => 1,
    key_fields   => 2,
    comment_char => '#',
    verbose      => 1,
});
is($rc, 0, "Read 6 INI entries");

($rc, $msgs) = readhash($ini_file, undef, {
    delimiter    => ':',
});
is($rc, -1, "no hash passed as arg 2");

unlink $ini_file;
($rc, $msgs) = readhash($ini_file, \%read, {
    delimiter    => ':',
});
is($rc, 0, "file not found");

writehash($ini_file, \%data, {
    # all other defaults to satify coverage
    delimiter    => ';',
    prot         => 0660,
    skip_headers => 1,
    backup       => 0,
    verbose      => 1,
});

($rc, $msgs) = readhash($ini_file, \%read, {
    delimiter    => ';',
    comment_char => '#',
    group        => 0,  # flat
    # all other defaults to satify coverage
    skip_empty   => 0,
    skip_headers => 1,
    key_fields   => 2,
    comment_char => '#',
    verbose      => 1,
});
is($rc, 0, "found 0 entries");

($rc, $msgs) = writehash($ini_file, $rc, {
    delimiter    => ';',
});
is($rc, 0, "field 2 is no hash1");
unlink $ini_file;
($rc, $msgs) = writehash($ini_file, $rc, {
    delimiter    => ';',
});
is($rc, 0, "field 2 is no hash2");

done_testing;
