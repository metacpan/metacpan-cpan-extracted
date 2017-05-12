#!/usr/bin/perl
use strict;
use warnings;
use Apache::Session::File;

# Would be nice to make it read these
# config options from httpd.conf

my $sessiondir  = '/www/sessions';                         # session directory
my $locksdir    = '/www/sessions/locks';                   # locks directory
my $expire      = '30';                                    # timeout period
my $globals     = 'Tie::SymlinkTree,/tmp/globals';         # global file name

# safety measure
die "Run this script in your session dir!" if ! -f $globals;

# Get global data
my @tie = split(/,/,$globals);
eval "require $tie[0];";
tie my %global, @tie;

chdir($sessiondir);
foreach (glob("*")) {
    next unless -f $_;
    
    my $sessionfile = $_;
    
    # Get session data
    tie my %session, 'Apache::Session::File', $sessionfile, {
        Directory       => $sessiondir,
        LockDirectory   => $locksdir,
    };

    # remove expired session files and update globals
    if (int(time()/300) > $session{'auth_last_access'}+$expire) {
        
        delete($global{'auth_online_users'}{$session{'auth_access_user'}});
        unlink($sessionfile);
        unlink($locksdir.'/Apache-Session-'.$sessionfile.'.lock');
    }
}
