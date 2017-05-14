use v5.10;
use strict;
use warnings;

package App::PandoraPeriscope;
# ABSTRACT: A Periscope for Pandora

use File::Spec;
use File::Basename;

use Periscope;

my $URL   = 'http://pandora.com';
my $TITLE = 'Pandora Periscope';
my $ICON  = File::Spec->join(dirname(__FILE__), '..', '..', 'extra', 'Pandora.png');

sub exec {
	Periscope->new(address => $URL, title => $TITLE, icon => $ICON, width => 800, height => 600)->show;
}

1;
