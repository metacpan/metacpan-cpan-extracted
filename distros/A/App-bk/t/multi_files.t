#!perl

use strict;
use warnings;
use Test::More;
use Test::Trap;
use FindBin qw($Bin);

my $result;

use_ok("App::bk");

chdir($Bin) || BAIL_OUT( 'Failed to cd into '. $Bin );

unlink <file*.txt.*>;

local @ARGV = ('no_such_file.txt');

$result = trap { App::bk::backup_files(); };

like(
    $trap->stderr,
    qr/WARNING: File no_such_file.txt not found/,
    'correct stderr output'
);
is( $trap->stdout,  '',       'no stdout output' );
is( $trap->exit,    undef,    'correct exit' );
is( $trap->leaveby, 'return', 'returned correctly' );
is( $trap->die,     undef,    'no death output' );
is( $result,        1,        'got correct return value' );

local @ARGV = ( 'file1.txt', 'file2.txt' );

$result = trap { App::bk::backup_files(); };

is( $trap->stderr, '', 'no stderr output' );
like(
    $trap->stdout,
    qr!Backed up file1.txt to ./file1.txt.([\w-]+\.)?\d{8}
Backed up file2.txt to ./file2.txt.([\w-]+\.)?\d{8}
$!,
    'got correct backup filename'
);
is( $trap->exit,    undef,    'correct exit' );
is( $trap->leaveby, 'return', 'returned correctly' );
is( $trap->die,     undef,    'no death output' );
is( $result,        1,        'got correct return value' );

$result = trap { App::bk::backup_files(); };

is( $trap->stderr, '', 'no stderr output' );
like(
    $trap->stdout,
    qr!No change since last backup of file1.txt
No change since last backup of file2.txt
$!,
    'got correct backup filename'
);
is( $trap->exit,    undef,    'correct exit' );
is( $trap->leaveby, 'return', 'returned correctly' );
is( $trap->die,     undef,    'no death output' );
is( $result,        1,        'got correct return value' );

my $file1_last_backup_file = App::bk::get_last_backup( $Bin, 'file1.txt' );
note( 'Amending file ', $file1_last_backup_file );
chmod 0644, $file1_last_backup_file || BAIL_OUT("Could not reset perms on $file1_last_backup_file:: ". $!);
open(my $fh, '>>', $file1_last_backup_file) || BAIL_OUT("Could not open $file1_last_backup_file: ". $!);
print $fh ' Amended test',$/ || BAIL_OUT("Could not write to $file1_last_backup_file: ", $!);
close($fh) || BAIL_OUT("Could not close $file1_last_backup_file: ". $!);

my $file2_last_backup_file = App::bk::get_last_backup( $Bin, 'file2.txt' );
note( 'Amending file ', $file2_last_backup_file );
chmod 0644, $file2_last_backup_file || BAIL_OUT("Could not reset perms on $file2_last_backup_file:: ". $!);
open($fh, '>>', $file2_last_backup_file) || BAIL_OUT("Could not open $file2_last_backup_file: ". $!);
print $fh ' Amended test',$/ || BAIL_OUT("Could not write to $file2_last_backup_file: ". $!);
close($fh) || BAIL_OUT("Could not close $file2_last_backup_file: ". $!);

$result = trap { App::bk::backup_files(); };

is( $trap->stderr, '', 'no stderr output' );
like(
    $trap->stdout,
    qr!Backed up file1.txt to ./file1.txt.([\w-]+\.)?\d{8}\.\d{6}
Backed up file2.txt to ./file2.txt.([\w-]+\.)?\d{8}\.\d{6}
$!,
    'got correct backup filename'
);
is( $trap->exit,    undef,    'correct exit' );
is( $trap->leaveby, 'return', 'returned correctly' );
is( $trap->die,     undef,    'no death output' );
is( $result,        1,        'got correct return value' );

unlink <file*.txt.*>;

done_testing();
