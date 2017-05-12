#!/usr/bin/perl -w
use strict;

use vars qw($VERSION);
$VERSION = '0.15';

#----------------------------------------------------------
# Additional Modules

use lib qw|. ./lib ./plugins|;

#use CGI::Carp			qw(fatalsToBrowser);

use Labyrinth;

#----------------------------------------------------------

my $lab = Labyrinth->new();
$lab->run('/var/www/cpanadmin/cgi-bin/config/settings.ini');

1;

__END__
