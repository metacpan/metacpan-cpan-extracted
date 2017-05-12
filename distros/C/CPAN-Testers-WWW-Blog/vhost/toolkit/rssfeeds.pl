#!/usr/bin/perl -w
use strict;

my $BASE;

# create images in pages
BEGIN {
    $BASE = '/var/www/cpanblog';
}

#----------------------------------------------------------
# Additional Modules

use lib qw|../cgi-bin/lib ../cgi-bin/plugins|;
use Labyrinth::Globals;
use Labyrinth::RSS;
use Labyrinth::Variables;
use Labyrinth::Plugin::Articles;

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

Labyrinth::Globals::LoadSettings("rssfeeds.ini");
Labyrinth::Globals::DBConnect();

# Diary Entries
$settings{perma} = $tvars{webpath} . '/diary/';
$cgiparams{sectionid} = 6;
$settings{data}{article_limit} = 10;
$settings{data}{article_stop}  = 10;

my $arts = Labyrinth::Plugin::Articles->new();
$arts->List();

$tvars{block} = 'articles/arts-block2.html';

#use Labyrinth::Audit;
#use Data::Dumper;
#LogDebug( Dumper(\%tvars) );

for my $item (@types) {
    my $rss = Labyrinth::RSS->new( %$item, perma => '/diary/' );
    my $xml = $rss->feed(@{$tvars{mainarts}});
    write_xml("rss/$item->{type}-$item->{version}.xml",$xml);
}

sub write_xml {
    my $file = shift;
    my $xml  = shift;
    my $fh = IO::File->new("$BASE/html/$file",'w')    or die "Cannot write to file [$BASE/html/$file]: $!";
    print $fh $xml;
    $fh->close;
}

__END__

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2011 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
