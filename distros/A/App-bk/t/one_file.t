#!perl

use strict;
use warnings;
use Test::More;
use Test::Trap;
use FindBin qw($Bin);

my $result;

use_ok("App::bk");

chdir($Bin) || BAIL_OUT( 'Failed to cd into '. $Bin );

unlink <file1.txt.*>;

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

local @ARGV = ('file1.txt');

$result = trap { App::bk::backup_files(); };

is( $trap->stderr, '', 'no stderr output' );
like(
    $trap->stdout,
    qr!Backed up file1.txt to ./file1.txt.([\w-]+\.)?\d{8}\s$!,
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
    qr!No change since last backup of file1.txt$!,
    'correctly got no change'
);
is( $trap->exit,    undef,    'correct exit' );
is( $trap->leaveby, 'return', 'returned correctly' );
is( $trap->die,     undef,    'no death output' );
is( $result,        1,        'got correct return value' );

my $last_backup_file = App::bk::get_last_backup( $Bin, 'file1.txt' );
note( 'Amending file ', $last_backup_file );
# have to reset perms on some systems as the backed up file might be RO
chmod 0644, $last_backup_file || BAIL_OUT("Could not reset perms on $last_backup_file:: ". $!);
open(my $fh, '>>', $last_backup_file) || BAIL_OUT("Could not open $last_backup_file: ". $!);
print $fh ' Amended test',$/ || BAIL_OUT("Could not write to $last_backup_file: ". $!);
close($fh) || BAIL_OUT("Could not close $last_backup_file: ". $!);

$result = trap { App::bk::backup_files(); };

is( $trap->stderr, '', 'no stderr output' );
like(
    $trap->stdout,
    qr!Backed up file1.txt to ./file1.txt.([\w-]+\.)?\d{8}\.\d{6}\s$!,
    'got correct backup filename'
);
is( $trap->exit,    undef,    'correct exit' );
is( $trap->leaveby, 'return', 'returned correctly' );
is( $trap->die,     undef,    'no death output' );
is( $result,        1,        'got correct return value' );

unlink <file1.txt.*>;

done_testing();
