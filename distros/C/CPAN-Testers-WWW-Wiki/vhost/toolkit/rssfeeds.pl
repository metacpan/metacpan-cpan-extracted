#!/usr/bin/perl -w
use strict;

my $BASE;

# create images in pages
BEGIN {
    $BASE = '/var/www/cpanwiki';
}

#----------------------------------------------------------
# Additional Modules

use lib qw|../cgi-bin/lib ../cgi-bin/plugins|;
use Labyrinth::Globals;
use Labyrinth::RSS;
use Labyrinth::Variables;
use Labyrinth::Plugin::Wiki;

use File::Basename;
use File::Path;
use IO::File;

#----------------------------------------------------------
# Variables

my @types = (
#    { type => 'rss',  version => '0.9' },
#    { type => 'rss',  version => '1.0' },
    { type => 'rss',  version => '2.0' },
    { type => 'atom', version => '1.0' },
);

#----------------------------------------------------------
# Code

Labyrinth::Globals::LoadSettings("$BASE/cgi-bin/config/settings.ini");
Labyrinth::Globals::DBConnect();

# Most Recent Entries
$settings{perma} = $tvars{webpath} . '/wiki/';

my $wiki = Labyrinth::Plugin::Wiki->new();
$wiki->Recent();

for my $item (@{$tvars{wikihash}{recent}}) {
    my %xml;
    $xml{data}{$_} = $item->{$_} for(qw(pagename createdate));
    $xml{data}{body} = $item->{comment} || '-- no comment added --';
    $xml{data}{title} = "$item->{pagename} : Version $item->{version}";
    $xml{data}{pageid} = "$item->{pagename}&version=$item->{version}";
    $xml{data}{permapath} = "/wiki/$item->{pagename}&version=$item->{version}";
    push @{$tvars{xmlhash}}, \%xml;
}

#use Data::Dumper;
#print STDERR Dumper($tvars{xmlhash});

for my $item (@types) {
    my $rss = Labyrinth::RSS->new( %$item, perma => $settings{perma}, id => 'pageid' );
    my $xml = $rss->feed(@{$tvars{xmlhash}});
    write_xml("rss/$item->{type}-$item->{version}.xml",$xml);
}

sub write_xml {
    my $file = shift;
    my $xml  = shift;
    my $target = "$BASE/html/$file";
    mkpath(dirname($target));

    my $fh = IO::File->new($target,'w')    or die "Cannot write to file [$target]: $!";
    print $fh $xml;
    $fh->close;
}