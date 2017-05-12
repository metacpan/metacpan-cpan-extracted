#! /usr/bin/perl

use lib '../lib';

package My::Machine;

use Moose;
extends 'Data::Pipeline::Machine';
use Data::Pipeline::Machine;

use Data::Pipeline qw( FetchPage CSV UrlBuilder Rename Regex Filter );

pipeline(
    FetchPage(
        cut_start => '<p class="g">',
        cut_end => '</div><center>',
        split => '<p class="g">',
        url => UrlBuilder(
            base => 'http://search.tamu.edu/search',
            query => {
                q => Option( q => (default => 'digital humanities') ),

                site => 'default_collection',
                client => 'TAMU_frontend',
                output => 'xml_no_dtd',
                proxystylesheet => 'TAMU_frontend',
                proxycustom => '/HOME/~',
                btnG => 'Search',
                entqr => '3',
                sort => 'date:D:L:d1',
                entsp => '0',
                ud => '1',
                oe => 'UTF-8',
                ie => 'UTF-8'
            }
        ),
    ),
    Rename(
        copies => [
            content => 'description',
            content => 'title',
        ],
        renames => [
            'content' => 'link'
        ]
    ),
    Regex(
        rules => [
            title => sub { s{^.*?<span class="l">(.+?)</span>.*$}{$1}gs; },
            link => sub { s{^.*?http://(.+?)".*$}{http://$1}gs },
            title => sub { s/<.+?>//gs },
            title => sub { s/&nbsp;//gs },
            title => sub { s/\s+/ /gs },
            description => sub { s{.+?<td class="s">(.+?)<font.*$}{$1}gs },
            description => sub { s{<.+?>}{}gs },
            description => sub { s/\s+/ /gs },
        ]
    ),
    Filter(
        reject_matching => 1,
        filters => {
            title => qr/^\s*$/
        }
    ),
    CSV( column_names => [qw( title link description )], file_has_header => 1 )
);

package main;

My::Machine 
    -> new
    -> from( defined($ARGV[0]) ? (q => $ARGV[0]) : () )
    -> to( \*STDOUT );
