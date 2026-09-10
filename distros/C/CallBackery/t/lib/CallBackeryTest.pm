package CallBackeryTest;

use strict;
use warnings;

use Exporter 'import';
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use Mojo::File qw(path);

our @EXPORT_OK = qw(setupTestConfig);

=head1 NAME

CallBackeryTest - shared setup for the CallBackery test suite

=head1 SYNOPSIS

  use lib $FindBin::Bin.'/lib';
  use CallBackeryTest qw(setupTestConfig);

  my $cfg = setupTestConfig();
  my $t   = Test::Mojo->new('CallBackery');

=head1 DESCRIPTION

t/callbackery.cfg names its config database with a relative path, so an app
built straight from it drops a callbackery.db into whatever the current
directory happens to be -- the checkout root when the suite is run with
prove. setupTestConfig writes a copy of the config pointing at a uniquely
named database below the system temp directory instead, and that directory
is removed when the test process exits.

=cut

# One temp directory per test process. tempdir CLEANUP removes it, and
# everything below it, at process exit -- including on failure, as long as
# the process is not killed outright.
my $dir;

=head2 setupTestConfig(%opt)

Set C<$ENV{CALLBACKERY_CONF}> to a private copy of the test config and
return a hash reference with the C<dir>, C<cfgFile> and C<cfgDb> paths.

Options: C<template> picks a config other than t/callbackery.cfg.

=cut

sub setupTestConfig {
    my %opt = @_;

    $dir //= tempdir('callbackery-test-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);

    my $cfgDb   = File::Spec->catfile($dir, 'config.db');
    my $cfgFile = File::Spec->catfile($dir, 'callbackery.cfg');
    my $template = $opt{template} // File::Spec->catfile($FindBin::Bin, 'callbackery.cfg');

    my $cfg = path($template)->slurp;
    $cfg =~ s{^cfg_db\s*=.*$}{cfg_db = $cfgDb}m
        or die "$template has no cfg_db setting to redirect\n";
    path($cfgFile)->spew($cfg);

    $ENV{CALLBACKERY_CONF} = $cfgFile;

    return {
        dir     => $dir,
        cfgFile => $cfgFile,
        cfgDb   => $cfgDb,
    };
}

1;
