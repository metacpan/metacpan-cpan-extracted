#!/usr/bin/perl

=head1 NAME

httpd-perl-startup.pl - Sample mod_perl startup file

=head1 SYNOPSIS

In httpd.conf:
	PerlRequire /etc/httpd/perl/httpd-perl-startup.pl

=head1 VARIABLES

=cut

use strict;
use warnings;

use lib qw( /etc/httpd/perl/lib );

use Apache::MiniWiki;

=head2 $wikidir
The directory where all your Wikis are located,
in individual subdirectories of their own.
=cut
my $wikidir = '/var/www/MiniWiki';

=head2 $wikipasswdfile
Path to the httpd password file for Wiki authentication.
=cut
my $wikipasswdfile = '/etc/httpd/pw/passwd';

=head2 $wikigroupfile
Path to the httpd group file for Wiki authentication.
=cut
my $wikigroupfile = '/etc/httpd/pw/group';

=head2 %wikis
A hash listing all the available Wikis and their properties,
as follows:

  %wikis = (
    'wiki-name' => {
      _title => 'Wiki Title',
      _uri => '/wiki-uri',
      _public => 0|1
    }
  )

All the keys are optional. If _public is 0, the Wiki will be
password-protected. If 1, it will use Apache::MiniWiki::access_handler,
which allows public viewing, and requires a password to edit
(not entirely Wiki-nature, I know).

=cut
my %wikis = (
	'lit-review' => {
		_title => "Concept Formation Annotated Bibliography",
  	_public => 0
	},
	'perl-ai' => {
		_title => "AI-Perl Resources Page",
    _uri => "/ai-perl",
  	_public => 1
	},
	'alife' => {
		_title => "Artificial Life",
  	_public => 0
	},
	'bookmarks' => {
		_title => "Bookmarks",
  	_public => 0
	}
);

while (my ($wiki, $wiki_info) = each %wikis) {
	my $uri = $wiki_info->{_uri} || "/$wiki";
	#$uri .= '-devel';
	my $title = $wiki_info->{_title} || "Apache::MiniWiki Authentication";

	# Deal with authentication, depending
	# on whether the wiki is public or not.
	my $perlaccesshandler = $wiki_info->{_public} ?
		"PerlAccessHandler Apache::MiniWiki::access_handler" : '';

	Apache->httpd_conf( <<EOF );
<Location $uri>
	PerlAddVar datadir "$wikidir/$wiki/"
	PerlAddVar vroot "$uri"
	PerlAddVar authen "$wikipasswdfile"
	SetHandler perl-script
	PerlHandler Apache::MiniWiki

	$perlaccesshandler

	AuthType Basic
	AuthName "$title"
	AuthUserFile "$wikipasswdfile"
	AuthGroupFile "$wikigroupfile"
	Require group $wiki
</Location>
EOF
}

1;
