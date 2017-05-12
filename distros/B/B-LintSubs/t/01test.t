#!/usr/bin/perl

use Test::More tests => 21;

use IPC::Run qw( run );

sub is_child
{
   my ( $cmdref, $exitcode, $outlike, $errlike, $name ) = @_;

   my( $childout, $childerr );

   run $cmdref, \undef, \$childout, \$childerr;

   is( $? >> 8, $exitcode, "$name exit code" );
   like( $childout, $outlike, "$name stdout" );
   like( $childerr, $errlike, "$name stderr" );
}

sub lint_oklike
{
   my $name = pop @_;
   my $errlike = pop @_;

   is_child( [ $^X, '-MO=LintSubs', '-e', @_ ], 0, qr/^$/, $errlike, $name );
}

sub lint_ok
{
   my $name = pop @_;
   lint_oklike( @_, qr/^$/, qr/^-e syntax OK\n$/, $name );
}

sub lint_noklike
{
   my $name = pop @_;
   my $errlike = pop @_;

   is_child( [ $^X, '-MO=LintSubs', '-e', @_ ], 1, qr/^$/, $errlike, $name );
}

lint_ok( 'print q{I am happy}', 'Simple print line' );

lint_ok( 'sub hello { 1; } hello()', 'Declare then call' );

lint_ok( 'hello(); sub hello { 1; }', 'Call then declare' );

lint_ok( 'sub hello { 1; } hello', 'Declare then call implicit' );

lint_ok( 'use POSIX qw( getpid ); print getpid', 'Imported function' );

lint_oklike( 'require POSIX; print POSIX::getpid()', 
             qr/^Unable to check call to POSIX::getpid in foreign package at -e line 1\n-e syntax OK$/,
             'Fully-qualified external function' );

lint_noklike( 'sub foo { 1; } bar()',
              qr/^Undefined subroutine bar called at -e line 1\n$/,
              'Missing function' );
