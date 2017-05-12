#!/usr/bin/perl -w
use strict;

use vars qw($VERSION);
$VERSION = '1.12';

#----------------------------------------------------------
# Additional Modules

use lib qw|. ./lib ./plugins|;

#use CGI::Carp			qw(fatalsToBrowser);

use Labyrinth;

#----------------------------------------------------------

my $wiki = Labyrinth->new();
$wiki->run('/var/www/cpanwiki/cgi-bin/config/settings.ini');

1;

__END__
