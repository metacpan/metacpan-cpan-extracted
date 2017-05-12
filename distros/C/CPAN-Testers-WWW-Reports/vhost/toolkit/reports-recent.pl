#!/usr/bin/perl -w
use strict;

$|++;

use vars qw($VERSION);
$VERSION = '3.44';

=head1 NAME

reports-recent - Build recent reports pages

=head1 SYNOPSIS

  perl reports-recent.pl

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
use Labyrinth::Plugin::CPAN::Builder;

#----------------------------------------------------------
# Code

Labyrinth::Variables::init();   # initial standard variable values
Labyrinth::Globals::LoadSettings("$BASE/cgi-bin/config/settings.ini");
Labyrinth::Globals::DBConnect();

    SetLogFile( FILE   => '/var/www/reports/toolkit/logs/recent-audit.log',
                USER   => 'labyrinth',
                LEVEL  => 0,
                CLEAR  => 1,
                CALLER => 1);

my $content = Labyrinth::Plugin::Content->new();
$content->GetVersion();

my $builder = Labyrinth::Plugin::CPAN::Builder->new();
$builder->RecentPage();

__END__

=head1 AUTHOR

  Copyright (c) 2009 Barbie <barbie@cpan.org> Miss Barbell Productions.

=head1 LICENSE

  This program is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

  See http://www.perl.com/perl/misc/Artistic.html

=cut
