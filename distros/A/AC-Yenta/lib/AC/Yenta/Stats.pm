# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Apr-06 13:27 (EDT)
# Function: internal stats monitoring
#
# $Id$

package AC::Yenta::Stats;
use AC::Yenta::Debug 'stats';
use AC::Import;
use strict;

our @EXPORT = qw(add_idle loadave inc_stat);
require AC::Yenta::Store;
AC::Yenta::Store->import();

my $loadave = 0;
my %STATS;

my %HANDLER = (
    loadave		=> \&http_load,
    stats		=> \&http_stats,
    status		=> \&http_status,
    peers		=> \&AC::Yenta::Status::report,
    dumppeers		=> \&AC::Yenta::Status::report_long,
   );

sub add_idle {
    my $idle  = shift;
    my $total = shift;

    # decaying average
    return unless $total;
    my $load = 1 - $idle / $total;
    $total = 60 if $total > 60;
    my $exp = exp( - $total / 60 );
    $loadave = $loadave * $exp + $load * (1 - $exp);
}

sub loadave {
    return $loadave;
}

sub inc_stat {
    my $stat = shift;

    $STATS{$stat} ++;
}

sub handler {
    my $class = shift;
    my $io    = shift;
    my $proto = shift;
    my $url   = shift;

    debug("http request $url");
    $url =~ s|^/||;
    $url =~ s/%(..)/chr(hex($1))/eg;

    my $f = $HANDLER{$url};
    $f = \&http_data if $url =~ m|^data/|;
    $f = \&http_file if $url =~ m|^file/|;
    $f ||= \&http_notfound;
    my( $content, $code, $text ) = $f->($url);
    $code ||= 200;
    $text ||= 'OK';

    my $res = "HTTP/1.0 $code $text\r\n"
      . "Server: AC/Yenta\r\n"
      . "Connection: close\r\n"
      . "Content-Type: text/plain; charset=UTF-8\r\n"
      . "Content-Length: " . length($content) . "\r\n"
      . "\r\n"
      . $content ;

    $io->write($res);
    $io->set_callback('write_buffer_empty', \&_done );
}

sub _done {
    my $io = shift;
    $io->shut();
}

################################################################

sub http_notfound {
    my $url = shift;

    return ("404 NOT FOUND\nThe requested url /$url was not found on this server.\nSo sorry.\n\n", 404, "Not Found");
}

sub http_load {

    return sprintf("loadave:    %0.4f\n\n", loadave());
}

sub http_status {
    my $status = AC::Yenta::NetMon::status_dom('public');
    return "status: OK\n\n" if $status == 200;
    return("status: PROBLEM\n\n", 500, "Problem");
}

sub http_stats {

    my $res;
    for my $k (sort keys %STATS){
        $res .= sprintf("%-24s%s\n", "$k:", $STATS{$k});
    }

    my @peers = AC::Yenta::Status->allpeers();
    $res .= sprintf("%-24s%s\n", "peers:", scalar @peers);
    $res .= "\n";
    return $res;
}

sub http_data {
    my $url = shift;

    my(undef, $map, $key, $ver) = split m|/|, $url;
    my($data, $version, $file, $meta) = store_get($map, $key, $ver);

    return http_notfound($url) unless $version;
    return $data;
}

sub http_file {
    my $url = shift;

    my(undef, $map, $key, $ver) = split m|/|, $url;
    my($data, $version, $file, $meta) = store_get($map, $key, $ver);

    return http_notfound($url) unless $version && $file;
    return $$file;
}

1;
