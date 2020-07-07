#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;

use Test::More tests => 1;
use English qw( -no_match_vars );
use Bat::Interpreter;
use Path::Tiny;

use Data::Dumper;

my $interpreter = Bat::Interpreter->new;

if ( $^O eq 'MSWin32' ) {

    my $cmd_file = $PROGRAM_NAME;
    $cmd_file =~ s/\.t/\.cmd/;

    local $ENV{"CWD"} = Path::Tiny::path($0)->parent()->absolute()->canonpath();

    $interpreter->run($cmd_file);

} else {
    my $cmd_file         = Path::Tiny::path($0)->parent()->child('10-call_command_path_with_colon_linux.cmd');
    my $cmd_subcall_file = Path::Tiny::path($0)->parent()->child('10-call_command_subcall_path_with_colon.cmd');
    my $cmd_dir          = Path::Tiny->tempdir(":cmd_dirXXXXXXXX");
    $cmd_subcall_file->copy($cmd_dir);
    local $ENV{"CMD_DIR"} = $cmd_dir->absolute();
    $interpreter->run( $cmd_file->absolute()->canonpath() );
}

is_deeply( ['cp file1 file2'], $interpreter->executor->commands_executed );
