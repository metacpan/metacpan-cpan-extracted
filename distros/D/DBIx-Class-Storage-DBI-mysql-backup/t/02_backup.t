use strict;
use warnings;

use Test::More;
use Test::mysqld;
use Symbol;
use File::Path qw/rmtree/;
use FindBin::libs;

my $mysqld;

BEGIN {

    $mysqld = Test::mysqld->new(
        my_cnf => { 'skip-networking' => '' },
    ) or plan skip_all => $Test::mysqld::errstr;
    
    use_ok 'DBICTest::Schema';
}

{
    local $ENV{DBIC_NO_VERSION_CHECK} = 1;

    my $schema = DBICTest::Schema->connect($mysqld->dsn(dbname => 'test'));
    $schema->deploy;
    my $artist_rs = $schema->resultset('Artist');
    my $cd_rs = $schema->resultset('CD');
    
    my ($artist, $cd);
    
    $artist = $artist_rs->create({
        name => 'the great artist',
    });
    
    $cd = $cd_rs->create({
        title => 'album1',
        artist => $artist,
    });
    
    $cd = $cd_rs->create({
        title => 'album2',
        artist => $artist,
    });
    
    my $dump = $schema->storage->dump;
    like $dump, qr/CREATE TABLE `artist`/i, 'has CREATE TABLE `artist`';
    like $dump, qr/CREATE TABLE `cd`/i, 'has CREATE TABLE `cd`';
    like $dump, qr/'album1'/, 'has album1';
    like $dump, qr/'album2'/, 'has album2';
    like $dump, qr/'the great artist'/, 'has the great artist';
    
    my $backup_file = $schema->backup;
    ok $backup_file, "returned file name $backup_file";

    my $dir = $schema->backup_directory;
    my $target = "$dir/$backup_file";
    ok -f $target, "backup file exists to $target";
    my $fh = Symbol::gensym();
    open $fh, $target or fail($!);
    local $/ = undef;
    my $read = <$fh>;
    close $fh;
    is $read, $dump, 'dumped sql file correctly';
    
    rmtree $dir;
}

done_testing;
