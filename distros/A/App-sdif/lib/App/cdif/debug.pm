=head1 NAME

debug - debug module

=head1 SYNOPSIS

cdif -Mdebug

=cut

package App::cdif::debug;

use strict;
use warnings;

use Getopt::EX::Loader;

$Getopt::EX::Loader::debug = 1;

1;
