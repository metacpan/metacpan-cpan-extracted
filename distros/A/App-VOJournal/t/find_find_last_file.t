#!perl -T
# vim: set sw=4 ts=4 et ai si:
#
use strict;
use warnings FATAL => 'all';

use Test::More;
use File::Find;
use File::Path qw(make_path remove_tree);

use App::VOJournal;

my $basedir = 't/testbase';
my $journaldir = "$basedir/2015/02";
my $journalfile = "$journaldir/20150231.otl";
my $oldjournalfile = "$journaldir/20150230.otl";

my ($last_file,@visited);

# 1. create test directory and files

setup_test();

# 2. find the last file

@visited = ();
$last_file = App::VOJournal::_find_last_file($basedir,$oldjournalfile,
    { wanted => sub { push @visited,[@_] } }
);
is($last_file, $oldjournalfile, "find the last file");
is(scalar @visited, 5, "looked at five files/dirs");

# 3. remove test directory and files

teardown();

done_testing();

#----- functions -----
sub create_empty_file {
    open TMPFILE, '>', $_[0] and close TMPFILE
    or die "Failed to create $_[0]: $!\n";
}

sub setup_test {
    teardown();
    make_path($journaldir);
    make_path("$basedir/2014/12");
    create_empty_file("$basedir/2014/12/20141231.otl");
    make_path("$basedir/2015/01");
    create_empty_file("$basedir/2015/01/20150101.otl");
    create_empty_file($journalfile);
    create_empty_file($oldjournalfile);
}

sub teardown {
    remove_tree($basedir);
}
