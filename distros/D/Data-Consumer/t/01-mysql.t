##!perl -T
use Data::Consumer;
use strict;
use warnings;
use Data::Dumper;
use DBI;
my $debug = @ARGV ? shift : $ENV{TEST_DEBUG};
our @fake_error;
our @expect_fail;
our %ignored;
our %process_state;
our @connect_args;
our $table;
our $class_to_test;

my $mod= "Data::Consumer::MySQL2";

eval "use $mod; 1" or die $@
    if !$class_to_test;
my $conf_file = 'mysql.pldat';
if (-e $conf_file) {
    # eval @connect_args into existance
    my $ok = do $conf_file;
    defined $ok or die "Error loading $conf_file: ", $@||$!;

    unless (@connect_args) {
        my $reason='no mysql connection details available';
        eval 'use Test::More skip_all => $reason; 1;'
            or die $@;
    }
}
if (!%process_state) {
    %process_state = (
	unprocessed => 0,
	working     => 1,
	processed   => 2,
	failed      => 3,
    );
}

my $drop = <<"ENDOFSQL";
DROP TABLE `$table`
ENDOFSQL

my $create = <<"ENDOFSQL";
CREATE TABLE `$table` (
    `id` int(11) NOT NULL auto_increment,
    `n` int(11) NOT NULL default '0',
    `done` tinyint(3) unsigned NOT NULL default '0',
    PRIMARY KEY  (`id`)
)
ENDOFSQL

defined(my $unprocessed= $process_state{unprocessed}) or die "Must have a 'unprocessed' state to test!";
# 100 rows
my $insert = <<"ENDOFSQL";
INSERT INTO `$table` (done) VALUES 
        ($unprocessed),($unprocessed),($unprocessed),($unprocessed),($unprocessed),($unprocessed),($unprocessed),($unprocessed),($unprocessed),($unprocessed),
        ($unprocessed),($unprocessed),($unprocessed),($unprocessed),($unprocessed),($unprocessed),($unprocessed),($unprocessed),($unprocessed),($unprocessed),
        ($unprocessed),($unprocessed),($unprocessed),($unprocessed),($unprocessed),($unprocessed),($unprocessed),($unprocessed),($unprocessed),($unprocessed),
        ($unprocessed),($unprocessed),($unprocessed),($unprocessed),($unprocessed),($unprocessed),($unprocessed),($unprocessed),($unprocessed),($unprocessed),
        ($unprocessed),($unprocessed),($unprocessed),($unprocessed),($unprocessed),($unprocessed),($unprocessed),($unprocessed),($unprocessed),($unprocessed)
ENDOFSQL

$insert.=",($_)" for @fake_error; 

$connect_args[0]=("DBI:mysql:$connect_args[0]");

{
    my $dbh = DBI->connect(@connect_args) 
	or die "Could not connect to '$connect_args[0]' : $DBI::errstr";
    local $dbh->{PrintError};
    local $dbh->{PrintWarn};
    local $dbh->{RaiseError} = 0;
    $dbh->do($drop);
    $dbh->{RaiseError} = 1;
    $dbh->do($create);
    $dbh->do($insert);
        
}


my $child;
my $procs = 4;
$debug  and Data::Consumer->debug_warn("Spawning children!\n");
my $pid = $$;
my @child;
do {
    $child = fork;
    if (!defined $child) {
        die "Fork failed!";
    } elsif ($child) {
        push @child,$child;
    }
} while $child and --$procs > 0;

if ( $child ) {
    $debug  and $debug and Data::Consumer->debug_warn("Using test more\n");
    eval "use Test::More tests => @{[2+@expect_fail]}; ok(1); 1;" 
        or die $@;
} else {
   sleep(1);
}

$child and diag("This will take around 30 seconds\n");
$debug and Data::Consumer->debug_warn(0,"starting processing\n");
$Data::Consumer::Debug=10 if $debug;

my %xargs;
%xargs=qw(type MySQL2) if $class_to_test;
$class_to_test||="Data::Consumer::MySQL2";

my $consumer = $class_to_test->new(
    %xargs,
    connect     => \@connect_args,
    table       => $table,
    flag_field  => 'done',
    lock_prefix => "test_lock",
    %process_state,
);

$consumer->consume(sub { 
    my ($consumer,$id,$dbh) = @_; 
    $debug  and $consumer->debug_warn(0,"*** processing '$id'"); 
    $debug and $consumer->debug_warn(0,$id,Dumper($dbh->selectrow_arrayref("select IS_USED_LOCK(CONCAT_WS('=','$0-$table',$id))")));
    if($ignored{$id}) {
        $debug and $consumer->debug_warn(0,"* ignoring '$id' as requested\n");
        $consumer->ignore();
        return;
    }
    sleep(1);
    $dbh->do("UPDATE `$table` SET `n` = `n` + 1 WHERE `id` = ?", undef, $id);

    $debug  and $consumer->debug_warn(0,"*** finished processing '$id'");
});


if ( $child ) {
    use POSIX ":sys_wait_h";
    while (@child) {
        @child=grep { waitpid($_,WNOHANG)==0 } @child;
        sleep(1);
    }
        
    my $recs = $consumer->dbh->selectall_arrayref(
        "SELECT * FROM `$table` WHERE NOT(`n` = ? AND `done` = ?)",
        undef, 1, $process_state{processed},
    );
    my $num = 0 + @$recs;
    my $expect = 0+@expect_fail;
    $debug and $consumer->debug_warn($expect,"Found $num incorrectly processed items expected $expect.\n");
    my $err = !is($num, $expect, "should be $expect incorrectly processed items");
    
    warn Dumper($recs) if $expect;
    foreach my $idx (0..$#expect_fail) {
        $err ||= !is("@{$recs->[$idx]}","@{$expect_fail[$idx]}");
    }
    if ($err) {
        warn map {  "[@{$recs->[$_]}] " . ( 7 == $_ % 8 ? "\n" : "" ) } (0..$#$recs);
    } else {
        $consumer->dbh->do("DROP TABLE `$table`");
    }
}
1;
