#!/usr/bin/perl -w
use strict;

use vars qw($VERSION);
$VERSION = '0.13';

#----------------------------------------------------------
# Additional Modules

use lib qw|. ./lib ./plugins|;

#use CGI::Carp			qw(fatalsToBrowser);

use Labyrinth;

#----------------------------------------------------------

my $app = Labyrinth->new();
$app->run('/var/www/cpanprefs/cgi-bin/config/settings.ini');

1;

__END__
