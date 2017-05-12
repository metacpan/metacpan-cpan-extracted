#!/usr/bin/env perl
# DEVELOPERS: Read build/build.PL & DEVELOPING for how to update this
## no critic
# __FATPACK__
## use critic
use strict;
use warnings;

use FindBin qw($Bin);  # For dev -- Auto-removed
use lib "$Bin/../lib"; # For dev -- Auto-removed
use Getopt::Long;
use Pod::Usage;

use App::CmdDirs;

=head1 NAME

cmddirs - perform a command in subdirectories

=head1 SYNOPSIS

cmddirs [options] command [dir ...]

If no directories are provided, cmddirs will perform the command in all
subdirectories of the current working directory.  Only subdirectories
appropriate for the given command (e.g. git repositories, if your command
    -contains the word "git") or the given directory options are acted upon.

See the man page (-man) for a full list of available directory filters.

=head1 OPTIONS

=over 4

=item B<-h|help>
Show help message

=item B<-m|man>
Show manpage

=item B<-a|all>
Perform command in all directories

=item B<-q|quiet>
Don't print out the commands as they're run

=back

=head1 FILTERS

=over 4

=item B<--git>

=item B<--svn>

=back

=head1 EXAMPLES

Check the status of all Git repos in this directory:
    gitall.pl "git status"

Check the status of the Git repos "foo" and "bar" in this directory:
    gitall.pl "git status" foo bar

=head1 AUTHOR

Drew Stephens <drew@dinomite.net>

=cut

my $options = {};
GetOptions($options,
    'help|h',
    'man|m',
    'all|a',
    'quiet|q',
    'git',
    'svn',
);

pod2usage(-verbose => 1) if ($options->{'help'});
pod2usage(-verbose => 2) if ($options->{'man'});

# We at least need a command
pod2usage(1) if (scalar(@ARGV) == 0);

my $cmdDirs = App::CmdDirs->new(\@ARGV, $options);
$cmdDirs->run();
