#!/usr/bin/env perl
use strict;
use warnings;

BEGIN {
  use FindBin;
  my $ScriptPath = "$FindBin::Bin/../bin/config-resolver.pl";
  require $ScriptPath;
}

use Test::More;
use File::Temp qw(tempfile);
use JSON qw(to_json);
use IPC::Open3;
use Symbol;
use File::Spec;

my $Bin     = $FindBin::Bin;
my $Script  = File::Spec->catfile( $Bin, '..', 'bin', 'config-resolver.pl' );
my $LibPath = File::Spec->catfile( $Bin, '..', 'lib' );
my $Perl    = $^X;  # Get the path to the current perl executable

# --- Test 1: Pipe parameters using '-p -' ---
subtest 'Test Case: Pipe parameters with -p -' => sub {

  # 1. --- Setup ---
  my ( $tpl_fh, $tpl_path ) = tempfile( SUFFIX => '.tpl', UNLINK => 1 );
  print $tpl_fh 'Hello, ${name}!';
  close $tpl_fh;

  my $json_params = to_json( { name => 'Piped Params' } );

  # THE REAL COMMAND: Use '-p -'
  my @command = ( $Perl, "-I$LibPath", $Script, "resolve", "-t", $tpl_path, "-p", "-" );

  # 2. --- Execute ---
  my ( $stdin, $stdout, $stderr );
  $stdin  = Symbol::gensym();
  $stdout = Symbol::gensym();
  $stderr = Symbol::gensym();
  my $pid = open3( $stdin, $stdout, $stderr, @command );
  unless ($pid) {
    fail("IPC::Open3 failed: $!");
    return;
  }

  print $stdin $json_params;
  close $stdin;  # Send EOF

  my $output = join '', <$stdout>;
  my $errors = join '', <$stderr>;
  waitpid $pid, 0;

  # 3. --- Verify ---
  is( $?,      0,                      'Script exited successfully (exit code 0)' );
  is( $errors, '',                     'Script produced no STDERR output' );
  is( $output, 'Hello, Piped Params!', 'Piped JSON params were correctly resolved' );
};

# --- Test 2: Pipe template using '-t -' ---
subtest 'Test Case: Pipe template with -t -' => sub {

  # 1. --- Setup ---
  my ( $p_fh, $p_path ) = tempfile( SUFFIX => '.json', UNLINK => 1 );
  print $p_fh to_json( { name => 'Piped Template' } );
  close $p_fh;

  my $template_string = 'Piped ${name}!';

  # THE REAL COMMAND: Use '-t -'
  my @command = ( $Perl, "-I$LibPath", $Script, "resolve", "-p", $p_path, "-t", "-" );

  # 2. --- Execute ---
  my ( $stdin, $stdout, $stderr );
  $stdin  = Symbol::gensym();
  $stdout = Symbol::gensym();
  $stderr = Symbol::gensym();
  my $pid = open3( $stdin, $stdout, $stderr, @command );
  unless ($pid) {
    fail("IPC::Open3 failed: $!");
    return;
  }

  print $stdin $template_string;
  close $stdin;

  my $output = join '', <$stdout>;
  my $errors = join '', <$stderr>;
  waitpid $pid, 0;

  # 3. --- Verify ---
  is( $?,      0,                       'Script exited successfully (exit code 0)' );
  is( $errors, '',                      'Script produced no STDERR output' );
  is( $output, 'Piped Piped Template!', 'Piped template was correctly resolved' );
};

# --- Test 3: Pipe template using 'implicit pipelining'
subtest 'Test Case: Pipe template with -t -' => sub {

  # 1. --- Setup ---
  my ( $p_fh, $p_path ) = tempfile( SUFFIX => '.json', UNLINK => 1 );
  print $p_fh to_json( { name => 'Piped Template' } );
  close $p_fh;

  my $template_string = 'Piped ${name}!';

  # THE REAL COMMAND: Use '-t -'
  my @command = ( $Perl, "-I$LibPath", $Script, "resolve", "-p", $p_path );

  # 2. --- Execute ---
  my ( $stdin, $stdout, $stderr );
  $stdin  = Symbol::gensym();
  $stdout = Symbol::gensym();
  $stderr = Symbol::gensym();
  my $pid = open3( $stdin, $stdout, $stderr, @command );
  unless ($pid) {
    fail("IPC::Open3 failed: $!");
    return;
  }

  print $stdin $template_string;
  close $stdin;

  my $output = join '', <$stdout>;
  my $errors = join '', <$stderr>;
  waitpid $pid, 0;

  # 3. --- Verify ---
  is( $?,      0,                       'Script exited successfully (exit code 0)' );
  is( $errors, '',                      'Script produced no STDERR output' );
  is( $output, 'Piped Piped Template!', 'Piped template was correctly resolved' );
};

done_testing();

1;
