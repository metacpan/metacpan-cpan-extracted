#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use Backup::EZ;
use Data::Dumper;
use Test::More;
use File::Slurp;
use Data::Printer alias => 'pdump';
use File::Path;
use File::RandomGenerator;

use constant SRC_DIR     => '/tmp/backup_ez_testdata';
use constant FOO_SUBDIR  => 'dir1/foo';
use constant SRC_FOO_DIR => sprintf( '%s/%s', SRC_DIR(), FOO_SUBDIR() );

###### NUKE AND PAVE ######

system("t/nuke.pl");
system("t/pave.pl");

###### RUN TESTS ######

my $ez = Backup::EZ->new(
    conf         => 't/ezbackup_exclude.conf',
    exclude_file => 'share/ezbackup_exclude.rsync',
    dryrun       => 0
);
die if !$ez;
system( "rm -rf " . $ez->get_dest_dir );

validate_conf($ez);
finish_paving($ez);
ok( $ez->backup );

my @list = $ez->get_list_of_backups();
ok( @list == 1 );

my $foo_subdir = get_dest_foo_dir($ez);
ok( !-d $foo_subdir, "checking that $foo_subdir does not exist" );

# check counts
my $src_count = get_dir_entry_count(SRC_DIR);
my $foo_count = get_dir_entry_count(SRC_FOO_DIR);
my $expect_count = $src_count - $foo_count;

my $dest_count = get_dir_entry_count(get_dest_backup_dir($ez));
ok($dest_count == $expect_count, "checking file counts");

done_testing();

system("t/nuke.pl");

#######################

sub get_dir_entry_count{
    
    my $dir = shift;    
    
    my @files = `find $dir -type f`;
    
    return scalar(@files);
}

sub finish_paving {
    my $ez = shift;

    my $src_foo = SRC_FOO_DIR;

    my $frg = File::RandomGenerator->new(
        root_dir => $src_foo,
        unlink   => 0,
        depth    => 2
    );
    $frg->generate;

    my @out = `find $src_foo`;
    if ( @out < 2 ) {
        die "not enough files in $src_foo";
    }
}

sub get_dest_foo_dir {
    my $ez = shift;

    my ($backup_dir) = $ez->get_list_of_backups();
    my $foo_dir = sprintf( '%s/%s%s',
        $ez->get_dest_dir, $backup_dir, get_root_backup_dir($ez), SRC_FOO_DIR() );

    return $foo_dir;
}

sub get_dest_backup_dir {
    my $ez = shift;
    
    return sprintf('%s/%s', get_root_backup_dir($ez), SRC_DIR());
}

sub get_root_backup_dir {
    my $ez = shift;

    my ($backup_dir) = $ez->get_list_of_backups();

    return sprintf( '%s/%s', $ez->get_dest_dir, $backup_dir );
}

sub validate_conf {
    my $ez = shift;

    # should only have one source dir
    my @dirs = $ez->get_conf_dirs;
    if ( scalar @dirs == 1 ) {
        return 1;
    }

    die "expected one dir stanza";
}
