use 5.010;
use warnings;
use strict;

our $VERSION = '2.00';

use rlib;

use App::PP::Autolink;


my $pp_autolink = App::PP::Autolink->new (@ARGV);

$pp_autolink->build;

