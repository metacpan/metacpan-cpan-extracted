# -*- perl -*-

# Copyright (c) 2008 by AdCopy
# Author: Jeff Weisberg
# Created: 2008-Dec-19 10:12 (EST)
# Function: read simple config file
#
# $Id$

# file:
# keyword value
# ...

package AC::ConfigFile::Simple;
use AC::Misc;
use AC::DC::Debug;
use Socket;
use strict;

my $MINSTAT = 15;

my %CONFIG = (
    include	=> \&include_file,
    debug	=> \&parse_debug,
    allow	=> \&parse_allow,
    _default	=> \&parse_keyvalue,
);


sub new {
    my $class = shift;
    my $file  = shift;

    my $me = bless {
	_laststat	=> $^T,
	_lastconf	=> $^T,
        _configfile	=> $file,
        _files		=> [ ],
	@_,
    }, $class;

    $me->_read();
    return $me;
}

sub check {
    my $me = shift;

    my $now = $^T;
    return if $now - $me->{_laststat} < $MINSTAT;
    $me->{_laststat} = $now;

    my $changed;
    for my $file ( @{$me->{_files}} ){
        my $mtime = (stat($file))[9];
        $changed = 1 if $mtime > $me->{_lastconf};
    }
    return unless $changed;

    verbose("config file changed. reloading");
    $me->{_lastconf} = $now;

    eval {
	$me->_read();
        verbose("installed new config file");
        if( my $f = $me->{onreload} ){
            $f->();
        }
    };
    if(my $e = $@){
        problem("error reading new config file: $e");
        return;
    }

    return 1;
}

sub _read {
    my $me = shift;

    delete $me->{_pending};

    $me->_readfile($me->{_configfile});

    $me->{config} = $me->{_pending};
    delete $me->{_pending};
}

sub _readfile {
    my $me   = shift;
    my $file = shift;

    my $fd;
    open($fd, $file) || die "cannot open file '$file': $!";
    $me->{fd} = $fd;

    push @{$me->{_files}}, $file;

    while( defined(my $l = $me->_nextline()) ){
        my($key, $rest) = split /\s+/, $l, 2;
        $me->handle_config( $key, $rest ) || die "invalid config '$key'\n";
    }

    close $fd;
}

sub handle_config {
    my $me   = shift;
    my $key  = shift;
    my $rest = shift;

    my $fnc = $CONFIG{$key} || $CONFIG{_default};
    return unless $fnc;
    $fnc->($me, $key, $rest);
    return 1;
}

sub _nextline {
    my $me = shift;

    my $line;
    while(1){
        my $fd = $me->{fd};

        my $l = <$fd>;
        return $line unless defined $l;
        chomp $l;

        $l =~ s/\#.*$//;
        $l =~ s/^\s*//;
        $l =~ s/\s+$//;
        next if $l =~ s/^\s*$/; #/;
        $line .= $l;

        if( $line =~ /\\$/ ){
            chop $line;
            next;
        }
        return $line;
    }
}

################################################################

sub include_file {
    my $me   = shift;
    my $key  = shift;
    my $file = shift;

    $file =~ s/^"(.*)"$/$1/;

    if( $file !~ m|^/| ){
        # add path from main config file
        my($path) = $me->{_configfile} =~ m|(.*)/[^/]+$|;
        $file = "$path/$file" if $path;
    }

    my $fd = $me->{fd};
    $me->_readfile($file);
    $me->{fd} = $fd;
}

sub parse_keyvalue {
    my $me    = shift;
    my $key   = shift;
    my $value = shift;

    problem("parameter '$key' redefined") if $me->{_pending}{$key};
    $me->{_pending}{$key} = $value;
}

sub parse_keyarray {
    my $me    = shift;
    my $key   = shift;
    my $value = shift;

    push @{$me->{_pending}{$key}}, $value;
}

sub parse_allow {
    my $me    = shift;
    my $key   = shift;
    my $acl   = shift;

    my($host, $len) = split m|/|, $acl;
    $host ||= $acl;
    $len  ||= 32;

    push @{$me->{_pending}{acl}}, [ inet_aton($host), inet_lton($len) ];
}

sub parse_debug {
    my $me    = shift;
    my $key   = shift;
    my $value = shift;

    $me->{_pending}{debug}{$value} = 1;
}


################################################################

sub config {
    my $me = shift;
    return $me->{config};
}

sub get {
    my $me = shift;
    my $k  = shift;

    return $me->{config}{$k};
}

sub check_acl {
    my $me = shift;
    my $ip = shift;	# ascii

    my $ipn = inet_aton($ip);
    for my $acl ( @{$me->{config}{acl}} ){
        my($net, $mask) = @$acl;
        return 1 if ($ipn & $mask) eq $net;
    }

    return 0;
}


1;
