package Bio::Grid::Run::SGE::Iterator::List;

use Mouse;

use warnings;
use strict;

our $VERSION = '0.066'; # VERSION


has cur_comb_idx => ( is => 'rw', lazy_build => 1 );

__PACKAGE__->meta->make_immutable;

1;
