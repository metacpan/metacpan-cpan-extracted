package DBIx::QuickDB::Util;
use strict;
use warnings;

our $VERSION = '0.000053';

use File::Path qw/remove_tree/;
use IPC::Cmd qw/can_run/;
use Carp qw/confess/;

use Importer Importer => 'import';

our @EXPORT_OK = qw/clone_dir strip_hash_defaults env_timeout/;

# Read a positive-integer timeout (in seconds) from an environment variable,
# falling back to $default when it is unset or not a positive integer. Used to
# make the server start/stop timeouts generous-but-tunable so slow hosts (e.g.
# CPAN smoke boxes) do not spuriously time out.
sub env_timeout {
    my ($name, $default) = @_;
    my $val = $ENV{$name};
    return $val if defined($val) && $val =~ /^\d+$/ && $val > 0;
    return $default;
}

my ($RSYNC, $CP);

BEGIN {
    local $@;
    $RSYNC = can_run('rsync');
    $CP    = can_run('cp');
}

sub clone_dir {
    return _clone_dir_rsync(@_) if $RSYNC;
    return _clone_dir_cp(@_)    if $CP;
    return _clone_dir_fcr(@_);
}

sub _clone_dir_rsync {
    my ($src, $dest, %params) = @_;
    system($RSYNC, '-a', '--delete', '--exclude' => '.nfs*', $params{checksum} ? ('-c') : (), $params{verbose} ? ( '-vP' ) : (), "$src/", $dest) and die "$RSYNC returned $?";
}

sub _clone_dir_cp {
    my ($src, $dest, %params) = @_;
    my $err;
    remove_tree($dest, {safe => 1, keep_root => 1, error => \$err}) if -d $dest;
    system($CP, '-a', $params{verbose} ? ( '-v' ) : (), "$src/.", $dest) and die "$CP returned $?";
}

sub _clone_dir_fcr {
    my ($src, $dest, %params) = @_;
    require File::Copy::Recursive;

    my $err;
    remove_tree($dest, {safe => 1, keep_root => 1, error => \$err}) if -d $dest;
    File::Copy::Recursive::dircopy($src, $dest) or die "$!";
}

sub strip_hash_defaults {
    my ($hash, $defaults) = @_;

    my $out = {%$hash};

    for my $key (keys %$defaults) {
        my $refout = ref($out->{$key});
        my $refdef = ref($defaults->{$key});

        if ($refout eq $refdef && $refdef eq 'HASH') {
            $out->{$key} = strip_hash_defaults($out->{$key}, $defaults->{$key});
            next;
        }

        if ($refout ne $refdef) {
            delete $out->{$key};
            next;
        }

        no warnings 'numeric';
        delete $out->{$key} if $out->{$key} && $out->{$key} eq $defaults->{$key};
    }

    return $out;
}

1;
