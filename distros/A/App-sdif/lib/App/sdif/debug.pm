=head1 NAME

debug - debug module

=head1 SYNOPSIS

sdif -Mdebug

=cut

package App::sdif::debug;

use strict;
use warnings;

use Getopt::EX::Loader;

$Getopt::EX::Loader::debug = 1;

1;
