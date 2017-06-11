#!/usr/bin/perl -w
use strict;

$|++;

use vars qw($VERSION);
$VERSION = '3.59';

=head1 NAME

reports-release - Updates the release_summary table

=head1 SYNOPSIS

  perl reports-release.pl

=head1 DESCRIPTION

??.

=cut

my $BASE;

# create images in pages
BEGIN {
    $BASE = '/var/www/reports';
}

#----------------------------------------------------------
# Additional Modules

use lib qw|../cgi-bin/lib ../cgi-bin/plugins|;

use Labyrinth::Audit;
use Labyrinth::DBUtils;
use Labyrinth::DTUtils;
use Labyrinth::Globals;
use Labyrinth::Variables;

use Labyrinth::Plugin::Content;
use Labyrinth::Plugin::CPAN::Release;

use Getopt::Long;

#----------------------------------------------------------
# Code

my %options;
usage() if(!GetOptions( \%options, 'create|c', 'update|u', 'fix|f', 'rebuild|r', 'dist=s', 'version=s'));
if($options{rebuild}) {
    usage() unless($options{dist} && $options{version});
}

Labyrinth::Variables::init();   # initial standard variable values
Labyrinth::Globals::LoadSettings("$BASE/cgi-bin/config/settings.ini");
Labyrinth::Globals::DBConnect();

    SetLogFile( FILE   => '/var/www/reports/toolkit/logs/release-audit.log',
                USER   => 'labyrinth',
                LEVEL  => 0,
                CLEAR  => 1,
                CALLER => 1);

my $content = Labyrinth::Plugin::Content->new();
$content->GetVersion();

_log("Start");

my $builder = Labyrinth::Plugin::CPAN::Release->new();
$builder->Create( \&_log)    if($options{create});
$builder->Update( \&_log)    if($options{update});
$builder->Fix(    \&_log)    if($options{fix});
$builder->Rebuild(\&_log,$options{dist},$options{version}) 
                             if($options{rebuild});

_log("Finish");

sub _log {
    my @date = localtime(time);
    my $date = sprintf "%04d/%02d/%02d %02d:%02d:%02d", $date[5]+1900, $date[4]+1, $date[3], $date[2], $date[1], $date[0];
    print "$date " . join(' ',@_ ). "\n";
}

sub usage {
    print STDERR "$0 ( --create | --update | --fix | --rebuild --dist=<dist> --version=<vers>) [--verbose]\n";
    exit;
}

__END__

=head1 AUTHOR

  Copyright (c) 2009-2017 Barbie <barbie@cpan.org> Miss Barbell Productions.

=head1 LICENSE

  This program is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.
  See http://www.perl.com/perl/misc/Artistic.html

=cut
