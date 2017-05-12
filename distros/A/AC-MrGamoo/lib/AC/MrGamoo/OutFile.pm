# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-27 11:34 (EST)
# Function: buffer output + open/close files as needed
#
# $Id: OutFile.pm,v 1.2 2011/01/06 17:58:13 jaw Exp $

package AC::MrGamoo::OutFile;
use AC::MrGamoo::Debug 'outfile';
use IO::Compress::Gzip;
use strict;

my $BUFMAX         = 200000;
my $max_open;
my $currently_open = 0;
my %all;


$max_open = `sh -c "ulimit -n"`;
$max_open = 255 if $^O eq 'solaris' && $max_open > 255;
$max_open -= 32;	# room for other fds


sub new {
    my $class = shift;
    my $file  = shift;
    my $gz    = shift;

    my $me = bless {
        file	=> $file,
        gz      => $gz,
    }, $class;

    $all{$file} = $me;

    # open as many as we can up front
    $me->_open() if $currently_open < $max_open;
    return $me;
}

sub close {
    my $me = shift;

    $me->_flush();
    $me->_touch() unless $me->{been_opened};
    $me->_close();
}

sub output {
    my $me  = shift;

    $me->{lastused} = $^T;	# $^T as been updated with current time

    if( my $fd = $me->{fd} ){
        print $fd @_;
    }else{
        $me->{buffer} .= $_ for @_;
        $me->_flush() if length($me->{buffer}) >= $BUFMAX;
    }
}

################################################################

sub DESTROY {
    my $me = shift;
    $me->close();
}

################################################################

sub _close {
    my $me = shift;

    return unless $me->{fd};
    close($me->{fd});
    $currently_open --;
    delete $me->{fd};
    debug("closed file $me->{file}");
}

sub _open {
    my $me = shift;

    if( $me->{gz} ){
        my $fd = IO::Compress::Gzip->new( $me->{file},
                                          Append	=> $me->{been_opened},
                                          Merge		=> $me->{been_opened},
                                         );
        $me->{fd} = $fd;
        debug("opened file (compressed) $me->{file}");
    }else{
        my $mode = $me->{been_opened} ? '>>' : '>';

        open(my $fd, $mode, $me->{file}) || die "cannot open '$me->{file}': $!\n";
        $me->{fd} = $fd;
        debug("opened file $me->{file}");
    }

    $me->{been_opened} = 1;
    $currently_open ++;
}

sub _flush {
    my $me = shift;

    return unless $me->{buffer};
    _close_things() if $currently_open >= $max_open;

    $me->_open();
    my $fd = $me->{fd};

    print $fd $me->{buffer};
    delete $me->{buffer};
}

# to make sure file gets created
sub _touch {
    my $me = shift;

    _close_things() if $currently_open >= $max_open;
    $me->_open();
}

sub _close_things {

    my $this_many = ($currently_open / 3) || 1;

    # close least recently used
    my @all = sort {
        $a->{lastused} <=> $b->{lastused}
    } values %all;

    for my $io (@all){
        next unless $io->{fd};
        $io->close();
        last if --$this_many <= 0;
    }

}


1;

