#!/usr/bin/perl -w

use strict;
use File::Find qw();
use POSIX qw(strftime);
use WWW::Google::SiteMap qw();
#use WWW::Google::SiteMap::Ping qw();
  
chdir('/home/nicolaw/webroot/www/bb-207-42-158-85.fallbr.tfb.net/') || die $!;
my $map = WWW::Google::SiteMap->new(file => 'sitemap.gz');

File::Find::find({wanted => sub {
			my ($dev,$ino,$mode,$nlink,$uid,$gid,$mtime,$vol);
			(($dev,$ino,$mode,$nlink,$uid,$gid,undef,undef,undef,$mtime) = lstat($_)) &&
			-d _ &&
			s/^\.\/// &&
			!/\/\./s &&
			($vol = substr($_,0,1)) &&
			print("$_\n") &&
			$map->add(WWW::Google::SiteMap::URL->new(
					loc        => "http://bb-207-42-158-85.fallbr.tfb.net/$_",
					lastmod    => strftime('%Y-%m-%d',localtime($mtime)),
					changefreq => ($vol eq 'D' ? 'daily' : 'monthly'),
					priority   => ($vol eq 'D' ? 0.75 : 0.25),
				  ));
		}, no_chdir => 1, follow => 1}, '.');

$map->write;

#my $ping = WWW::Google::SiteMap::Ping->new(
#		'http://bb-207-42-158-85.fallbr.tfb.net/sitemap.gz',
#	);

#eval {
#	$ping->submit;
#	print "These pings succeeded:\n";
#	foreach($ping->success) {
#		print "$_: ".$ping->status($_)."\n";
#	}
#	print "These pings failed:\n";
#	foreach($ping->failure) {
#		print "$_: ".$ping->status($_)."\n";
#	}
#};

exit;

__END__

